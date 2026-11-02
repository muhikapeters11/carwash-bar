# Supabase setup for Carwash POS

## Project connection
This package is configured for the Supabase project `hesrojwhwintwwnehpvd` using its anon/public browser key. The anon key is designed to be present in a frontend bundle; never add a `service_role` or secret key to this app or Netlify.

## Create the two Auth users first
In Supabase Dashboard → Authentication → Users → Add user, create and confirm:

| Email | Auth password | POS role |
|---|---|---|
| `pmuhika7@gmail.com` | `233456` | Admin |
| `malikpeters92@gmail.com` | `222222` | Cashier |

If either account already exists, edit that Auth user's password instead of creating a duplicate. Set the password to the PIN shown in the table.

## Configure their profiles and PIN hashes
1. Open SQL Editor.
2. Run `supabase/MANUAL-PROFILE-SETUP.sql` once to remove legacy auto-profile triggers and policies.
3. Run `supabase/ensure-pin-login.sql` to install/refresh the PIN lookup RPC.
4. Run `supabase/set-two-users-pin.sql` to create/update only these two profiles and set their SHA-256 PIN hashes.
5. Confirm the final query returns two rows with `auth_profile_ids_match = true` and `pin_configured = true`.

The SQL intentionally does not create Auth users, change other profiles, or create users from inside the POS. If the account emails do not exist in `auth.users`, it stops with a clear error.

## Netlify deployment
- Base directory: blank (repository root)
- Build command: `npm install --include=dev && npm run build`
- Publish directory: `dist`
- Node: 20

The Supabase URL and anon key are already configured as safe frontend defaults in `src/App.tsx`. You may also set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in Netlify environment variables. Then use **Clear cache and deploy site**.

## Important
The PIN login flow first resolves the SHA-256 PIN hash to an email using `public.resolve_pin_login`, then signs in to Supabase Auth using that email and the same PIN as the Auth password. Both the profile PIN hash and Auth password therefore need to match.


## 2.7.6 profile provisioning
Run `supabase/AUTOMATIC-PROFILE-AND-PIN-SETUP.sql` once in Supabase SQL Editor. It backfills the two known accounts and installs a trigger for future Auth users. Auth passwords still need to match the POS PINs in Authentication > Users. Do not run legacy PIN setup scripts after this file unless intentionally reverting to the old setup.
