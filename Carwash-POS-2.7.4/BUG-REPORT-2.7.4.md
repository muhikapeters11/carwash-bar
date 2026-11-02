# Carwash POS 2.7.4 — Investigation & Fix Report

## 1. User/account changes requested

### Removed from the POS
- Removed the in-app **Add User/Create User** workflow.
- Removed in-app PIN reset/account deletion controls from the Users screen.
- Removed the obsolete `admin-user` Edge Function from this source package.
- The POS no longer auto-creates a `profiles` row when an Auth user has no profile.

### Users screen now does one thing
The admin Users tab now only edits `profiles.full_name`.

That value is treated as the **receipt display/cashier name**. It does not change:
- Supabase Auth email
- Supabase Auth password/PIN
- role
- permissions/allowed tabs
- account active/disabled status
- staff code

User creation and account administration must be performed in Supabase.

## 2. Fixed the “No profile found” behaviour
The previous application attempted to create a profile automatically when an Auth account had no matching profile. This could result in inconsistent accounts and was contrary to the requested architecture.

2.7.4 now:
1. Authenticates the user.
2. Looks up the matching `profiles.id = auth.uid()` row.
3. If it exists, uses it.
4. If it does not exist, clearly tells the admin to create/link the profile in Supabase.

Editing a user now updates only `full_name` and verifies that an actual profile row was updated.

## 3. Offline + online user persistence
The offline credential vault already existed, but it was strengthened so cached profile information for known users is updated when the online profile list refreshes.

Offline login uses the locally stored PIN/password hash and cached profile. No plaintext PIN is stored by the offline credential vault.

Important limitation: a brand-new Supabase user cannot magically become an offline user on a device that has never seen that account. Each user must successfully log in online on that device once so the device can securely cache the account/PIN hash.

## 4. Login logo fix
The login screen previously depended on `settings` being loaded after authentication. This meant a newly opened device could show the default logo instead of the logo configured in Backup & Settings.

2.7.4 loads cached branding immediately and then calls a new Supabase RPC:

`get_public_branding()`

The RPC returns only:
- `bar_name`
- `logo_url`

It does **not** expose the admin PIN hash, till number, receipt footer, or other private settings.

Run `supabase/public-branding.sql` once in the Supabase SQL Editor if the function does not already exist.

The existing Settings page continues to provide the direct image upload. The uploaded logo is stored in `app_settings.logo_url` and is then used on:
- PIN login page
- sidebar/application branding
- receipts where applicable

## 5. Additional bugs/issues found

### A. Existing schema contains automatic profile creation
`supabase/schema.sql`, `FULL-SCHEMA-ALL-UPDATES.sql`, and `fix-missing-profiles.sql` contain older automatic-profile creation logic.

This is now inconsistent with the requested architecture. The POS itself no longer performs automatic profile creation. If you want profile creation to be strictly manual in Supabase, the old trigger should also be removed from the live Supabase database.

### B. Public branding requires the migration
Because `app_settings` is protected by RLS for authenticated users, the login page cannot safely query the whole settings table anonymously. 2.7.4 therefore uses the restricted `get_public_branding()` RPC.

### C. Desktop auto-update configuration
The Electron package still contains a GitHub publisher configuration using placeholder values (`YOUR_GITHUB_USER` / `bar-pos-cloud`). Automatic desktop updates will not work correctly until the real GitHub owner/repository is configured.

### D. Build verification limitation
The source was checked with the system TypeScript compiler. No new TypeScript/JSX syntax errors were detected; the remaining compiler output is dependency-related because this environment could not complete `npm install` within the available execution time.

A full Vite production build should therefore be run after extracting the ZIP on a machine with internet/npm access:

`npm install`

then:

`npm run build`

### E. Service-worker cache can delay web updates
The application uses a service worker and checks for updates periodically. A previously cached app shell can remain active briefly after a Netlify deployment. The service worker already calls `registration.update()` periodically, but a hard refresh may still be required immediately after a deployment.

## 6. Regression checks performed

- Removed all references to the old in-app user creation UI.
- Removed references to the old `admin-user` function from the React application.
- Removed the old in-app user deletion workflow.
- Removed the automatic profile creation paths from the React application.
- Users screen now exposes only receipt-name editing.
- Offline PIN matching remains supported.
- Cached profile information is synchronized for known offline users.
- Login branding is loaded before authentication through the restricted branding RPC.
- Existing error boundary remains in place so React rendering errors are displayed instead of silently producing a blank page.

## 7. Recommended Supabase setup

For each staff member:

1. Create the account in **Supabase Authentication → Users**.
2. Create the corresponding row in `public.profiles` using the same Auth user UUID.
3. Set `full_name` to the name that should appear on receipts.
4. Set `role`, `active`, `allowed_tabs`, `staff_code`, and `pin_hash` in Supabase according to the staff member.
5. Ensure the PIN is unique.
6. Run `public-branding.sql` once for the login logo/name functionality.

After a staff member successfully logs in online on a device, that device can use the cached account for offline PIN login.

## Version

**Carwash POS 2.7.4**
