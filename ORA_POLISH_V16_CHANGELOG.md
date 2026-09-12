# ORA Web V16 — Account deletion

## Added
- Added a dedicated **Delete account** section to Settings.
- Added a destructive confirmation modal requiring the user to type `DELETE` before deletion can run.
- Added a Supabase Edge Function at `apps/supabase/functions/delete-account`.
- The function authenticates the caller, removes that user's files from the `profile-media`, `posts`, and `chat-media` buckets, then deletes the Supabase Auth user so database rows with `ON DELETE CASCADE` are removed by the existing schema.
- Added `authService.deleteAccount()` to invoke the Edge Function and sign out after successful deletion.

## Safety
- The UI does not delete an account from a single accidental click.
- The Edge Function independently requires an authenticated session and the exact `DELETE` confirmation string.
- No production database was modified by this package build.

## Validation
- Web TypeScript check: `tsc --noEmit` passed with no diagnostics.
