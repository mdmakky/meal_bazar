# Development

## Layout
```
app/            Flutter app (Android first)
supabase/       migrations/ (SQL, applied in order) · tests/ (SQL + RLS tests)
ai-gateway/     Vercel functions (Phase 6)
*.md            specs — see CLAUDE.md for the source-of-truth order
```

## Prerequisites
- Flutter 3.35+ (Dart 3.9+), Java 17, and the Android SDK with cmdline-tools (`~/Library/Android/sdk`). Run `flutter doctor --android-licenses` once.
- PostgreSQL 15+ locally, for the SQL tests (`brew install postgresql@16 && brew services start postgresql@16`).
- A Supabase project, created on the free tier.

## Running the app
```sh
cd app
cp env.example.json env.json   # fill in the URL + publishable key (env.json is gitignored)
flutter pub get
flutter run --dart-define-from-file=env.json
```
Only the publishable/anon key goes into the app; RLS protects the data. Never put the secret/service-role key or any AI key into the app.

## Database
- Apply migrations: in the Supabase dashboard SQL editor, run `supabase/migrations/*.sql` in order. With the CLI, run `npx supabase db push`.
- Auth (Supabase → Authentication → Providers):
  - **Email**: on. With "Confirm email" on, sign-up shows a "click the emailed link" step; set the Site URL / redirect URLs for the confirm and password-reset links.
  - **Redirect URL**: Supabase → Authentication → URL Configuration → add `mealbazar://auth-callback` (confirm and reset-password links open the app; a reset link only works on the device that requested it).
  - **Google**: in Google Cloud Console create a **Web** OAuth client (its client id + secret go into Supabase's Google provider) and an **Android** OAuth client with package `com.mealbazar.meal_bazar` and the debug keystore SHA-1 (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`; add the release SHA-1 before shipping). Put the **web** client id in `env.json` as `GOOGLE_WEB_CLIENT_ID`; empty hides the Google button.
  - **Phone**: off. Phone OTP code is kept but unrouted until an SMS provider (e.g. Twilio) is funded.
- Run the tests with `./supabase/tests/run.sh`. It creates a throwaway local database, stubs `auth.uid()` and the Supabase roles, applies all migrations, and runs every `supabase/tests/*_test.sql`.

## Release (Android)
1. **Upload keystore** (once; back it up outside the repo, since losing it means asking Play for an upload-key reset):
   ```sh
   keytool -genkey -v -keystore ~/keys/meal_bazar-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **key.properties**: `cp app/android/key.properties.example app/android/key.properties` and fill it in. Both it and `*.jks` are gitignored. Without it, release builds are debug-signed and Gradle prints a warning; that's fine for local testing but Play rejects them.
3. **Build** (R8 minify and resource shrinking are on for release):
   ```sh
   cd app
   flutter build appbundle --release --dart-define-from-file=env.json              # Play upload
   flutter build apk --release --split-per-abi --dart-define-from-file=env.json   # sideload/testing, target under 30 MB per ABI
   ```
4. **Play App Signing**: Play re-signs the app with its own app-signing key, so the installed app's SHA-1 is not your upload key's SHA-1.
5. **Google login in release**: add both the **upload-key SHA-1** (`keytool -list -v -keystore ~/keys/meal_bazar-upload.jks -alias upload`) and the **Play app-signing SHA-1** (Play Console → Test and release → App integrity → App signing) to the Google Cloud **Android** OAuth client(s) for `com.mealbazar.meal_bazar`. If one is missing, Google sign-in fails silently in that build.
6. **Versioning**: bump `version: x.y.z+N` in `app/pubspec.yaml` for every upload. `x.y.z` becomes versionName and `N` becomes versionCode, which must strictly increase. Split-per-ABI APKs add an ABI offset to the versionCode automatically.
7. **Invite App Links**: the `https://mealbazar.app/join/` filter has `autoVerify="false"`, so Android shows a chooser. To make links open the app directly, host `/.well-known/assetlinks.json` with the Play app-signing SHA-256, then switch it to `true`.

## Quality gate (every phase)
```sh
cd app && dart format . && flutter analyze && flutter test
./supabase/tests/run.sh
```
Don't move to the next phase while any of these fail. Commit each part to `main` once its gate passes.

## Roadmap
- [x] **Phase 0**: specs
- [x] **Phase 1**: scaffold, design system, l10n, core migration and RLS, phone OTP, create/join mess, members, invites
- [x] **Phase 2**: meal types, Today screen and meal grid, Meals tab (impeccable finish review and DESIGN.md still pending)
- [x] **Phase 3**: bazar, expenses, deposits, guest meals
- [x] **Phase 4**: SQL engine, close/reopen, closed-month guard, PDF report and share
- [ ] **Phase 5**: Drift offline mirror and sync queue (blocked: drift_dev needs Dart 3.10, so upgrade Flutter first)
- [x] **Phase 6**: AI gateway, meal draft, receipt scan
- [x] Meal-off cutoff for members, deposit verification, receipt photos
- [ ] **Phase 7**: FCM push notifications (needs a Firebase project)
- [x] Account deletion and audit log screen (Play Store and v1.1)
- [x] Hard-delete auth users from `deletion_requests` (daily gateway cron)
