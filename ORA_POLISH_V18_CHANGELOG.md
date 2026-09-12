# ORA Web V18 — themed environments, resilient chat media, emoji picker

## Appearance
- Restored two distinct appearance options instead of hard-coding the Luxe palette.
- **Graphite** restores the previous neutral dark ORA direction, with layered dot/wave/diagonal textures.
- **Luxe Forest** keeps the deep premium forest/black, ivory and antique-gold direction from the supplied reference, now with layered dot/wave textures.
- Theme patterns are visible across the broader app shell, not only as a flat background color.
- Existing chat wallpaper choices remain available.

## Messaging media
- Chat media uploads above ~6 MB now use Supabase TUS resumable uploads for better reliability on larger files and unstable connections.
- Current Supabase Free-plan ceiling remains **50 MB per file**; the app reports that limit clearly instead of failing with a generic unavailable message.
- Added browser-friendly AVIF/BMP image and additional common video MIME support in the prepared storage migration.
- Media URLs are refreshed from the stored `media_path` when messages are loaded, avoiding stale/pending public URLs.
- View-once media remains blurred until the receiver explicitly opens it; the 12-second expiry window begins after the view is registered.

## Emoji
- Removed the sticker control and sticker picker entirely.
- Expanded the emoji picker substantially and organized it into categories: Smileys & emotion, People & body, Animals & nature, Food & drink, Travel & places, Activities, Objects, and Symbols.
- Category tabs are horizontally scrollable and the emoji grid is independently scrollable, keeping the composer compact.

## Database migration
- Added `apps/mobile/docs/sql/20240921_chat_media_uploads_v2.sql`.
- The migration updates the `chat-media` bucket MIME allowlist while retaining the current 50 MB ceiling.
- It is prepared for the project's normal Supabase migration workflow and is **not auto-applied to production**.
