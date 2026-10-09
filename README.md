<p align="center">
  <img src="app/assets/icon/brand.png" width="96" alt="Meal Bazar icon">
</p>

<h1 align="center">মিল বাজার · Meal Bazar</h1>

<p align="center"><b>মেসের পুরো হিসাব, ফোন থেকেই।</b><br>
Run your whole mess from your phone in 2 minutes a day, in Bangla.</p>

<p align="center">
  <a href="https://github.com/mdmakky/meal_bazar/releases/latest"><b>⬇️ Download the latest APK</b></a>
</p>

---

## বাংলায়

মিল বাজার হলো মেস (ব্যাচেলর বাসা, ছাত্রাবাস) চালানোর অ্যাপ। প্রতিদিনের মিল, বাজার, খরচ, জমা আর মাস শেষের হিসাব, সব এক জায়গায়, বাংলায়। ইন্টারনেট না থাকলেও কাজ করে, নেট এলে নিজে থেকে সিঙ্ক হয়।

### কী কী করা যায়
- **মিল:** সবার সকাল/দুপুর/রাতের মিল এক স্ক্রিনে; হাফ মিল, গেস্ট মিল, মিল বন্ধ। সদস্য নিজেই নিজের মিল বন্ধ করতে পারেন, ম্যানেজার ঠিক করে দেন কত আগে পর্যন্ত।
- **বাজার:** কে কে বাজারে গেছে, কোন আইটেম কত দাম, মেস ফান্ড নাকি নিজের পকেট থেকে। রসিদের ছবি থেকে AI দিয়ে আইটেম তোলা যায় (আপনি যাচাই করে সেভ করবেন)।
- **খরচ ও জমা:** সবার মধ্যে সমান ভাগ, মিল অনুযায়ী, বা নির্দিষ্ট কয়েকজনের মধ্যে ভাগ। বিকাশ/নগদ/ক্যাশ জমা, ম্যানেজার যাচাই করেন।
- **মাসের হিসাব:** মিল রেট, প্রত্যেকের অগ্রিম/বাকি, মাস বন্ধ করলে পরের মাসে ব্যালেন্স চলে যায়। পুরো মাসের বিস্তারিত PDF রিপোর্ট (দিনভিত্তিক মিল, প্রতিটি বাজার)।
- **স্বচ্ছতা:** সদস্যরা সবার জমা আর ব্যালেন্স দেখতে পান, নিজের বিষয়ে প্রতিটি এন্ট্রি দেখতে পান, আর ভুল দেখলে "সমস্যা জানান"।
- **যোগাযোগ:** ম্যানেজারকে বার্তা, পুরো মেসের গ্রুপ, নোটিশ বোর্ড, বাজারের পালা, পুশ নোটিফিকেশন।

### ইনস্টল করবেন যেভাবে
1. [Releases](https://github.com/mdmakky/meal_bazar/releases/latest) থেকে **`app-arm64-v8a-release.apk`** নামান (বেশিরভাগ ফোনে এটাই চলবে)। পুরনো/কম দামের ফোনে না চললে **`app-armeabi-v7a-release.apk`** নিন।
2. ফাইলটা খুলুন। ফোন অনুমতি চাইলে "এই উৎস থেকে ইনস্টল করার অনুমতি দিন" চালু করুন।
3. Google বা ইমেইল দিয়ে ঢুকুন, নতুন মেস বানান অথবা ম্যানেজারের দেওয়া কোড দিয়ে যোগ দিন।

লাগবে Android 7.0 বা তার পরের ভার্সন। অ্যাপের সাইজ ৩০ MB এর কম।

---

## In English

Meal Bazar is a Bangla-first, offline-first app for running a shared "mess" (bachelor housing) in Bangladesh: daily meal counts, grocery (bazar) runs, shared expenses, deposits and the month-end settlement.

### Features
| Area | What it does |
|---|---|
| Meals | Grid for every member × meal, with half meals, guests and meal-off. Members switch their own meals off up to a deadline the manager sets (for example 2 hours before the meal), and it is announced in the mess group. |
| Bazar | Several buyers per trip, an itemised list with a picker, paid from the mess fund or someone's own pocket, receipt photos, and AI receipt scan as a draft you confirm. |
| Expenses | Split equally among everyone present, by meals (added to the meal rate), or among selected members with weights. Recurring monthly bills. |
| Deposits | Cash, bKash, Nagad or bank, with a transaction ID. Members record their own and the manager verifies. |
| Month | Meal rate, each member's advance or due, close and reopen the month (reopening needs a reason and is audited), carry-forward balances, a fixed meal rate option, a detailed monthly PDF and CSV export. |
| Transparency | Members see everyone's deposits and balances plus every entry that affects them, and can report a problem on any entry. |
| Communication | Member-to-manager messages, a mess group, notices, a bazar duty rota and push notifications. |
| Platform admin | A web panel for feature flags, branding, AI model chains (free or paid filter), credentials, suspensions and usage. |

### How it's built
- **App:** Flutter (Riverpod, go_router, Drift for offline storage with a sync queue), in Bangla and English. Code is in [`app/`](app/).
- **Backend:** Supabase Postgres. All money and meal maths lives in SQL functions, and Row Level Security is the access boundary. Migrations and SQL tests are in [`supabase/`](supabase/).
- **AI gateway:** Vercel serverless functions in TypeScript, using Gemini with OpenRouter as the fallback. The AI only drafts, and a person always confirms. Code is in [`ai-gateway/`](ai-gateway/).
- **Push:** Firebase Cloud Messaging through a database outbox.

Rules of the product: [PRODUCT_RULES.md](PRODUCT_RULES.md) · Schema: [DATABASE.md](DATABASE.md) · Architecture: [ARCHITECTURE.md](ARCHITECTURE.md) · Setup and release: [DEVELOPMENT.md](DEVELOPMENT.md)

### Run it locally
```sh
cd app
cp env.example.json env.json        # fill in your Supabase URL and publishable key
flutter pub get
flutter run --dart-define-from-file=env.json
```
Tests:
```sh
cd app && flutter analyze && flutter test   # app
./supabase/tests/run.sh                     # SQL and RLS (needs a local Postgres)
cd ai-gateway && npm test                   # gateway
```

### Privacy
See the [privacy policy](docs/privacy-policy.md) and [account deletion](docs/account-deletion.md). No secrets ship in the app; only the Supabase URL and publishable key do.
