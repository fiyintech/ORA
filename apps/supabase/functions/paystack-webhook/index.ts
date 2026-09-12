import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = { "Content-Type": "application/json" };

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const secret = Deno.env.get("PAYSTACK_SECRET_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SECRET_KEY");
  if (!secret || !supabaseUrl || !serviceKey) return new Response("Not configured", { status: 500 });

  const rawBody = await req.text();
  const signature = req.headers.get("x-paystack-signature") ?? "";
  const valid = await verifyHmacSha512(rawBody, secret, signature);
  if (!valid) return new Response("Invalid signature", { status: 401 });

  const payload = JSON.parse(rawBody);
  if (payload?.event !== "charge.success") return new Response("ok", { headers: corsHeaders });

  const data = payload.data;
  const reference = data?.reference;
  if (!reference || data?.status !== "success" || data?.currency !== "NGN" || Number(data?.amount) !== 10000) {
    return new Response("ok", { headers: corsHeaders });
  }

  const admin = createClient(supabaseUrl, serviceKey);
  const { data: payment } = await admin
    .from("payment_transactions")
    .select("id, amount_kobo, currency, product_code")
    .eq("reference", reference)
    .maybeSingle();

  if (!payment) return new Response("Unknown reference", { status: 404 });
  if (payment.amount_kobo !== 10000 || payment.currency !== "NGN" || payment.product_code !== "power_hour") {
    return new Response("Invalid payment", { status: 400 });
  }

  // The database function locks the payment row and serializes entitlement
  // extension per user, making webhook retries and callback races idempotent.
  const { error } = await admin.rpc("fulfill_power_hour_payment", {
    p_reference: reference,
    p_provider_transaction_id: Number(data.id),
    p_provider_payload: payload,
  });

  if (error) return new Response("Unable to fulfill payment", { status: 500 });
  return new Response("ok", { headers: corsHeaders });
});

async function verifyHmacSha512(body: string, secret: string, expectedHex: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body));
  const actual = [...new Uint8Array(signature)].map((b) => b.toString(16).padStart(2, "0")).join("");
  return actual === expectedHex;
}
