# GetaRebate Admin (standalone)

Separate from the public website. Deploy this folder’s `dist` to its own Netlify site.

## Develop
```bash
cd admin
npm install
npm run dev
```
Opens on http://127.0.0.1:5174 — login at `/login`, dashboard at `/`.

## Build / Netlify
```bash
cd admin
npm run build
```
- Base directory: `admin`
- Build command: `npm run build`
- Publish: `dist`

Login only (no create account). Requires `admin` or `mainadmin` role.
