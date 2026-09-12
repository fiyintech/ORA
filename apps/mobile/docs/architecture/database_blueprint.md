# ORA Database Blueprint

## Overview

This document describes the production database schema for ORA's Supabase backend.
This is a design document only — no SQL migrations are included.

---

## Tables

### users
Authentication table managed by Supabase Auth.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| email | TEXT | Unique, used for login |
| created_at | TIMESTAMP | Account creation time |
| updated_at | TIMESTAMP | Last update time |

### profiles
User profile information.

| Column | Type | Description |
|--------|------|-------------|
| user_id | UUID | Primary key, FK to users |
| username | TEXT | Unique handle |
| display_name | TEXT | Full name |
| avatar | TEXT | URL or path |
| bio | TEXT | Personal description |
| school | TEXT | Education info |
| city | TEXT | Location |
| country | TEXT | Location |
| website | TEXT | Personal website |
| interests | TEXT[] | Array of interest strings |
| aura_points | INTEGER | Default 0 |
| steeze_level | INTEGER | Default 1 |
| verified | BOOLEAN | Default false |
| profile_completed | INTEGER | Percentage 0-100 |
| created_at | TIMESTAMP | Profile creation |
| updated_at | TIMESTAMP | Last update |

**Indexes:**
- `username` (unique)
- `aura_points` (for leaderboard queries)

### posts
User posts in the global feed.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| text | TEXT | Post content |
| media_urls | JSONB | Array of media URLs |
| visibility | TEXT | 'public', 'friends', 'private' |
| created_at | TIMESTAMP | Post time |
| updated_at | TIMESTAMP | Edit time |

**Indexes:**
- `user_id` (for user's posts)
- `created_at` (for feed ordering)

### post_media
Media attachments for posts.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| post_id | UUID | FK to posts |
| url | TEXT | Media URL |
| type | TEXT | 'image' or 'video' |
| order | INTEGER | Display order |

### comments
Comments on posts.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| post_id | UUID | FK to posts |
| user_id | UUID | FK to users |
| text | TEXT | Comment content |
| created_at | TIMESTAMP | Comment time |
| updated_at | TIMESTAMP | Edit time |

**Indexes:**
- `post_id` (for post's comments)

### comment_likes
Likes on comments.

| Column | Type | Description |
|--------|------|-------------|
| comment_id | UUID | FK to comments |
| user_id | UUID | FK to users |
| created_at | TIMESTAMP | Like time |

**Primary Key:** (comment_id, user_id)

### post_likes
Likes on posts.

| Column | Type | Description |
|--------|------|-------------|
| post_id | UUID | FK to posts |
| user_id | UUID | FK to users |
| created_at | TIMESTAMP | Like time |

**Primary Key:** (post_id, user_id)

### shares
Post shares.

| Column | Type | Description |
|--------|------|-------------|
| post_id | UUID | FK to posts |
| user_id | UUID | FK to users |
| created_at | TIMESTAMP | Share time |

**Primary Key:** (post_id, user_id)

### followers
User follow relationships.

| Column | Type | Description |
|--------|------|-------------|
| follower_id | UUID | FK to users |
| following_id | UUID | FK to users |
| created_at | TIMESTAMP | Follow time |

**Primary Key:** (follower_id, following_id)

### hoods
Community groups.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| owner_id | UUID | FK to users |
| name | TEXT | Hood name |
| description | TEXT | Hood description |
| category | TEXT | Category tag |
| banner | TEXT | Banner image URL |
| privacy | TEXT | 'public' or 'private' |
| created_at | TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | Last update |

**Indexes:**
- `owner_id`
- `category`

### hood_members
Hood membership.

| Column | Type | Description |
|--------|------|-------------|
| hood_id | UUID | FK to hoods |
| user_id | UUID | FK to users |
| role | TEXT | 'member', 'moderator', 'owner' |
| joined_at | TIMESTAMP | Join time |

**Primary Key:** (hood_id, user_id)

### hood_posts
Posts within a Hood.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| hood_id | UUID | FK to hoods |
| user_id | UUID | FK to users |
| text | TEXT | Post content |
| media_urls | JSONB | Media URLs |
| created_at | TIMESTAMP | Post time |

**Indexes:**
- `hood_id` (for hood's posts)
- `created_at` (for feed ordering)

### conversations
Direct message conversations.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| created_at | TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | Last message time |

### conversation_members
Participants in conversations.

| Column | Type | Description |
|--------|------|-------------|
| conversation_id | UUID | FK to conversations |
| user_id | UUID | FK to users |
| joined_at | TIMESTAMP | Join time |

**Primary Key:** (conversation_id, user_id)

### messages
Chat messages.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| conversation_id | UUID | FK to conversations |
| sender_id | UUID | FK to users |
| text | TEXT | Message content |
| media_url | TEXT | Optional media |
| type | TEXT | 'text', 'image', 'voice' |
| reply_to | UUID | Optional parent message |
| read_by | UUID[] | Array of reader IDs |
| created_at | TIMESTAMP | Send time |

**Indexes:**
- `conversation_id` (for conversation's messages)
- `created_at` (for message ordering)

### notifications
User notifications.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| type | TEXT | 'like', 'comment', 'follow', etc. |
| reference_id | UUID | Related entity ID |
| reference_type | TEXT | 'post', 'comment', etc. |
| read | BOOLEAN | Default false |
| created_at | TIMESTAMP | Notification time |

**Indexes:**
- `user_id` (for user's notifications)
- `created_at` (for ordering)

### achievements
Achievement definitions.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| code | TEXT | Unique code (e.g., 'first_impression') |
| name | TEXT | Display name |
| description | TEXT | Description |
| icon | TEXT | Icon URL |
| aura_reward | INTEGER | Aura points awarded |
| criteria | JSONB | Unlock conditions |

**Indexes:**
- `code` (unique)

### user_achievements
User achievement progress.

| Column | Type | Description |
|--------|------|-------------|
| user_id | UUID | FK to users |
| achievement_id | UUID | FK to achievements |
| unlocked_at | TIMESTAMP | Unlock time |

**Primary Key:** (user_id, achievement_id)

### aura_history
Audit trail for Aura changes.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| action | TEXT | Action type |
| amount | INTEGER | Change amount |
| reason | TEXT | Explanation |
| created_at | TIMESTAMP | Change time |

**Indexes:**
- `user_id` (for user's history)
- `created_at` (for time-based queries)

### leaderboard_cache
Precomputed leaderboard data.

| Column | Type | Description |
|--------|------|-------------|
| user_id | UUID | FK to users |
| rank | INTEGER | Current rank |
| period | TEXT | 'daily', 'weekly', 'monthly', 'all_time' |
| aura | INTEGER | Aura at time of caching |
| cached_at | TIMESTAMP | Cache time |

**Primary Key:** (user_id, period)

### reports
User-generated reports.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| reporter_id | UUID | FK to users |
| target_type | TEXT | 'post', 'user', 'hood', etc. |
| target_id | UUID | Reported entity ID |
| reason | TEXT | Report reason |
| status | TEXT | 'pending', 'resolved', 'dismissed' |
| created_at | TIMESTAMP | Report time |

---

## Storage Buckets

### avatars
User profile pictures.

- Path: `avatars/{user_id}/{filename}`
- Max size: 2MB
- Allowed types: image/jpeg, image/png, image/webp

### posts
Post media attachments.

- Path: `posts/{post_id}/{filename}`
- Max size: 10MB
- Allowed types: image/jpeg, image/png, image/webp, video/mp4

### hoods
Hood banner images.

- Path: `hoods/{hood_id}/{filename}`
- Max size: 2MB
- Allowed types: image/jpeg, image/png, image/webp

### chat-media
Chat message attachments.

- Path: `chat/{message_id}/{filename}`
- Max size: 10MB
- Allowed types: image/jpeg, image/png, image/webp, audio/mpeg
