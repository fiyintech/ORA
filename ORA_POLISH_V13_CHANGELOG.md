# ORA Web Polish v13 — performance, theme, mobile header, chat-media deletion

This pass responds to the next round of deployed/local testing feedback. It keeps the existing feature set and Supabase architecture, but fixes the specific UX/performance and chat-media lifecycle problems identified in testing.

## Implemented

### 1. Replaced the irritating gold theme
- Removed the previous gold/brown "Aura Gold" visual palette.
- Reworked the alternate theme into a neutral **Plum** theme: charcoal/slate surfaces with ORA purple accents.
- Improved contrast while keeping the dark, premium ORA feel.
- Updated the Settings theme label from "Aura Gold" to **Plum**.

### 2. Real client-side caching / stale-while-revalidate
- Added a small cache layer backed by memory + `sessionStorage`.
- Cached data is scoped by resource/user where appropriate and automatically expires.
- Returning to Feed, Hoods, Aura, Notifications, Messages and Profiles can now render cached content immediately instead of waiting for another full request.
- Cached content is refreshed in the background so it does not become the permanent source of truth.
- Profile/auth startup was also changed to use the already-persisted Supabase session locally before doing authoritative background checks.
- This specifically addresses the repeated 2–3 second "load every page again" feeling during route navigation.

### 3. Mobile topbar redesign
- Desktop keeps the wide search field.
- Mobile no longer displays the desktop-width search input.
- Mobile topbar now uses compact Search and Notifications icon buttons alongside the ORA logo.
- Search remains one tap away and routes into the dedicated Search page.
- The notification control remains compact and retains its unread badge.

### 4. Chat photo/video deletion — database + Storage
- Explicit message deletion now permanently removes the message row from `public.messages` rather than only soft-deleting it.
- Before deleting, the client captures the message's `media_path`.
- The owned object is then removed from the Supabase `chat-media` Storage bucket.
- Storage deletion retries up to three times to tolerate transient failures.
- The UI removes the message immediately after successful deletion.
- Realtime chat updates now handle message DELETE events as well as UPDATE events.
- The Supabase `delete_own_message(uuid)` RPC was updated and deployed as a migration.

### 5. Automatic disappearing chat media cleanup
- The existing `ora-cleanup-chat-media` cron job was verified live and is running every minute.
- The cleanup Edge Function was deployed as version 2.
- Expired chat media is now removed from Supabase Storage and the corresponding message row is permanently deleted.
- This prevents expired photos/videos from remaining as empty or stale message records.
- The live cron endpoint was also verified to be returning HTTP 200 responses.

## Live Supabase changes

Applied to project `ora`:
- `ora_chat_message_media_delete_fix`
- `ora_chat_message_media_delete_hard_fix`

Deployed Edge Function:
- `cleanup-chat-media` version 2

## Validation

- 53 web TypeScript/TSX files passed TypeScript transpilation/syntax validation.
- Relative source imports were checked and all resolved.
- A full `tsc -b` still cannot complete in this environment because the local dependency/type cache is incomplete (`vite/client` and Node types are unavailable).
- Live Supabase migration state was rechecked after the database change.
- Live chat-media cleanup cron was verified active and its recent HTTP calls returned 200.

## Notes

- No existing user data was intentionally modified.
- No service-role credentials were added to the web client.
- The web client continues to use Supabase's publishable client credentials; Storage/DB authorization remains enforced by Supabase policies/RPCs.
