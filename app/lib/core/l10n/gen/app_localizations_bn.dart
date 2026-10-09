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
  String get navHome => 'হোম';

  @override
  String get navMeals => 'মিল';

  @override
  String get navMoney => 'হিসাব';

  @override
  String get navMore => 'আরও';

  @override
  String get syncSyncing => 'সিঙ্ক হচ্ছে';

  @override
  String get syncOffline => 'অফলাইনে সেভ হয়েছে';

  @override
  String get syncFailed => 'সিঙ্ক হয়নি';

  @override
  String get syncDiscard => 'বাদ দিন';

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
  String get failureInvalidCredentials => 'ইমেইল বা পাসওয়ার্ড মেলেনি';

  @override
  String get failureEmailTaken => 'এই ইমেইলে আগেই অ্যাকাউন্ট আছে। লগইন করুন।';

  @override
  String get failureWeakPassword => 'পাসওয়ার্ডটা আরও শক্ত করুন';

  @override
  String get failureEmailNotConfirmed =>
      'আগে ইমেইলে পাঠানো লিংকে ক্লিক করে অ্যাকাউন্ট নিশ্চিত করুন';

  @override
  String get signInTitle => 'মিল বাজারে ঢুকুন';

  @override
  String get signInHint => 'মেসের পুরো হিসাব, ফোন থেকেই';

  @override
  String get signInGoogle => 'Google দিয়ে চালিয়ে যান';

  @override
  String get signInOrEmail => 'অথবা ইমেইল দিয়ে';

  @override
  String get signInModeLogin => 'লগইন';

  @override
  String get signInModeSignUp => 'নতুন অ্যাকাউন্ট';

  @override
  String get signInEmailLabel => 'ইমেইল';

  @override
  String get signInPasswordLabel => 'পাসওয়ার্ড';

  @override
  String get signInEmailInvalid => 'সঠিক ইমেইল দিন';

  @override
  String get signInPasswordShort => 'পাসওয়ার্ড অন্তত ৮ অক্ষরের দিন';

  @override
  String get signInSubmitLogin => 'লগইন করুন';

  @override
  String get signInSubmitSignUp => 'অ্যাকাউন্ট খুলুন';

  @override
  String get signInForgot => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get signInResetSent => 'পাসওয়ার্ড বদলানোর লিংক ইমেইলে পাঠানো হয়েছে';

  @override
  String get signInConfirmTitle => 'ইমেইলে পাঠানো লিংকে ক্লিক করুন';

  @override
  String signInConfirmBody(String email) {
    return '$email ঠিকানায় একটা লিংক পাঠিয়েছি। লিংকে ক্লিক করে এখানে ফিরে লগইন করুন।';
  }

  @override
  String get signInBackToLogin => 'লগইনে ফিরে যান';

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
  String moreSignOutUnsent(String count) {
    return 'অফলাইনে সেভ করা $count টি এন্ট্রি এখনো পাঠানো হয়নি — সাইন আউট করলে মুছে যাবে';
  }

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
      'সব সদস্যের মিল গতকালের মতো বসবে, না থাকলে তাদের ডিফল্ট মিল (তাও না থাকলে ১টা)। পরে ট্যাপ করে বদলাবেন।';

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
      'মিল রেটে যোগ হবে, যে যত মিল খেয়েছে সে তত দেবে। যেমন: গ্যাস, রান্নার খরচ';

  @override
  String get expenseSplitEqualHelp =>
      'সেদিন মেসে থাকা সবার মধ্যে সমান ভাগ হবে। যেমন: ওয়াইফাই, বাসা ভাড়া';

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
  String lastMonthNewMonth(String month) {
    return '$month মাস শুরু হয়েছে';
  }

  @override
  String get lastMonthFinalTitle => 'গত মাসের চূড়ান্ত হিসাব';

  @override
  String get lastMonthMeals => 'আমার মিল';

  @override
  String get lastMonthCost => 'আমার খরচ';

  @override
  String lastMonthCostProof(String food, String extra) {
    return 'খাবার $food + অন্যান্য $extra';
  }

  @override
  String get lastMonthPaid => 'আমি দিয়েছি';

  @override
  String get lastMonthOpening => 'আগের মাসের জের';

  @override
  String get lastMonthFinalBalance => 'চূড়ান্ত ব্যালেন্স';

  @override
  String get lastMonthAdvance => 'জমা আছে';

  @override
  String get lastMonthDue => 'বাকি';

  @override
  String get lastMonthSettled => 'হিসাব মিটে গেছে';

  @override
  String get lastMonthCarried => 'এই ব্যালেন্স নতুন মাসে যোগ হয়েছে';

  @override
  String get lastMonthReport => 'মাসের PDF';

  @override
  String get lastMonthPay => 'জমা দিন';

  @override
  String get lastMonthHide => 'লুকান';

  @override
  String get lastMonthNotFinal =>
      'গত মাসের হিসাব এখনো চূড়ান্ত হয়নি — ম্যানেজার মাস বন্ধ করলে চূড়ান্ত ব্যালেন্স দেখা যাবে';

  @override
  String get closeMonthCtaTitle => 'গত মাস বন্ধ করুন';

  @override
  String closeMonthCtaBody(String month) {
    return '$month-এর হিসাব চূড়ান্ত করুন। বন্ধ করলে সবার ব্যালেন্স নতুন মাসে যাবে।';
  }

  @override
  String get closeMonthPendingTitle => 'বন্ধ করার আগে এগুলো মিটিয়ে নিন';

  @override
  String closeMonthPendingDeposits(String count) {
    return '$countটি জমা যাচাই বাকি';
  }

  @override
  String closeMonthPendingBazar(String count) {
    return '$countটি বাজার অনুরোধ বাকি';
  }

  @override
  String get closeMonthWhatHappens => 'বন্ধ করলে যা হবে';

  @override
  String get closeMonthFinal => 'সবার ব্যালেন্স চূড়ান্ত হবে';

  @override
  String get closeMonthLocked => 'এই মাসে আর কিছু যোগ বা বদলানো যাবে না';

  @override
  String get closeMonthCarry => 'প্রত্যেকের ব্যালেন্স নতুন মাসে যোগ হবে';

  @override
  String get closeMonthNotify => 'সব সদস্য নোটিফিকেশন পাবেন';

  @override
  String get closeMonthPendingItems =>
      'এই মাসে যাচাই বাকি জমা বা বাজার অনুরোধ আছে। আগে হিসাব ট্যাবে জমা আর বাজার ট্যাবে অনুরোধগুলো অনুমোদন বা বাতিল করুন, তারপর মাস বন্ধ করুন।';

  @override
  String get closeMonthDayLocked => 'এই মাস বন্ধ — শুধু দেখা যাবে';

  @override
  String get activityMoreTile => 'আমার কার্যকলাপ';

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
  String get reportFoodCost => 'মিল খরচ';

  @override
  String get reportExtra => 'অন্যান্য';

  @override
  String get reportPaid => 'জমা + পকেট';

  @override
  String get reportBalance => 'ব্যালেন্স';

  @override
  String get reportFormula => 'মিল রেট = খাবারের মোট খরচ ÷ মোট মিল';

  @override
  String get reportNoMembers => 'এই মাসে কোনো সদস্য নেই';

  @override
  String get reportShare => 'রিপোর্ট শেয়ার করুন';

  @override
  String get reportPrint => 'রিপোর্ট প্রিন্ট করুন';

  @override
  String reportFooter(String date) {
    return 'মিল বাজার দিয়ে তৈরি · $date';
  }

  @override
  String get reportPage => 'পৃষ্ঠা';

  @override
  String reportManager(String name) {
    return 'ম্যানেজার: $name';
  }

  @override
  String get reportSectionMeals => 'মিল';

  @override
  String get reportSectionDaily => 'দৈনিক মিল (সদস্যভিত্তিক)';

  @override
  String get reportSectionBazar => 'বাজার';

  @override
  String get reportSectionMoney => 'খরচ, জমা ও সারসংক্ষেপ';

  @override
  String get reportMatrix => 'মিল ম্যাট্রিক্স';

  @override
  String get reportMatrixHint =>
      'সারি = সদস্য, কলাম = তারিখ; রং যত গাঢ় তত বেশি মিল';

  @override
  String get reportMember => 'সদস্য';

  @override
  String get reportTotal => 'মোট';

  @override
  String get reportDayTotal => 'দিনের মোট';

  @override
  String get reportOffShort => 'অ';

  @override
  String get reportOffLegend => 'অ = অফ';

  @override
  String get reportAbsentLegend => '· = তখন মেসে ছিল না';

  @override
  String get reportTypeBreakdown => 'সদস্যভিত্তিক মিলের ধরন';

  @override
  String get reportGuests => 'গেস্ট';

  @override
  String get reportOffDays => 'অফ দিন';

  @override
  String get reportBazarTrips => 'বাজারে গেছে';

  @override
  String reportTimes(String count) {
    return '$count বার';
  }

  @override
  String get reportWeightedMeals => 'ওজনসহ মিল';

  @override
  String get reportDaily => 'কে কবে কয়টা মিল খেয়েছে';

  @override
  String reportDailyHint(String types) {
    return 'প্রতি সদস্যের $types, দিন ধরে · ½ = হাফ মিল · +১ = গেস্ট · অ = অফ';
  }

  @override
  String reportMealsCount(String meals) {
    return '$meals মিল';
  }

  @override
  String get reportHalfMeal => 'হাফ মিল';

  @override
  String get reportDoubleMeal => 'ডাবল মিল';

  @override
  String get reportOff => 'অফ';

  @override
  String get reportCountNote =>
      'মোট কলামে ওজন ছাড়া গোনা; ওজনসহ মিল নামের নিচে';

  @override
  String get reportTimeline => 'বাজার টাইমলাইন';

  @override
  String get reportMessFund => 'মেস ফান্ড';

  @override
  String reportOwnPocket(String name) {
    return '$name-এর পকেট';
  }

  @override
  String get reportDate => 'তারিখ';

  @override
  String get reportCategory => 'খাত';

  @override
  String get reportSplit => 'ভাগ';

  @override
  String get reportAmount => 'টাকা';

  @override
  String reportEveryone(String count) {
    return 'সবাই ($count জন)';
  }

  @override
  String get reportExpenseTotal => 'মোট অন্যান্য খরচ';

  @override
  String get reportDepositsTitle => 'জমা';

  @override
  String get reportMethod => 'মাধ্যম';

  @override
  String get reportVerifiedTotal => 'মোট জমা (যাচাই করা)';

  @override
  String get reportSummary => 'সারসংক্ষেপ';

  @override
  String get reportOpening => 'আগের';

  @override
  String get reportNone => 'কিছু নেই';

  @override
  String get reportWeekdays =>
      'রবিবার,সোমবার,মঙ্গলবার,বুধবার,বৃহস্পতিবার,শুক্রবার,শনিবার';

  @override
  String get reportWeekdaysShort => 'র,সো,ম,বু,বৃ,শু,শ';

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
  String auditDutyOf(String name) {
    return '$name-এর বাজার ডিউটি';
  }

  @override
  String auditNotice(String title) {
    return 'নোটিশ $title';
  }

  @override
  String get auditRecurring => 'মাসিক বিল';

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

  @override
  String get resetTitle => 'নতুন পাসওয়ার্ড দিন';

  @override
  String get resetHint => 'এই অ্যাকাউন্টের জন্য একটা নতুন পাসওয়ার্ড ঠিক করুন';

  @override
  String get resetNewPasswordLabel => 'নতুন পাসওয়ার্ড';

  @override
  String get resetConfirmLabel => 'আবার নতুন পাসওয়ার্ড';

  @override
  String get resetMismatch => 'দুটো পাসওয়ার্ড মিলছে না';

  @override
  String get resetSave => 'পাসওয়ার্ড সেভ করুন';

  @override
  String get resetDone => 'পাসওয়ার্ড বদলানো হয়েছে';

  @override
  String get dashTitle => 'এই মাস';

  @override
  String get dashMembers => 'সদস্য';

  @override
  String get dashMembersProof => 'সক্রিয় সদস্য';

  @override
  String dashMembersPending(String count) {
    return '$count জন অনুমোদনের অপেক্ষায়';
  }

  @override
  String get dashBazar => 'মোট বাজার';

  @override
  String dashBazarProof(String food) {
    return 'মিলে ভাগের খরচসহ খাবার খরচ $food';
  }

  @override
  String get dashExtra => 'অন্যান্য খরচ';

  @override
  String dashExtraProof(String total) {
    return 'সমান ভাগে · মাসের মোট খরচ $total';
  }

  @override
  String get dashDeposits => 'মোট জমা';

  @override
  String get dashDues => 'মোট বাকি';

  @override
  String dashDuesProof(String count) {
    return '$count জনের বাকি';
  }

  @override
  String get dashAdvances => 'মোট অগ্রিম';

  @override
  String dashAdvancesProof(String count) {
    return '$count জনের অগ্রিম';
  }

  @override
  String get dashMeals => 'মোট মিল';

  @override
  String dashPeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get dashRate => 'মিল রেট';

  @override
  String get dashWhoOwes => 'কার কত বাকি';

  @override
  String get dashMine => 'আমার হিসাব';

  @override
  String get dashMyMeals => 'আমার মিল';

  @override
  String get dashMyFood => 'খাবার খরচ';

  @override
  String dashMyFoodProof(String meals, String rate) {
    return '$meals মিল × $rate';
  }

  @override
  String get dashMyPaid => 'জমা দিয়েছি';

  @override
  String get dashExplain => 'হিসাবটা বুঝিয়ে দিন';

  @override
  String get dashNotInMonth => 'এই মাসে আপনার কোনো হিসাব নেই';

  @override
  String get dashDailyTitle => 'দৈনিক মিল';

  @override
  String dashDailySummary(String total, String max, String date) {
    return 'দৈনিক মিল: মোট $total, সবচেয়ে বেশি $max ($date)';
  }

  @override
  String get dashCategoryTitle => 'কোথায় খরচ হলো';

  @override
  String get dashMonthlyTitle => 'মাসে মাসে মিল রেট';

  @override
  String get dashChartEmpty => 'এই মাসে এখনো কিছু নেই';

  @override
  String get dashRecentBazar => 'সাম্প্রতিক বাজার';

  @override
  String get dashNobodyThatDay => 'এই দিনে কেউ মেসে ছিল না';

  @override
  String get navBazar => 'বাজার';

  @override
  String mealGridManager(String name) {
    return 'ম্যানেজার: $name';
  }

  @override
  String get mealGridPrevMonth => 'আগের মাস';

  @override
  String get mealGridNextMonth => 'পরের মাস';

  @override
  String get mealGridTotalRow => 'মোট মিল';

  @override
  String get mealGridDayTotal => 'এই দিনের মোট মিল';

  @override
  String get mealGridHint => 'সংখ্যায় ট্যাপ করলে ০, ০.৫, ১, ১.৫, ২ ঘুরে আসবে';

  @override
  String get mealGridAllOne => 'সবাই ১';

  @override
  String get mealGridLikeYesterday => 'গতকালের মতো';

  @override
  String get mealGridNothingToChange => 'বদলানোর কিছু নেই';

  @override
  String get mealGridAdd => 'যোগ করুন';

  @override
  String get mealGridAddTitle => 'কী যোগ করবেন?';

  @override
  String get mealGridAi => 'মিল লিখে বলুন';

  @override
  String get mealGridToday => 'আজকের মিল';

  @override
  String get mealGridGoToMeals => 'মিল বসান';

  @override
  String get bazarTabTotal => 'এই মাসের বাজার';

  @override
  String get bazarPickerFrequent => 'বেশি কেনা হয়';

  @override
  String get bazarPickerStaples => 'চাল-ডাল-তেল';

  @override
  String get bazarPickerVeg => 'সবজি';

  @override
  String get bazarPickerProtein => 'মাছ-মাংস-ডিম';

  @override
  String get bazarPickerSpice => 'মসলা ও অন্যান্য';

  @override
  String get bazarPickerCustom => 'নতুন আইটেম';

  @override
  String get bazarPickerHelp => 'ট্যাপ করে আইটেম যোগ করুন, আবার ট্যাপে বাদ';

  @override
  String get setupTitle => 'শুরু করি';

  @override
  String setupProgress(String done, String total) {
    return '$done/$total হয়েছে';
  }

  @override
  String get setupLater => 'পরে করব';

  @override
  String get setupStart => 'শুরু';

  @override
  String get setupMess => 'মেস খোলা হয়েছে';

  @override
  String get setupMealTypes => 'মিলের বেলা ঠিক করুন';

  @override
  String get setupMembers => 'সদস্য যোগ করুন';

  @override
  String get setupDeposit => 'শুরুর জমা লিখুন';

  @override
  String get setupMeals => 'আজকের মিল বসান';

  @override
  String shareBillTitle(String mess) {
    return '*$mess* · মাসের বিল';
  }

  @override
  String shareBillSummaryTitle(String mess) {
    return '*$mess* · মাসের হিসাব';
  }

  @override
  String shareBillMeals(String meals, String rate, String cost) {
    return 'মিল: $meals × $rate = $cost';
  }

  @override
  String get shareBillPaid => 'জমা দিয়েছেন';

  @override
  String get shareBillFoodTotal => 'মোট খাবার খরচ';

  @override
  String get shareBillTotalMeals => 'মোট মিল';

  @override
  String get shareBillRate => 'মিল রেট';

  @override
  String get shareBillExtraTotal => 'অন্যান্য খরচ';

  @override
  String get shareBillShare => 'বিল শেয়ার';

  @override
  String get shareBillRemind => 'মনে করিয়ে দিন';

  @override
  String get shareBillShareAll => 'সবার হিসাব শেয়ার';

  @override
  String get shareBillToneTitle => 'কীভাবে বলবেন?';

  @override
  String get shareBillTonePolite => 'ভদ্রভাবে';

  @override
  String get shareBillToneShort => 'ছোট করে';

  @override
  String get shareBillToneFirm => 'জোর দিয়ে';

  @override
  String shareBillRemindPolite(String name, String amount) {
    return 'আসসালামু আলাইকুম $name, এই মাসের মেসের হিসাবে আপনার $amount বাকি আছে। সুবিধামতো সময়ে দিয়ে দিলে খুব উপকার হয়। ধন্যবাদ!';
  }

  @override
  String shareBillRemindShort(String name, String amount) {
    return '$name, মেসের বাকি $amount। দয়া করে দিয়ে দিন।';
  }

  @override
  String shareBillRemindFirm(String name, String amount) {
    return '$name, আপনার মেসের বাকি $amount এখনো জমা হয়নি। দয়া করে ৩ দিনের মধ্যে পরিশোধ করুন।';
  }

  @override
  String shareBillPayHint(String number) {
    return 'বিকাশ/নগদ: $number';
  }

  @override
  String get noticeTitle => 'নোটিশ';

  @override
  String get noticeEmpty => 'এখনো কোনো নোটিশ নেই';

  @override
  String get noticeAdd => 'নোটিশ দিন';

  @override
  String get noticeEdit => 'নোটিশ বদলান';

  @override
  String get noticeTitleLabel => 'শিরোনাম';

  @override
  String get noticeTitleRequired => 'শিরোনাম লিখুন';

  @override
  String get noticeBodyLabel => 'বিস্তারিত';

  @override
  String get noticePin => 'সবার উপরে পিন করুন';

  @override
  String get noticePinned => 'পিন করা';

  @override
  String get noticeUnread => 'নতুন';

  @override
  String get noticeExpiry => 'মেয়াদ';

  @override
  String get noticeNoExpiry => 'মেয়াদ নেই';

  @override
  String get noticeClearExpiry => 'মেয়াদ সরান';

  @override
  String noticeUntil(String date) {
    return '$date পর্যন্ত';
  }

  @override
  String get noticeSave => 'নোটিশ সেভ করুন';

  @override
  String get noticeSaved => 'নোটিশ সেভ হয়েছে';

  @override
  String get noticeDeleted => 'নোটিশ মুছে ফেলা হয়েছে';

  @override
  String get noticeDeleteConfirmTitle => 'নোটিশটি মুছবেন?';

  @override
  String get noticeDeleteConfirmBody => 'সবার কাছ থেকে নোটিশটি সরে যাবে।';

  @override
  String get noticeGone => 'নোটিশটি আর নেই';

  @override
  String get dutyTitle => 'বাজারের পালা';

  @override
  String get dutyGenerate => 'পালা বানান';

  @override
  String get dutyEmpty => 'এই মাসে কারও বাজারের পালা নেই';

  @override
  String get dutyMyUpcoming => 'আপনার সামনের পালা';

  @override
  String get dutyThisMonth => 'এই মাসের পালা';

  @override
  String get dutyDone => 'বাজার হয়ে গেছে';

  @override
  String get dutyMarkDone => 'বাজার করেছি';

  @override
  String get dutyMembersLabel => 'কে কে করবে, ক্রম অনুযায়ী ট্যাপ করুন';

  @override
  String get dutyPickMembers => 'অন্তত একজনকে বাছুন';

  @override
  String get dutyStart => 'শুরুর দিন';

  @override
  String get dutyEveryLabel => 'কত দিন পরপর';

  @override
  String dutyEvery(String n) {
    return 'প্রতি $n দিনে';
  }

  @override
  String get dutyDays => 'কত দিনের জন্য';

  @override
  String get dutyDaysInvalid => '১ থেকে ৩৬৬ দিনের মধ্যে দিন';

  @override
  String dutyCreated(String count) {
    return '$countটি পালা তৈরি হয়েছে';
  }

  @override
  String get dutyEditTitle => 'পালা বদলান';

  @override
  String get dutyMember => 'কে বাজার করবে';

  @override
  String get dutyNote => 'নোট';

  @override
  String get dutyDeleteConfirm => 'এই দিনের পালা মুছে ফেলবেন?';

  @override
  String get dutyTodayMine => 'আজ আপনার বাজারের পালা';

  @override
  String get dutyTomorrowMine => 'কাল আপনার বাজারের পালা';

  @override
  String dutyTodayOther(String name) {
    return 'আজ বাজার করবেন $name';
  }

  @override
  String dutyTomorrowOther(String name) {
    return 'কাল বাজার করবেন $name';
  }

  @override
  String get dutyDayAfterMine => 'পরশু আপনার বাজারের পালা';

  @override
  String dutyDayAfterOther(String name) {
    return 'পরশু বাজার করবেন $name';
  }

  @override
  String get dutyNextMonth => 'পরের মাস';

  @override
  String get splitEqualAll => 'সবাই সমান';

  @override
  String get splitByMeal => 'মিল অনুযায়ী';

  @override
  String get splitSelected => 'কয়েকজন';

  @override
  String get splitSelectedHelp =>
      'শুধু বাছাই করা সদস্যরা দেবেন, যার যত ভাগ সে তত দেবে। যেমন: এক রুমের ফ্যান মেরামত';

  @override
  String get splitPickMember => 'অন্তত একজন সদস্য বাছুন';

  @override
  String splitWeight(String weight) {
    return 'ভাগ $weight';
  }

  @override
  String get splitWeightLess => 'ভাগ কমান';

  @override
  String get splitWeightMore => 'ভাগ বাড়ান';

  @override
  String get splitPreview => 'প্রিভিউ: কে কত দেবে (আসল হিসাব মাস শেষে)';

  @override
  String get exportTitle => 'ডেটা এক্সপোর্ট (CSV)';

  @override
  String get exportAction => 'CSV এক্সপোর্ট';

  @override
  String get exportPeriod => 'কোন মাসের হিসাব';

  @override
  String get exportCurrent => 'চলতি মাস';

  @override
  String get exportHint =>
      'ব্যালেন্স, মিল, বাজার, খরচ আর জমা — ৫টি CSV ফাইল। Excel বা Google Sheets-এ খোলা যায়।';

  @override
  String get exportButton => 'এক্সপোর্ট করে শেয়ার করুন';

  @override
  String get exportDate => 'তারিখ';

  @override
  String get exportMember => 'সদস্য';

  @override
  String get exportGuests => 'অতিথি';

  @override
  String get exportOpening => 'আগের ব্যালেন্স';

  @override
  String get exportAmount => 'টাকা';

  @override
  String get exportBuyer => 'বাজারকারী';

  @override
  String get exportPaidBy => 'টাকা দিয়েছে';

  @override
  String get exportItems => 'জিনিসপত্র';

  @override
  String get exportNote => 'নোট';

  @override
  String get exportCategory => 'খাত';

  @override
  String get exportSplit => 'ভাগ';

  @override
  String get exportMethod => 'মাধ্যম';

  @override
  String get exportStatus => 'অবস্থা';

  @override
  String get exportVerified => 'যাচাই হয়েছে';

  @override
  String get cookShare => 'রাঁধুনিকে কালকের মিল পাঠান';

  @override
  String get remindTitle => 'রিমাইন্ডার';

  @override
  String get remindCutoffTitle => 'মিল বন্ধের সময় শেষ হচ্ছে';

  @override
  String get remindCutoffBody => 'কালকের মিল বন্ধ করতে চাইলে এখনই করুন';

  @override
  String get remindNudgeTitle => 'আজকের মিল বসানো হয়নি';

  @override
  String get remindNudgeBody => 'আজকের মিল বসানো হয়নি? এখনই বসিয়ে দিন';

  @override
  String get remindDutyTitle => 'কাল আপনার বাজার';

  @override
  String remindDutyBody(String mess) {
    return '$mess: কাল বাজারের দায়িত্ব আপনার';
  }

  @override
  String get remindCutoffToggle => 'মিল বন্ধের সময়ের আগে';

  @override
  String get remindCutoffToggleSub => 'শেষ সময়ের ৩০ মিনিট আগে মনে করিয়ে দেবে';

  @override
  String get remindNudgeToggle => 'রাতে মিল বসানোর কথা';

  @override
  String get remindNudgeToggleSub => 'প্রতিদিন রাত ৯টায়, ম্যানেজারদের জন্য';

  @override
  String get remindDutyToggle => 'বাজারের দায়িত্ব';

  @override
  String get remindDutyToggleSub => 'দায়িত্বের আগের দিন রাত ৮টায়';

  @override
  String get remindPermissionOff => 'নোটিফিকেশন বন্ধ আছে';

  @override
  String get remindPermissionBody => 'রিমাইন্ডার পেতে নোটিফিকেশন চালু করুন';

  @override
  String get remindPermissionButton => 'চালু করুন';

  @override
  String get recurringTitle => 'নিয়মিত মাসিক বিল';

  @override
  String get recurringHelp =>
      'ভাড়া, ওয়াইফাই, বুয়ার মতো যে বিল প্রতি মাসে একই থাকে, একবার লিখে রাখুন। তারপর প্রতি মাসে এক চাপে খরচে বসান।';

  @override
  String get recurringEmpty => 'এখনো কোনো নিয়মিত বিল নেই';

  @override
  String get recurringAdd => 'নতুন নিয়মিত বিল';

  @override
  String get recurringEdit => 'নিয়মিত বিল বদলান';

  @override
  String get recurringDay => 'মাসের কততম দিনে বসবে';

  @override
  String recurringDayValue(String day) {
    return 'মাসের $day নম্বর দিন';
  }

  @override
  String recurringActive(String name) {
    return '$name চালু';
  }

  @override
  String get recurringApply => 'এই মাসের বিল বসান';

  @override
  String recurringApplied(String count) {
    return '$countটি বিল খরচে বসানো হলো';
  }

  @override
  String get recurringNothingToApply =>
      'এই মাসের সব নিয়মিত বিল আগেই বসানো হয়েছে';

  @override
  String recurringPending(String count) {
    return 'এই মাসের $countটি নিয়মিত বিল বসানো বাকি';
  }

  @override
  String get recurringManagerOnly => 'শুধু ম্যানেজার নিয়মিত বিল বদলাতে পারেন';

  @override
  String get mealDefaultTitle => 'সদস্যদের ডিফল্ট মিল';

  @override
  String get mealDefaultHelp =>
      'আগের দিনের মিল না থাকলে \"আজকের মিল বসান\" এই হিসাবে মিল বসাবে।';

  @override
  String get mealDefaultEmpty => 'কোনো সক্রিয় সদস্য বা চালু বেলা নেই';

  @override
  String get mealDefaultManagerOnly => 'শুধু ম্যানেজার ডিফল্ট মিল বদলাতে পারেন';

  @override
  String get rateSection => 'মিল রেট';

  @override
  String get rateHelp =>
      'হিসাব করে: বাজার খরচ ÷ মোট মিল। নির্দিষ্ট রেট: আগে থেকে ঘোষণা করা রেট, সবাই প্রতি মিলে এটাই দেবে।';

  @override
  String get rateCalculated => 'হিসাব করে';

  @override
  String get rateFixed => 'নির্দিষ্ট রেট';

  @override
  String get rateAmountLabel => 'প্রতি মিলের রেট (৳)';

  @override
  String get rateAmountRequired => '০-এর বেশি একটি রেট লিখুন';

  @override
  String rateSurplus(String amount) {
    return 'বাজার খরচের চেয়ে $amount বেশি উঠেছে';
  }

  @override
  String rateDeficit(String amount) {
    return 'বাজার খরচের চেয়ে $amount কম উঠেছে';
  }

  @override
  String rateBalanceFood(String meals, String rate) {
    return 'খাবার খরচ = $meals মিল × $rate (নির্দিষ্ট রেট)';
  }

  @override
  String get platformMaintenanceTitle => 'একটু কাজ চলছে';

  @override
  String get platformMaintenanceBody =>
      'অ্যাপটি কিছুক্ষণের জন্য বন্ধ আছে। একটু পরে আবার খুলুন, আপনার হিসাব নিরাপদ আছে।';

  @override
  String get platformMaintenanceRetry => 'আবার দেখুন';

  @override
  String get platformSignOut => 'সাইন আউট';

  @override
  String get platformUpdateTitle => 'নতুন ভার্সন এসেছে';

  @override
  String get platformUpdateBody =>
      'ঠিকঠাক চালাতে Play Store থেকে অ্যাপটি আপডেট করে নিন।';

  @override
  String get platformUpdateLater => 'পরে করব';

  @override
  String get platformBannerDismiss => 'বন্ধ করুন';

  @override
  String get platformSupportTitle => 'সাহায্য';

  @override
  String get platformSupportEmail => 'ইমেইল';

  @override
  String get platformSupportWhatsapp => 'WhatsApp';

  @override
  String get platformPrivacy => 'প্রাইভেসি পলিসি';

  @override
  String get platformCopy => 'কপি করুন';

  @override
  String get platformCopied => 'কপি হয়েছে';

  @override
  String get platformAboutTitle => 'অ্যাপ সম্পর্কে';

  @override
  String platformVersion(String version) {
    return 'ভার্সন $version';
  }

  @override
  String get adminTitle => 'মিল বাজার অ্যাডমিন';

  @override
  String get adminTitleShort => 'অ্যাডমিন';

  @override
  String get adminSignIn => 'লগইন করুন';

  @override
  String get adminSignInGoogle => 'গুগল দিয়ে লগইন';

  @override
  String get adminSignInHint =>
      'শুধু প্ল্যাটফর্ম অ্যাডমিনরা এখানে ঢুকতে পারেন।';

  @override
  String get adminSignOut => 'লগআউট';

  @override
  String get adminAccessDenied => 'প্রবেশাধিকার নেই';

  @override
  String get adminAccessDeniedBody =>
      'এই অ্যাকাউন্ট প্ল্যাটফর্ম অ্যাডমিন নয়। অন্য অ্যাকাউন্টে লগইন করুন।';

  @override
  String get adminNavDashboard => 'ড্যাশবোর্ড';

  @override
  String get adminNavMesses => 'মেস';

  @override
  String get adminNavUsers => 'ইউজার';

  @override
  String get adminNavSettings => 'সেটিংস';

  @override
  String get adminNavAi => 'এআই';

  @override
  String get adminNavBranding => 'ব্র্যান্ডিং';

  @override
  String get adminNavCredentials => 'ক্রেডেনশিয়াল';

  @override
  String get adminNavDeletion => 'মুছে ফেলার সারি';

  @override
  String get adminStatUsersTotal => 'মোট ইউজার';

  @override
  String get adminStatUsers7d => 'নতুন ইউজার (৭ দিন)';

  @override
  String get adminStatMessesTotal => 'মোট মেস';

  @override
  String get adminStatMessesActive7d => 'সক্রিয় মেস (৭ দিন)';

  @override
  String get adminStatMeals7d => 'মিল (৭ দিন)';

  @override
  String get adminStatBazars7d => 'বাজার (৭ দিন)';

  @override
  String get adminStatAiCalls7d => 'এআই কল (৭ দিন)';

  @override
  String get adminStatSuspendedMesses => 'স্থগিত মেস';

  @override
  String get adminStatDeletionPending => 'মুছে ফেলার অপেক্ষায়';

  @override
  String get adminAiUsage30d => 'এআই ব্যবহার, শেষ ৩০ দিন';

  @override
  String get adminAiUsageEmpty => 'এই সময়ে কোনো এআই কল হয়নি';

  @override
  String get adminDeletionEmpty => 'মুছে ফেলার কোনো অনুরোধ নেই';

  @override
  String get adminUserId => 'ইউজার আইডি';

  @override
  String get adminRequestedAt => 'অনুরোধের সময়';

  @override
  String get adminProcessedAt => 'সম্পন্ন';

  @override
  String get adminLastError => 'শেষ ত্রুটি';

  @override
  String get adminSearchMesses => 'মেসের নাম দিয়ে খুঁজুন, তারপর Enter';

  @override
  String get adminSearchUsers => 'ইমেইল বা নাম দিয়ে খুঁজুন, তারপর Enter';

  @override
  String get adminNoResults => 'কিছু পাওয়া যায়নি';

  @override
  String adminPage(String page) {
    return 'পৃষ্ঠা $page';
  }

  @override
  String get adminName => 'নাম';

  @override
  String get adminMembers => 'সদস্য';

  @override
  String get adminManagers => 'ম্যানেজার';

  @override
  String get adminCreated => 'তৈরি';

  @override
  String get adminLastActivity => 'শেষ কাজ';

  @override
  String get adminLastSignIn => 'শেষ লগইন';

  @override
  String get adminMessCount => 'মেস';

  @override
  String get adminStatus => 'অবস্থা';

  @override
  String get adminRole => 'ভূমিকা';

  @override
  String get adminRoleAdmin => 'অ্যাডমিন';

  @override
  String get adminActive => 'চালু';

  @override
  String get adminSuspended => 'স্থগিত';

  @override
  String get adminSuspend => 'স্থগিত করুন';

  @override
  String get adminUnsuspend => 'আবার চালু করুন';

  @override
  String adminSuspendMess(String name) {
    return '\"$name\" মেস স্থগিত করবেন?';
  }

  @override
  String adminUnsuspendMess(String name) {
    return '\"$name\" মেস আবার চালু করবেন?';
  }

  @override
  String adminSuspendUser(String email) {
    return '$email স্থগিত করবেন?';
  }

  @override
  String adminUnsuspendUser(String email) {
    return '$email আবার চালু করবেন?';
  }

  @override
  String get adminReason => 'কারণ';

  @override
  String get adminMakeAdmin => 'অ্যাডমিন বানান';

  @override
  String get adminRemoveAdmin => 'অ্যাডমিন থেকে সরান';

  @override
  String get adminSaved => 'সেভ হয়েছে';

  @override
  String get adminRawJson => 'অ্যাডভান্সড: কাঁচা JSON';

  @override
  String get adminAdd => 'যোগ করুন';

  @override
  String get adminMoveUp => 'ওপরে নিন';

  @override
  String get adminMoveDown => 'নিচে নিন';

  @override
  String get adminErrRequired => 'এটা দিতে হবে';

  @override
  String get adminErrNumber => 'একটা সংখ্যা দিন';

  @override
  String get adminErrRange => 'সীমার বাইরে';

  @override
  String get adminErrVersion => '১.২.৩ ধরনের ভার্সন দিন';

  @override
  String get adminErrEmail => 'সঠিক ইমেইল দিন';

  @override
  String get adminErrUrl => 'http(s):// দিয়ে শুরু হওয়া লিংক দিন';

  @override
  String get adminErrTime => 'HH:MM ধরনে সময় দিন';

  @override
  String get adminErrHex => '#RRGGBB ধরনে রং দিন';

  @override
  String get adminErrMealTypes => 'অন্তত একটা বেলা রাখুন';

  @override
  String get adminErrChain => 'প্রতিটি চেইনে ১ থেকে ৫টি মডেল রাখুন';

  @override
  String get adminFeatures => 'ফিচার';

  @override
  String get adminFeaturesHelp =>
      'বন্ধ করলে অ্যাপে ওই ফিচারের সব পথ লুকিয়ে যায়। ডেটা থেকে যায়।';

  @override
  String get adminAppSection => 'অ্যাপ';

  @override
  String get adminMaintenance => 'রক্ষণাবেক্ষণ মোড';

  @override
  String get adminMaintenanceHelp =>
      'চালু থাকলে অ্যাপে পুরো পর্দার নোটিশ দেখায়';

  @override
  String get adminMessageBn => 'বার্তা (বাংলা)';

  @override
  String get adminMessageEn => 'বার্তা (ইংরেজি)';

  @override
  String get adminVersions => 'ভার্সন';

  @override
  String get adminMinVersion => 'ন্যূনতম ভার্সন';

  @override
  String get adminMinVersionHelp => 'এর নিচে থাকলে আপডেট করতে বলা হয়';

  @override
  String get adminLatestVersion => 'সর্বশেষ ভার্সন';

  @override
  String get adminUpdateMessageBn => 'আপডেট বার্তা (বাংলা)';

  @override
  String get adminUpdateMessageEn => 'আপডেট বার্তা (ইংরেজি)';

  @override
  String get adminSupport => 'সহায়তা';

  @override
  String get adminSupportEmail => 'সহায়তার ইমেইল';

  @override
  String get adminSupportWhatsapp => 'সহায়তার হোয়াটসঅ্যাপ';

  @override
  String get adminPrivacyUrl => 'প্রাইভেসি পলিসির লিংক';

  @override
  String get adminBanner => 'ব্যানার';

  @override
  String get adminBannerActive => 'হোমে ব্যানার দেখান';

  @override
  String get adminBannerLevel => 'ধরন';

  @override
  String get adminDefaults => 'নতুন মেসের ডিফল্ট';

  @override
  String get adminDefaultsHelp => 'শুধু নতুন মেস তৈরির সময় কাজে লাগে';

  @override
  String get adminMonthStartDay => 'মাস শুরুর দিন (১–২৮)';

  @override
  String get adminCutoff => 'মিল বন্ধের শেষ সময়';

  @override
  String get adminMealTypes => 'বেলা';

  @override
  String get adminWeight => 'ওজন';

  @override
  String get adminExpenseCategories => 'খরচের ধরন';

  @override
  String get adminSplit => 'ভাগ';

  @override
  String get adminSplitEqual => 'সমান ভাগ';

  @override
  String get adminSplitMeal => 'মিল অনুযায়ী';

  @override
  String get adminCatalogue => 'বাজারের তালিকা';

  @override
  String get adminCatalogueHelp =>
      'বাজার যোগ করার সময় যে জিনিসগুলো বাছাই করা যায়';

  @override
  String get adminAddGroup => 'গ্রুপ যোগ করুন';

  @override
  String get adminAddItem => 'জিনিস যোগ করুন';

  @override
  String get adminGroupName => 'গ্রুপের নাম';

  @override
  String get adminUnit => 'একক';

  @override
  String get adminPaymentMethods => 'পেমেন্টের মাধ্যম';

  @override
  String get adminPaymentMethodsHelp =>
      'কী বদলানো যায় না, শুধু নাম আর দেখানো/লুকানো';

  @override
  String get adminLabelBn => 'নাম (বাংলা)';

  @override
  String get adminLabelEn => 'নাম (ইংরেজি)';

  @override
  String get adminAppNameBn => 'অ্যাপের নাম (বাংলা)';

  @override
  String get adminAppNameEn => 'অ্যাপের নাম (ইংরেজি)';

  @override
  String get adminTaglineBn => 'ট্যাগলাইন (বাংলা)';

  @override
  String get adminTaglineEn => 'ট্যাগলাইন (ইংরেজি)';

  @override
  String get adminBrandingReleaseNote =>
      'লগইন ও অ্যাকাউন্ট পর্দায় নাম, ট্যাগলাইন, লোগো আর রং বদলায়। লঞ্চার আইকন আর হোম স্ক্রিনের নাম বদলাতে নতুন রিলিজ লাগবে (অ্যান্ড্রয়েডের সীমাবদ্ধতা)।';

  @override
  String get adminLogo => 'লোগো';

  @override
  String get adminLogoUpload => 'লোগো আপলোড';

  @override
  String get adminLogoReplace => 'লোগো বদলান';

  @override
  String get adminLogoRemove => 'লোগো সরান';

  @override
  String get adminLogoDefault => 'লোগো না থাকলে অ্যাপ নিজের \"ম\" চিহ্ন দেখায়';

  @override
  String get adminLogoSaveHint => 'আপলোডের পর সেভ চাপলে অ্যাপে দেখাবে';

  @override
  String get adminAccent => 'অ্যাকসেন্ট রং';

  @override
  String get adminAccentLight => 'লাইট থিম';

  @override
  String get adminAccentDark => 'ডার্ক থিম';

  @override
  String adminContrast(String ratio) {
    return 'কনট্রাস্ট $ratio:১';
  }

  @override
  String get adminContrastOk => 'কনট্রাস্ট ঠিক আছে (৩:১ বা বেশি)';

  @override
  String get adminContrastLow =>
      'কনট্রাস্ট কম (৩:১ এর নিচে): চিহ্ন ঝাপসা দেখাবে';

  @override
  String get adminSecretsHelp =>
      'কী শুধু লেখা যায়, পড়া যায় না। সেভ করা মান কখনো দেখানো হয় না, শুধু শেষ ৪ অক্ষর।';

  @override
  String get adminSecretNotSet => 'সেট করা নেই (এনভ ভ্যারিয়েবল ব্যবহার হবে)';

  @override
  String get adminSecretSet => 'সেট করুন';

  @override
  String get adminSecretReplace => 'বদলান';

  @override
  String get adminSecretValue => 'নতুন মান';

  @override
  String get adminSecretValueHelp => 'আগের মান মুছে এটা বসবে';

  @override
  String adminSecretDeleteTitle(String name) {
    return '$name মুছবেন?';
  }

  @override
  String get adminSecretDeleteBody =>
      'মুছলে গেটওয়ে আবার এনভ ভ্যারিয়েবল ব্যবহার করবে।';

  @override
  String adminUpdatedAt(String date) {
    return 'আপডেট $date';
  }

  @override
  String get adminAiSettings => 'এআই সেটিংস';

  @override
  String get adminAiEnabled => 'এআই চালু';

  @override
  String get adminAllowPaid => 'পেইড মডেল চলতে দিন';

  @override
  String get adminAllowPaidHelp =>
      'বন্ধ থাকলে গেটওয়ে দাম আছে এমন OpenRouter মডেল বাদ দেয়';

  @override
  String get adminQuotaMeal => 'দৈনিক মিল খসড়া কোটা (মেস প্রতি)';

  @override
  String get adminQuotaBazar => 'দৈনিক বাজার স্ক্যান কোটা (মেস প্রতি)';

  @override
  String get adminTimeoutMs => 'টাইমআউট (মিলিসেকেন্ড)';

  @override
  String get adminTemperature => 'টেম্পারেচার';

  @override
  String get adminTextChain => 'টেক্সট চেইন (মিলের খসড়া)';

  @override
  String get adminVisionChain => 'ভিশন চেইন (রসিদ স্ক্যান)';

  @override
  String get adminChains => 'চেইন';

  @override
  String get adminChainEmpty => 'কোনো মডেল নেই। তালিকা থেকে যোগ করুন।';

  @override
  String get adminAddManually => 'হাতে মডেল যোগ';

  @override
  String get adminProvider => 'প্রোভাইডার';

  @override
  String get adminModelId => 'মডেল আইডি';

  @override
  String get adminModel => 'মডেল';

  @override
  String get adminModelCatalogue => 'মডেল তালিকা';

  @override
  String get adminAll => 'সব';

  @override
  String get adminSearchModels => 'মডেল খুঁজুন';

  @override
  String get adminFree => 'ফ্রি';

  @override
  String get adminPaid => 'পেইড';

  @override
  String get adminVision => 'ভিশন';

  @override
  String get adminText => 'টেক্সট';

  @override
  String get adminMinContext => 'ন্যূনতম কনটেক্সট';

  @override
  String get adminMaxPrice => 'সর্বোচ্চ দাম \$/১M';

  @override
  String get adminContext => 'কনটেক্সট';

  @override
  String get adminInputPrice => 'ইনপুট \$/১M';

  @override
  String get adminOutputPrice => 'আউটপুট \$/১M';

  @override
  String get adminAddToText => 'টেক্সট চেইনে যোগ';

  @override
  String get adminAddToVision => 'ভিশন চেইনে যোগ';

  @override
  String get adminTest => 'টেস্ট';

  @override
  String adminTestOk(String ms, String sample) {
    return 'ঠিক আছে · $ms ms · $sample';
  }

  @override
  String get adminGatewayMissing =>
      'এআই গেটওয়ে সেট করা নেই। env.json-এ AI_GATEWAY_URL দিয়ে প্যানেল আবার বিল্ড করুন, আর গেটওয়ের CORS-এ এই সাইটের ঠিকানা যোগ করুন।';

  @override
  String get adminPaidWarningTitle => 'পেইড মডেল সেভ করবেন?';

  @override
  String get adminPaidWarningBody =>
      '\"পেইড মডেল চলতে দিন\" বন্ধ, তাই গেটওয়ে এই মডেলগুলো বাদ দেবে:';

  @override
  String get adminSaveAnyway => 'তবুও সেভ করুন';

  @override
  String get stampPaid => 'পরিশোধিত';

  @override
  String get bazarBuyers => 'কে কে বাজারে গেছে';

  @override
  String get bazarReqTitle => 'বাজারের হিসাব দিন';

  @override
  String get bazarReqHelp => 'ম্যানেজার গ্রহণ করলে মেসের হিসাবে যোগ হবে';

  @override
  String get bazarReqWith => 'কে কে বাজারে গেছে';

  @override
  String get bazarReqOwnPocket => 'নিজের টাকায়';

  @override
  String get bazarReqMessFund => 'মেসের টাকা থেকে';

  @override
  String get bazarReqSend => 'জমা দিন';

  @override
  String get bazarReqSent => 'জমা হয়েছে, ম্যানেজারের যাচাইয়ের অপেক্ষায়';

  @override
  String get bazarReqFab => 'বাজার জমা দিন';

  @override
  String get bazarReqMine => 'আমার জমা';

  @override
  String get bazarReqPending => 'অপেক্ষায়';

  @override
  String get bazarReqApproved => 'গৃহীত';

  @override
  String get bazarReqRejected => 'ফেরত';

  @override
  String get bazarReqCancelled => 'তুলে নেওয়া';

  @override
  String bazarReqReason(String reason) {
    return 'কারণ: $reason';
  }

  @override
  String get bazarReqCancel => 'তুলে নিন';

  @override
  String get bazarReqCancelTitle => 'জমা তুলে নেবেন?';

  @override
  String bazarReqCancelBody(String amount) {
    return '$amount এর বাজারটি ম্যানেজারের কাছে আর যাবে না।';
  }

  @override
  String get bazarReqCancelDone => 'জমা তুলে নেওয়া হয়েছে';

  @override
  String get bazarReqReview => 'যাচাইয়ের অপেক্ষায়';

  @override
  String bazarReqWithNames(String names) {
    return 'সঙ্গে $names';
  }

  @override
  String bazarReqOf(String name) {
    return '$name এর বাজার';
  }

  @override
  String bazarReqPaidOwn(String name) {
    return '$name নিজের টাকায় দিয়েছেন';
  }

  @override
  String get bazarReqPaidFund => 'মেসের টাকা থেকে দেওয়া';

  @override
  String get bazarReqApprove => 'গ্রহণ করুন';

  @override
  String get bazarReqReject => 'ফেরত দিন';

  @override
  String get bazarReqRejectTitle => 'বাজার ফেরত দেবেন?';

  @override
  String get bazarReqRejectReason => 'কারণ (ঐচ্ছিক)';

  @override
  String get bazarReqApproveDone => 'বাজার যোগ হয়েছে';

  @override
  String get bazarReqRejectDone => 'ফেরত পাঠানো হয়েছে';

  @override
  String bazarReqAttn(String count) {
    return '$countটি বাজার যাচাই বাকি';
  }

  @override
  String get bazarReqFailFutureDate => 'সামনের তারিখে বাজার দেওয়া যায় না';

  @override
  String get bazarReqFailNotPending => 'এই বাজারটি আর অপেক্ষায় নেই';

  @override
  String get bazarReqFailItemsInvalid => 'জিনিসের তালিকা ঠিক নেই';

  @override
  String get bazarPickBuyer => 'অন্তত একজন বাছুন';

  @override
  String get bazarPayer => 'কে টাকা দিয়েছে';

  @override
  String get bazarTotal => 'মোট';

  @override
  String get bazarItemRemoved => 'আইটেম বাদ দেওয়া হলো';

  @override
  String get undo => 'ফিরিয়ে আনুন';

  @override
  String get bazarPickerTitle => 'তালিকা থেকে বাছুন';

  @override
  String get bazarPickerSearch => 'খুঁজুন বা নতুন নাম লিখুন';

  @override
  String bazarPickerAddNamed(String name) {
    return '“$name” যোগ করুন';
  }

  @override
  String get bazarUnitNone => 'একক ছাড়া';

  @override
  String bazarQtyLabel(String qty) {
    return 'পরিমাণ $qty, একক বদলাতে ট্যাপ করুন';
  }

  @override
  String get bazarSwipeHint => 'বাদ দিতে বাঁয়ে সরান';

  @override
  String get pushTitle => 'নোটিফিকেশন';

  @override
  String get pushIntro => 'মেসের কোন খবর ফোনে পেতে চান, বেছে নিন';

  @override
  String get pushPermissionBody => 'মেসের খবর পেতে ফোনের নোটিফিকেশন চালু করুন';

  @override
  String get pushOpenSub => 'বাজার, খরচ, জমা, নোটিশ';

  @override
  String get pushJoinRequest => 'যোগদানের অনুরোধ';

  @override
  String get pushJoinRequestSub => 'কেউ মেসে যোগ দিতে চাইলে';

  @override
  String get pushDepositPending => 'যাচাইয়ের অপেক্ষায় জমা';

  @override
  String get pushDepositPendingSub => 'কোনো সদস্য টাকা জমা দিলে';

  @override
  String get pushDepositVerified => 'জমা গৃহীত হলে';

  @override
  String get pushDepositVerifiedSub => 'ম্যানেজার আপনার জমা যাচাই করলে';

  @override
  String get pushDepositRejected => 'জমা বাতিল হলে';

  @override
  String get pushDepositRejectedSub => 'ম্যানেজার আপনার জমা বাতিল করলে';

  @override
  String get pushNotice => 'নতুন নোটিশ';

  @override
  String get pushNoticeSub => 'নোটিশ বোর্ডে কিছু লেখা হলে';

  @override
  String get pushBazar => 'নতুন বাজার';

  @override
  String get pushBazarSub => 'কেউ বাজারের হিসাব যোগ করলে';

  @override
  String get pushExpense => 'নতুন খরচ';

  @override
  String get pushExpenseSub => 'বিল বা অন্য খরচ যোগ হলে';

  @override
  String get pushMonthClosed => 'মাস বন্ধ';

  @override
  String get pushMonthClosedSub => 'মাসের হিসাব চূড়ান্ত হলে';

  @override
  String get pushDue => 'বকেয়ার রিমাইন্ডার';

  @override
  String get pushDueSub => 'ম্যানেজার বকেয়া মনে করিয়ে দিলে';

  @override
  String get dueRemindButton => 'বকেয়া মনে করিয়ে দিন';

  @override
  String get dueRemindConfirmTitle => 'বকেয়া রিমাইন্ডার পাঠাবেন?';

  @override
  String get dueRemindConfirmBody =>
      'যাদের বকেয়া আছে, তারা ফোনে নিজের বকেয়ার পরিমাণসহ নোটিফিকেশন পাবেন।';

  @override
  String get dueRemindSend => 'পাঠান';

  @override
  String dueRemindSent(String count) {
    return '$count জনকে রিমাইন্ডার পাঠানো হয়েছে';
  }

  @override
  String get dueRemindNone =>
      'কাউকে পাঠানো যায়নি: বকেয়া থাকা সদস্যদের ফোনে নোটিফিকেশন চালু নেই';

  @override
  String get msgTitle => 'বার্তা';

  @override
  String get msgMoreSub => 'জরুরি কথা ও সমস্যা জানানো';

  @override
  String get msgEmpty =>
      'এখনো কোনো বার্তা নেই। জরুরি কিছু হলে বা কোনো হিসাব ভুল মনে হলে ম্যানেজারকে লিখুন।';

  @override
  String get msgEmptyManager => 'সদস্যদের কোনো বার্তা নেই';

  @override
  String get msgEmptyResolved => 'কোনো মীমাংসিত বার্তা নেই';

  @override
  String get msgNew => 'নতুন বার্তা';

  @override
  String get msgFilterOpen => 'খোলা';

  @override
  String get msgResolved => 'মীমাংসিত';

  @override
  String get msgUnread => 'অপঠিত';

  @override
  String msgYou(String text) {
    return 'আপনি: $text';
  }

  @override
  String get msgComposeHint => 'বার্তা লিখুন…';

  @override
  String get msgSend => 'পাঠান';

  @override
  String get msgSending => 'পাঠানো হচ্ছে…';

  @override
  String get msgNotSent => 'পাঠানো যায়নি · আবার চেষ্টা করুন';

  @override
  String get msgResolve => 'মীমাংসিত করুন';

  @override
  String get msgReopen => 'আবার খুলুন';

  @override
  String get msgResolvedNote => 'বিষয়টি মীমাংসিত। আবার লিখলে খুলে যাবে।';

  @override
  String get msgGone => 'বার্তাটি পাওয়া যায়নি';

  @override
  String get msgSubject => 'বিষয়';

  @override
  String get msgSubjectRequired => 'বিষয় লিখুন';

  @override
  String get msgBody => 'বার্তা';

  @override
  String get msgBodyRequired => 'বার্তা লিখুন';

  @override
  String get msgTo => 'কাকে';

  @override
  String get msgToManagers =>
      'মেসের ম্যানেজার বার্তাটি দেখবেন। এটা চ্যাট নয়, উত্তর এলে নোটিফিকেশন পাবেন।';

  @override
  String get msgMemberRequired => 'একজন সদস্য বাছুন';

  @override
  String msgReportSubject(String label) {
    return 'সমস্যা: $label';
  }

  @override
  String get msgReportStarter =>
      'এই তথ্যটি ভুল মনে হচ্ছে, দয়া করে ঠিক করে দিন।';

  @override
  String get msgReport => 'সমস্যা জানান';

  @override
  String get msgSent => 'বার্তা পাঠানো হয়েছে';

  @override
  String get msgAbout => 'যে এন্ট্রি নিয়ে';

  @override
  String get msgRefDeposit => 'জমা';

  @override
  String get msgRefBazar => 'বাজার';

  @override
  String get msgRefExpense => 'খরচ';

  @override
  String get msgRefMeal => 'মিল';

  @override
  String get msgRefOther => 'অন্যান্য';

  @override
  String get msgDeletedUser => 'সাবেক সদস্য';

  @override
  String get pushMessage => 'বার্তা';

  @override
  String get pushMessageSub => 'ম্যানেজার বা সদস্য আপনাকে লিখলে';

  @override
  String get auditVerified => 'যাচাই করেছেন';

  @override
  String get auditRejected => 'বাতিল করেছেন';

  @override
  String get auditOff => 'অফ';

  @override
  String get attnTitle => 'এখন যা দেখতে হবে';

  @override
  String attnDeposits(String count) {
    return '$countটি জমা যাচাই বাকি';
  }

  @override
  String attnJoin(String count) {
    return '$countটি যোগদানের অনুরোধ';
  }

  @override
  String attnMessages(String count) {
    return '$countটি নতুন বার্তা';
  }

  @override
  String attnMeals(String count) {
    return 'আজ $count জনের মিল বসানো হয়নি';
  }

  @override
  String get cashTitle => 'হাতে নগদ (মেস ফান্ড)';

  @override
  String cashProof(String deposits, String spent) {
    return 'জমা $deposits − ফান্ড থেকে খরচ $spent';
  }

  @override
  String cashPending(String amount) {
    return 'যাচাই বাকি $amount, এখনো ধরা হয়নি';
  }

  @override
  String get dashSeeAll => 'সবাই দেখুন';

  @override
  String get dashOthers => 'অন্যান্য';

  @override
  String get dashAllSettled => 'কারো বকেয়া নেই';

  @override
  String get mineBalance => 'আমার হিসাব';

  @override
  String get myTodayTitle => 'আজ আমার মিল';

  @override
  String get transTitle => 'সবার হিসাব';

  @override
  String get transNote =>
      'এই মাস · জমা, নিজের পকেট থেকে দেওয়া টাকা আর ব্যালেন্স';

  @override
  String get transDeposits => 'জমা';

  @override
  String get transOwnPocket => 'নিজে দিয়েছেন';

  @override
  String get transBalance => 'ব্যালেন্স';

  @override
  String get activityTitle => 'আমার বিষয়ে এন্ট্রি';

  @override
  String get activityEmpty =>
      'ম্যানেজার আপনার মিল, জমা বা বাজার নিয়ে কিছু লিখলে এখানে দেখাবে';

  @override
  String get reportProblem => 'সমস্যা জানান';

  @override
  String get youTag => 'আপনি';

  @override
  String get activitySeeAll => 'সব দেখুন';

  @override
  String get auditMealMine => 'আপনার মিল';

  @override
  String get auditDepositMine => 'আপনার জমা';

  @override
  String get messagesComingSoon =>
      'বার্তা পাঠানোর সুবিধা শিগগিরই আসছে। ততক্ষণ ম্যানেজারকে সরাসরি জানান।';

  @override
  String get msgGroupShort => 'মেস গ্রুপ';

  @override
  String msgGroupTitle(String mess) {
    return '$mess গ্রুপ';
  }

  @override
  String msgGroupMembers(String count) {
    return '$count জন সদস্য';
  }

  @override
  String get msgGroupEmpty =>
      'এখনো কোনো বার্তা নেই। মেসের সবাইকে কিছু জানাতে নিচে লিখুন।';

  @override
  String get msgHidden => 'বার্তাটি মুছে ফেলা হয়েছে';

  @override
  String get msgHide => 'বার্তাটি মুছুন';

  @override
  String get msgHideBody =>
      'বার্তাটি সবার কাছ থেকে সরে যাবে। এটা ফেরানো যাবে না।';

  @override
  String get msgHideAction => 'মুছুন';

  @override
  String get msgDayToday => 'আজ';

  @override
  String get msgDayYesterday => 'গতকাল';

  @override
  String get homeMsgManager => 'ম্যানেজারকে বার্তা';

  @override
  String homeUnreadCount(String count) {
    return '$countটি অপঠিত';
  }

  @override
  String get pushGroup => 'মেস গ্রুপ';

  @override
  String get pushGroupSub =>
      'গ্রুপে নতুন বার্তা এলে। বন্ধ করলে গ্রুপ মিউট থাকবে';

  @override
  String mealOffUntil(String time) {
    return '$time পর্যন্ত';
  }

  @override
  String myMealCount(String count) {
    return '$count মিল';
  }

  @override
  String get myMealOff => 'বন্ধ';

  @override
  String get myTomorrow => 'কাল';

  @override
  String get dayTomorrow => 'কাল';

  @override
  String get dayYesterday => 'গতকাল';

  @override
  String get settingsLeadTitle => 'মিল বন্ধের সময়সীমা';

  @override
  String get settingsLeadHelp =>
      'খাবারের কতক্ষণ আগ পর্যন্ত সদস্যরা নিজের মিল বন্ধ বা চালু করতে পারবেন';

  @override
  String settingsLeadHours(String hours) {
    return 'খাবারের $hours ঘণ্টা আগে';
  }

  @override
  String settingsLeadPrevDay(String time) {
    return 'আগের দিন $time';
  }

  @override
  String get settingsLeadCustom => 'নিজে ঠিক করুন';

  @override
  String get settingsLeadCustomLabel => 'খাবারের কত ঘণ্টা আগে (০–৪৮)';

  @override
  String get settingsLeadCustomInvalid => '০ থেকে ৪৮ ঘণ্টার মধ্যে দিন';

  @override
  String settingsLeadExample(String meal, String time) {
    return 'আজ $meal মিল বন্ধ করা যাবে $time পর্যন্ত';
  }

  @override
  String get mealTypesServeTime => 'খাবারের সময়';

  @override
  String mealOffHintLead(String hours) {
    return 'খাবারের $hours ঘণ্টা আগ পর্যন্ত নিজের মিল বন্ধ করা যায়';
  }

  @override
  String msgMealOff(String name, String day, String meal) {
    return '$name $day $meal মিল বন্ধ করেছেন';
  }

  @override
  String msgMealOn(String name, String day, String meal) {
    return '$name $day $meal মিল আবার চালু করেছেন';
  }

  @override
  String get myMealNotEntered => 'এখনো দেওয়া হয়নি';

  @override
  String mealOffConfirmTitle(Object day, Object meal) {
    return '$day $meal মিল বন্ধ করবেন?';
  }

  @override
  String get mealOffConfirmBody =>
      'বন্ধ করলে মেস গ্রুপে আপনার পক্ষ থেকে সবাইকে জানানো হবে।';

  @override
  String get mealOffConfirmAction => 'হ্যাঁ, বন্ধ করুন';

  @override
  String get homeNoticeAll => 'সব নোটিশ';

  @override
  String get inboxTitle => 'বিজ্ঞপ্তি';

  @override
  String get inboxMoreSub => 'যা যা জানানো হয়েছে, এক জায়গায়';

  @override
  String get inboxMarkAllRead => 'সব পড়া হয়েছে';

  @override
  String get inboxEmpty =>
      'এখনো কোনো বিজ্ঞপ্তি নেই। জমা, বাজার বা নোটিশে কিছু হলে এখানে দেখবেন।';

  @override
  String get inboxUnread => 'অপঠিত';

  @override
  String get inboxPushDepositAdded => 'আপনার নামে জমা';

  @override
  String get inboxPushDepositAddedSub => 'ম্যানেজার আপনার জমা লিখলে';

  @override
  String get inboxPushBazarRequest => 'সদস্যের বাজার';

  @override
  String get inboxPushBazarRequestSub =>
      'কোনো সদস্য নিজের বাজার অনুমোদনের জন্য পাঠালে';

  @override
  String get inboxPushBazarReviewed => 'আমার বাজারের সিদ্ধান্ত';

  @override
  String get inboxPushBazarReviewedSub =>
      'ম্যানেজার আপনার বাজার মেনে নিলে বা ফিরিয়ে দিলে';

  @override
  String get inboxPushDutyToday => 'আজ আমার বাজারের পালা';

  @override
  String get inboxPushDutyTodaySub =>
      'যেদিন আমার বাজার, সেদিন সকালে মনে করিয়ে দেবে';

  @override
  String syncStripOffline(String n) {
    return 'অফলাইন · $nটি পরিবর্তন ফোনে সেভ আছে, নেট এলে নিজেই পাঠানো হবে';
  }

  @override
  String syncStripSending(String n) {
    return '$nটি পরিবর্তন পাঠানো হচ্ছে…';
  }

  @override
  String syncStripFailed(String n) {
    return '$nটি পরিবর্তন পাঠানো যায়নি';
  }

  @override
  String get syncStripRetry => 'আবার চেষ্টা';
}
