# Admin web panel: build and deploy

The Super Admin panel is a Flutter web entrypoint, `app/lib/admin/admin_main.dart`. It shares the theme, l10n and auth code with the mobile app but none of the mobile-only plugins, and the API it calls is in `docs/platform-admin.md`.

## Build
```sh
cd app
flutter build web -t lib/admin/admin_main.dart --dart-define-from-file=env.json --release
```
The output is `app/build/web`. `env.json` needs `SUPABASE_URL` and `SUPABASE_ANON_KEY`. `AI_GATEWAY_URL` is used by the AI page (the model catalogue and Test buttons), and `GOOGLE_WEB_CLIENT_ID` turns on the "Sign in with Google" button. No secret goes into the build, because every admin RPC re-checks `is_platform_admin()` on the server.

Run it locally with `flutter run -d chrome -t lib/admin/admin_main.dart --dart-define-from-file=env.json`.

## Deploy to Vercel (static)
`app/web/vercel.json` is copied into `build/web` by the build. It holds the SPA rewrite to `/index.html`, no-cache for the bootstrap files, and basic security headers. So the built folder is the whole site:
```sh
cd app/build/web
vercel deploy --prod        # first time: link a new project, e.g. "meal-bazar-admin"
```
This must be its own Vercel project, separate from `ai-gateway/`. It has no build step and no framework preset, and its output directory is the folder itself.

## Auth redirect settings (Supabase → Authentication → URL Configuration)
- Add the panel's origin to **Redirect URLs**, for example `https://meal-bazar-admin.vercel.app/**`, plus `http://localhost:*/**` for local runs.
- Google sign-in on the web uses Supabase's OAuth redirect flow (`signInWithOAuth`, `redirectTo` = the panel origin), not the native ID-token flow. The Google provider in Supabase must be enabled. In Google Cloud → OAuth client (Web), the **Authorized redirect URI** is `https://<project-ref>.supabase.co/auth/v1/callback`, and the panel origin goes under **Authorized JavaScript origins**.
- Email and password sign-in needs no extra setup.

## AI gateway CORS
The AI page calls `GET /api/admin/models` and `POST /api/admin/test-model` straight from the browser, with an `Authorization: Bearer <JWT>` header. The gateway must answer the `OPTIONS` preflight with `Access-Control-Allow-Origin: <panel origin>`, `Access-Control-Allow-Headers: authorization, content-type` and `Access-Control-Allow-Methods: GET, POST, OPTIONS`. Without these the catalogue shows a network error. The chains can still be edited by hand.

## Storage
The logo upload writes to the public `branding` bucket. The bucket and its admin-only insert policy come from the SQL migration.
