import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const POWER_HOUR_AMOUNT_KOBO = 10000;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SECRET_KEY");
  const paystackSecret = Deno.env.get("PAYSTACK_SECRET_KEY");
  const callbackUrl = Deno.env.get("PAYSTACK_CALLBACK_URL") ?? Deno.env.get("ORA_WEB_URL");

  if (!supabaseUrl || !anonKey || !serviceKey || !paystackSecret || !callbackUrl) {
    return json({ error: "Payment service is not configured." }, 500);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Authentication required." }, 401);

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const admin = createClient(supabaseUrl, serviceKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user?.email) return json({ error: "Unable to identify your account." }, 401);

  const reference = `ORA-${crypto.randomUUID()}`;
  const { data: transaction, error: insertError } = await admin
    .from("payment_transactions")
    .insert({
      user_id: userData.user.id,
      provider: "paystack",
      reference,
      amount_kobo: POWER_HOUR_AMOUNT_KOBO,
      currency: "NGN",
      product_code: "power_hour",
      status: "pending",
    })
    .select("id, reference")
    .single();

  if (insertError || !transaction) return json({ error: "Unable to create payment." }, 500);

  const response = await fetch("https://api.paystack.co/transaction/initialize", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${paystackSecret}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      email: userData.user.email,
      amount: String(POWER_HOUR_AMOUNT_KOBO),
      currency: "NGN",
      reference,
      callback_url: `${callbackUrl.replace(/\/$/, "")}/premium/payment-complete`,
      metadata: JSON.stringify({
        ora_user_id: userData.user.id,
        ora_payment_id: transaction.id,
        product_code: "power_hour",
      }),
    }),
  });

  const result = await response.json().catch(() => null);
  if (!response.ok || !result?.status || !result?.data?.authorization_url) {
    await admin.from("payment_transactions").update({ status: "failed", provider_payload: result }).eq("id", transaction.id);
    return json({ error: "Paystack could not start the payment." }, 502);
  }

  return json({
    authorizationUrl: result.data.authorization_url,
    reference,
    paymentId: transaction.id,
  });
});

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}
