import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { text, user_id } = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 1. FETCH CONTEXT (Parallel)
    // We fetch names directly to save processing time later
    const [catsRes, acctsRes, histRes, profRes] = await Promise.all([
      supabaseClient.from('categories').select('id, name').eq('user_id', user_id),
      supabaseClient.from('accounts').select('id, name').eq('user_id', user_id),
      // Optimization: Fetch only necessary fields for pattern matching, limit to 10
      supabaseClient.from('logs').select('item_name, category_id, account_id').eq('user_id', user_id).order('created_at', { ascending: false }).limit(10),
      supabaseClient.from('profiles').select('currency_code').eq('id', user_id).single()
    ])

    const categories = catsRes.data ?? []
    const accounts = acctsRes.data ?? []
    const rawHistory = histRes.data ?? []
    const baseCurrency = profRes.data?.currency_code ?? 'INR'

    // 2. TOKEN OPTIMIZATION: COMPRESS CONTEXT
    // Instead of sending JSON objects, we send a tiny string representation.
    // Format: "ItemName:CategoryName(AccountName)"
    const compressedHistory = rawHistory.map(h => {
        const cName = categories.find(c => c.id === h.category_id)?.name || '?';
        const aName = accounts.find(a => a.id === h.account_id)?.name || '?';
        return `${h.item_name}:${cName}(${aName})`;
    }).join(' | ');

    const categoryNames = categories.map(c => c.name).join(', ');
    const accountNames = accounts.map(a => a.name).join(', ');
    const today = new Date().toISOString().split('T')[0];

    // 3. ULTRA-EFFICIENT PROMPT
    const systemPrompt = `
    Role: Finance Parser. Today: ${today}. BaseCurrency: ${baseCurrency}.
    
    Context:
    - Cats: [${categoryNames}]
    - Accts: [${accountNames}]
    - Patterns: [${compressedHistory}]

    Rules:
    1. Input in any language/script -> Translate item_name to English.
    2. Match "item_name" to closest Pattern. If "Uber" was "Transport" before, use "Transport".
    3. If input currency != ${baseCurrency}, set foreign_amount & foreign_currency_code. amount=0.
    4. Account Rule: Explicit mentions > Pattern Match > Default (${accounts[0]?.name}).

    Output JSON:
    {
      "amount": number,
      "foreign_amount": number|null,
      "foreign_currency_code": string|null,
      "category_name": string (Exact match from Cats),
      "account_name": string (Exact match from Accts),
      "type": "expense"|"income"|"transfer",
      "item_name": string (English),
      "log_date": "YYYY-MM-DD"
    }
    `

    // 4. CALL OPENAI (GPT-4o-mini)
    const openAIResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-5-nano',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: text }
        ],
        response_format: { type: "json_object" },
        temperature: 0.1 // Low temp = cheaper because it stops hallucinations/retries
      }),
    })

    const aiData = await openAIResponse.json()
    
    // Safety check for empty response
    if (!aiData.choices || !aiData.choices[0].message.content) {
        throw new Error("AI returned empty response");
    }

    const result = JSON.parse(aiData.choices[0].message.content)

    // 5. RESOLVE ID MAPPING
    const matchedCategory = categories.find(c => c.name.toLowerCase() === result.category_name.toLowerCase()) || categories[0]
    const matchedAccount = accounts.find(a => a.name.toLowerCase() === result.account_name.toLowerCase()) || accounts[0]

    // 6. INSERT LOG
    const { data: insertedLog, error } = await supabaseClient
      .from('logs')
      .insert({
        user_id: user_id,
        amount: result.amount,
        foreign_amount: result.foreign_amount,
        foreign_currency_code: result.foreign_currency_code,
        category_id: matchedCategory?.id,
        account_id: matchedAccount?.id,
        type: result.type,
        item_name: result.item_name,
        log_date: result.log_date,
        description: `Voice: ${text}`,
        is_verified: false
      })
      .select()
      .single()

    if (error) throw error

    return new Response(JSON.stringify({ success: true, log: insertedLog }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})