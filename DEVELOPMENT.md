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
- Enable **Phone** auth in Supabase. It needs an SMS provider such as Twilio. For development, use Supabase's test phone numbers and OTPs.
- Run the tests with `./supabase/tests/run.sh`. It creates a throwaway local database, stubs `auth.uid()` and the Supabase roles, applies all migrations, and runs every `supabase/tests/*_test.sql`.

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
