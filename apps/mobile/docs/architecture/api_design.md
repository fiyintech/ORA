# ORA API Design

## Overview

This document defines the future REST/Supabase API endpoints for ORA.
All endpoints are documented for future implementation — no code is included.

---

## Authentication

### POST /auth/register
Register a new user.

**Request:**
```json
{
  "email": "string",
  "password": "string",
  "full_name": "string"
}
```

**Response:**
```json
{
  "user": { "id": "uuid", "email": "string" },
  "session": { "access_token": "string", "refresh_token": "string" }
}
```

### POST /auth/login
Login with email and password.

**Request:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "user": { "id": "uuid", "email": "string" },
  "session": { "access_token": "string", "refresh_token": "string" }
}
```

### POST /auth/logout
Logout the current user.

**Headers:** Authorization: Bearer {token}

**Response:** 204 No Content

### POST /auth/refresh
Refresh the access token.

**Request:**
```json
{
  "refresh_token": "string"
}
```

**Response:**
```json
{
  "session": { "access_token": "string", "refresh_token": "string" }
}
```

---

## Profile

### GET /profile/{userId}
Retrieve a user's profile.

**Response:**
```json
{
  "user_id": "uuid",
  "username": "string",
  "display_name": "string",
  "avatar": "string",
  "bio": "string",
  "school": "string",
  "city": "string",
  "country": "string",
  "website": "string",
  "interests": ["string"],
  "aura_points": 0,
  "steeze_level": 1,
  "verified": false,
  "profile_completed": 0
}
```

### PUT /profile/{userId}
Update a user's profile.

**Headers:** Authorization: Bearer {token}

**Request:**
```json
{
  "username": "string",
  "display_name": "string",
  "bio": "string",
  "school": "string",
  "city": "string",
  "country": "string",
  "website": "string",
  "interests": ["string"]
}
```

**Response:** 200 OK

### POST /profile/{userId}/avatar
Upload a profile avatar.

**Headers:** Authorization: Bearer {token}

**Request:** Multipart form data (image file)

**Response:**
```json
{
  "avatar_url": "string"
}
```

---

## Posts

### GET /posts/feed
Retrieve the global feed.

**Query Parameters:**
- `limit` (default: 20)
- `offset` (default: 0)

**Response:**
```json
[
  {
    "id": "uuid",
    "user": { "id": "uuid", "username": "string", "avatar": "string" },
    "text": "string",
    "media_urls": ["string"],
    "visibility": "public",
    "likes_count": 0,
    "comments_count": 0,
    "created_at": "timestamp"
  }
]
```

### POST /posts/create
Create a new post.

**Headers:** Authorization: Bearer {token}

**Request:**
```json
{
  "text": "string",
  "media_urls": ["string"],
  "visibility": "public"
}
```

**Response:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "text": "string",
  "media_urls": ["string"],
  "visibility": "public",
  "created_at": "timestamp"
}
```

### DELETE /posts/{postId}
Delete a post.

**Headers:** Authorization: Bearer {token}

**Response:** 204 No Content

### POST /posts/{postId}/like
Like a post.

**Headers:** Authorization: Bearer {token}

**Response:** 201 Created

### DELETE /posts/{postId}/like
Unlike a post.

**Headers:** Authorization: Bearer {token}

**Response:** 204 No Content

### POST /posts/{postId}/share
Share a post.

**Headers:** Authorization: Bearer {token}

**Response:** 201 Created

---

## Comments

### GET /posts/{postId}/comments
Retrieve comments for a post.

**Query Parameters:**
- `limit` (default: 50)
- `offset` (default: 0)

**Response:**
```json
[
  {
    "id": "uuid",
    "user": { "id": "uuid", "username": "string", "avatar": "string" },
    "text": "string",
    "likes_count": 0,
    "created_at": "timestamp"
  }
]
```

### POST /posts/{postId}/comments
Create a comment.

**Headers:** Authorization: Bearer {token}

**Request:**
```json
{
  "text": "string"
}
```

**Response:**
```json
{
  "id": "uuid",
  "post_id": "uuid",
  "user_id": "uuid",
  "text": "string",
  "created_at": "timestamp"
}
```

### POST /comments/{commentId}/like
Like a comment.

**Headers:** Authorization: Bearer {token}

**Response:** 201 Created

---

## Hoods

### GET /hoods
Retrieve all public Hoods.

**Query Parameters:**
- `category` (optional)
- `limit` (default: 20)
- `offset` (default: 0)

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "string",
    "description": "string",
    "category": "string",
    "banner": "string",
    "member_count": 0,
    "is_joined": false
  }
]
```

### GET /hoods/{hoodId}
Retrieve a specific Hood.

**Response:**
```json
{
  "id": "uuid",
  "owner": { "id": "uuid", "username": "string" },
  "name": "string",
  "description": "string",
  "category": "string",
  "banner": "string",
  "privacy": "public",
  "member_count": 0,
  "is_joined": false
}
```

### POST /hoods/create
Create a new Hood.

**Headers:** Authorization: Bearer {token}

**Request:**
```json
{
  "name": "string",
  "description": "string",
  "category": "string",
  "privacy": "public"
}
```

**Response:**
```json
{
  "id": "uuid",
  "owner_id": "uuid",
  "name": "string",
  "description": "string",
  "category": "string",
  "privacy": "public",
  "created_at": "timestamp"
}
```

### POST /hoods/{hoodId}/join
Join a Hood.

**Headers:** Authorization: Bearer {token}

**Response:** 201 Created

### POST /hoods/{hoodId}/leave
Leave a Hood.

**Headers:** Authorization: Bearer {token}

**Response:** 204 No Content

### GET /hoods/{hoodId}/posts
Retrieve posts in a Hood.

**Query Parameters:**
- `limit` (default: 20)
- `offset` (default: 0)

**Response:** Array of post objects

### POST /hoods/{hoodId}/posts
Create a post in a Hood.

**Headers:** Authorization: Bearer {token}

**Request:**
```json
{
  "text": "string",
  "media_urls": ["string"]
}
```

**Response:** Post object

---

## Chat

### GET /chat/conversations
Retrieve user's conversations.

**Headers:** Authorization: Bearer {token}

**Response:**
```json
[
  {
    "id": "uuid",
    "participants": [
      { "id": "uuid", "username": "string", "avatar": "string" }
    ],
    "last_message": {
      "text": "string",
      "created_at": "timestamp"
    },
    "unread_count": 0
  }
]
```

### GET /chat/conversations/{conversationId}/messages
Retrieve messages in a conversation.

**Query Parameters:**
- `limit` (default: 50)
- `offset` (default: 0)

**Response:**
```json
[
  {
    "id": "uuid",
    "sender_id": "uuid",
    "text": "string",
    "type": "text",
    "read_by": ["uuid"],
    "created_at": "timestamp"
  }
]
```

### POST /chat/conversations/{conversationId}/messages
Send a message.

**Headers:** Authorization: Bearer {token}

**Request:**
```json
{
  "text": "string",
  "type": "text",
  "media_url": "string"
}
```

**Response:** Message object

### POST /chat/conversations
Create a new conversation.

**Headers:** Authorization: Bearer {token}

**Request:**
```json
{
  "participant_ids": ["uuid"]
}
```

**Response:**
```json
{
  "id": "uuid",
  "participants": [...],
  "created_at": "timestamp"
}
```

### PUT /chat/messages/{messageId}/read
Mark messages as read.

**Headers:** Authorization: Bearer {token}

**Response:** 204 No Content

---

## Leaderboard

### GET /leaderboard/global
Retrieve the global leaderboard.

**Query Parameters:**
- `period` (default: "all_time")
- `limit` (default: 50)
- `offset` (default: 0)

**Response:**
```json
[
  {
    "rank": 1,
    "user": { "id": "uuid", "username": "string", "avatar": "string" },
    "aura_points": 0
  }
]
```

### GET /leaderboard/user/{userId}
Retrieve a user's rank.

**Response:**
```json
{
  "rank": 1,
  "aura_points": 0,
  "period": "all_time"
}
```

---

## Aura

### GET /aura/history/{userId}
Retrieve Aura history for a user.

**Query Parameters:**
- `limit` (default: 50)
- `offset` (default: 0)

**Response:**
```json
[
  {
    "action": "string",
    "amount": 0,
    "reason": "string",
    "created_at": "timestamp"
  }
]
```

### POST /aura/award
Award Aura to a user (admin/backend only).

**Headers:** Authorization: Bearer {admin_token}

**Request:**
```json
{
  "user_id": "uuid",
  "amount": 0,
  "reason": "string"
}
```

**Response:** 201 Created

---

## Notifications

### GET /notifications
Retrieve user's notifications.

**Headers:** Authorization: Bearer {token}

**Query Parameters:**
- `limit` (default: 20)
- `offset` (default: 0)

**Response:**
```json
[
  {
    "id": "uuid",
    "type": "like",
    "reference_id": "uuid",
    "reference_type": "post",
    "read": false,
    "created_at": "timestamp"
  }
]
```

### PUT /notifications/{notificationId}/read
Mark a notification as read.

**Headers:** Authorization: Bearer {token}

**Response:** 204 No Content

### PUT /notifications/read-all
Mark all notifications as read.

**Headers:** Authorization: Bearer {token}

**Response:** 204 No Content

---

## Achievements

### GET /achievements
Retrieve all achievements.

**Response:**
```json
[
  {
    "id": "uuid",
    "code": "first_impression",
    "name": "string",
    "description": "string",
    "icon": "string",
    "aura_reward": 0
  }
]
```

### GET /achievements/user/{userId}
Retrieve user's unlocked achievements.

**Response:**
```json
[
  {
    "achievement": { ... },
    "unlocked_at": "timestamp"
  }
]
```

---

## Error Responses

All endpoints return standard error responses:

```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": {}
  }
}
```

**Common Status Codes:**
- 200 OK — Success
- 201 Created — Resource created
- 204 No Content — Success, no response body
- 400 Bad Request — Invalid input
- 401 Unauthorized — Missing or invalid token
- 403 Forbidden — Insufficient permissions
- 404 Not Found — Resource not found
- 409 Conflict — Duplicate or conflict
- 422 Unprocessable — Validation error
- 500 Internal Server Error — Server error
