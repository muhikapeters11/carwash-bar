# Carwash POS 2.7.6

## Supabase profile provisioning fix
- Adds `supabase/AUTOMATIC-PROFILE-AND-PIN-SETUP.sql`.
- SQL creates missing internal POS profiles for existing Auth users and adds a trigger for future Auth users.
- Existing known admin and cashier accounts are assigned their intended roles and PIN lookup hashes.
- POS still does not create Auth accounts or profiles from the browser.

## Required setup
1. Back up the Supabase database.
2. Run `supabase/AUTOMATIC-PROFILE-AND-PIN-SETUP.sql` once in Supabase SQL Editor.
3. In Authentication > Users, ensure each account's Auth password matches its POS PIN and its email is confirmed.
4. Check the SQL verification query returns a profile ID for each account and `pin_configured = true`.
5. Deploy this package to Netlify.

The app source is otherwise unchanged from 2.7.5. The frontend production build has not been run in this environment; run `npm install` then `npm run build` before deployment if you need a fresh local build verification.
