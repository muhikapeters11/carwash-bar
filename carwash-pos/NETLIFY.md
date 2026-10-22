# Deploy Carwash POS on Netlify (from GitHub)

## 1. Push this folder to GitHub
- Repo root must contain: `package.json`, `netlify.toml`, `src/`, `public/`, `index.html`
- Do **not** upload only the `release/` installer folder as the site

## 2. Netlify → Add site → Import from Git
- Build command: `npm install --include=dev && npm run build` (from netlify.toml)
- Publish directory: `dist`
- Node: 20

## 3. Environment variables (Site settings → Environment)
- `VITE_SUPABASE_URL` = your Supabase project URL
- `VITE_SUPABASE_ANON_KEY` = your Supabase **anon** key (never service_role)

## 4. After first deploy
- Open the site URL — you should see the login screen (not "Page not found")
- SPA redirects are in `netlify.toml` and `public/_redirects`

## Common failures
| Error | Fix |
|-------|-----|
| Page not found | Publish dir must be `dist`; redirects must be present |
| vite: not found | Use build command with `--include=dev` |
| Blank app after login | Set VITE_SUPABASE_* env vars and redeploy |
| Build OOM | Free tier: reduce if needed; Node 20 is enough for this app |
