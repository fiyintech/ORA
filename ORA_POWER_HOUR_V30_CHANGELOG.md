# ORA Power Hour V30

## Standard limits
- Voice notes: 60 seconds total per UTC day, regardless of how many recordings are sent.
- Feed post reshares/reposts are Power Hour only.
- Text messages and photo messages remain available on Standard.

## Power Hour
- Removes the Standard daily voice-note allowance; voice notes remain temporary and disappear after listening.
- Allows Feed post reshares/reposts.

## Backend enforcement
- Added `voice_note_daily_usage` with an atomic quota check inside `send_message`.
- Added `get_voice_note_daily_remaining()` for the web composer.
- `toggle_post_repost` now requires an active Power Hour entitlement.
- Existing RLS/storage architecture is preserved.
