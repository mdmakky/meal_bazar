# Development

## Layout
```
app/            Flutter app (Android first)
supabase/       migrations/ (SQL, applied in order) · tests/ (SQL + RLS tests)
ai-gateway/     Vercel functions (Phase 6)
*.md            specs — see CLAUDE.md for the source-of-truth order
```

## Prerequisites
- Flutter 3.35+ (Dart 3.9+), Android SDK.
- PostgreSQL 15+ locally, for the SQL tests (`brew install postgresql@16 && brew services start postgresql@16`).
- A Supabase project, created on the free tier.

## Running the app
```sh
cd app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```
Only the anon key goes into the app. RLS protects the data. Never put the service-role key or any AI key into the app.

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
- [x] **Phase 0**: specs (REQUIREMENTS, PRODUCT_RULES, ARCHITECTURE, DATABASE, AI, DESIGN_SYSTEM, PRODUCT)
- [ ] **Phase 1**: Flutter scaffold, theme and core widgets, l10n bn/en, core migration and RLS, phone OTP auth, create/join mess, members
- [ ] **Phase 2**: meal types, meal grid, Today screen, meal SQL views (then the impeccable finish review plus DESIGN.md)
- [ ] **Phase 3**: bazar, expenses, deposits, guest meals
- [ ] **Phase 4**: month totals and balances, close/reopen, closed-month guard, PDF/share
- [ ] **Phase 5**: Drift, sync queue, sync badges
- [ ] **Phase 6**: AI gateway, meal draft, bazar-receipt draft
- [ ] **Phase 7**: FCM, audit UI, meal-off, v1.1 items
