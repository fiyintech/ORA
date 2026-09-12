# ORA Power Hour V20 Checkpoint

- Added Vercel SPA rewrite so React Router deep links such as `/premium/payment-complete` resolve instead of returning Vercel 404.
- Updated Paystack webhook fulfillment to use the atomic `fulfill_power_hour_payment` database function.
- Updated callback verification to use the same atomic fulfillment path.
- This prevents webhook/callback races from double-granting Power Hour.
