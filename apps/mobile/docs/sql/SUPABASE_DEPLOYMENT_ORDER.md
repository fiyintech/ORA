# ORA Supabase deployment order

The ORA Supabase project is already connected for the current web development pass.

## Historical migration order

For a fresh ORA database, apply the consolidated bundle:

1. `00000000_ora_supabase_install.sql`

Or, when applying individual migrations, use the feature files in dependency order:

- `20240909_core_social_system.sql`
- `20240101_notifications_system.sql`
- `20240908_hoods_system.sql`
- `20240910_storage_posts.sql`
- `20240911_aura_system.sql`
- `20240912_notification_triggers.sql`
- `20240913_hood_rls_recursion_fix.sql`
- `20240914_messaging_notifications_hood_admin_profile_media.sql`
- `20240915_chat_write_security.sql`

`feed_rpc_functions.sql` is legacy/auxiliary and is not part of the current install path.

## Current live ORA project

The live project has additionally received the following targeted migrations during web integration:

- `ora_backend_missing_features_v1`
- `ora_security_and_aura_v2`
- `ora_storage_policies_and_validation_v1`
- `ora_notifications_realtime_v1`
- `hood_rls_recursion_fix_v1`
- `ora_messaging_notifications_hood_admin_profile_media_v1`
- `ora_private_hood_share_access_v1`
- `ora_chat_write_security_v1`

These were applied as targeted migrations rather than re-running the consolidated bundle over the existing database.

## Important

Never re-run the consolidated install bundle blindly against the live project. The live schema is authoritative and contains pre-existing tables/RPCs whose exact definitions differ from some of the historical preparation SQL.
- `20240916_hood_owner_admin_controls.sql`
- `20240917_chat_media_and_hood_rejoin.sql`
- `20240918_chat_media_cleanup_schedule.sql`
- `20240919_message_notification_type_fix.sql`

- `20240920_live_feed_realtime.sql` — enables Realtime for `posts` and `post_reposts` so the web feed updates live.
