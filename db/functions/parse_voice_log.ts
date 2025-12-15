import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

Deno.serve(async (req) => {
  try {
    const { raw_text, user_id } = await req.json();
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // ---------------------------------------------------------
    // 1. FETCH CONTEXT DATA (Parallel for speed)
    // ---------------------------------------------------------
    const [profileRes, catRes, accRes, histRes] = await Promise.all([
      // A. Get User's Base Currency
      supabase.from("profiles").select("currency_code").eq("id", user_id).single(),
      
      // B. Get User's Categories
      supabase.from("categories").select("name").eq("user_id", user_id),
      
      // C. Get User's Accounts
      supabase.from("accounts").select("name").eq("user_id", user_id),
      
      // D. Get Recent History (Smart Pattern Matching)
      supabase.from("logs")
        .select("category:categories(name), account:accounts(name)")
        .eq("user_id", user_id)
        .order("created_at", { ascending: false })
        .limit(10)
    ]);

    // ---------------------------------------------------------
    // 2. PREPARE PROMPT VARIABLES
    // ---------------------------------------------------------
    const baseCurrency = profileRes.data?.currency_code || "USD";
    const categories = catRes.data?.map(c => c.name).join(", ") || "General";
    const accounts = accRes.data?.map(a => a.name).join(", ") || "Cash";
    
    // Format History: "Food -> Credit Card; Rent -> Bank"
    // @ts-ignore
    const history = histRes.data?.map(l => `${l.category?.name || 'Unk'} used ${l.account?.name || 'Cash'}`).join("; ");

    const finalSystemPrompt = `
      You are an intelligent financial parser API.
      
      ### CONTEXT VARIABLES
      - CURRENT TIME: ${new Date().toISOString()}
      - USER BASE CURRENCY: ${baseCurrency}
      - VALID CATEGORIES: [${categories}]
      - VALID ACCOUNTS: [${accounts}]
      - RECENT PATTERNS: [${history}]

      ### RULES
      1. If input currency != ${baseCurrency}, set 'foreign_amount' and 'foreign_currency_code'. Set 'amount' to 0.
      2. If input currency == ${baseCurrency}, set 'amount'. Leave foreign fields null.
      3. Use RECENT PATTERNS to guess the account if not specified.
      4. Return strictly valid JSON with keys: amount, foreign_amount, foreign_currency_code, category_name, account_name, type, item_name, log_date.
    `;

    // ---------------------------------------------------------
    // 3. CALL OPENAI
    // ---------------------------------------------------------
    const openAIRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        response_format: { type: "json_object" }, // <--- Strict JSON Mode
        messages: [
          { role: "system", content: finalSystemPrompt },
          { role: "user", content: raw_text },
        ],
      }),
    });

    const aiData = await openAIRes.json();
    const parsedLog = JSON.parse(aiData.choices[0].message.content);

    // ---------------------------------------------------------
    // 4. (OPTIONAL) HANDLE CURRENCY CONVERSION HERE
    // ---------------------------------------------------------
    // If AI returned a foreign amount, use your DB 'currencies' table to calculate 'amount'
    // (We discussed this logic in the previous step)

    return new Response(JSON.stringify(parsedLog), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});