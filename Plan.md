**Modern Bangladesh Mess Management App**


Modern Bangladesh Mess Management App — Development Prompt

Build a complete, modern, production-ready Mess Management & Meal Management Application for Bangladesh, inspired by the core workflow of popular Bangladeshi mess-management platforms, but with a cleaner UI/UX, highly dynamic architecture, and full customization/editing capabilities.

The application should be designed for Bachelor Mess, Student Mess, Hostel, Shared Apartment, Family/Group Meal Management, and Small Boarding Houses.

The main goal is to make daily mess management extremely simple while automatically calculating meals, bazar expenses, member balances, meal rates, dues, and monthly summaries.

**1\. CORE PRODUCT CONCEPT**  
\- Manager/Admin can create and manage a mess.  
\- Members/users can be added dynamically.  
\- Each member can have their own meal count.  
\- Daily meals can be entered easily.  
\- Meals can be represented in compact formats such as: 0 5 5 1 1 5.  
\- Support configurable meal types such as Breakfast, Lunch, Dinner, Snacks.  
\- Number and names of meal types must be configurable.

**2\. USER ROLES**  
Super Admin: manage platform, messes, users, analytics, suspension/deletion and system settings.  
Mess Manager/Admin: manage mess, members, meals, bazar, expenses, deposits, reports and settings.  
Member: view own meals, balance, bazar, expenses, reports, announcements and edit own profile.  
Permissions should be configurable rather than hardcoded.

**3\. AUTHENTICATION**  
Implement registration, login, logout, forgot/reset password, verification where supported, profile management, password change and session management.  
Support Bangladesh phone format +8801XXXXXXXXX.  
Allow joining through invitation link, code, QR code and manager approval.

**4\. MESS CREATION**  
Fields: mess name, address, description, start date, monthly cycle/start day, currency, meal types, default calculation method, manager, logo/image and contact information.  
Creator automatically becomes Manager.

**5\. MEMBER MANAGEMENT**  
Add/edit/remove/deactivate/restore members, change role, assign manager, view profile, meals, deposits and balance.  
Fields: name, phone, email, photo, join date, role, status, room/seat and notes.  
Use Active, Inactive and Left Mess states. Preserve historical financial data.

**6\. DAILY MEAL MANAGEMENT**  
Provide a fast meal-entry table with Member, Breakfast, Lunch, Dinner and Total.  
Also support compact entry such as Arafat → 1 1 1.  
Support add/edit/delete, bulk entry, copy previous day, meal patterns, absence/presence, day lock/unlock.  
Allow managers to configure whether members can edit meals.

**7\. QUICK MEAL ENTRY**  
Mobile-first one-tap +/− controls, long press, keyboard input and swipe-friendly interaction.  
Automatically calculate daily and monthly meal totals.

**8\. CUSTOM MEAL SYSTEM**  
Do not hardcode breakfast/lunch/dinner. Allow adding, renaming, deleting, reordering, enabling/disabling and setting defaults for meal types. All calculations adapt dynamically.

**9\. BAZAR MANAGEMENT**  
Create a complete Bazar/Shopping module.  
Bazar entry: date, buyer, category, items, quantity, unit, price, total, receipt/image and notes.  
Support add/edit/delete, receipt upload, search and filtering by member/date/category.

**10\. BAZAR SHARING**  
Provide a clean shareable summary with buyer, items and total.  
Support copy, WhatsApp, Messenger, native mobile share, image/PDF generation.

**11\. EXPENSE MANAGEMENT**  
Separate general expenses from bazar.  
Categories: Bazar, Electricity, Gas, WiFi, Water, Rent, Maid, Cleaning, Maintenance and Other.  
Allow custom categories and fields for amount, date, category, paid by, description, receipt and notes.

**12\. DEPOSIT / ADVANCE MANAGEMENT**  
Track member deposits with amount, date, member, payment method, reference and notes.  
Payment methods: Cash, bKash, Nagad, Bank and Other.  
Maintain transaction history/audit logs.

**13\. AUTOMATIC MEAL RATE**  
Meal Rate = Total Food Expense / Total Meals.  
Member Food Cost = Member Meals × Meal Rate.  
Example: 85 meals × ৳30 = ৳2,550.

**14\. MONTHLY BILL CALCULATION**  
Calculate total meals, food expense, meal rate, food cost, additional expenses, deposits, current balance, due and advance.  
Example:  
Food Cost ৳2,550 + WiFi ৳200 + Electricity ৳300 + Other ৳100 = ৳3,150.  
Deposit ৳4,000 → ৳850 advance.  
Calculation system must be configurable.

**15\. COST-SHARING METHODS**  
Support meal-based, equal split, custom split and weighted split.  
Allow choosing the method for each expense.

**16\. DASHBOARD**  
Show total members, today's meals, current meal rate, total bazar, total expenses, deposits, dues, advances and current month cost.  
Charts: daily meal trend, monthly expense trend, bazar spending, member meal distribution and expense categories.  
Responsive and mobile-first.

**17\. MEMBER DASHBOARD**  
Show today's meals, monthly meals, current meal rate, food cost, additional expenses, total paid, current due/advance and recent transactions/bazar entries.

**18\. MONTHLY REPORT**  
Show month, members, total meals, total food expense, meal rate, additional expense and total expense.  
Member table should include Meals, Food Cost, Extra Cost, Paid and Balance.  
Support PDF, Excel/CSV, print, share and download.

**19\. DATE & MONTH MANAGEMENT**  
Support daily, weekly, monthly and custom ranges.  
Allow create/close/reopen month, lock previous records and carry forward balances.  
Never destroy previous month's data.

**20\. ANNOUNCEMENT SYSTEM**  
Managers can create/edit/delete/pin announcements with expiry dates and read/unread status.

**21\. NOTIFICATIONS**  
Support notifications for announcements, meal reminders, deposits, expenses, due payments, month closing and new members. Design for future push notification integration.

**22\. ACTIVITY / AUDIT LOG**  
Record user, action, timestamp, entity, previous value and new value.  
Examples: added bazar, edited meal, added member, deposited money.

**23\. SEARCH & FILTER**  
Everything should support search/filtering by date, member, category, amount, transaction type and status.  
Use pagination.

**24\. DYNAMIC / EDITABLE SYSTEM**  
Avoid hardcoded business logic. Configure meal types, expense categories, roles, settings, calculation methods, monthly cycle, permissions, notifications, currency and labels dynamically.  
Changing Dinner to Night Meal should reflect throughout the application.

**25\. UI/UX**  
Design as a modern SaaS product, not an old accounting application.  
Use cards, mobile bottom navigation, desktop sidebar, floating action buttons, modal/drawer forms, clean tables, tabs, search, filters, toast notifications, confirmation dialogs, skeleton loaders and helpful empty states.  
Avoid excessive gradients, clutter, tiny buttons and old-fashioned Bootstrap-style layouts.

**26\. MOBILE EXPERIENCE**  
Android-first quality. Navigation: Dashboard, Meals, Bazar, Expenses, Members, More.  
Important daily actions should require very few taps.

**27\. DARK MODE**  
Support Light, Dark and System modes.

**28\. RESPONSIVE DESIGN**  
Proper layouts for Android phones, iPhone, tablets, laptop and desktop. Do not merely shrink desktop UI for mobile.

**29\. BANGLA LANGUAGE SUPPORT**  
Support English and বাংলা using i18n translation keys. Do not hardcode UI text.

**30\. BANGLADESHI CONTEXT**  
Use ৳, Bangladesh phone numbers and bKash/Nagad/Bank/Cash payment methods. Use Bangladesh-friendly date and number formatting.

**31\. DATA MODEL**  
Consider User, Mess, MessMember, Role, Permission, MealType, Meal, Bazar, BazarItem, Expense, ExpenseCategory, Deposit, Transaction, MonthlySummary, Announcement, Notification, AuditLog and Settings.  
Use proper relationships and foreign keys. Use decimal/numeric types for financial values.

**32\. API ARCHITECTURE**  
Build clean REST APIs with authentication, authorization, validation, pagination, filtering, sorting and proper errors.  
Examples:  
POST /api/auth/login  
GET /api/messes/:id  
GET /api/messes/:id/members  
POST /api/messes/:id/members  
GET /api/messes/:id/meals  
POST /api/messes/:id/meals  
GET /api/messes/:id/bazar  
POST /api/messes/:id/bazar  
GET /api/messes/:id/reports/monthly

**33\. SECURITY**  
Implement password hashing, JWT/session authentication, RBAC, validation, rate limiting, SQL injection protection, XSS protection, CSRF protection where applicable, secure uploads, authorization and audit logging.  
Strictly isolate each mess's data.

**34\. FILE / RECEIPT MANAGEMENT**  
Support image/PDF receipts and payment screenshots. Store securely and restrict access.

**35\. VALIDATION**  
Amounts cannot be negative. Meal counts cannot be invalid. Members must belong to the mess. Closed months cannot be edited without authorization. Leaving a mess must not break historical calculations.

**36\. ERROR HANDLING**  
Use friendly user-facing errors and detailed internal logging.

**37\. PERFORMANCE**  
Optimize for low-end Android devices and slower internet using pagination, lazy loading, caching, optimized API calls, debounced search, optimistic UI where appropriate, indexes and efficient queries.

**38\. ARCHITECTURE**  
Separate UI, business logic, API, database, authentication, authorization, calculation engine, storage and notifications.  
The calculation engine must be isolated so billing rules can change without rewriting the app.

**39\. CALCULATION ENGINE**  
Centralize calculations for total meals, expenses, meal rate, member food cost, shared/individual expenses, deposits, due, advance and monthly balance.  
Use the same logic for dashboard, reports, member view, API and exports.

**40\. DATABASE INTEGRITY**  
Use transactions, foreign keys, unique constraints, indexes, soft deletion where appropriate and audit logs.  
Preserve history when financial transactions are edited.

**41\. ADMIN SETTINGS**  
Create settings for mess, meals, expenses, members/permissions, notifications, security and appearance.

**42\. ONBOARDING**  
Guide a new manager through Create Mess → Configure Meal Types → Add Members → Add Initial Deposit → Start First Month.

**43\. EMPTY STATES**  
Every section needs helpful empty states and clear actions such as + Add Meal and + Add Bazar.

**44\. CONFIRMATION**  
Use confirmation dialogs before delete, member removal, month closing/reopening and expense deletion.

**45\. FUTURE-READY FEATURES**  
Keep architecture extensible for PWA, Android app, push notifications, bKash/Nagad integration, WhatsApp sharing, AI insights, OCR receipt scanning, automatic monthly reports, multiple mess management, subscriptions, cloud backup and import/export.

**46\. RECOMMENDED TECH STACK**  
If no existing stack is specified:  
Frontend: Next.js/React + TypeScript + Tailwind CSS + modern component library.  
Backend: Node.js + Express.js or NestJS.  
Database: PostgreSQL.  
ORM: Prisma or equivalent.  
Authentication: JWT/session.  
Storage: S3-compatible.  
Deployment: Docker + Linux + CI/CD.  
If an existing stack exists, preserve it rather than rewriting unnecessarily.

**47\. CODE QUALITY**  
Use type safety, reusable components, modular architecture, meaningful naming, no duplicated logic, validation, error handling, environment variables, no secrets in source code, clean folder structure and API documentation.  
Avoid giant files/components.

**48\. IMPORTANT DEVELOPMENT RULE**  
Do not build only a static frontend mockup.  
Major UI actions must connect to real application logic and database.  
Adding a meal updates the database.  
Adding bazar affects calculations.  
Adding deposits affects balances.  
Changing meals updates reports.  
Changing meal types updates the UI dynamically.  
Removing a member preserves history.

**49\. DEVELOPMENT PHASES**  
Phase 1: project setup, authentication, mess creation, member management, RBAC.  
Phase 2: meal management, custom meal types, daily/monthly calculations.  
Phase 3: bazar, expenses, deposits, transactions.  
Phase 4: dashboard, reports, billing, exports.  
Phase 5: notifications, announcements, audit logs, advanced settings.  
Phase 6: performance, security hardening, testing and deployment.

At every phase, ensure existing functionality continues to work.

**50\. FINAL PRODUCT EXPECTATION**  
The final product should feel like a professional SaaS product specifically designed for Bangladeshi mess management.

It must be:  
Fast  
Simple  
Modern  
Mobile-first  
Dynamic  
Customizable  
Secure  
Scalable  
Easy to maintain

Core principle:  
"A manager should be able to manage an entire mess from their phone in a few minutes every day."

Before implementation, first create:  
**1\. Project architecture**  
**2\. Database schema**  
**3\. Entity relationships**  
**4\. API structure**  
**5\. Authentication/authorization strategy**  
**6\. Calculation engine design**  
**7\. UI page structure**  
**8\. Component structure**

Then implement systematically.

Do not skip backend/database logic just to make the frontend look complete.  
<br/>