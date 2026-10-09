# Meal Bazar — গোপনীয়তা নীতি / Privacy Policy

কার্যকর তারিখ / Effective date: 9 October 2026
পরিচালনাকারী / Operated by: Md. Arafatuzzaman, Dhaka, Bangladesh
যোগাযোগ / Contact: makky.cse@gmail.com

---

## বাংলা

Meal Bazar (মিল বাজার) একটি মেস ম্যানেজমেন্ট অ্যাপ। এই নীতিতে সহজ ভাষায় বলা আছে আমরা কী তথ্য নিই, কেন নিই, কোথায় রাখি আর আপনি কীভাবে তা মুছতে পারেন।

**মূল কথা:** আমরা কোনো বিজ্ঞাপন দেখাই না, কোনো অ্যানালিটিক্স SDK ব্যবহার করি না, এবং আপনার তথ্য বিক্রি করি না।

### ১. আমরা কী তথ্য নিই
| তথ্য | কেন |
|---|---|
| ইমেইল ঠিকানা (ইমেইল দিয়ে লগইন করলে), অথবা Google অ্যাকাউন্টের মৌলিক তথ্য (ইমেইল, নাম) Google দিয়ে লগইন করলে | লগইন ও অ্যাকাউন্ট চালানোর জন্য |
| প্রোফাইল: নাম, ছবি (দিলে), ফোন নম্বর (দিলে), পছন্দের ভাষা | মেসের অন্য সদস্যরা যেন আপনাকে চিনতে পারে; অ্যাপের ভাষা ঠিক রাখতে |
| মেসের তথ্য: মেসের নাম ও ঠিকানা, সদস্যের তালিকা ও ভূমিকা, প্রতিদিনের মিল, বাজার (আইটেম, দাম), খরচ, জমা (পরিমাণ, মাধ্যম যেমন নগদ/বিকাশ/নগদ, TrxID) | মিল রেট, প্রত্যেকের বিল ও ব্যালান্স হিসাব করতে |
| ছবি: বাজারের রসিদ/ফর্দ, জমার স্ক্রিনশট | হিসাবের প্রমাণ হিসেবে মেসের সদস্যদের দেখাতে |
| কার্যক্রমের লগ (কে, কখন, কী বদলেছে) | হিসাবে স্বচ্ছতা ও বিবাদ মেটাতে |
| AI ব্যবহারের সংখ্যা (মেস, দিন, ফিচার) | দৈনিক AI সীমা মানতে |

ক্যামেরা ব্যবহার হয় শুধু রসিদের ছবি তোলা ও মেসে যোগ দেওয়ার QR কোড স্ক্যানের জন্য। মাসিক PDF রিপোর্ট আপনার ফোনেই তৈরি হয়।

### ২. কে আপনার তথ্য দেখতে পায়
- **আপনার মেসের সদস্যরা** — মেসের মিল, বাজার, খরচ, জমা, রসিদ ও কার্যক্রমের লগ মেসের সব সদস্য দেখতে পারেন। এটাই অ্যাপের উদ্দেশ্য (স্বচ্ছ হিসাব)। লেখার অধিকার মূলত ম্যানেজারের।
- অন্য মেসের কেউ আপনার মেসের তথ্য দেখতে পায় না। ডাটাবেসের প্রতিটি টেবিলে Row Level Security চালু আছে।

### ৩. কোথায় রাখা হয় ও কারা প্রসেস করে
| সেবাদাতা | কাজ |
|---|---|
| Supabase (সার্ভার অঞ্চল: সিঙ্গাপুর) | ডাটাবেস, লগইন, এবং রসিদের ছবি (প্রাইভেট স্টোরেজ, শুধু সাময়িক সাইন করা লিংকে দেখা যায়) |
| Vercel | AI গেটওয়ে চালায় এবং দৈনিক রক্ষণাবেক্ষণের কাজ (মুছে ফেলার অনুরোধ প্রসেস করা) |
| Google (Gemini) ও OpenRouter | শুধু AI ফিচার ব্যবহার করলে এবং মেসে AI চালু থাকলে (নিচে দেখুন) |
| Google Sign-In | শুধু Google দিয়ে লগইন করলে |

### ৪. AI সম্পর্কে
- AI শুধু **খসড়া** বানায় (যেমন "আজ রহিম ২, করিম অফ" লিখলে মিলের খসড়া, বা ফর্দের ছবি থেকে বাজারের খসড়া)। আপনি দেখে নিশ্চিত না করা পর্যন্ত কিছু সেভ হয় না। AI কখনো নিজে হিসাব বা টাকার অঙ্ক বদলায় না।
- আপনি যখন AI ফিচার ব্যবহার করেন, তখন আপনার লেখা টেক্সট বা ছবি Google Gemini-তে, আর তা ব্যর্থ হলে OpenRouter-এ পাঠানো হয়। **এদের ফ্রি টিয়ার এই তথ্য তাদের মডেল উন্নত করতে ব্যবহার করতে পারে।** তাই ছবিতে বা লেখায় অপ্রয়োজনীয় ব্যক্তিগত তথ্য দেবেন না।
- সদস্যদের পাঠানো হয় কোড হিসেবে (M1, M2…), সাথে শুধু মেলানোর জন্য দরকারি নাম/ডাকনাম। কোনো আইডি, ফোন নম্বর বা টাকার অঙ্ক পাঠানো হয় না।
- আমাদের গেটওয়ে আপনার টেক্সট, ছবি বা AI-এর উত্তর সংরক্ষণ করে না; শুধু ব্যবহারের সংখ্যা রাখে।
- মেসের ম্যানেজার মেস সেটিংস থেকে AI পুরোপুরি বন্ধ করতে পারেন (ডিফল্টে চালু)। AI ছাড়াও অ্যাপ পুরোপুরি চলে।

### ৫. কতদিন রাখা হয়
- অ্যাকাউন্ট থাকা পর্যন্ত আপনার প্রোফাইল ও লগইন তথ্য থাকে।
- মেসের হিসাব (মিল, বাজার, খরচ, জমা, রসিদ, লগ) মেসের রেকর্ড; মেস চালু থাকা পর্যন্ত থাকে। মুছে ফেলা মেসের তথ্য রাখা থাকে যতক্ষণ না কেউ মোছার অনুরোধ করেন; অনুরোধ পেলে ৩০ দিনের মধ্যে স্থায়ীভাবে মুছে ফেলা হয়।
- ব্যাকআপ থেকে তথ্য মুছে যেতে সর্বোচ্চ ৭ দিন লাগতে পারে।

### ৬. অ্যাকাউন্ট মুছে ফেলা
অ্যাপে: **আরও → অ্যাকাউন্ট → অ্যাকাউন্ট মুছে ফেলুন**। অ্যাপ ইনস্টল না থাকলে makky.cse@gmail.com-এ ইমেইল করুন। বিস্তারিত: https://meal-bazar-admin.vercel.app/delete-account

- **যা মুছে যায়:** আপনার নাম (প্রোফাইলে "Former member" হয়ে যায়), ফোন নম্বর, প্রোফাইল ছবি, আপনার লগইন অ্যাকাউন্ট (ইমেইল/Google লিংকসহ — দৈনিক স্বয়ংক্রিয় কাজে স্থায়ীভাবে মুছে যায়), অপেক্ষমাণ যোগদানের অনুরোধ, এবং সব মেসে আপনার প্রবেশাধিকার।
- **যা থাকে:** মেসের মিল, বাজার, খরচ, জমা (TrxID সহ), রসিদের ছবি ও কার্যক্রমের লগ — যাতে অন্য সদস্যদের হিসাব না বদলায়। এসব রেকর্ডে মেস আপনাকে যে নামে রেখেছিল (ডিসপ্লে নাম) সেটি থেকে যায়, কিন্তু আর আপনার অ্যাকাউন্টের সাথে যুক্ত থাকে না। মুছে ফেলার অনুরোধের একটি রেকর্ড (ব্যবহারকারী আইডি ও সময়) প্রমাণ হিসেবে থাকে।
- যে মেসে আপনি ছাড়া আর কোনো অ্যাপ ব্যবহারকারী নেই, সেটি বন্ধ (মুছে ফেলা হিসেবে চিহ্নিত) হয়।
- আপনি কোনো মেসের একমাত্র ম্যানেজার হলে আগে অন্য কাউকে ম্যানেজার করতে হবে।

### ৭. শিশুরা
Meal Bazar ১৩ বছরের কম বয়সীদের জন্য নয়, এবং আমরা জেনেশুনে তাদের তথ্য নিই না। এমন তথ্য পেলে makky.cse@gmail.com-এ জানান, আমরা মুছে দেব।

### ৮. নিরাপত্তা
- অ্যাপ ও সার্ভারের মধ্যে সব যোগাযোগ HTTPS দিয়ে এনক্রিপ্টেড।
- প্রতিটি ডাটাবেস টেবিলে Row Level Security: আপনি শুধু নিজের মেসের তথ্য দেখতে পান।
- রসিদের ছবি প্রাইভেট স্টোরেজে থাকে, শুধু মেসের সদস্যরা সাময়িক লিংকে দেখতে পান।
- অ্যাপে কোনো গোপন চাবি (secret key) রাখা হয় না; AI গেটওয়ে প্রতিটি অনুরোধে লগইন ও মেস-সদস্যপদ যাচাই করে।

কোনো ব্যবস্থাই শতভাগ নিরাপদ নয়, তবে আমরা যুক্তিসঙ্গত সতর্কতা নিই।

### ৯. পরিবর্তন ও যোগাযোগ
এই নীতি বদলালে এই পাতায় নতুন তারিখসহ জানানো হবে। প্রশ্ন বা অনুরোধ (তথ্য দেখা, ঠিক করা, মোছা): makky.cse@gmail.com

---

## English

Meal Bazar is a mess-management app. This policy explains, in plain language, what we collect, why, where it is stored, and how you can delete it.

**In short:** no ads, no analytics SDKs, and we do not sell your data.

### 1. What we collect
| Data | Why |
|---|---|
| Email address (email sign-in), or basic Google account info (email, name) if you sign in with Google | Sign-in and running your account |
| Profile: name, photo (if set), phone number (if provided), preferred language | So your mess can recognise you; to show the app in your language |
| Mess data: mess name and address, member list and roles, daily meals, bazar (items, prices), expenses, deposits (amount, method such as cash/bKash/Nagad, TrxID) | To compute the meal rate and each member's bill and balance |
| Photos: bazar receipts / handwritten lists (ফর্দ), deposit screenshots | Proof for the mess's accounts |
| Activity log (who changed what, and when) | Transparency and settling disputes |
| AI usage counts (mess, day, feature) | Enforcing the daily AI limit |

The camera is used only to photograph receipts and to scan a mess's invite QR code. Monthly PDF reports are generated on your phone.

### 2. Who can see your data
- **Members of your mess** can see that mess's meals, bazar, expenses, deposits, receipts and activity log. That is the point of the app (a transparent bill). Writing is mainly done by managers.
- People outside your mess cannot see it. Row Level Security is enabled on every database table.

### 3. Where it is stored and who processes it
| Provider | Role |
|---|---|
| Supabase (server region: Singapore) | Database, sign-in, and receipt photos (private storage, viewable only through short-lived signed links) |
| Vercel | Hosts the AI gateway and a daily maintenance job (which processes deletion requests) |
| Google (Gemini) and OpenRouter | Only when you use an AI feature and AI is enabled for your mess (see below) |
| Google Sign-In | Only if you choose to sign in with Google |

### 4. AI disclosure
- AI only produces **drafts** (for example a meal draft from "aj Rahim 2, Karim off", or a bazar draft from a photo of a ফর্দ). Nothing is saved until you review and confirm it. AI never changes the calculations or money on its own.
- When you use an AI feature, the text or photo you provide is sent to Google Gemini, and to OpenRouter if Gemini fails. **Their free tiers may use it to improve their models.** Do not include personal details you do not need to.
- Members are sent as codes (M1, M2…) plus only the names/nicknames needed to match what you typed. No account IDs, phone numbers or money figures are sent.
- Our gateway does not store your text, photos or the AI's replies; it keeps only a usage counter.
- The mess manager can switch AI off for the whole mess in the mess settings (it is on by default). The app works fully without AI.

### 5. Retention
- Your profile and sign-in data are kept while your account exists.
- Mess records (meals, bazar, expenses, deposits, receipts, log) belong to the mess and are kept while the mess exists. Data of a deleted mess is kept until someone asks us to delete it; we then delete it permanently within 30 days.
- Removal from backups may take up to 7 days.

### 6. Account deletion
In the app: **আরও (More) → অ্যাকাউন্ট (Account) → অ্যাকাউন্ট মুছে ফেলুন (Delete account)**. Without the app, email makky.cse@gmail.com. Details: https://meal-bazar-admin.vercel.app/delete-account

- **Deleted:** your name (the profile becomes "Former member"), phone number, profile photo, your sign-in account (including email / Google link — permanently removed by an automatic daily job), pending join requests, and your access to every mess.
- **Kept:** the mess's meals, bazar, expenses, deposits (including TrxIDs), receipt photos and activity log, so other members' accounts do not change. In those records the name the mess used for you (display name) stays, but it is no longer linked to any account. A record of the deletion request (user ID and timestamps) is kept as proof that it was processed.
- A mess with no other app users is closed (marked deleted).
- If you are the only manager of a mess, you must make someone else manager first.

### 7. Children
Meal Bazar is not directed at children under 13, and we do not knowingly collect their data. If you believe we have, contact makky.cse@gmail.com and we will delete it.

### 8. Security
- All traffic between the app and our servers is encrypted with HTTPS.
- Row Level Security on every table: you can only access your own messes' data.
- Receipt photos are in private storage, viewable only by mess members through short-lived links.
- No secret keys are shipped in the app; the AI gateway verifies your sign-in and mess membership on every request.

No system is perfectly secure, but we take reasonable precautions.

### 9. Changes and contact
If this policy changes, we will update this page with a new date. Questions or requests (access, correction, deletion): makky.cse@gmail.com
