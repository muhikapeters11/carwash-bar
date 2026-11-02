# Carwash POS 2.7.5 — Supabase deployment configuration

- Configured frontend defaults for Supabase project `hesrojwhwintwwnehpvd`.
- Replaced the stale cashier email in `supabase/set-two-users-pin.sql` with `malikpeters92@gmail.com`.
- Removed the unused automatic profile-creation function from both schema bundles. User profiles remain manually managed in Supabase.
- Added a safe, targeted two-account setup script. It refuses to proceed unless both Auth users already exist and only touches those two profile rows.
- Added Supabase and Netlify deployment instructions.

Build verification was not completed in this environment because npm dependency installation timed out; run the documented Netlify build or `npm install --include=dev && npm run build` locally before production deployment.
