# ORA Web Polish v12

This pass implements the visual/UX improvements identified from the supplied deployed-site recording while preserving the existing Supabase data model and feature architecture.

## Implemented

### Loading & reliability
- Replaced generic route loading copy with a branded, contextual "Getting ORA ready" state.
- Added reusable page loading and error/retry UI primitives.
- Replaced the feed's blank loading state with layout-matched skeletons.
- Reduced Hood discovery skeletons from six large placeholders to three richer placeholders.
- Settings and Profile now use contextual loading states instead of a bare spinner.
- Added explicit 404 page instead of silently redirecting unknown routes to Home.

### Feed
- Added a working Share action using native share where available and clipboard fallback elsewhere.
- Shared post links target the specific post via a URL hash.
- Post notification links now target the specific post hash.
- Added smooth post hash scrolling after feed content loads.
- Increased social-action hit areas for easier clicking/tapping.
- Removed zero-value counters from the visual row while retaining accessible labels.
- Added failed-media fallback UI instead of leaving blank media.
- Kept feed media constrained to avoid viewport-dominating images.

### Profiles & avatars
- Hardened the shared Avatar component with image-load fallback, flexible sizing, and profile-object support.
- This also fixes inconsistent avatar implementations across messages, Hoods, notifications, and settings.
- Profile banner/avatar failures now fall back cleanly.
- Added explanatory titles to Aura/Steeze labels.

### Notifications
- Existing read/unread treatment and "Mark all read" behavior preserved.
- Post notifications now route to the specific post rather than only Home.
- Shared avatar fallback prevents broken/blank avatar presentation.

### Messaging
- Added a clear New message affordance in the chat header that takes users to people search.
- Shared avatar component is now used in chats.
- Added failed shared-media fallback.

### Search
- Kept search focused on people and aligned the global search placeholder with that behavior.
- Added avatar failure fallback.

### Hoods
- Improved Hood-card hover/focus treatment.
- Reduced excessive loading placeholders.
- Preserved existing Hood creation, joining, admin, owner, privacy, and rejoin functionality.

### Settings & theme
- Improved Aura Gold theme contrast substantially while retaining the warm gold/purple identity.
- Renamed the user-facing theme label to "Aura Gold".
- Settings now has a contextual loading state and a proper retry path when the profile cannot be loaded.
- Shared avatar fallback is used for the profile picture.

### Authentication
- Replaced the non-functional "Forgot password?" alert with a real Supabase password-recovery flow.
- Added `/reset-password` page for setting a new password after the recovery email.
- Added visible loading spinners to sign-in/sign-up buttons.

### Global polish
- Stronger topbar surface/background treatment.
- Improved light/warm theme text and border contrast.
- Stronger focus-visible treatment.
- Reduced-motion accessibility support.
- Better mobile safe-area handling.

## Intentionally not changed
- No database schema was changed in this polish pass.
- No production Supabase data was modified.
- Existing social/feed/Hood/messaging business logic was preserved unless needed for the UI behavior above.
- Mobile-specific redesign beyond responsive CSS was not invented from desktop-only evidence.

## Validation
- All 52 web TypeScript/TSX source files passed a TypeScript transpile/syntax check.
- Relative source imports were checked; the only non-resolved references are CSS imports, which are expected and handled by Vite.
- A full `npm run build` could not be completed in this environment because the available dependency cache is incomplete (`vite/client` and Node type packages are unavailable after the package-install timeout). The source itself passed syntax transpilation.
