# Meal Bazar landing page

Static HTML/CSS/JS. No build step, no dependencies, no external requests (fonts are local).

## Deploy (Vercel)
1. New Project, import this repo.
2. Set **Root Directory** to `landing`.
3. Framework preset: **Other**. Leave the build command and output directory empty.
4. Deploy. `vercel.json` turns on clean URLs (`/privacy`, `/terms`, `/delete-account`), security headers and long cache for `/fonts` and `/assets`.

## Local preview
`cd landing && python3 -m http.server 8099`, then open http://localhost:8099/ (`?lang=bn` forces Bangla).

## Notes
- English is the default. Bangla follows the toggle (remembered in localStorage) or a `bn` browser language.
- Page text lives in the HTML: English inline, Bangla in `data-bn` attributes. App mockup screens are drawn in `app.js`.
- Privacy, Terms and Delete-account pages are ported from `app/web/`. Keep them in sync.
- `assets/qr.svg` encodes the GitHub releases URL (regenerate with `qrencode -t SVG`).

## Site URL
Absolute URLs in `<head>` (og:image, og:url, hreflang, apple-touch-icon, JSON-LD) use the placeholder `https://meal-bazar.vercel.app`. Replace it once the real domain is known:
`grep -rl "meal-bazar.vercel.app" . | xargs sed -i '' 's#https://meal-bazar.vercel.app#https://YOUR-DOMAIN#g'`
