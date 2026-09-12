# ORA Web V32 — Full Feature Audit & Hardening Report

## Scope
This audit covers the current web application and the production Supabase project, including features introduced across the ORA polish and Power Hour passes. Mobile source was treated as reference only, per the web-first deployment scope.

## Feature inventory checked
- Authentication: public landing, sign-in, sign-up, session restore, auth-state changes, profile setup, password recovery/reset, saved-account switching, add-account flow, logout, account deletion.
- Navigation/app shell: protected routes, public routes, 404, desktop sidebar, mobile bottom navigation, topbar, route-specific shell behavior.
- Feed: loading/cache, realtime inserts/updates/deletes, text posts, Premium image posts, post limits, edit/delete, likes, comments/replies, reposts, share links, post-hash navigation, media fallback, full-screen media viewer.
- Hoods: discovery, create, public/private join, pending requests, leave, owner/admin controls, moderator management, ownership transfer, privacy changes, member removal, rejoin flow, Hood posts, sharing, RLS protections.
- Messaging: conversation creation, conversation list, unread counts, direct routing, realtime messages, message read state, smart presence, notifications, text limits, photo messages, video messages, voice notes, cumulative Standard voice quota, view-once media, 12-second media expiry, voice-note deletion after listening, forwarding, copying, delete-for-me, delete-for-everyone, emoji picker, media uploads/TUS, video playback MIME handling.
- Notifications: list/cache, realtime updates, unread badge, mark-one-read, mark-all-read, message/follow/post routing, active-conversation suppression.
- Profiles: current/public profile, follow/unfollow, follower counts, messaging shortcut, post/media tabs, profile setup, avatar/banner uploads, profile editing, fallback handling.
- Aura: current score, history, leaderboard, database triggers/rewards.
- Settings/appearance: Graphite/Luxe Forest themes, chat wallpapers, Premium wallpapers, Premium profile frames, account controls, delete-account confirmation, Power Hour entry point.
- Power Hour: ₦100/one-hour entitlement, Paystack initialization, webhook signature validation, callback verification, atomic fulfillment, entitlement countdown, payment history, Premium limits/gates, Standard/Premium UI locks.
- Reliability/security: cache behavior, relative imports, source transpilation, CSS delimiter balance, production schema, RLS, storage policies, realtime publication, Edge Function deployment state, Premium bypass paths.

## Static validation
- 59 web TS/TSX source files transpiled successfully with TypeScript transpile diagnostics: 0.
- Relative source import resolution: 0 missing relative imports.
- CSS brace balance: balanced.
- No TODO/FIXME/no-op markers were found in the web feature source during the scan.
- A complete `npm run build` could not be executed in this environment because the package dependency cache could not be fully installed; `npm ci --offline` reported a missing cached package and the environment has no usable local Vite/Node type installation. This is an environment limitation, not a source transpilation failure.

## Production Supabase validation
- Production migration chain was inspected through the current Power Hour daily voice/repost migrations.
- Production schema contains the expected core social, messaging, notification, Hood, Aura, payment, entitlement and voice-quota tables.
- Production realtime publication includes messages, notifications, post_reposts and posts.
- Production Edge Functions are active for cleanup-chat-media, initialize-premium-payment, paystack-webhook and verify-premium-payment.
- The cleanup-chat-media function is active at version 6 and uses authenticated receiver checks for per-message cleanup.
- Power Hour payment fulfillment uses row locking/advisory locking to prevent duplicate entitlement grants.
- Standard repost bypass was hardened: direct post_reposts INSERT/DELETE policies were removed; repost mutation is through the entitlement-aware RPC.
- Standard/Premium post limits were hardened at the posts RLS boundary.
- Standard Feed image storage uploads are now Premium-only.
- Direct message INSERT is blocked by RLS; message creation remains through the authenticated send_message RPC.
- Message content and media entitlement checks were added as database constraints backed by non-public helper functions.

## V31 issues found and fixed in V32
1. Standard voice recording could stop using whole seconds rather than the exact remaining milliseconds. V32 now tracks the allowance precisely and clamps recorded duration to the remaining quota.
2. Premium PostCard editing remained capped at 500 characters even though Power Hour allows 1,000. V32 makes the edit control dynamic: 500 Standard / 1,000 Power Hour.
3. Premium bypass paths existed through direct Supabase writes. V32 hardens posts, reposts, storage uploads and message inserts at the database/storage boundary.
4. Standard message content could exceed 500 characters through a direct RPC call. V32 adds a database check tied to current entitlement.
5. Standard image-message size could be bypassed through direct RPC/storage manipulation. V32 adds database-side media verification for message rows.

## Intentional limitations / items that require real-user runtime testing
- Browser microphone permission and MediaRecorder codec behavior must be exercised in a real browser/device.
- Paystack checkout requires a real Test Mode transaction to exercise the external payment provider.
- Multi-account switching requires at least two real authenticated accounts to exercise end-to-end.
- Hood owner/admin/rejoin behavior requires multiple accounts with different roles.
- Realtime behavior requires at least two live browser sessions.
- A production Vite build must still be confirmed by Vercel after the package is pushed, because this environment could not complete dependency installation.

## Result
The V32 package is the audited/hardened web package. It should replace the previous V31 package for the next deployment attempt.
