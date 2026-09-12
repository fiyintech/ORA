# cleanup-chat-media

The live Supabase project runs `cleanup-chat-media` once per minute via `pg_cron`/`pg_net`.
The Edge Function uses the service role internally to remove expired objects from the `chat-media` bucket and clears the corresponding media fields on `public.messages`.

Lifecycle: media receives a 24-hour fallback expiry at send time; once the recipient fully views an image or finishes a video, the database sets the expiry to three minutes later.
