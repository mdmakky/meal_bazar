// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'মিল বাজার';

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get save => 'সেভ করুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get confirm => 'নিশ্চিত করুন';

  @override
  String get delete => 'মুছে ফেলুন';

  @override
  String get edit => 'এডিট করুন';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get done => 'হয়ে গেছে';

  @override
  String get next => 'পরের ধাপ';

  @override
  String get back => 'পেছনে';

  @override
  String get loading => 'লোড হচ্ছে';

  @override
  String get navToday => 'আজ';

  @override
  String get navMeals => 'মিল';

  @override
  String get navMoney => 'হিসাব';

  @override
  String get navMore => 'আরও';

  @override
  String get syncSynced => 'সেভ হয়েছে';

  @override
  String get syncSyncing => 'সিঙ্ক হচ্ছে';

  @override
  String get syncOffline => 'অফলাইনে সেভ হয়েছে';

  @override
  String get syncFailed => 'সিঙ্ক হয়নি';

  @override
  String get genericError => 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get networkError =>
      'ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না। নেট চালু করে আবার চেষ্টা করুন।';

  @override
  String get emptyGeneric => 'এখানে এখনো কিছু নেই';

  @override
  String get authPhoneTitle => 'আপনার ফোন নম্বর দিন';

  @override
  String get authPhoneHint => 'এই নম্বরে একটা ৬ সংখ্যার কোড পাঠাব';

  @override
  String get authPhoneLabel => 'ফোন নম্বর';

  @override
  String get authPhoneInvalid => 'সঠিক মোবাইল নম্বর দিন, যেমন ০১৭১২৩৪৫৬৭৮';

  @override
  String get authSendCode => 'কোড পাঠান';

  @override
  String get authCodeTitle => '৬ সংখ্যার কোড দিন';

  @override
  String authCodeSentTo(String phone) {
    return '$phone নম্বরে কোড পাঠানো হয়েছে';
  }

  @override
  String get authCodeLabel => 'কোড';

  @override
  String get authVerify => 'ঢুকে পড়ুন';

  @override
  String get authResend => 'আবার কোড পাঠান';

  @override
  String authResendIn(int seconds) {
    return '$seconds সেকেন্ড পরে আবার কোড পাঠাতে পারবেন';
  }

  @override
  String get authChangeNumber => 'নম্বর বদলান';

  @override
  String get authProfileTitle => 'আপনার নাম কী?';

  @override
  String get authProfileHint => 'মেসের সবাই এই নামে আপনাকে চিনবে';

  @override
  String get authNameLabel => 'আপনার নাম';

  @override
  String get authNameRequired => 'নামটা লিখুন';

  @override
  String get authLanguageLabel => 'অ্যাপের ভাষা';

  @override
  String get authProfileSave => 'চালিয়ে যান';

  @override
  String get shellComingSoon => 'শিগগিরই আসছে, পরের আপডেটে';

  @override
  String get failureNotAuthenticated => 'আবার লগইন করতে হবে';

  @override
  String get failureNotManager => 'এটা শুধু ম্যানেজার করতে পারেন';

  @override
  String get failureInvalidInvite =>
      'এই কোডটা কাজ করছে না। ম্যানেজারের কাছে নতুন কোড চান।';

  @override
  String get failureAlreadyMember => 'আপনি আগে থেকেই এই মেসে আছেন';

  @override
  String get failureLastManager => 'মেসে অন্তত একজন ম্যানেজার থাকতে হবে';

  @override
  String get failureMonthClosed =>
      'এই মাসের হিসাব বন্ধ হয়ে গেছে, আর বদলানো যাবে না';

  @override
  String get failureInvalidOtp => 'কোডটা মেলেনি। আবার দেখে লিখুন।';

  @override
  String get failureRateLimited =>
      'অনেকবার চেষ্টা হয়েছে। একটু পরে আবার চেষ্টা করুন।';

  @override
  String get failureValidation => 'কিছু তথ্য ঠিক নেই। দেখে আবার দিন।';

  @override
  String get configMissingTitle => 'সুপাবেস কনফিগ পাওয়া যায়নি';

  @override
  String get configMissingBody =>
      'অ্যাপ চালানোর সময় --dart-define দিয়ে SUPABASE_URL আর SUPABASE_ANON_KEY দিন।';

  @override
  String get messOnboardingTitle => 'শুরু করতে একটা মেস লাগবে';

  @override
  String get messOnboardingBody =>
      'নিজে ম্যানেজার হলে নতুন মেস খুলুন। মেস আগে থেকে থাকলে ম্যানেজারের কাছ থেকে কোড নিয়ে যোগ দিন।';

  @override
  String get messCreateAction => 'নতুন মেস খুলুন';

  @override
  String get messJoinAction => 'কোড দিয়ে যোগ দিন';

  @override
  String get messCreateTitle => 'নতুন মেস';

  @override
  String get messNameLabel => 'মেসের নাম';

  @override
  String get messNameHint => 'যেমন: মিরপুর ১০ ব্যাচেলর মেস';

  @override
  String get messNameRequired => 'নামটা লিখুন';

  @override
  String get messYourNameLabel => 'মেসে আপনার নাম';

  @override
  String get messYourNameHelp => 'মেসের সবাই আপনাকে এই নামে দেখবে';

  @override
  String get messMonthStartLabel => 'মাস শুরু হয় যে তারিখে';

  @override
  String get messMonthStartHelp =>
      'প্রতি মাসের এই তারিখ থেকে পরের মাসের একই তারিখ পর্যন্ত এক মাসের হিসাব';

  @override
  String messMonthStartDay(String day) {
    return '$day তারিখ';
  }

  @override
  String get messCreateSubmit => 'মেস খুলুন';

  @override
  String get messJoinTitle => 'মেসে যোগ দিন';

  @override
  String get messCodeLabel => 'ইনভাইট কোড';

  @override
  String get messCodeHelp => 'ম্যানেজারের কাছ থেকে ৬ অক্ষরের কোডটা নিন';

  @override
  String get messCodeInvalid => 'কোডটা ৬ অক্ষরের হতে হবে';

  @override
  String get messScanQr => 'QR স্ক্যান করুন';

  @override
  String get messScanTitle => 'QR কোড স্ক্যান করুন';

  @override
  String get messScanHint => 'ম্যানেজারের ফোনের QR কোডটা ফ্রেমের মধ্যে ধরুন';

  @override
  String get messJoinSubmit => 'যোগ দেওয়ার অনুরোধ পাঠান';

  @override
  String get messPendingTitle => 'অনুমোদনের অপেক্ষায়';

  @override
  String messPendingBody(String mess) {
    return '$mess-এর ম্যানেজার আপনার অনুরোধ অনুমোদন করলেই মেসের হিসাব দেখতে পাবেন।';
  }

  @override
  String get messPendingBodyNoName =>
      'ম্যানেজার আপনার অনুরোধ অনুমোদন করলেই মেসের হিসাব দেখতে পাবেন।';

  @override
  String get messPendingRefresh => 'আবার দেখুন';

  @override
  String get messPendingStill => 'এখনো অনুমোদন হয়নি';

  @override
  String get messPendingJoinOther => 'অন্য মেসে যোগ দিন';

  @override
  String get moreTitle => 'আরও';

  @override
  String get moreMembers => 'সদস্যরা';

  @override
  String get moreInvite => 'নতুন সদস্য ডাকুন';

  @override
  String get moreSettings => 'মেসের সেটিংস';

  @override
  String get moreSwitchMess => 'অন্য মেস দেখুন';

  @override
  String get moreRoleManager => 'ম্যানেজার';

  @override
  String get moreRoleMember => 'সদস্য';

  @override
  String get moreSignOut => 'সাইন আউট';

  @override
  String get moreSignOutConfirmTitle => 'সাইন আউট করবেন?';

  @override
  String get moreSignOutConfirmBody =>
      'আবার ঢুকতে ফোন নম্বরে কোড লাগবে। মেসের হিসাব সব থেকে যাবে।';

  @override
  String get membersTitle => 'সদস্যরা';

  @override
  String get membersPending => 'যোগ দিতে চায়';

  @override
  String get membersActive => 'আছেন';

  @override
  String get membersInactive => 'নিষ্ক্রিয়';

  @override
  String get membersLeft => 'চলে গেছেন';

  @override
  String get membersRoleManager => 'ম্যানেজার';

  @override
  String get membersNoApp => 'অ্যাপ নেই';

  @override
  String get membersYou => '(আপনি)';

  @override
  String membersRoom(String room) {
    return 'রুম $room';
  }

  @override
  String membersLeftOn(String date) {
    return '$date থেকে নেই';
  }

  @override
  String get membersEmpty => 'এখনো কোনো সদস্য নেই। কোড দিয়ে সবাইকে ডাকুন।';

  @override
  String get membersApprove => 'অনুমোদন দিন';

  @override
  String membersApproved(String name) {
    return '$name এখন মেসের সদস্য';
  }

  @override
  String get membersReject => 'বাদ দিন';

  @override
  String get membersRejected => 'অনুরোধটা বাদ দেওয়া হয়েছে';

  @override
  String membersRejectConfirmTitle(String name) {
    return '$name-এর অনুরোধ বাদ দেবেন?';
  }

  @override
  String get membersRejectConfirmBody =>
      'চাইলে তিনি পরে আবার কোড দিয়ে অনুরোধ পাঠাতে পারবেন।';

  @override
  String get membersMakeManager => 'ম্যানেজার বানান';

  @override
  String get membersMakeMember => 'সাধারণ সদস্য বানান';

  @override
  String get membersMarkInactive => 'নিষ্ক্রিয় করুন';

  @override
  String get membersInactiveHelp =>
      'মিলের তালিকায় দেখাবে না, টাকার হিসাব আগের মতোই চলবে';

  @override
  String get membersMarkActive => 'আবার সক্রিয় করুন';

  @override
  String get membersMarkLeft => 'মেস ছেড়ে দিয়েছেন';

  @override
  String membersLeftConfirmTitle(String name) {
    return '$name কি মেস ছেড়ে দিয়েছেন?';
  }

  @override
  String get membersLeftConfirmBody =>
      'আজ থেকে তাকে আর নতুন হিসাবে ধরা হবে না। আগের মিল, বাজার আর জমার সব হিসাব যেমন আছে তেমনই থাকবে।';

  @override
  String get membersLeftConfirmAction => 'হ্যাঁ, ছেড়েছেন';

  @override
  String get membersSaved => 'পরিবর্তন সেভ হয়েছে';

  @override
  String get membersAdd => 'সদস্য যোগ করুন';

  @override
  String get membersAddHelp =>
      'যার ফোনে অ্যাপ নেই, তার মিল আর জমা আপনি লিখে দেবেন।';

  @override
  String get membersAddName => 'নাম';

  @override
  String get membersAddRoom => 'রুম (না দিলেও চলবে)';

  @override
  String get membersAddSubmit => 'যোগ করুন';

  @override
  String membersAdded(String name) {
    return '$name যোগ হয়েছেন';
  }

  @override
  String get inviteTitle => 'নতুন সদস্য ডাকুন';

  @override
  String get inviteBody =>
      'এই কোডটা দিন, অথবা QR স্ক্যান করতে বলুন। অনুরোধ এলে আপনি অনুমোদন দিলেই সে মেসে ঢুকবে।';

  @override
  String get inviteValidity => '৭ দিন পর্যন্ত বৈধ';

  @override
  String get inviteQrLabel => 'মেসে যোগ দেওয়ার QR কোড';

  @override
  String get inviteCopy => 'কোড কপি করুন';

  @override
  String get inviteCopied => 'কোড কপি হয়েছে';

  @override
  String get inviteShare => 'শেয়ার করুন';

  @override
  String inviteShareMessage(String mess, String code, String link) {
    return 'মিল বাজার অ্যাপে আমাদের মেস \"$mess\"-এ যোগ দাও।\nকোড: $code\nলিংক: $link';
  }

  @override
  String get inviteRegenerate => 'নতুন কোড';

  @override
  String get inviteManagerOnly => 'শুধু ম্যানেজার নতুন সদস্য ডাকতে পারেন';

  @override
  String get settingsTitle => 'মেসের সেটিংস';

  @override
  String get settingsAddress => 'ঠিকানা (না দিলেও চলবে)';

  @override
  String get settingsCutoff => 'মিল বন্ধের শেষ সময়';

  @override
  String get settingsCutoffHelp =>
      'সদস্যরা আগের দিন এই সময়ের মধ্যে মিল বন্ধ করতে পারবেন';

  @override
  String get settingsSave => 'সেটিংস সেভ করুন';

  @override
  String get settingsSaved => 'সেটিংস সেভ হয়েছে';

  @override
  String get settingsManagerOnly => 'শুধু ম্যানেজার সেটিংস বদলাতে পারেন';

  @override
  String get mealCellOff => 'অফ';

  @override
  String mealCellGuests(String count) {
    return '$count জন অতিথি';
  }

  @override
  String get mealCellOwn => 'নিজের মিল';

  @override
  String get mealCellGuestsLabel => 'অতিথি';

  @override
  String get mealCellSave => 'মিল সেভ করুন';

  @override
  String get mealCellDecrease => 'কমান';

  @override
  String get mealCellIncrease => 'বাড়ান';

  @override
  String get todayPrevDay => 'আগের দিন';

  @override
  String get todayNextDay => 'পরের দিন';

  @override
  String get todayBackToToday => 'আজকে ফিরুন';

  @override
  String get todayIsToday => 'আজ';

  @override
  String get todayHeadcountLabel => 'আজ মোট মিল';

  @override
  String get todayDayHeadcountLabel => 'এই দিনের মোট মিল';

  @override
  String todayGuestsProof(String count) {
    return 'অতিথি $count';
  }

  @override
  String get todayRateLabel => 'এই মাসের মিল রেট';

  @override
  String todayRateProof(String food, String meals) {
    return '$food ÷ $meals মিল';
  }

  @override
  String todayRateUnallocated(String food) {
    return '$food খরচ হয়েছে, কিন্তু এখনো কোনো মিল নেই। মিল বসালে রেট আসবে।';
  }

  @override
  String get todayNoEntries => 'এই দিনের মিল এখনো বসানো হয়নি';

  @override
  String get todayNoEntriesMember => 'ম্যানেজার এখনো এই দিনের মিল বসাননি';

  @override
  String get todayFillHelp =>
      'সব সদস্যের মিল গতকালের মতো বসবে, না থাকলে ১টা করে। পরে ট্যাপ করে বদলাবেন।';

  @override
  String get todayFill => 'আজকের মিল বসান';

  @override
  String get todayFillDay => 'এই দিনের মিল বসান';

  @override
  String get todayNoMembers => 'মেসে এখনো কোনো সদস্য নেই';

  @override
  String get todayNoMealTypes => 'কোনো বেলার মিল চালু নেই';

  @override
  String get todayNoMealTypesAction => 'মিলের ধরন ঠিক করুন';

  @override
  String get todayMemberColumn => 'সদস্য';

  @override
  String get todayActionBazar => 'বাজার';

  @override
  String get todayActionExpense => 'খরচ';

  @override
  String get todayActionDeposit => 'জমা';

  @override
  String get todayActionGuest => 'অতিথি';

  @override
  String get todayActionMealOff => 'মিল অফ';

  @override
  String get todayPickMember => 'কার জন্য?';

  @override
  String get todayPickMealType => 'কোন বেলার মিল?';

  @override
  String todayMealOffDone(String name, String meal) {
    return '$name-এর $meal অফ করা হলো';
  }

  @override
  String get mealsTitle => 'মিল';

  @override
  String get mealsTotalLabel => 'এই মাসের মোট মিল';

  @override
  String mealsPeriod(String from, String to) {
    return '$from থেকে $to';
  }

  @override
  String get mealsByMember => 'সদস্যদের মিল';

  @override
  String mealsGuestNote(String count) {
    return 'অতিথির $count মিল সহ';
  }

  @override
  String get mealsEmpty => 'এই মাসে এখনো কোনো মিল নেই';

  @override
  String mealsMemberEmpty(String name) {
    return 'এই মাসে $name-এর কোনো মিল নেই';
  }

  @override
  String mealsMemberTotal(String count) {
    return 'এই মাসে মোট $count মিল';
  }

  @override
  String get mealTypesTitle => 'মিলের ধরন';

  @override
  String get mealTypesHelp =>
      'ওজন মানে এক বেলায় কত মিল ধরা হবে। যেমন সকালের নাশতা ×০.৫।';

  @override
  String get mealTypesAdd => 'নতুন বেলা যোগ করুন';

  @override
  String get mealTypesName => 'নাম';

  @override
  String get mealTypesNameHint => 'যেমন: বিকেলের নাশতা';

  @override
  String get mealTypesNameInvalid => '১ থেকে ৩০ অক্ষরের মধ্যে নাম দিন';

  @override
  String get mealTypesRename => 'নাম বদলান';

  @override
  String get mealTypesWeight => 'ওজন';

  @override
  String mealTypesEnabled(String name) {
    return '$name চালু';
  }

  @override
  String get mealTypesEmpty => 'এখনো কোনো মিলের ধরন নেই';

  @override
  String get mealTypesManagerOnly => 'শুধু ম্যানেজার মিলের ধরন বদলাতে পারেন';

  @override
  String get moneyFoodTotal => 'খাবার খরচ';

  @override
  String get moneyFoodProof => 'বাজার আর মিলে ভাগ হওয়া খরচ মিলিয়ে';

  @override
  String get moneyMealRate => 'মিল রেট';

  @override
  String moneyMealRateProof(String food, String meals) {
    return '$food ÷ $meals মিল';
  }

  @override
  String get moneyExtraTotal => 'অন্যান্য খরচ';

  @override
  String get moneyExtraProof => 'সবার মধ্যে সমান ভাগে';

  @override
  String get moneyDepositTotal => 'মোট জমা';

  @override
  String get moneyDepositProof => 'যাচাই হওয়া জমা মিলিয়ে';

  @override
  String get moneyNoMealsWarning =>
      'খরচ আছে কিন্তু এখনো কোনো মিল নেই, তাই কারো ভাগে ধরা হয়নি';

  @override
  String get moneyTabMembers => 'সদস্য';

  @override
  String get moneyTabBazar => 'বাজার';

  @override
  String get moneyTabExpense => 'খরচ';

  @override
  String get moneyTabDeposit => 'জমা';

  @override
  String get moneyAmount => 'টাকার পরিমাণ';

  @override
  String get moneyAmountInvalid =>
      'সঠিক টাকার পরিমাণ লিখুন, যেমন ২৫০ বা ২৫০.৫০';

  @override
  String get moneyChangeDate => 'তারিখ বদলান';

  @override
  String get moneyPaidFrom => 'টাকা গেছে';

  @override
  String get moneyPaidFund => 'মেস ফান্ড';

  @override
  String get moneyPaidPocket => 'নিজের পকেট';

  @override
  String get moneyPaidPocketHelp => 'যে দিয়েছে তার জমায় যোগ হবে';

  @override
  String get moneyPickMember => 'একজন সদস্য বেছে নিন';

  @override
  String get moneyNote => 'নোট (না দিলেও চলবে)';

  @override
  String get moneySave => 'সেভ করুন';

  @override
  String get moneySaved => 'সেভ হয়েছে';

  @override
  String get moneyDeleted => 'মুছে ফেলা হয়েছে';

  @override
  String get moneyDeleteConfirmTitle => 'এটা মুছে ফেলবেন?';

  @override
  String get moneyDeleteConfirmBody =>
      'মুছে ফেললে এই মাসের হিসাব থেকে বাদ যাবে।';

  @override
  String get moneyLoadMore => 'আরও দেখুন';

  @override
  String get moneyNoMess => 'আগে একটা মেসে যোগ দিন';

  @override
  String get bazarAdd => 'বাজার যোগ করুন';

  @override
  String get bazarEdit => 'বাজার এডিট করুন';

  @override
  String get bazarTitle => 'বাজার';

  @override
  String get bazarBuyer => 'কে বাজার করেছে';

  @override
  String get bazarItems => 'আইটেম (না দিলেও চলবে)';

  @override
  String get bazarAddItem => 'আইটেম যোগ করুন';

  @override
  String get bazarRemoveItem => 'আইটেম বাদ দিন';

  @override
  String get bazarItemName => 'নাম';

  @override
  String get bazarItemQty => 'পরিমাণ';

  @override
  String get bazarItemUnit => 'একক';

  @override
  String get bazarItemPrice => 'দাম';

  @override
  String get bazarItemInvalid => 'নাম আর দাম দুটোই লিখুন';

  @override
  String bazarItemsSum(String sum) {
    return 'আইটেমের যোগফল $sum';
  }

  @override
  String get bazarUseSum => 'এটাই বসান';

  @override
  String bazarItemCount(String count) {
    return '$countটি আইটেম';
  }

  @override
  String get bazarEmpty => 'এই মাসে এখনো কোনো বাজার নেই';

  @override
  String get bazarShare => 'শেয়ার করুন';

  @override
  String bazarShareHeader(String date) {
    return 'বাজারের হিসাব · $date';
  }

  @override
  String bazarShareBuyer(String name) {
    return 'বাজার করেছে: $name';
  }

  @override
  String bazarShareTotal(String total) {
    return 'মোট: $total';
  }

  @override
  String get expenseAdd => 'খরচ যোগ করুন';

  @override
  String get expenseEdit => 'খরচ এডিট করুন';

  @override
  String get expenseCategory => 'কিসের খরচ';

  @override
  String get expensePickCategory => 'কিসের খরচ সেটা বেছে নিন';

  @override
  String get expenseSplit => 'কীভাবে ভাগ হবে';

  @override
  String get expenseSplitMeal => 'মিল';

  @override
  String get expenseSplitEqual => 'সমান';

  @override
  String get expenseSplitMealHelp =>
      'মিল রেটে যোগ হবে, যে যত মিল খেয়েছে সে তত দেবে';

  @override
  String get expenseSplitEqualHelp => 'সেদিন মেসে থাকা সবার মধ্যে সমান ভাগ হবে';

  @override
  String get expenseEmpty => 'এই মাসে এখনো কোনো খরচ নেই';

  @override
  String get depositAdd => 'জমা যোগ করুন';

  @override
  String get depositEdit => 'জমা এডিট করুন';

  @override
  String get depositMember => 'কে জমা দিয়েছে';

  @override
  String get depositMethod => 'কীভাবে দিয়েছে';

  @override
  String get depositCash => 'ক্যাশ';

  @override
  String get depositBkash => 'বিকাশ';

  @override
  String get depositNagad => 'নগদ';

  @override
  String get depositBank => 'ব্যাংক';

  @override
  String get depositOther => 'অন্যভাবে';

  @override
  String get depositTrxId => 'TrxID (না দিলেও চলবে)';

  @override
  String get depositAmountPositive => 'জমা ০ টাকার বেশি হতে হবে';

  @override
  String get depositPending => 'যাচাই বাকি';

  @override
  String get depositRejected => 'বাতিল';

  @override
  String get depositEmpty => 'এই মাসে এখনো কোনো জমা নেই';

  @override
  String get balanceDue => 'বাকি';

  @override
  String get balanceAdvance => 'অগ্রিম';

  @override
  String get balanceSettled => 'মিটে গেছে';

  @override
  String balanceMeals(String meals) {
    return '$meals মিল';
  }

  @override
  String get balanceEmpty => 'এই মাসে এখনো কারো হিসাব নেই';

  @override
  String balanceExplainTitle(String name) {
    return '$name-এর হিসাব';
  }

  @override
  String get balanceOpening => 'আগের মাস থেকে';

  @override
  String get balanceCredit => 'জমা আর নিজের পকেট থেকে খরচ';

  @override
  String balanceFood(String meals, String rate) {
    return 'খাবার খরচ ($meals মিল × $rate)';
  }

  @override
  String get balanceExtra => 'অন্যান্য খরচের ভাগ';

  @override
  String get balanceClosing => 'এখনকার হিসাব';

  @override
  String get monthTitle => 'মাসের হিসাব';

  @override
  String get monthClose => 'মাস বন্ধ করুন';

  @override
  String get monthCloseBody =>
      'বন্ধ করলে এই মাসের মিল, বাজার, খরচ আর জমা আর বদলানো যাবে না। সবার শেষ হিসাব পরের মাসে চলে যাবে।';

  @override
  String get monthThis => 'এই মাস';

  @override
  String get monthPrevious => 'আগের মাস';

  @override
  String monthRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get monthTotalMeals => 'মোট মিল';

  @override
  String get monthClosedDone => 'মাস বন্ধ হয়েছে';

  @override
  String get monthStatusOpen => 'খোলা';

  @override
  String get monthStatusClosed => 'বন্ধ';

  @override
  String get monthReopen => 'আবার খুলুন';

  @override
  String get monthReopenTitle => 'মাসটা আবার খুলবেন?';

  @override
  String get monthReopenReason => 'কেন খুলছেন';

  @override
  String get monthReopenReasonHelp =>
      'অন্তত ৫ অক্ষর। মেসের সবাই এটা দেখতে পাবে।';

  @override
  String get monthReopenReasonShort => 'কারণটা অন্তত ৫ অক্ষরে লিখুন';

  @override
  String get monthReopened => 'মাস আবার খোলা হয়েছে';

  @override
  String get monthNoneClosed => 'এখনো কোনো মাস বন্ধ হয়নি';

  @override
  String get monthHistory => 'আগের মাসগুলো';

  @override
  String get monthManagerOnly => 'শুধু ম্যানেজার মাস বন্ধ বা খুলতে পারেন';

  @override
  String get monthPreviousOpen => 'আগের মাসটা আগে বন্ধ করুন';

  @override
  String get monthLaterClosed => 'পরের মাসটা আগে খুলুন';

  @override
  String get aiDraftLabel => 'AI খসড়া';

  @override
  String get aiMealTitle => 'এআই দিয়ে মিল লিখুন';

  @override
  String get aiMealHint => 'আজ রহিম ২, করিম অফ, রাতে গেস্ট ১';

  @override
  String get aiSend => 'পাঠান';

  @override
  String get aiUnavailableDisabled => 'এআই বন্ধ আছে';

  @override
  String get aiUnavailableQuota => 'আজকের এআই সীমা শেষ, হাতে লিখে দিন';

  @override
  String get aiUnavailableProviders => 'এআই এখন পাওয়া যাচ্ছে না';

  @override
  String get aiEdit => 'বদলান';

  @override
  String get aiRemove => 'বাদ দিন';

  @override
  String get aiUnmatchedNote => 'এগুলো বোঝা যায়নি, হাতে লিখে দিন';

  @override
  String get aiReject => 'বাতিল করুন';

  @override
  String get aiConfirmAll => 'সব নিশ্চিত করুন';

  @override
  String get aiNoMeals => 'কোনো মিল পাওয়া যায়নি';

  @override
  String aiMealsSaved(String count) {
    return '$countটি মিল সেভ হয়েছে';
  }

  @override
  String get aiScanTitle => 'বাজারের রসিদ স্ক্যান';

  @override
  String get aiCamera => 'ছবি তুলুন';

  @override
  String get aiGallery => 'গ্যালারি থেকে নিন';

  @override
  String get aiNotJpeg => 'এই ছবিটি পড়া যাচ্ছে না, ক্যামেরা দিয়ে ছবি তুলুন';

  @override
  String get aiItemName => 'জিনিস';

  @override
  String get aiItemPrice => 'দাম';

  @override
  String get aiNoItems => 'রসিদ থেকে কোনো জিনিস পড়া যায়নি';

  @override
  String get aiTotalMismatch =>
      'রসিদের মোট আর জিনিসের যোগফল মিলছে না। কোনটা নেবেন?';

  @override
  String aiReceiptTotal(String amount) {
    return 'রসিদের মোট $amount';
  }

  @override
  String aiItemsSum(String amount) {
    return 'জিনিসের যোগফল $amount';
  }

  @override
  String get aiUseDraft => 'বাজারে বসান';

  @override
  String get reportTitle => 'মাসিক রিপোর্ট';

  @override
  String get reportFoodTotal => 'খাবারের মোট খরচ';

  @override
  String get reportTotalMeals => 'মোট মিল';

  @override
  String get reportMealRate => 'মিল রেট';

  @override
  String get reportExtraTotal => 'অন্যান্য খরচ';

  @override
  String get reportDeposits => 'মোট জমা';

  @override
  String get reportName => 'নাম';

  @override
  String get reportMeals => 'মিল';

  @override
  String get reportFoodCost => 'খাবার খরচ';

  @override
  String get reportExtra => 'অন্যান্য';

  @override
  String get reportPaid => 'জমা';

  @override
  String get reportBalance => 'ব্যালেন্স';

  @override
  String get reportDue => 'বাকি';

  @override
  String get reportAdvance => 'অগ্রিম';

  @override
  String get reportFormula => 'মিল রেট = খাবারের মোট খরচ ÷ মোট মিল';

  @override
  String reportFooter(String date) {
    return 'Meal Bazar · তৈরি $date';
  }

  @override
  String get reportNoMembers => 'এই মাসে কোনো সদস্য নেই';

  @override
  String get reportShare => 'রিপোর্ট শেয়ার করুন';

  @override
  String get reportPrint => 'রিপোর্ট প্রিন্ট করুন';

  @override
  String get accountTitle => 'অ্যাকাউন্ট';

  @override
  String get accountName => 'আপনার নাম';

  @override
  String get accountNameSave => 'নাম সেভ করুন';

  @override
  String get accountNameSaved => 'নাম সেভ হয়েছে';

  @override
  String get accountLanguage => 'ভাষা';

  @override
  String get accountLangBn => 'বাংলা';

  @override
  String get accountLangEn => 'English';

  @override
  String get accountDelete => 'অ্যাকাউন্ট মুছে ফেলুন';

  @override
  String get accountDeleteTitle => 'অ্যাকাউন্ট মুছবেন?';

  @override
  String get accountDeleteRemoved =>
      'যা মুছে যাবে: আপনার নাম, ফোন নম্বর ও ছবি। আপনি আর কোনো মেসে ঢুকতে পারবেন না।';

  @override
  String get accountDeleteKept =>
      'যা থাকবে: মেসের মিল, বাজার, জমা ও খরচের হিসাব আপনার মেসের নামেই থেকে যাবে, যাতে মেসের হিসাব না বদলায়।';

  @override
  String get accountDeleteManager =>
      'আপনি একমাত্র ম্যানেজার হলে আগে অন্য কাউকে ম্যানেজার করুন।';

  @override
  String get accountDeleteWord => 'মুছুন';

  @override
  String accountDeleteTypeHint(String word) {
    return 'নিশ্চিত করতে লিখুন: $word';
  }

  @override
  String get accountDeleteConfirm => 'চিরতরে মুছুন';

  @override
  String get auditTitle => 'কার্যক্রম';

  @override
  String get auditFilterAll => 'সব';

  @override
  String get auditFilterMeals => 'মিল';

  @override
  String get auditFilterMoney => 'টাকা';

  @override
  String get auditFilterMembers => 'সদস্য';

  @override
  String get auditEmpty => 'এখনো কোনো কার্যক্রম নেই';

  @override
  String get auditAi => 'এআই';

  @override
  String get auditLoadMore => 'আরও দেখুন';

  @override
  String auditReason(String reason) {
    return 'কারণ: $reason';
  }

  @override
  String get auditSomeone => 'কেউ';

  @override
  String get auditSystem => 'সিস্টেম';

  @override
  String auditSentence(String actor, String thing, String verb) {
    return '$actor $thing $verb';
  }

  @override
  String get auditAdded => 'যোগ করেছেন';

  @override
  String get auditChanged => 'বদলেছেন';

  @override
  String get auditDeleted => 'মুছেছেন';

  @override
  String get auditBazar => 'বাজার';

  @override
  String get auditExpense => 'খরচ';

  @override
  String auditDepositOf(String name) {
    return '$name-এর জমা';
  }

  @override
  String auditMealOf(String name) {
    return '$name-এর মিল';
  }

  @override
  String auditMealType(String name) {
    return 'মিলের ধরন $name';
  }

  @override
  String auditMember(String name) {
    return 'সদস্য $name';
  }

  @override
  String get auditMessSettings => 'মেসের সেটিংস';

  @override
  String auditMonthClosed(String actor) {
    return '$actor মাস বন্ধ করেছেন';
  }

  @override
  String auditMonthReopened(String actor) {
    return '$actor মাস আবার খুলেছেন';
  }

  @override
  String auditAccountDeleted(String name) {
    return '$name অ্যাকাউন্ট মুছে ফেলেছেন';
  }

  @override
  String get todayAiEntry => 'লিখে বলুন: ‘আজ রহিম ২, করিম অফ’';

  @override
  String get bazarScan => 'রসিদ/ফর্দ স্ক্যান';

  @override
  String get mealOffCutoffPassed => 'সময় শেষ — ম্যানেজারকে বলুন';

  @override
  String mealOffHint(String time) {
    return 'কালকের মিল বন্ধ করতে আজ রাত $timeটার আগে';
  }

  @override
  String get mealOffTomorrow => 'কাল মিল বন্ধ';

  @override
  String get mealOffTomorrowTitle => 'কাল কোন মিল বন্ধ থাকবে?';

  @override
  String get mealOffSave => 'ঠিক আছে';

  @override
  String get mealOffSaved => 'কালকের মিল আপডেট হলো';

  @override
  String get receiptAttach => 'রসিদের ছবি';

  @override
  String get receiptScreenshot => 'পেমেন্টের স্ক্রিনশট (না দিলেও চলবে)';

  @override
  String get receiptRemove => 'ছবি সরান';

  @override
  String get receiptView => 'রসিদ দেখুন';

  @override
  String get depositVerifyMine => 'আমার জমা দিন';

  @override
  String get depositVerifyHelp =>
      'ম্যানেজার যাচাই না করা পর্যন্ত এই জমা হিসাবে ধরা হবে না।';

  @override
  String get depositVerifySent => 'জমা পাঠানো হয়েছে, ম্যানেজার যাচাই করবেন';

  @override
  String get depositVerifyApprove => 'যাচাই করুন';

  @override
  String get depositVerifyReject => 'বাতিল করুন';

  @override
  String get depositVerifyApproveTitle => 'জমা যাচাই করবেন?';

  @override
  String depositVerifyApproveBody(String name, String amount) {
    return '$name-এর $amount জমা হিসাবে যোগ হবে।';
  }

  @override
  String get depositVerifyRejectTitle => 'জমা বাতিল করবেন?';

  @override
  String depositVerifyRejectBody(String name, String amount) {
    return '$name-এর $amount জমা হিসাবে ধরা হবে না।';
  }

  @override
  String get depositVerifyDone => 'জমা যাচাই হয়েছে';

  @override
  String get depositVerifyRejected => 'জমা বাতিল হয়েছে';
}
