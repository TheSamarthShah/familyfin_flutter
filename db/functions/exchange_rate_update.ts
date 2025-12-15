// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

console.info('server started');

Deno.serve(async (req: Request) => {
  try {
    // 1. Fetch from API
    // Ensure you have set CURRENCY_RATE_ENDPOINT in your secrets!
    const endpoint = Deno.env.get("CURRENCY_RATE_ENDPOINT");
    if (!endpoint) throw new Error("Secret CURRENCY_RATE_ENDPOINT is missing");

    const apiRes = await fetch(endpoint);
    const data = await apiRes.json();

    // SAFETY CHECK: Verify the API returned success
    if (data.result !== "success") {
        throw new Error(`API Error: ${data["error-type"] || "Unknown failure"}`);
    }

    // FIX: The JSON key is 'conversion_rates', not 'rates'
    const rates = data.conversion_rates; 

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // 2. Create an array of Promises (Pending updates)
    const updatePromises = Object.entries(rates).map(([code, rate]) => {
      return supabase
        .from('currencies')
        .update({ 
            rate_to_usd: rate,
            last_updated: new Date().toISOString()
        })
        .eq('code', code); // Only updates if code exists in your DB
    });

    // 3. Fire them all at once
    await Promise.all(updatePromises);

    return new Response(JSON.stringify({ success: true, count: updatePromises.length }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Function failed:", error); // Important for debugging in Dashboard
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});