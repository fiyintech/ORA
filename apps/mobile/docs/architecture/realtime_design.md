# ORA Realtime Design

## Overview

This document describes the realtime features for ORA using Supabase Realtime.
All subscriptions are documented for future implementation.

---

## Chat Subscriptions

### Purpose
Enable real-time messaging between users.

### Subscription Pattern
```sql
-- Subscribe to messages in a conversation
SELECT * FROM messages
WHERE conversation_id = '{conversationId}'
AND created_at > '{lastMessageTimestamp}'
```

### Events
- `INSERT` — New message received
- `UPDATE` — Message edited or deleted

### Client Behavior
1. Subscribe when user opens a conversation.
2. Receive new messages instantly.
3. Update UI with new message.
4. Play notification sound/vibration.
5. Mark message as read.

### Reconnection
- On disconnect, resubscribe automatically.
- On reconnect, fetch missed messages via REST API.
- Show "reconnecting..." indicator.

---

## Notification Subscriptions

### Purpose
Deliver real-time notifications to users.

### Subscription Pattern
```sql
-- Subscribe to notifications for current user
SELECT * FROM notifications
WHERE user_id = '{currentUserId}'
AND created_at > '{lastNotificationTimestamp}'
```

### Events
- `INSERT` — New notification (like, comment, follow, mention, achievement)

### Client Behavior
1. Subscribe on app launch.
2. Show badge count on bell icon.
3. Play subtle notification sound.
4. Update notification list in real-time.

### Notification Types
- **Like** — Someone liked your post
- **Comment** — Someone commented on your post
- **Follow** — Someone followed you
- **Mention** — Someone mentioned you in a post/comment
- **Hood Invite** — Invited to join a Hood
- **Achievement** — Unlocked a new achievement

---

## Hood Updates

### Purpose
Keep Hood feeds and members in sync.

### Subscription Pattern
```sql
-- Subscribe to new posts in joined Hoods
SELECT * FROM hood_posts
WHERE hood_id IN ({userHoodIds})
AND created_at > '{lastPostTimestamp}'
```

### Events
- `INSERT` — New post in a Hood
- `INSERT` on `hood_members` — New member joined

### Client Behavior
1. Subscribe to all joined Hoods.
2. Update Hood feed when new posts arrive.
3. Update member count when users join/leave.
4. Show "new posts" indicator if user is not viewing the feed.

---

## Feed Refresh

### Purpose
Update the global feed with new posts from followed users.

### Subscription Pattern
```sql
-- Subscribe to posts from followed users
SELECT * FROM posts
WHERE user_id IN ({followedUserIds})
AND created_at > '{lastFeedTimestamp}'
```

### Events
- `INSERT` — New post from followed user

### Client Behavior
1. Subscribe on app launch.
2. Prepend new posts to feed.
3. Show "new posts" banner if user has scrolled down.
4. Update feed tab badge.

---

## Leaderboard Refresh

### Purpose
Keep leaderboard rankings up-to-date.

### Subscription Pattern
```sql
-- Subscribe to aura changes from top 100 users
SELECT * FROM aura_history
WHERE user_id IN ({top100UserIds})
AND created_at > '{lastLeaderboardUpdate}'
```

### Events
- `INSERT` on `aura_history` — Aura points changed

### Client Behavior
1. Subscribe when user views leaderboard.
2. Recalculate rankings on Aura changes.
3. Animate rank changes.
4. Update user's own rank in profile.

---

## Realtime Channels

### Channel Naming Convention
- `chat:{conversationId}` — Chat messages
- `notifications:{userId}` — User notifications
- `hood:{hoodId}` — Hood updates
- `feed:{userId}` — User's feed
- `leaderboard` — Global leaderboard

### Presence
Track online status for:
- Chat participants
- Hood members
- Friends

```sql
-- Presence schema
{
  "user_id": "uuid",
  "status": "online" | "offline" | "away",
  "last_seen": "timestamp"
}
```

---

## Error Handling

### Connection Failures
- Retry with exponential backoff (1s, 2s, 4s, 8s, max 30s).
- Show "connection lost" indicator.
- Fall back to polling if WebSocket fails.

### Message Delivery
- Queue messages when offline.
- Send on reconnection.
- Show "sending..." indicator.
- Confirm delivery with checkmark.

### Duplicate Events
- Use `idempotency_key` to deduplicate.
- Ignore events with already-processed IDs.

---

## Performance Considerations

### Subscription Limits
- Max 10 active subscriptions per client.
- Prioritize: notifications > chat > feed > leaderboard.

### Throttling
- Debounce rapid updates (e.g., leaderboard).
- Batch multiple changes into single UI update.

### Offline Mode
- Queue realtime events when offline.
- Replay on reconnection.
- Show "you have missed updates" banner.
