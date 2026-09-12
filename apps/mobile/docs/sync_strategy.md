# ORA Offline-First Sync Strategy

## Overview

ORA is an **offline-first** application. All data is read from and written to
local storage first. Backend sync is a future enhancement.

## Current Behavior

### Read
1. Read from local storage (SharedPreferences).
2. If local data exists, return it immediately.
3. If local data does not exist, return empty/null.

### Write
1. Write to local storage immediately.
2. Return success to the UI.
3. Sync to backend is deferred (TODO).

## Future Sync Strategy

When the backend is ready, the following strategy will be implemented:

### 1. Write-Through with Queue
- All writes go to local storage first.
- A sync queue records pending changes (create, update, delete).
- A background worker processes the queue when online.
- On conflict, last-write-wins (with server timestamp comparison).

### 2. Read-Through with Cache
- On app launch, attempt to fetch from backend.
- If online, update local cache and return fresh data.
- If offline, return cached data with a "stale" indicator.

### 3. Conflict Resolution
- Each record has a `updated_at` timestamp.
- On sync conflict, the record with the latest timestamp wins.
- Manual merge for critical data (e.g., profile changes).

### 4. Realtime
- Use Supabase Realtime for live updates on:
  - Messages
  - Post likes/comments
  - Hood membership changes
- Subscribe to relevant channels based on user context.

## Sync TODO Locations

- `lib/features/auth/repository/auth_repository.dart` — TODO: Sync user to backend
- `lib/core/storage/local_storage_service.dart` — TODO: Add sync queue
- `lib/core/backend/repositories/` — All repository interfaces have TODO comments

## Data Flow Diagram

```
UI Action
    ↓
Local Storage (immediate)
    ↓
Sync Queue (pending)
    ↓
Background Worker
    ↓
Supabase Backend
```

## Error Handling

- If backend sync fails, the local change is preserved.
- The sync queue is retried with exponential backoff.
- The user is notified of sync failures via a banner.
- Offline mode is transparent — the app always works.
