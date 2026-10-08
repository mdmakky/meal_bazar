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
}
