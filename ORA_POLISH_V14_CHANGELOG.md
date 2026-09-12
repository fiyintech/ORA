# ORA Web v14 — navigation, performance, notifications and view-once media

## Public landing
- Public `/` no longer renders the authenticated Topbar/Sidebar/BottomNav.
- Logged-out users see the dedicated landing experience only.

## Performance
- Increased short-lived page cache windows to 10 minutes.
- Added authenticated startup cache warming for Feed, Hoods, Aura, Messages and Notifications.
- Cached conversation participant profiles.
- Switched read-heavy client identity lookups from `auth.getUser()` to local `auth.getSession()` where appropriate, reducing avoidable auth round trips.

## Notifications / messages
- Opening a conversation now marks its message notifications read even when the user arrived directly from `/messages?conversation=...`.
- Incoming messages in the currently open conversation immediately clear the related notification state.
- The unread notification badge excludes the active conversation's message notifications.
- Message notification logic remains compatible with the existing notification history.

## View-once chat media
- Photos/videos in chat open in a full-screen viewer.
- Recipient media is marked viewed only when opened, not merely when it scrolls into view.
- Recipient gets a 12-second save/download window.
- After the window, the message is consumed: Storage object + message row are deleted.
- Scheduled cleanup also removes viewed media after the same 12-second window if the client closes.
- Sender-side manual deletion remains supported.
- Realtime DELETE events now remove hard-deleted messages safely instead of treating a DELETE payload as an UPDATE.

## Feed media
- Post images open in the same full-screen media viewer.
- Added keyboard Escape/overlay-close behavior and stronger focus/click affordances.

## Theme
- Plum remains the clean dark alternative to the previous gold/brown treatment.
- Native controls are forced to dark color-scheme so the Plum theme stays visually consistent.
