# Play Console — Data safety answers (Meal Bazar v1.0)

Source of truth: REQUIREMENTS.md, AI.md, DATABASE.md, `supabase/migrations/0007_account_deletion.sql`, `ai-gateway/README.md`. Re-check before each release if features change (e.g. v1.1 push notifications add FCM tokens).

## Overview questions
| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all user data collected by your app encrypted in transit? | **Yes** (HTTPS to Supabase and the Vercel gateway) |
| Do you provide a way for users to request that their data is deleted? | **Yes** — in-app (আরও → অ্যাকাউন্ট → অ্যাকাউন্ট মুছে ফেলুন) and web: [ACCOUNT_DELETION_URL] |
| Account creation methods | Username/password (email) and OAuth (Google) |
| Delete-account URL | [ACCOUNT_DELETION_URL] (publish `docs/account-deletion.md`) |
| Privacy policy URL | [PRIVACY_POLICY_URL] (publish `docs/privacy-policy.md`) |
| Ads | **No** ads (answer "No" in the Ads declaration) |
| Committed to Play Families policy / target audience includes children | **No** — target audience 18+ (users are students/young professionals) |

## Sharing decision (owner must confirm)
Supabase and Vercel act as service providers on our behalf → **not "shared"**.
Google Gemini / OpenRouter: their free tiers **may use prompts to improve their models** (AI.md), which goes beyond processing purely on our behalf. Conservative answer used below: **declare as Shared** for the data sent to them (user-typed text and photos), purpose *App functionality*. [OWNER_CONFIRM_AI_SHARING]

## Data types
Legend: Collected = sent off the device to our backend. Optional = user can use the app without providing it.

| Play category → type | Collected | Shared | Processed ephemerally | Required / optional | Purposes | What it is in Meal Bazar |
|---|---|---|---|---|---|---|
| Personal info → **Name** | Yes | Yes (AI, only member names/nicknames used to match AI meal text) | No | Required | App functionality, Account management | Profile name, member display name |
| Personal info → **Email address** | Yes | No | No | Required | Account management, App functionality | Supabase Auth (email sign-in or Google) |
| Personal info → **User IDs** | Yes | No | No | Required | Account management, App functionality | Supabase user ID |
| Personal info → **Phone number** | Yes, if the user provides it | No | No | Optional | App functionality | `profiles.phone`; phone sign-in is off in v1.0 [OWNER_CONFIRM_PHONE_FIELD_IN_UI] |
| Personal info → **Address** | Yes | No | No | Optional | App functionality | Mess address (a shared mess's address, not a home address of the user per se) |
| Financial info → **Other financial info** | Yes | No | No | Required for core use | App functionality | Deposits (amount, method cash/bKash/Nagad/bank, TrxID), bazar amounts and item prices, expenses, balances. No card or bank account numbers are collected. |
| Financial info → **Purchase history** | Yes | Yes (AI, only if a receipt photo is scanned) | No | Required for core use | App functionality | Bazar purchases and item lines |
| Photos and videos → **Photos** | Yes | Yes (AI receipt scan only) | No (storage); gateway does not store AI images | Optional | App functionality | Receipt / ফর্দ photos, deposit screenshots, profile photo — private bucket |
| App activity → **Other user-generated content** | Yes | Yes (AI meal text only) | No | Required for core use | App functionality | Meal entries, notes, AI quick-entry text |
| App activity → **Other actions** | Yes | No | No | Required | App functionality | Audit log of mess changes (who/what/when) |
| App info and performance → Crash logs / Diagnostics | **No** | — | — | — | — | No crash/analytics SDK |
| Location, Contacts, Messages, Audio, Health, Calendar, Web browsing, Device IDs | **No** | — | — | — | — | Not collected. Camera is used for photos/QR only; voice entry uses the device keyboard's speech-to-text, not the app. |

Not used for: Advertising or marketing, Analytics, Personalisation, Fraud prevention (none declared). No data is sold.

## Deletion behaviour to keep consistent with the form
- In-app RPC `delete_my_account()` anonymises the profile (name → "Former member", phone and photo removed), unlinks memberships, deletes pending join requests, soft-deletes a mess with no other app users.
- The auth user (email / Google identity) is hard-deleted by the daily cron (`/api/cron/daily`).
- Mess financial records, receipts, audit log and the member display name are **retained** as mess data. Play allows retaining data with a disclosed reason; this is disclosed on the deletion page and privacy policy.
