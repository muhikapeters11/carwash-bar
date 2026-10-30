# Desktop build (Windows)

## Requirements
- Node.js 20+ (LTS)
- On Windows: for installer, no extra tools usually needed with electron-builder NSIS

## Commands (from project root)

```cmd
cd carwash-pos
npm install
npm run brand
npm run desktop:build:win
```

Installer output: `release\` (e.g. Carwash POS Setup.exe)

## If build fails

1. **Syntax / Vite error** — fix App.tsx line shown; run:
   ```cmd
   npm run build
   ```
2. **electron-builder fails** — try:
   ```cmd
   npm run check:build
   npx electron-builder --win --config.npmRebuild=false
   ```
3. **Delete and reinstall deps**
   ```cmd
   rmdir /s /q node_modules
   del package-lock.json
   npm install
   ```

## Open at login
Enabled by default on first installed run (tray can turn off).
