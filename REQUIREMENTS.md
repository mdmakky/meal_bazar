# Meal Bazar — Requirements

> **Run your whole mess from your phone in 2 minutes a day, in Bangla.**

This file is the primary source of truth for the product. It refines `Plan.md` (the original brief, which stays untouched) for the actual stack and budget: a Flutter Android app on the Play Store, Supabase, a thin Vercel AI gateway, and free AI tiers.

---

## 1. Positioning

Existing Bangladeshi mess apps are digital ledgers. You open them, fill forms, and do the accounting yourself. Meal Bazar is built around **the manager's daily 2-minute routine**:

```
Open app → Today screen (status at a glance) → tap meals / add bazar / record deposit → numbers update → done
```

**What makes it different:**
| Differentiator | What it means |
|---|---|
| Bangla-first | Bangla is the default UI language. Numbers can be shown in Bangla digits. Banglish input is understood. |
| Offline-first | Meal and bazar entry work with no connection and sync later. Bangladeshi mobile data is unreliable, and the app must not care. |
| Tap, not forms | The meal grid uses tap cycling (1 → ½ → 0 → Off). Guest and meal-off are single actions, and quick actions open bottom sheets. |
| AI drafts, you confirm | Type "aj Rahim 2, Karim off" or photograph a handwritten ফর্দ, then review the draft and confirm it. AI never touches money on its own. |
| Transparent bill | Every member sees exactly how their due was computed, and can ask the AI to explain it in Bangla. This removes the #1 source of mess disputes. |
| Member self-service | Members turn off their own meals before the cutoff and see their own balance, so the manager is no longer a bottleneck. |
| Community price index (v1.2) | An opt-in, anonymised view of bazar prices by area, such as "Eggs ৳145/dozen in Mirpur this week". |

## 2. Personas
- **Manager** (one or two per mess). Usually a student or young professional who does this unpaid and wants it done fast. Has full write access.
- **Member**. Wants to know their meals and their due, and to switch meals off without calling the manager.
- **Bazar-duty member**. Buys groceries on their assigned day and must log the purchase (the ফর্দ scan helps).
- **Super Admin** (us). Platform health, abuse handling, the AI provider config, and the global kill switch. In v1.2 this becomes a Flutter-web admin panel. Until then, it is the Supabase dashboard.

## 3. Modules and priority

MoSCoW: **M** = MVP (v1.0, Play Store launch), **S** = v1.1, **C** = v1.2, **W** = later.

### 3.1 Auth and account
| Req | Pri |
|---|---|
| Google sign-in (one tap) and email + password, both free | M |
| Phone OTP sign-in (`+8801XXXXXXXXX`). The code exists but is switched off until an SMS provider is funded | W |
| Profile: name, photo, preferred language | M |
| Sessions handled by the Supabase Auth refresh token, with a logout action | M |
| **In-app account deletion** (a Play Store requirement). Personal data is anonymised and the financial rows are kept, attributed to "Former member". | M |

### 3.2 Mess and members
| Req | Pri |
|---|---|
| Create a mess with name, address, month start day and currency (৳). The creator becomes the manager. | M |
| Onboarding: Create mess → meal types → invite members → first deposits → start month | M |
| Invite by 6-character code, by QR code, or by share link. A join request requires manager approval. | M |
| Member states are active, inactive and left. History is always preserved. | M |
| Roles: manager and member. Multiple managers are allowed. A configurable permission matrix comes later. | M (W for the matrix) |
| Room/seat and notes fields on a member | S |
| One user belonging to several messes, with a mess switcher | S |

### 3.3 Meals
| Req | Pri |
|---|---|
| Configurable meal types: add, rename, reorder, enable/disable, with a **weight** (for example breakfast = 0.5) | M |
| Meal grid for one day: members × meal types. Tapping a cell cycles **1 → ½ → 0**. Long-pressing a cell offers Off, Guest +n, or a custom value. | M |
| Today screen totals per meal type, and member totals for the month | M |
| Copy yesterday, and set all of a member's meals or all of a meal type's cells in one action | M |
| Guest meals: count + host member. The cost is charged to the host. | M |
| **Meal off** by the member themselves, before a manager-set cutoff (for example tomorrow's lunch off before 10 pm). The manager can override. | S |
| Default pattern per member (for example "always skips breakfast") | S |
| Day lock (a manager action) | S |
| Ramadan preset (Sehri/Iftar meal types) | C |

### 3.4 Bazar, expenses, deposits
| Req | Pri |
|---|---|
| Bazar entry: date, buyer, total, optional item lines (name, qty, unit, price), receipt photo | M |
| Expenses: category (Electricity, Gas, WiFi, Water, Rent, Maid, Cleaning, Maintenance, Other, plus custom), amount, paid by, split method | M |
| Split methods: **meal-based** (food) and **equal across active members**. Custom and weighted splits come later. | M (C for custom/weighted) |
| Deposits: member, amount, method (Cash, bKash, Nagad, Bank, Other), TrxID, screenshot | M |
| A deposit made by a member themselves → "pending" until the manager verifies it | S |
| Bazar duty rotation calendar, with a reminder on the duty day | S |
| Share a bazar summary as text or an image to WhatsApp/Messenger | M |

### 3.5 Month and billing
| Req | Pri |
|---|---|
| Meal rate, member food cost, extra costs, deposits and balance, all computed by SQL (see PRODUCT_RULES.md) | M |
| Live running balance throughout the month | M |
| Close month: freezes the numbers, writes a snapshot, and carries the balance forward | M |
| Reopen a month: manager only, with a required reason, and audited | M |
| Monthly report as a PDF on the device, shared via the share sheet | M |
| CSV export | S |
| Weekly and custom date ranges for reports | C |

### 3.6 Communication
| Req | Pri |
|---|---|
| Announcements (pin, expiry, read status) | S |
| Push notifications (FCM): meal-off cutoff reminder, bazar duty, deposit verified, month closed, due reminder | S |
| In-app notification list | S |

### 3.7 Audit
| Req | Pri |
|---|---|
| Audit log of business events (who, what, when, old → new, source `app`/`ai`/`system`, reason) | M (data), S (UI) |

### 3.8 Settings
Mess settings, meal types, expense categories, meal-off cutoff, language (bn/en), Bangla digits on or off, theme (system/light/dark), and the AI settings (see §4). **M**

## 4. AI

Full design: [AI.md](AI.md). The rules: **AI drafts, a human confirms. SQL is the truth and AI only explains. The app works fully with AI switched off.**

| # | Feature | Pri | Cost profile |
|---|---|---|---|
| 1 | **Bangla/Banglish quick meal entry** (text; voice via the device's speech-to-text) → a meal draft | M | 1 small text call |
| 2 | **Receipt or handwritten ফর্দ scan** → a bazar draft (items, qty, unit, price, total) | M | 1 vision call |
| 3 | **Explain my bill** in Bangla, from SQL-computed numbers | S | 1 small call, cached for each balance version |
| 4 | Meal-rate forecast with a one-line tip (the projection is SQL, the AI only writes the sentence) | S | cached daily |
| 5 | Anomaly flags: duplicate bazar, price far above the mess's own history, edits after lock (SQL rules, AI wording) | S | rules first |
| 6 | Polite due-reminder text (choice of tone, bn/en) → share | S | 1 small call |
| 7 | **Ask your mess** chat over whitelisted read-only tools | C | tool-calling |
| 8 | Monthly Mess Wrap share card | C | 1 call per month |
| 9 | Community price index (opt-in, anonymised by area) | C | SQL only |
| 10 | Smart bazar list and duty-rotation suggestions | W | — |

**AI settings (per mess, manager only):** an AI master switch, a toggle for each feature, the response language, the tone, a usage meter (today's count against the quota), "share anonymised prices", and "hide member names from AI" (on by default, so names are pseudonymised).
**Super Admin:** the provider chain, model IDs, global and per-mess quotas, and a kill switch.

## 5. Non-functional requirements
| Area | Requirement |
|---|---|
| Performance | Cold start under 3 s on a 2 GB RAM Android phone. Usable on 3G. Release APK target under 30 MB (split per ABI). Aggregation happens in SQL, and the app never downloads whole tables. |
| Offline | Meals and bazar are written locally first (Drift) and synced through a queue. Each row shows its sync state: synced, syncing, offline or failed. |
| Security | RLS on every table. No secrets in the APK. Receipts live in a private bucket served through signed URLs. The AI gateway checks the Supabase JWT, mess membership and quota. Rate limits apply. |
| Integrity | `numeric(12,2)` for money. Client-generated UUIDs make writes idempotent. Soft delete. Closed months are protected by a DB trigger. |
| i18n | bn (default) and en through ARB keys, with no hard-coded UI strings. Optional Bangla digits. Dates in the form ৮ অক্টোবর ২০২৬. |
| Accessibility | Touch targets at least 48 dp, contrast at least 4.5:1, works at 1.3× text scale, labels for TalkBack. |
| Privacy | A privacy policy, the Play Data Safety form, AI disclosure (data goes to Google/OpenRouter when AI is on), and in-app account deletion. |

## 6. Free-tier constraints (accepted risks)
| Service | Limit | Mitigation |
|---|---|---|
| Vercel Hobby | Non-commercial use only. Limited cron jobs. Function time limits. | Vercel handles only AI and cron. **Move to Pro before ads or subscriptions.** |
| Supabase Free | Pauses after 7 days idle. 500 MB DB, 1 GB storage, 2 GB egress. | The daily cron keeps the project awake. Receipts are compressed on the device to about 200 KB. Aggregates are cached. |
| Gemini free tier | Low RPM/RPD limits. Google may use prompts to improve its products. | Per-mess quotas, the OpenRouter fallback, name pseudonymisation, and disclosure in the AI settings. |
| OpenRouter free models | About 50 requests per day without credits | Used only as the fallback. Adding $10 of credit raises the limit. |
| SMS OTP | Supabase phone auth needs a paid SMS provider | Phone login is off. Google and email are free; phone comes back when there is budget. |

## 7. Releases
- **v1.0 (MVP, Play Store):** every **M** item above, plus AI #1 and #2.
- **v1.1:** **S** items: meal-off, notifications, audit UI, AI #3–6, deposit verification, duty rotation.
- **v1.2:** **C** items: Ask your mess, Mess Wrap, price index, custom/weighted split, the admin panel.
- **Later:** bKash/Nagad API integration, subscriptions, cloud backup and import, iOS release.

## 8. Success metrics
- The manager's daily routine takes **under 2 minutes** (measured as the time from opening the app to the last write of the day).
- AI draft acceptance (confirmed with at most minor edits) is above 80%.
- At least 70% of active messes close their month.
- D30 retention for managers.
- At least 99% of offline writes sync without user intervention.

## 9. Coverage of Plan.md
| Plan.md § | Where it lives |
|---|---|
| 1 Core concept, 6–8 Meals | §3.3, PRODUCT_RULES §1 |
| 2 Roles | §3.2. Super Admin uses the Supabase dashboard until v1.2. The configurable permission matrix is **W**. |
| 3 Auth | §3.1 |
| 4–5 Mess, members | §3.2 |
| 9–12 Bazar, sharing, expenses, deposits | §3.4 |
| 13–15 Meal rate, bill, split | §3.5, PRODUCT_RULES §2–3. Custom/weighted split is **C**. |
| 16–18 Dashboards, report | Today screen and Month screen (DESIGN_SYSTEM). PDF is §3.5. |
| 19 Date/month | §3.5. Weekly/custom ranges are **C**. |
| 20–21 Announcements, notifications | §3.6 |
| 22, 40 Audit, integrity | §3.7, DATABASE.md |
| 23 Search/filter | Filters by member and month on each list, with pagination. Free-text search is **S**. |
| 24 Dynamic system | Meal types, categories, cutoff and labels are configurable. Fully dynamic labels for every term is **W**. |
| 25–28 UI, mobile, dark mode, responsive | DESIGN_SYSTEM.md. Android phones come first. Tablet layout is **C**. |
| 29–30 Bangla, BD context | §5 i18n, §3.4 payment methods |
| 31–33 Data model, API, security | DATABASE.md. The REST API is replaced by Supabase PostgREST + RPC, protected by RLS. |
| 34 Receipts | Private Storage bucket with signed URLs |
| 35–36 Validation, errors | DB constraints and triggers, plus the app's error mapper |
| 37 Performance | §5 |
| 38–39 Architecture, calculation engine | ARCHITECTURE.md. The engine is Postgres views and functions. |
| 41–44 Settings, onboarding, empty states, confirmation | §3.8, §3.2, DESIGN_SYSTEM |
| 45 Future-ready | §7 |
| 46 Tech stack | **Replaced**: Flutter, Supabase and Vercel instead of Next.js/Express/Docker (see ARCHITECTURE.md) |
| 47–50 Quality, phases | CLAUDE.md, DEVELOPMENT.md |
