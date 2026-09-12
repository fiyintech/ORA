import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SECRET_KEY");
  const paystackSecret = Deno.env.get("PAYSTACK_SECRET_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey || !paystackSecret) return json({ error: "Payment service is not configured." }, 500);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Authentication required." }, 401);

  const userClient = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authHeader } } });
  const admin = createClient(supabaseUrl, serviceKey);
  const { data: userData } = await userClient.auth.getUser();
  if (!userData.user) return json({ error: "Authentication required." }, 401);

  const { reference } = await req.json().catch(() => ({ reference: "" }));
  if (typeof reference !== "string" || !reference) return json({ error: "Payment reference is required." }, 400);

  const { data: payment } = await admin
    .from("payment_transactions")
    .select("id, user_id, status, amount_kobo, currency, product_code")
    .eq("reference", reference)
    .maybeSingle();
  if (!payment || payment.user_id !== userData.user.id) return json({ error: "Payment not found." }, 404);

  const response = await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`, {
    headers: { Authorization: `Bearer ${paystackSecret}` },
  });
  const result = await response.json().catch(() => null);
  const data = result?.data;

  if (!response.ok || !result?.status || data?.status !== "success" || Number(data?.amount) !== 10000 || data?.currency !== "NGN") {
    return json({ status: payment.status });
  }

  // Both the callback verifier and Paystack webhook use the same atomic
  // database fulfillment path, so a race cannot grant two hours for one payment.
  const { error } = await admin.rpc("fulfill_power_hour_payment", {
    p_reference: reference,
    p_provider_transaction_id: Number(data.id),
    p_provider_payload: result,
  });
  if (error) return json({ error: "Payment verified but Premium activation failed." }, 500);

  return json({ status: "success" });
});

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}
