# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack
Flutter (Riverpod, go_router, Drift) + Supabase + Vercel AI gateway. Fixed by the owner; see ARCHITECTURE.md.

## Users
Mess managers in Bangladeshi bachelor messes: students and young professionals (18–30) in Dhaka and other cities. They are comfortable with phones, short on time, and type a mix of Bangla and English (Banglish). They do the job unpaid, usually at night or just after a meal, often on a low-end Android phone with patchy mobile data. Secondary users are the mess members, who check their meals and dues and switch meals off.

## Product Purpose
Run a whole mess (daily meals, bazar, expenses, deposits and the month-end bill) from a phone in under 2 minutes a day, in Bangla. Success means the manager opens the app, completes the day's routine, and closes it, and that members trust the bill without arguing about it.

## Positioning
Other Bangladeshi mess apps are digital ledgers that make the manager do the accounting. Meal Bazar is built around the daily routine. It uses a tap-cycling meal grid instead of forms, works fully offline, accepts Bangla/Banglish text and photos of handwritten ফর্দ that the AI turns into drafts for a person to confirm, and gives every member a transparent bill that explains itself.

## Operating Context
- Meal counting happens once or twice a day, often in the kitchen or after dinner. The conventions are 1, ½ and 0 meals, guests charged to the host, and "meal off" requests.
- Bazar duty rotates among members. The receipts are handwritten lists (ফর্দ) or shop slips.
- Deposits arrive by cash, bKash or Nagad (with a TrxID).
- The month closes with a bill per member: a due or an advance. Summaries get shared in WhatsApp and Messenger groups.

## Capabilities and Constraints
See REQUIREMENTS.md. Bangla is the default language, with English also supported. Bangla digits are optional. Currency is ৳. The app must work on 2 GB RAM Android phones and on 3G, with a cold start under 3 s. Offline states must not feel like errors. AI is optional and always a draft that a person confirms.

## Brand Commitments
The name is "Meal Bazar" (মিল বাজার). No logo, colors or other assets exist yet.

## Evidence on Hand
None: no users, testimonials or metrics exist yet. Do not fabricate any.

## Product Principles
1. The daily routine comes first. Every screen is judged by whether it shortens the 2-minute routine.
2. Prefer taps to forms.
3. The numbers must be trustworthy. Show how every figure was computed, and never let AI touch the math.
4. Offline is normal, not a failure state.
5. Bangla first. Bangla text sets the type and spacing decisions, and English adapts to them.

## Accessibility & Inclusion
Touch targets of at least 48 dp. Contrast of at least 4.5:1. Layouts survive a 1.3× text scale, and TalkBack labels are present. Bengali script needs extra line height for its matras and conjuncts.
