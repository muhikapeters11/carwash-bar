# Netlify deploy (fix Page not found)

## Correct GitHub layout
The **root** of the GitHub repository must contain:

- `package.json`
- `netlify.toml`
- `index.html`
- `vite.config.ts`
- `src/`
- `public/`

If the repo root is only a folder named `carwash-pos/` and files are inside it,
set **Base directory** in Netlify to `carwash-pos`, **or** push the inner files to the repo root.

## Netlify site settings
| Setting | Value |
|--------|--------|
| Base directory | *(empty)* unless app is in a subfolder |
| Build command | `npm install --include=dev && npm run build` |
| Publish directory | `dist` |
| Node version | 20 |

Environment variables:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

## Why you saw Page not found
1. Publish directory was not `dist` (or build never produced `dist/index.html`)
2. Repo root did not contain the app (`package.json` missing at root)
3. SPA redirect used `force = true`, which can break static assets

After fixing, trigger **Clear cache and deploy site** in Netlify.
