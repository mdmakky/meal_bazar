import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In bn, this message translates to:
  /// **'মিল বাজার'**
  String get appName;

  /// No description provided for @retry.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা করুন'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In bn, this message translates to:
  /// **'সেভ করুন'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In bn, this message translates to:
  /// **'নিশ্চিত করুন'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলুন'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In bn, this message translates to:
  /// **'এডিট করুন'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করুন'**
  String get close;

  /// No description provided for @done.
  ///
  /// In bn, this message translates to:
  /// **'হয়ে গেছে'**
  String get done;

  /// No description provided for @next.
  ///
  /// In bn, this message translates to:
  /// **'পরের ধাপ'**
  String get next;

  /// No description provided for @back.
  ///
  /// In bn, this message translates to:
  /// **'পেছনে'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In bn, this message translates to:
  /// **'লোড হচ্ছে'**
  String get loading;

  /// No description provided for @navToday.
  ///
  /// In bn, this message translates to:
  /// **'আজ'**
  String get navToday;

  /// No description provided for @navMeals.
  ///
  /// In bn, this message translates to:
  /// **'মিল'**
  String get navMeals;

  /// No description provided for @navMoney.
  ///
  /// In bn, this message translates to:
  /// **'হিসাব'**
  String get navMoney;

  /// No description provided for @navMore.
  ///
  /// In bn, this message translates to:
  /// **'আরও'**
  String get navMore;

  /// No description provided for @syncSynced.
  ///
  /// In bn, this message translates to:
  /// **'সেভ হয়েছে'**
  String get syncSynced;

  /// No description provided for @syncSyncing.
  ///
  /// In bn, this message translates to:
  /// **'সিঙ্ক হচ্ছে'**
  String get syncSyncing;

  /// No description provided for @syncOffline.
  ///
  /// In bn, this message translates to:
  /// **'অফলাইনে সেভ হয়েছে'**
  String get syncOffline;

  /// No description provided for @syncFailed.
  ///
  /// In bn, this message translates to:
  /// **'সিঙ্ক হয়নি'**
  String get syncFailed;

  /// No description provided for @genericError.
  ///
  /// In bn, this message translates to:
  /// **'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।'**
  String get genericError;

  /// No description provided for @networkError.
  ///
  /// In bn, this message translates to:
  /// **'ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না। নেট চালু করে আবার চেষ্টা করুন।'**
  String get networkError;

  /// No description provided for @emptyGeneric.
  ///
  /// In bn, this message translates to:
  /// **'এখানে এখনো কিছু নেই'**
  String get emptyGeneric;

  /// No description provided for @authPhoneTitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার ফোন নম্বর দিন'**
  String get authPhoneTitle;

  /// No description provided for @authPhoneHint.
  ///
  /// In bn, this message translates to:
  /// **'এই নম্বরে একটা ৬ সংখ্যার কোড পাঠাব'**
  String get authPhoneHint;

  /// No description provided for @authPhoneLabel.
  ///
  /// In bn, this message translates to:
  /// **'ফোন নম্বর'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক মোবাইল নম্বর দিন, যেমন ০১৭১২৩৪৫৬৭৮'**
  String get authPhoneInvalid;

  /// No description provided for @authSendCode.
  ///
  /// In bn, this message translates to:
  /// **'কোড পাঠান'**
  String get authSendCode;

  /// No description provided for @authCodeTitle.
  ///
  /// In bn, this message translates to:
  /// **'৬ সংখ্যার কোড দিন'**
  String get authCodeTitle;

  /// No description provided for @authCodeSentTo.
  ///
  /// In bn, this message translates to:
  /// **'{phone} নম্বরে কোড পাঠানো হয়েছে'**
  String authCodeSentTo(String phone);

  /// No description provided for @authCodeLabel.
  ///
  /// In bn, this message translates to:
  /// **'কোড'**
  String get authCodeLabel;

  /// No description provided for @authVerify.
  ///
  /// In bn, this message translates to:
  /// **'ঢুকে পড়ুন'**
  String get authVerify;

  /// No description provided for @authResend.
  ///
  /// In bn, this message translates to:
  /// **'আবার কোড পাঠান'**
  String get authResend;

  /// No description provided for @authResendIn.
  ///
  /// In bn, this message translates to:
  /// **'{seconds} সেকেন্ড পরে আবার কোড পাঠাতে পারবেন'**
  String authResendIn(int seconds);

  /// No description provided for @authChangeNumber.
  ///
  /// In bn, this message translates to:
  /// **'নম্বর বদলান'**
  String get authChangeNumber;

  /// No description provided for @authProfileTitle.
  ///
  /// In bn, this message translates to:
  /// **'আপনার নাম কী?'**
  String get authProfileTitle;

  /// No description provided for @authProfileHint.
  ///
  /// In bn, this message translates to:
  /// **'মেসের সবাই এই নামে আপনাকে চিনবে'**
  String get authProfileHint;

  /// No description provided for @authNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'আপনার নাম'**
  String get authNameLabel;

  /// No description provided for @authNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'নামটা লিখুন'**
  String get authNameRequired;

  /// No description provided for @authLanguageLabel.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপের ভাষা'**
  String get authLanguageLabel;

  /// No description provided for @authProfileSave.
  ///
  /// In bn, this message translates to:
  /// **'চালিয়ে যান'**
  String get authProfileSave;

  /// No description provided for @shellComingSoon.
  ///
  /// In bn, this message translates to:
  /// **'শিগগিরই আসছে, পরের আপডেটে'**
  String get shellComingSoon;

  /// No description provided for @failureNotAuthenticated.
  ///
  /// In bn, this message translates to:
  /// **'আবার লগইন করতে হবে'**
  String get failureNotAuthenticated;

  /// No description provided for @failureNotManager.
  ///
  /// In bn, this message translates to:
  /// **'এটা শুধু ম্যানেজার করতে পারেন'**
  String get failureNotManager;

  /// No description provided for @failureInvalidInvite.
  ///
  /// In bn, this message translates to:
  /// **'এই কোডটা কাজ করছে না। ম্যানেজারের কাছে নতুন কোড চান।'**
  String get failureInvalidInvite;

  /// No description provided for @failureAlreadyMember.
  ///
  /// In bn, this message translates to:
  /// **'আপনি আগে থেকেই এই মেসে আছেন'**
  String get failureAlreadyMember;

  /// No description provided for @failureLastManager.
  ///
  /// In bn, this message translates to:
  /// **'মেসে অন্তত একজন ম্যানেজার থাকতে হবে'**
  String get failureLastManager;

  /// No description provided for @failureMonthClosed.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের হিসাব বন্ধ হয়ে গেছে, আর বদলানো যাবে না'**
  String get failureMonthClosed;

  /// No description provided for @failureInvalidOtp.
  ///
  /// In bn, this message translates to:
  /// **'কোডটা মেলেনি। আবার দেখে লিখুন।'**
  String get failureInvalidOtp;

  /// No description provided for @failureRateLimited.
  ///
  /// In bn, this message translates to:
  /// **'অনেকবার চেষ্টা হয়েছে। একটু পরে আবার চেষ্টা করুন।'**
  String get failureRateLimited;

  /// No description provided for @failureValidation.
  ///
  /// In bn, this message translates to:
  /// **'কিছু তথ্য ঠিক নেই। দেখে আবার দিন।'**
  String get failureValidation;

  /// No description provided for @configMissingTitle.
  ///
  /// In bn, this message translates to:
  /// **'সুপাবেস কনফিগ পাওয়া যায়নি'**
  String get configMissingTitle;

  /// No description provided for @configMissingBody.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ চালানোর সময় --dart-define দিয়ে SUPABASE_URL আর SUPABASE_ANON_KEY দিন।'**
  String get configMissingBody;

  /// No description provided for @messOnboardingTitle.
  ///
  /// In bn, this message translates to:
  /// **'শুরু করতে একটা মেস লাগবে'**
  String get messOnboardingTitle;

  /// No description provided for @messOnboardingBody.
  ///
  /// In bn, this message translates to:
  /// **'নিজে ম্যানেজার হলে নতুন মেস খুলুন। মেস আগে থেকে থাকলে ম্যানেজারের কাছ থেকে কোড নিয়ে যোগ দিন।'**
  String get messOnboardingBody;

  /// No description provided for @messCreateAction.
  ///
  /// In bn, this message translates to:
  /// **'নতুন মেস খুলুন'**
  String get messCreateAction;

  /// No description provided for @messJoinAction.
  ///
  /// In bn, this message translates to:
  /// **'কোড দিয়ে যোগ দিন'**
  String get messJoinAction;

  /// No description provided for @messCreateTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন মেস'**
  String get messCreateTitle;

  /// No description provided for @messNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'মেসের নাম'**
  String get messNameLabel;

  /// No description provided for @messNameHint.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: মিরপুর ১০ ব্যাচেলর মেস'**
  String get messNameHint;

  /// No description provided for @messNameRequired.
  ///
  /// In bn, this message translates to:
  /// **'নামটা লিখুন'**
  String get messNameRequired;

  /// No description provided for @messYourNameLabel.
  ///
  /// In bn, this message translates to:
  /// **'মেসে আপনার নাম'**
  String get messYourNameLabel;

  /// No description provided for @messYourNameHelp.
  ///
  /// In bn, this message translates to:
  /// **'মেসের সবাই আপনাকে এই নামে দেখবে'**
  String get messYourNameHelp;

  /// No description provided for @messMonthStartLabel.
  ///
  /// In bn, this message translates to:
  /// **'মাস শুরু হয় যে তারিখে'**
  String get messMonthStartLabel;

  /// No description provided for @messMonthStartHelp.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি মাসের এই তারিখ থেকে পরের মাসের একই তারিখ পর্যন্ত এক মাসের হিসাব'**
  String get messMonthStartHelp;

  /// No description provided for @messMonthStartDay.
  ///
  /// In bn, this message translates to:
  /// **'{day} তারিখ'**
  String messMonthStartDay(String day);

  /// No description provided for @messCreateSubmit.
  ///
  /// In bn, this message translates to:
  /// **'মেস খুলুন'**
  String get messCreateSubmit;

  /// No description provided for @messJoinTitle.
  ///
  /// In bn, this message translates to:
  /// **'মেসে যোগ দিন'**
  String get messJoinTitle;

  /// No description provided for @messCodeLabel.
  ///
  /// In bn, this message translates to:
  /// **'ইনভাইট কোড'**
  String get messCodeLabel;

  /// No description provided for @messCodeHelp.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজারের কাছ থেকে ৬ অক্ষরের কোডটা নিন'**
  String get messCodeHelp;

  /// No description provided for @messCodeInvalid.
  ///
  /// In bn, this message translates to:
  /// **'কোডটা ৬ অক্ষরের হতে হবে'**
  String get messCodeInvalid;

  /// No description provided for @messScanQr.
  ///
  /// In bn, this message translates to:
  /// **'QR স্ক্যান করুন'**
  String get messScanQr;

  /// No description provided for @messScanTitle.
  ///
  /// In bn, this message translates to:
  /// **'QR কোড স্ক্যান করুন'**
  String get messScanTitle;

  /// No description provided for @messScanHint.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজারের ফোনের QR কোডটা ফ্রেমের মধ্যে ধরুন'**
  String get messScanHint;

  /// No description provided for @messJoinSubmit.
  ///
  /// In bn, this message translates to:
  /// **'যোগ দেওয়ার অনুরোধ পাঠান'**
  String get messJoinSubmit;

  /// No description provided for @messPendingTitle.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদনের অপেক্ষায়'**
  String get messPendingTitle;

  /// No description provided for @messPendingBody.
  ///
  /// In bn, this message translates to:
  /// **'{mess}-এর ম্যানেজার আপনার অনুরোধ অনুমোদন করলেই মেসের হিসাব দেখতে পাবেন।'**
  String messPendingBody(String mess);

  /// No description provided for @messPendingBodyNoName.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার আপনার অনুরোধ অনুমোদন করলেই মেসের হিসাব দেখতে পাবেন।'**
  String get messPendingBodyNoName;

  /// No description provided for @messPendingRefresh.
  ///
  /// In bn, this message translates to:
  /// **'আবার দেখুন'**
  String get messPendingRefresh;

  /// No description provided for @messPendingStill.
  ///
  /// In bn, this message translates to:
  /// **'এখনো অনুমোদন হয়নি'**
  String get messPendingStill;

  /// No description provided for @messPendingJoinOther.
  ///
  /// In bn, this message translates to:
  /// **'অন্য মেসে যোগ দিন'**
  String get messPendingJoinOther;

  /// No description provided for @moreTitle.
  ///
  /// In bn, this message translates to:
  /// **'আরও'**
  String get moreTitle;

  /// No description provided for @moreMembers.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যরা'**
  String get moreMembers;

  /// No description provided for @moreInvite.
  ///
  /// In bn, this message translates to:
  /// **'নতুন সদস্য ডাকুন'**
  String get moreInvite;

  /// No description provided for @moreSettings.
  ///
  /// In bn, this message translates to:
  /// **'মেসের সেটিংস'**
  String get moreSettings;

  /// No description provided for @moreSwitchMess.
  ///
  /// In bn, this message translates to:
  /// **'অন্য মেস দেখুন'**
  String get moreSwitchMess;

  /// No description provided for @moreRoleManager.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার'**
  String get moreRoleManager;

  /// No description provided for @moreRoleMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get moreRoleMember;

  /// No description provided for @moreSignOut.
  ///
  /// In bn, this message translates to:
  /// **'সাইন আউট'**
  String get moreSignOut;

  /// No description provided for @moreSignOutConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'সাইন আউট করবেন?'**
  String get moreSignOutConfirmTitle;

  /// No description provided for @moreSignOutConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'আবার ঢুকতে ফোন নম্বরে কোড লাগবে। মেসের হিসাব সব থেকে যাবে।'**
  String get moreSignOutConfirmBody;

  /// No description provided for @membersTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যরা'**
  String get membersTitle;

  /// No description provided for @membersPending.
  ///
  /// In bn, this message translates to:
  /// **'যোগ দিতে চায়'**
  String get membersPending;

  /// No description provided for @membersActive.
  ///
  /// In bn, this message translates to:
  /// **'আছেন'**
  String get membersActive;

  /// No description provided for @membersInactive.
  ///
  /// In bn, this message translates to:
  /// **'নিষ্ক্রিয়'**
  String get membersInactive;

  /// No description provided for @membersLeft.
  ///
  /// In bn, this message translates to:
  /// **'চলে গেছেন'**
  String get membersLeft;

  /// No description provided for @membersRoleManager.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার'**
  String get membersRoleManager;

  /// No description provided for @membersNoApp.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ নেই'**
  String get membersNoApp;

  /// No description provided for @membersYou.
  ///
  /// In bn, this message translates to:
  /// **'(আপনি)'**
  String get membersYou;

  /// No description provided for @membersRoom.
  ///
  /// In bn, this message translates to:
  /// **'রুম {room}'**
  String membersRoom(String room);

  /// No description provided for @membersLeftOn.
  ///
  /// In bn, this message translates to:
  /// **'{date} থেকে নেই'**
  String membersLeftOn(String date);

  /// No description provided for @membersEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো সদস্য নেই। কোড দিয়ে সবাইকে ডাকুন।'**
  String get membersEmpty;

  /// No description provided for @membersApprove.
  ///
  /// In bn, this message translates to:
  /// **'অনুমোদন দিন'**
  String get membersApprove;

  /// No description provided for @membersApproved.
  ///
  /// In bn, this message translates to:
  /// **'{name} এখন মেসের সদস্য'**
  String membersApproved(String name);

  /// No description provided for @membersReject.
  ///
  /// In bn, this message translates to:
  /// **'বাদ দিন'**
  String get membersReject;

  /// No description provided for @membersRejected.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধটা বাদ দেওয়া হয়েছে'**
  String get membersRejected;

  /// No description provided for @membersRejectConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর অনুরোধ বাদ দেবেন?'**
  String membersRejectConfirmTitle(String name);

  /// No description provided for @membersRejectConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'চাইলে তিনি পরে আবার কোড দিয়ে অনুরোধ পাঠাতে পারবেন।'**
  String get membersRejectConfirmBody;

  /// No description provided for @membersMakeManager.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার বানান'**
  String get membersMakeManager;

  /// No description provided for @membersMakeMember.
  ///
  /// In bn, this message translates to:
  /// **'সাধারণ সদস্য বানান'**
  String get membersMakeMember;

  /// No description provided for @membersMarkInactive.
  ///
  /// In bn, this message translates to:
  /// **'নিষ্ক্রিয় করুন'**
  String get membersMarkInactive;

  /// No description provided for @membersInactiveHelp.
  ///
  /// In bn, this message translates to:
  /// **'মিলের তালিকায় দেখাবে না, টাকার হিসাব আগের মতোই চলবে'**
  String get membersInactiveHelp;

  /// No description provided for @membersMarkActive.
  ///
  /// In bn, this message translates to:
  /// **'আবার সক্রিয় করুন'**
  String get membersMarkActive;

  /// No description provided for @membersMarkLeft.
  ///
  /// In bn, this message translates to:
  /// **'মেস ছেড়ে দিয়েছেন'**
  String get membersMarkLeft;

  /// No description provided for @membersLeftConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'{name} কি মেস ছেড়ে দিয়েছেন?'**
  String membersLeftConfirmTitle(String name);

  /// No description provided for @membersLeftConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'আজ থেকে তাকে আর নতুন হিসাবে ধরা হবে না। আগের মিল, বাজার আর জমার সব হিসাব যেমন আছে তেমনই থাকবে।'**
  String get membersLeftConfirmBody;

  /// No description provided for @membersLeftConfirmAction.
  ///
  /// In bn, this message translates to:
  /// **'হ্যাঁ, ছেড়েছেন'**
  String get membersLeftConfirmAction;

  /// No description provided for @membersSaved.
  ///
  /// In bn, this message translates to:
  /// **'পরিবর্তন সেভ হয়েছে'**
  String get membersSaved;

  /// No description provided for @membersAdd.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য যোগ করুন'**
  String get membersAdd;

  /// No description provided for @membersAddHelp.
  ///
  /// In bn, this message translates to:
  /// **'যার ফোনে অ্যাপ নেই, তার মিল আর জমা আপনি লিখে দেবেন।'**
  String get membersAddHelp;

  /// No description provided for @membersAddName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get membersAddName;

  /// No description provided for @membersAddRoom.
  ///
  /// In bn, this message translates to:
  /// **'রুম (না দিলেও চলবে)'**
  String get membersAddRoom;

  /// No description provided for @membersAddSubmit.
  ///
  /// In bn, this message translates to:
  /// **'যোগ করুন'**
  String get membersAddSubmit;

  /// No description provided for @membersAdded.
  ///
  /// In bn, this message translates to:
  /// **'{name} যোগ হয়েছেন'**
  String membersAdded(String name);

  /// No description provided for @inviteTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন সদস্য ডাকুন'**
  String get inviteTitle;

  /// No description provided for @inviteBody.
  ///
  /// In bn, this message translates to:
  /// **'এই কোডটা দিন, অথবা QR স্ক্যান করতে বলুন। অনুরোধ এলে আপনি অনুমোদন দিলেই সে মেসে ঢুকবে।'**
  String get inviteBody;

  /// No description provided for @inviteValidity.
  ///
  /// In bn, this message translates to:
  /// **'৭ দিন পর্যন্ত বৈধ'**
  String get inviteValidity;

  /// No description provided for @inviteQrLabel.
  ///
  /// In bn, this message translates to:
  /// **'মেসে যোগ দেওয়ার QR কোড'**
  String get inviteQrLabel;

  /// No description provided for @inviteCopy.
  ///
  /// In bn, this message translates to:
  /// **'কোড কপি করুন'**
  String get inviteCopy;

  /// No description provided for @inviteCopied.
  ///
  /// In bn, this message translates to:
  /// **'কোড কপি হয়েছে'**
  String get inviteCopied;

  /// No description provided for @inviteShare.
  ///
  /// In bn, this message translates to:
  /// **'শেয়ার করুন'**
  String get inviteShare;

  /// No description provided for @inviteShareMessage.
  ///
  /// In bn, this message translates to:
  /// **'মিল বাজার অ্যাপে আমাদের মেস \"{mess}\"-এ যোগ দাও।\nকোড: {code}\nলিংক: {link}'**
  String inviteShareMessage(String mess, String code, String link);

  /// No description provided for @inviteRegenerate.
  ///
  /// In bn, this message translates to:
  /// **'নতুন কোড'**
  String get inviteRegenerate;

  /// No description provided for @inviteManagerOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধু ম্যানেজার নতুন সদস্য ডাকতে পারেন'**
  String get inviteManagerOnly;

  /// No description provided for @settingsTitle.
  ///
  /// In bn, this message translates to:
  /// **'মেসের সেটিংস'**
  String get settingsTitle;

  /// No description provided for @settingsAddress.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা (না দিলেও চলবে)'**
  String get settingsAddress;

  /// No description provided for @settingsCutoff.
  ///
  /// In bn, this message translates to:
  /// **'মিল বন্ধের শেষ সময়'**
  String get settingsCutoff;

  /// No description provided for @settingsCutoffHelp.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যরা আগের দিন এই সময়ের মধ্যে মিল বন্ধ করতে পারবেন'**
  String get settingsCutoffHelp;

  /// No description provided for @settingsSave.
  ///
  /// In bn, this message translates to:
  /// **'সেটিংস সেভ করুন'**
  String get settingsSave;

  /// No description provided for @settingsSaved.
  ///
  /// In bn, this message translates to:
  /// **'সেটিংস সেভ হয়েছে'**
  String get settingsSaved;

  /// No description provided for @settingsManagerOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধু ম্যানেজার সেটিংস বদলাতে পারেন'**
  String get settingsManagerOnly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
