# Carwash POS 2.7.3 — Login/Blank Page Investigation Report

## Executive summary
I inspected the uploaded `carwash-pos-FIXED-LOGIN-2.7.2.zip` source code and found several concrete defects in the application code that can make post-login failures look like a blank screen or prevent later screens/actions from working.

The repaired package is **Carwash POS 2.7.3**.

## Main findings

### 1. Missing function definitions in `src/App.tsx` — FIXED
The application referenced these functions but did not define them:
- `flash()`
- `signOut()`
- `openNewProduct()`
- `openEditProduct()`
- `saveProduct()`

This is a serious source-code defect. Vite can transpile the TSX without doing full TypeScript type checking, so the defect can survive until the affected code path is executed.

I restored all five functions:
- `flash()` now provides a safe temporary notification.
- `signOut()` clears Supabase/local React session state safely.
- `openNewProduct()` resets the product form and opens the product modal.
- `openEditProduct()` loads the selected product into the form.
- `saveProduct()` validates and persists products, updates the local/cache state, and closes the modal.

### 2. Post-login render protection — FIXED
There was no React error boundary around the application. A render-time exception therefore had no friendly recovery UI and could present to the user as an apparently blank page.

I added an `AppErrorBoundary` in `src/main.tsx`.
If a future render exception occurs, the POS now displays:
- the fact that a render error occurred;
- the captured error message;
- a Reload POS button;
- the error in the browser/Electron console.

This is especially important for diagnosing the exact post-login failure instead of seeing a blank screen.

### 3. Product data defensive handling — FIXED
The main render path used direct calls such as:
`p.category.toLowerCase()`

A malformed/null product field could therefore crash the entire React render after products are loaded.

I hardened product/category filtering to use safe string handling. This prevents one malformed product record from taking down the whole POS UI.

### 4. PIN authentication flow — REVIEWED
The PIN flow itself has three resolution paths:
1. Supabase RPC `resolve_pin_login`
2. direct REST RPC fallback
3. `pin-login` Edge Function fallback

After resolving the account email, it signs in through Supabase Auth using the PIN as the Auth password.

The existing Edge Function also synchronizes the Auth password with the PIN.

No service-role key is exposed in the browser code; the service key remains inside the Edge Function.

## Additional issues checked

### Authentication/session handling
The application deliberately prevents an old Supabase session from automatically opening the POS without an explicit login. This is intentional security behavior.

The repaired `signOut()` now consistently clears:
- Supabase local session
- React session
- profile
- cart
- receipt
- visible errors/notices

### Offline mode
Offline credentials and cached profile/product/settings data are already implemented. The repair preserves that design.

### Service worker
The service worker explicitly avoids caching Supabase API requests. That is correct and reduces the risk of stale authentication/API responses.

### Desktop/Electron
The Electron preload uses `contextIsolation: true` and `nodeIntegration: false`, which is a good security configuration.

## Verification performed

I performed source-level inspection and TypeScript parsing against the repaired source.

The TypeScript checker successfully got past the previously missing application symbols after the repair. Full dependency compilation could not be completed in this environment because `npm install` could not finish downloading the project's dependencies within the available execution window.

Therefore:
- **Source inspection:** completed
- **Defect repair:** completed
- **TypeScript syntax/parsing:** checked
- **Full Vite production build:** not independently completed here because dependencies could not be installed
- **Live Supabase PIN login against your production database:** not possible from this isolated environment

## Important deployment note

The PIN login depends on the Supabase database function / Edge Function being deployed in your Supabase project. The package contains:
- `supabase/ensure-pin-login.sql`
- `supabase/fix-pin-digest.sql`
- `supabase/functions/pin-login/index.ts`

If the live project was created from an older schema, make sure the current PIN-login SQL/function is deployed.

## Recommended production checks

1. Deploy/build the repaired package.
2. Enter a valid PIN.
3. Confirm the Dashboard/Sell screen appears instead of a blank page.
4. Test a cashier PIN.
5. Test an admin PIN.
6. Sign out and sign back in.
7. Refresh the browser after login.
8. Test offline mode after one successful online login.
9. Test Add Product and Edit Product.
10. Test Receive Stock and a sale.
11. Test the Electron desktop build separately if using the Windows installer.

## Files changed

- `src/App.tsx`
  - restored missing login/session/product functions
  - hardened product data handling
- `src/main.tsx`
  - added React error boundary
- `BUG-REPORT-2.7.3.md`
  - this investigation report

## Result

The repaired archive is intended as the next test build: **Carwash POS 2.7.3**.

The most important improvement is that post-login runtime failures should no longer silently become a blank page: the application now has both the missing core functions restored and a visible crash boundary for any remaining runtime exception.
