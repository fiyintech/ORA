# ORA Power Hour V24 Checkpoint

- Hardened messaging limits with server-side entitlement lookup: Standard 6 MB media / 500-char messages; active Power Hour 50 MB media / 1000-char messages.
- Hardened post creation with server-side entitlement lookup: Standard 4 images / 500-char posts; active Power Hour 8 images / 1000-char posts.
- Added temporary global Power Hour ambience via `data-premium` on the document root; it follows the live entitlement countdown and clears when inactive.
- Preserved existing functionality and did not modify production database schema in this checkpoint.
- Validation: CSS braces balanced (240/240). Full TypeScript build not run because `web/node_modules` is not present in the package workspace.
