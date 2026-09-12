# ORA Power Hour — payment setup

Phase 2 adds a ₦100 one-hour Premium pass backed by Paystack.

## What is included

- `payment_transactions` and `premium_entitlements` schema migration
- Authenticated Edge Function to initialize a Paystack checkout
- Public Paystack webhook with HMAC SHA-512 signature verification
- Authenticated verification fallback for delayed webhooks
- One-hour entitlement extension logic
- React Premium context and countdown
- `/premium` and `/premium/payment-complete` routes
- Payment history
- Settings entry point

## Before enabling payments

Apply the SQL migration deliberately:

`apps/mobile/docs/sql/20260911_premium_power_hour_payments.sql`

Do not paste payment secrets into the web app or commit them to Git.

## Supabase Edge Function secrets

Set these as Supabase Edge Function secrets:

- `PAYSTACK_SECRET_KEY` — Paystack test key for staging, live key for production
- `PAYSTACK_CALLBACK_URL` — the ORA web origin, for example `https://ora-two-pink.vercel.app`

The functions also use the Supabase-provided server credentials. Never expose a Supabase secret/service-role key in Vercel/browser code.

## Paystack dashboard

Configure the webhook URL to:

`https://<SUPABASE_PROJECT_REF>.supabase.co/functions/v1/paystack-webhook`

Use the same Paystack environment as the key stored in Supabase.

## User flow

1. User opens `/premium`.
2. ORA calls `initialize-premium-payment` with the signed-in user's session.
3. The function creates a unique pending payment and initializes Paystack for exactly ₦100.
4. Paystack hosts the payment checkout.
5. Paystack calls `paystack-webhook` after a successful charge.
6. ORA validates the webhook signature, reference, amount, currency, and product.
7. ORA records the payment and grants one hour of Premium.
8. The callback page also performs server-side verification so a delayed webhook does not leave a legitimate payment waiting indefinitely.
9. If the user buys while Premium is active, the new hour starts at the current expiry instead of overlapping it.

## Important production rule

The browser countdown is only presentation. Premium authorization must continue to be based on `premium_entitlements.expires_at` and server-side checks. Do not trust a local timer, localStorage flag, or frontend-only `isPremium` value for protected operations.

## Current scope

This package establishes the payment/entitlement foundation. Individual Premium tools should be gated against the entitlement as they are implemented in Phase 2.
