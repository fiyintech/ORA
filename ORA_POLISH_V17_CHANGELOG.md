# ORA Web V17 — Luxe theme, view-once privacy and account switching

## Included

- Replaced the previous Graphite/Plum visual direction with a deep premium Luxe system inspired by the supplied luxury reference: deep forest/black surfaces, warm ivory text and restrained antique-gold accents.
- Added three local chat wallpaper choices: Silk, Botanical and Night Sky. The selected wallpaper is remembered per account/device.
- Added receiver-side view-once media blur. Incoming image/video media remains visibly blurred with a "Tap to view" treatment until explicitly opened; the view-once timer begins after the media is marked viewed.
- Reworked Settings account controls so **Switch account** opens a dedicated account switcher instead of logging out.
- Added a dedicated switch-account page with one-tap saved-account switching, **Add an account**, and per-account removal.
- Saved-account limit is hard-capped at 3. Passwords are never stored; the device stores Supabase session credentials needed for quick switching.
- **Log out** remains a separate action that ends the active session.
- Added a "Use a saved account" shortcut on the normal login page when saved accounts exist.
- Added `/add-account` so an additional account can be authenticated without first destroying the saved-account list.
- Account sessions are captured/refreshed through the auth lifecycle so the saved list stays current.

## Validation

- TypeScript transpilation/syntax check: 56 TS/TSX files, 0 syntax diagnostics.
- Full `npm run build` was not run because this package does not include installed `node_modules` in the execution environment.
