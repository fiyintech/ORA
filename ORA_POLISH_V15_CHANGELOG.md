# ORA Web v15 — Messaging, account controls, Graphite theme

## Implemented
- Logged-out root route no longer renders authenticated app shell during auth loading or when unauthenticated.
- Settings now includes Switch account and Log out actions. Both end the current Supabase session and return to login; switch-account wording is used for the multi-account workflow.
- Added Delete for me and Delete for everyone message actions.
- Added message_deletions table/RLS and RPC for per-user message hiding.
- Added right-click/context menu support for chat messages.
- Message action menu closes when clicking elsewhere or scrolling.
- Added Forward and Copy actions; Copy appears for text messages. Forward supports text and available media.
- Added forwarding conversation chooser.
- Added active-conversation presence heartbeat so message notifications are not created while the recipient is actively in that chat. Presence expires after 30 seconds.
- Existing message notification read handling remains in place.
- Added emoji and sticker-style picker to the chat composer.
- Reworked the previous Plum theme into a neutral Graphite theme with restrained teal/green accents inspired by modern dark chat UIs.
- Existing full-screen media viewer remains used for chat and feed media.
- Added per-user hidden-message filtering to conversation/message reads.

## Validation
- TypeScript/TSX transpilation check: 54 files, 0 syntax diagnostics.
- Full npm build not run because dependencies are not installed in this environment.
