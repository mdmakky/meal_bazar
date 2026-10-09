<p align="center">
  <img src="app/assets/icon/brand.png" width="96" alt="Meal Bazar icon">
</p>

<h1 align="center">Meal Bazar</h1>

<p align="center"><b>Run your whole mess from your phone in two minutes a day.</b><br>
Meals, groceries, shared expenses and the month-end settlement, in Bangla and English.</p>

<p align="center">
  <a href="https://github.com/mdmakky/meal_bazar/releases/latest"><b>Download the latest APK</b></a>
  ·
  <a href="#installation">Installation</a>
  ·
  <a href="#features">Features</a>
  ·
  <a href="#architecture">Architecture</a>
</p>

---

## Overview

A *mess* is shared bachelor housing, common among students and young professionals in Bangladesh. Members eat together, take turns buying groceries (*bazar*), and split rent and utilities. Most messes still track this in a notebook, and the month-end calculation causes disputes.

Meal Bazar replaces the notebook. The manager records meals and spending in a few taps, and every member can see exactly how their balance was calculated. The app works offline and syncs when a connection returns.

## Installation

1. Open the [latest release](https://github.com/mdmakky/meal_bazar/releases/latest) and download the APK for your phone:
   - **`app-arm64-v8a-release.apk`** is for most phones made in the last several years.
   - **`app-armeabi-v7a-release.apk`** is for older or entry-level phones, if the first one does not install.
   - `app-x86_64-release.apk` is only for Android emulators on a computer.
2. Open the downloaded file. If Android asks, allow installing apps from this source.
3. Sign in with Google or email. Then create a mess, or join one with the invite code from your manager.

**Requirements:** Android 7.0 or later. Each APK is under 30 MB.

## Features

| Area | What it does |
|---|---|
| **Meals** | A grid of every member and meal (breakfast, lunch, dinner, or the mess's own meal types). It handles half meals, guest meals and meal-off. Members can switch their own meals off until a deadline the manager sets (for example, two hours before the meal), and the change is announced in the mess group. |
| **Bazar** | Each trip records one or more buyers, an itemised list with quantities and prices, and whether it was paid from the mess fund or someone's own pocket. Receipt photos are supported. An optional AI scan turns a receipt into a draft that the user reviews before saving. |
| **Expenses** | Costs can be split equally among everyone present, by meals eaten (added to the meal rate), or among selected members with weights. Monthly bills such as rent and Wi-Fi can be posted automatically. |
| **Deposits** | Cash, bKash, Nagad or bank deposits, with an optional transaction ID. Members can record their own deposits, which the manager verifies. |
| **Month-end** | The meal rate, each member's advance or due, closing a month (with carry-forward balances), reopening with an audited reason, and an optional fixed meal rate. A detailed monthly PDF report covers the day-by-day meals of every member and every bazar trip. CSV export is also available. |
| **Transparency** | Every member sees everyone's deposits and balances, plus each entry that affects their own account. Any entry can be reported to the manager as a problem. |
| **Communication** | Private member-to-manager messages, a group for the whole mess, a notice board, a bazar duty rota, and push notifications. |
| **Administration** | A web panel for the platform owner: feature flags, branding, AI model selection (with a free/paid filter), credentials, suspensions and usage statistics. |

## Architecture

| Component | Technology | Location |
|---|---|---|
| Mobile app | Flutter, Riverpod, go_router, Drift (offline storage with a sync queue) | [`app/`](app/) |
| Backend | Supabase (Postgres, Auth, Storage). All money and meal calculations are SQL functions, and Row Level Security is the access boundary. | [`supabase/`](supabase/) |
| AI gateway | Vercel serverless functions in TypeScript. Gemini is the primary provider and OpenRouter is the fallback. AI output is always a draft that a person confirms. | [`ai-gateway/`](ai-gateway/) |
| Push | Firebase Cloud Messaging, sent from a database outbox | [`supabase/migrations`](supabase/migrations/), [`ai-gateway/`](ai-gateway/) |
| Admin panel | Flutter web | [`app/lib/admin/`](app/lib/admin/) |

Design principles:
- **The database is the source of truth.** Balances are never recalculated on the device or by AI.
- **AI drafts, people confirm.** Nothing AI-generated is saved without review.
- **Closed months are immutable.** Any change after closing requires a reason and is recorded in the audit log.

Further reading: [Product rules](PRODUCT_RULES.md) · [Database](DATABASE.md) · [Architecture](ARCHITECTURE.md) · [Development and release](DEVELOPMENT.md)

## Development

```sh
cd app
cp env.example.json env.json        # add your Supabase URL and publishable key
flutter pub get
flutter run --dart-define-from-file=env.json
```

Running the tests:

```sh
cd app && flutter analyze && flutter test   # mobile app
./supabase/tests/run.sh                     # SQL and Row Level Security (needs a local PostgreSQL)
cd ai-gateway && npm test                   # AI gateway
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for backend setup, push notifications and signed release builds.

## Privacy

Only the Supabase URL and publishable key are bundled with the app; no secrets are. See the [privacy policy](docs/privacy-policy.md) and [account deletion](docs/account-deletion.md).
