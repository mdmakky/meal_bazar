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

  /// No description provided for @mealCellOff.
  ///
  /// In bn, this message translates to:
  /// **'অফ'**
  String get mealCellOff;

  /// No description provided for @mealCellGuests.
  ///
  /// In bn, this message translates to:
  /// **'{count} জন অতিথি'**
  String mealCellGuests(String count);

  /// No description provided for @mealCellOwn.
  ///
  /// In bn, this message translates to:
  /// **'নিজের মিল'**
  String get mealCellOwn;

  /// No description provided for @mealCellGuestsLabel.
  ///
  /// In bn, this message translates to:
  /// **'অতিথি'**
  String get mealCellGuestsLabel;

  /// No description provided for @mealCellSave.
  ///
  /// In bn, this message translates to:
  /// **'মিল সেভ করুন'**
  String get mealCellSave;

  /// No description provided for @mealCellDecrease.
  ///
  /// In bn, this message translates to:
  /// **'কমান'**
  String get mealCellDecrease;

  /// No description provided for @mealCellIncrease.
  ///
  /// In bn, this message translates to:
  /// **'বাড়ান'**
  String get mealCellIncrease;

  /// No description provided for @todayPrevDay.
  ///
  /// In bn, this message translates to:
  /// **'আগের দিন'**
  String get todayPrevDay;

  /// No description provided for @todayNextDay.
  ///
  /// In bn, this message translates to:
  /// **'পরের দিন'**
  String get todayNextDay;

  /// No description provided for @todayBackToToday.
  ///
  /// In bn, this message translates to:
  /// **'আজকে ফিরুন'**
  String get todayBackToToday;

  /// No description provided for @todayIsToday.
  ///
  /// In bn, this message translates to:
  /// **'আজ'**
  String get todayIsToday;

  /// No description provided for @todayHeadcountLabel.
  ///
  /// In bn, this message translates to:
  /// **'আজ মোট মিল'**
  String get todayHeadcountLabel;

  /// No description provided for @todayDayHeadcountLabel.
  ///
  /// In bn, this message translates to:
  /// **'এই দিনের মোট মিল'**
  String get todayDayHeadcountLabel;

  /// No description provided for @todayGuestsProof.
  ///
  /// In bn, this message translates to:
  /// **'অতিথি {count}'**
  String todayGuestsProof(String count);

  /// No description provided for @todayRateLabel.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের মিল রেট'**
  String get todayRateLabel;

  /// No description provided for @todayRateProof.
  ///
  /// In bn, this message translates to:
  /// **'{food} ÷ {meals} মিল'**
  String todayRateProof(String food, String meals);

  /// No description provided for @todayRateUnallocated.
  ///
  /// In bn, this message translates to:
  /// **'{food} খরচ হয়েছে, কিন্তু এখনো কোনো মিল নেই। মিল বসালে রেট আসবে।'**
  String todayRateUnallocated(String food);

  /// No description provided for @todayNoEntries.
  ///
  /// In bn, this message translates to:
  /// **'এই দিনের মিল এখনো বসানো হয়নি'**
  String get todayNoEntries;

  /// No description provided for @todayNoEntriesMember.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার এখনো এই দিনের মিল বসাননি'**
  String get todayNoEntriesMember;

  /// No description provided for @todayFillHelp.
  ///
  /// In bn, this message translates to:
  /// **'সব সদস্যের মিল গতকালের মতো বসবে, না থাকলে ১টা করে। পরে ট্যাপ করে বদলাবেন।'**
  String get todayFillHelp;

  /// No description provided for @todayFill.
  ///
  /// In bn, this message translates to:
  /// **'আজকের মিল বসান'**
  String get todayFill;

  /// No description provided for @todayFillDay.
  ///
  /// In bn, this message translates to:
  /// **'এই দিনের মিল বসান'**
  String get todayFillDay;

  /// No description provided for @todayNoMembers.
  ///
  /// In bn, this message translates to:
  /// **'মেসে এখনো কোনো সদস্য নেই'**
  String get todayNoMembers;

  /// No description provided for @todayNoMealTypes.
  ///
  /// In bn, this message translates to:
  /// **'কোনো বেলার মিল চালু নেই'**
  String get todayNoMealTypes;

  /// No description provided for @todayNoMealTypesAction.
  ///
  /// In bn, this message translates to:
  /// **'মিলের ধরন ঠিক করুন'**
  String get todayNoMealTypesAction;

  /// No description provided for @todayMemberColumn.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get todayMemberColumn;

  /// No description provided for @todayActionBazar.
  ///
  /// In bn, this message translates to:
  /// **'বাজার'**
  String get todayActionBazar;

  /// No description provided for @todayActionExpense.
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get todayActionExpense;

  /// No description provided for @todayActionDeposit.
  ///
  /// In bn, this message translates to:
  /// **'জমা'**
  String get todayActionDeposit;

  /// No description provided for @todayActionGuest.
  ///
  /// In bn, this message translates to:
  /// **'অতিথি'**
  String get todayActionGuest;

  /// No description provided for @todayActionMealOff.
  ///
  /// In bn, this message translates to:
  /// **'মিল অফ'**
  String get todayActionMealOff;

  /// No description provided for @todayPickMember.
  ///
  /// In bn, this message translates to:
  /// **'কার জন্য?'**
  String get todayPickMember;

  /// No description provided for @todayPickMealType.
  ///
  /// In bn, this message translates to:
  /// **'কোন বেলার মিল?'**
  String get todayPickMealType;

  /// No description provided for @todayMealOffDone.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর {meal} অফ করা হলো'**
  String todayMealOffDone(String name, String meal);

  /// No description provided for @mealsTitle.
  ///
  /// In bn, this message translates to:
  /// **'মিল'**
  String get mealsTitle;

  /// No description provided for @mealsTotalLabel.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের মোট মিল'**
  String get mealsTotalLabel;

  /// No description provided for @mealsPeriod.
  ///
  /// In bn, this message translates to:
  /// **'{from} থেকে {to}'**
  String mealsPeriod(String from, String to);

  /// No description provided for @mealsByMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের মিল'**
  String get mealsByMember;

  /// No description provided for @mealsGuestNote.
  ///
  /// In bn, this message translates to:
  /// **'অতিথির {count} মিল সহ'**
  String mealsGuestNote(String count);

  /// No description provided for @mealsEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে এখনো কোনো মিল নেই'**
  String get mealsEmpty;

  /// No description provided for @mealsMemberEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে {name}-এর কোনো মিল নেই'**
  String mealsMemberEmpty(String name);

  /// No description provided for @mealsMemberTotal.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে মোট {count} মিল'**
  String mealsMemberTotal(String count);

  /// No description provided for @mealTypesTitle.
  ///
  /// In bn, this message translates to:
  /// **'মিলের ধরন'**
  String get mealTypesTitle;

  /// No description provided for @mealTypesHelp.
  ///
  /// In bn, this message translates to:
  /// **'ওজন মানে এক বেলায় কত মিল ধরা হবে। যেমন সকালের নাশতা ×০.৫।'**
  String get mealTypesHelp;

  /// No description provided for @mealTypesAdd.
  ///
  /// In bn, this message translates to:
  /// **'নতুন বেলা যোগ করুন'**
  String get mealTypesAdd;

  /// No description provided for @mealTypesName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get mealTypesName;

  /// No description provided for @mealTypesNameHint.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: বিকেলের নাশতা'**
  String get mealTypesNameHint;

  /// No description provided for @mealTypesNameInvalid.
  ///
  /// In bn, this message translates to:
  /// **'১ থেকে ৩০ অক্ষরের মধ্যে নাম দিন'**
  String get mealTypesNameInvalid;

  /// No description provided for @mealTypesRename.
  ///
  /// In bn, this message translates to:
  /// **'নাম বদলান'**
  String get mealTypesRename;

  /// No description provided for @mealTypesWeight.
  ///
  /// In bn, this message translates to:
  /// **'ওজন'**
  String get mealTypesWeight;

  /// No description provided for @mealTypesEnabled.
  ///
  /// In bn, this message translates to:
  /// **'{name} চালু'**
  String mealTypesEnabled(String name);

  /// No description provided for @mealTypesEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো মিলের ধরন নেই'**
  String get mealTypesEmpty;

  /// No description provided for @mealTypesManagerOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধু ম্যানেজার মিলের ধরন বদলাতে পারেন'**
  String get mealTypesManagerOnly;

  /// No description provided for @moneyFoodTotal.
  ///
  /// In bn, this message translates to:
  /// **'খাবার খরচ'**
  String get moneyFoodTotal;

  /// No description provided for @moneyFoodProof.
  ///
  /// In bn, this message translates to:
  /// **'বাজার আর মিলে ভাগ হওয়া খরচ মিলিয়ে'**
  String get moneyFoodProof;

  /// No description provided for @moneyMealRate.
  ///
  /// In bn, this message translates to:
  /// **'মিল রেট'**
  String get moneyMealRate;

  /// No description provided for @moneyMealRateProof.
  ///
  /// In bn, this message translates to:
  /// **'{food} ÷ {meals} মিল'**
  String moneyMealRateProof(String food, String meals);

  /// No description provided for @moneyExtraTotal.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য খরচ'**
  String get moneyExtraTotal;

  /// No description provided for @moneyExtraProof.
  ///
  /// In bn, this message translates to:
  /// **'সবার মধ্যে সমান ভাগে'**
  String get moneyExtraProof;

  /// No description provided for @moneyDepositTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমা'**
  String get moneyDepositTotal;

  /// No description provided for @moneyDepositProof.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই হওয়া জমা মিলিয়ে'**
  String get moneyDepositProof;

  /// No description provided for @moneyNoMealsWarning.
  ///
  /// In bn, this message translates to:
  /// **'খরচ আছে কিন্তু এখনো কোনো মিল নেই, তাই কারো ভাগে ধরা হয়নি'**
  String get moneyNoMealsWarning;

  /// No description provided for @moneyTabMembers.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get moneyTabMembers;

  /// No description provided for @moneyTabBazar.
  ///
  /// In bn, this message translates to:
  /// **'বাজার'**
  String get moneyTabBazar;

  /// No description provided for @moneyTabExpense.
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get moneyTabExpense;

  /// No description provided for @moneyTabDeposit.
  ///
  /// In bn, this message translates to:
  /// **'জমা'**
  String get moneyTabDeposit;

  /// No description provided for @moneyAmount.
  ///
  /// In bn, this message translates to:
  /// **'টাকার পরিমাণ'**
  String get moneyAmount;

  /// No description provided for @moneyAmountInvalid.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক টাকার পরিমাণ লিখুন, যেমন ২৫০ বা ২৫০.৫০'**
  String get moneyAmountInvalid;

  /// No description provided for @moneyChangeDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ বদলান'**
  String get moneyChangeDate;

  /// No description provided for @moneyPaidFrom.
  ///
  /// In bn, this message translates to:
  /// **'টাকা গেছে'**
  String get moneyPaidFrom;

  /// No description provided for @moneyPaidFund.
  ///
  /// In bn, this message translates to:
  /// **'মেস ফান্ড'**
  String get moneyPaidFund;

  /// No description provided for @moneyPaidPocket.
  ///
  /// In bn, this message translates to:
  /// **'নিজের পকেট'**
  String get moneyPaidPocket;

  /// No description provided for @moneyPaidPocketHelp.
  ///
  /// In bn, this message translates to:
  /// **'যে দিয়েছে তার জমায় যোগ হবে'**
  String get moneyPaidPocketHelp;

  /// No description provided for @moneyPickMember.
  ///
  /// In bn, this message translates to:
  /// **'একজন সদস্য বেছে নিন'**
  String get moneyPickMember;

  /// No description provided for @moneyNote.
  ///
  /// In bn, this message translates to:
  /// **'নোট (না দিলেও চলবে)'**
  String get moneyNote;

  /// No description provided for @moneySave.
  ///
  /// In bn, this message translates to:
  /// **'সেভ করুন'**
  String get moneySave;

  /// No description provided for @moneySaved.
  ///
  /// In bn, this message translates to:
  /// **'সেভ হয়েছে'**
  String get moneySaved;

  /// No description provided for @moneyDeleted.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলা হয়েছে'**
  String get moneyDeleted;

  /// No description provided for @moneyDeleteConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'এটা মুছে ফেলবেন?'**
  String get moneyDeleteConfirmTitle;

  /// No description provided for @moneyDeleteConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেললে এই মাসের হিসাব থেকে বাদ যাবে।'**
  String get moneyDeleteConfirmBody;

  /// No description provided for @moneyLoadMore.
  ///
  /// In bn, this message translates to:
  /// **'আরও দেখুন'**
  String get moneyLoadMore;

  /// No description provided for @moneyNoMess.
  ///
  /// In bn, this message translates to:
  /// **'আগে একটা মেসে যোগ দিন'**
  String get moneyNoMess;

  /// No description provided for @bazarAdd.
  ///
  /// In bn, this message translates to:
  /// **'বাজার যোগ করুন'**
  String get bazarAdd;

  /// No description provided for @bazarEdit.
  ///
  /// In bn, this message translates to:
  /// **'বাজার এডিট করুন'**
  String get bazarEdit;

  /// No description provided for @bazarTitle.
  ///
  /// In bn, this message translates to:
  /// **'বাজার'**
  String get bazarTitle;

  /// No description provided for @bazarBuyer.
  ///
  /// In bn, this message translates to:
  /// **'কে বাজার করেছে'**
  String get bazarBuyer;

  /// No description provided for @bazarItems.
  ///
  /// In bn, this message translates to:
  /// **'আইটেম (না দিলেও চলবে)'**
  String get bazarItems;

  /// No description provided for @bazarAddItem.
  ///
  /// In bn, this message translates to:
  /// **'আইটেম যোগ করুন'**
  String get bazarAddItem;

  /// No description provided for @bazarRemoveItem.
  ///
  /// In bn, this message translates to:
  /// **'আইটেম বাদ দিন'**
  String get bazarRemoveItem;

  /// No description provided for @bazarItemName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get bazarItemName;

  /// No description provided for @bazarItemQty.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get bazarItemQty;

  /// No description provided for @bazarItemUnit.
  ///
  /// In bn, this message translates to:
  /// **'একক'**
  String get bazarItemUnit;

  /// No description provided for @bazarItemPrice.
  ///
  /// In bn, this message translates to:
  /// **'দাম'**
  String get bazarItemPrice;

  /// No description provided for @bazarItemInvalid.
  ///
  /// In bn, this message translates to:
  /// **'নাম আর দাম দুটোই লিখুন'**
  String get bazarItemInvalid;

  /// No description provided for @bazarItemsSum.
  ///
  /// In bn, this message translates to:
  /// **'আইটেমের যোগফল {sum}'**
  String bazarItemsSum(String sum);

  /// No description provided for @bazarUseSum.
  ///
  /// In bn, this message translates to:
  /// **'এটাই বসান'**
  String get bazarUseSum;

  /// No description provided for @bazarItemCount.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি আইটেম'**
  String bazarItemCount(String count);

  /// No description provided for @bazarEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে এখনো কোনো বাজার নেই'**
  String get bazarEmpty;

  /// No description provided for @bazarShare.
  ///
  /// In bn, this message translates to:
  /// **'শেয়ার করুন'**
  String get bazarShare;

  /// No description provided for @bazarShareHeader.
  ///
  /// In bn, this message translates to:
  /// **'বাজারের হিসাব · {date}'**
  String bazarShareHeader(String date);

  /// No description provided for @bazarShareBuyer.
  ///
  /// In bn, this message translates to:
  /// **'বাজার করেছে: {name}'**
  String bazarShareBuyer(String name);

  /// No description provided for @bazarShareTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট: {total}'**
  String bazarShareTotal(String total);

  /// No description provided for @expenseAdd.
  ///
  /// In bn, this message translates to:
  /// **'খরচ যোগ করুন'**
  String get expenseAdd;

  /// No description provided for @expenseEdit.
  ///
  /// In bn, this message translates to:
  /// **'খরচ এডিট করুন'**
  String get expenseEdit;

  /// No description provided for @expenseCategory.
  ///
  /// In bn, this message translates to:
  /// **'কিসের খরচ'**
  String get expenseCategory;

  /// No description provided for @expensePickCategory.
  ///
  /// In bn, this message translates to:
  /// **'কিসের খরচ সেটা বেছে নিন'**
  String get expensePickCategory;

  /// No description provided for @expenseSplit.
  ///
  /// In bn, this message translates to:
  /// **'কীভাবে ভাগ হবে'**
  String get expenseSplit;

  /// No description provided for @expenseSplitMeal.
  ///
  /// In bn, this message translates to:
  /// **'মিল'**
  String get expenseSplitMeal;

  /// No description provided for @expenseSplitEqual.
  ///
  /// In bn, this message translates to:
  /// **'সমান'**
  String get expenseSplitEqual;

  /// No description provided for @expenseSplitMealHelp.
  ///
  /// In bn, this message translates to:
  /// **'মিল রেটে যোগ হবে, যে যত মিল খেয়েছে সে তত দেবে'**
  String get expenseSplitMealHelp;

  /// No description provided for @expenseSplitEqualHelp.
  ///
  /// In bn, this message translates to:
  /// **'সেদিন মেসে থাকা সবার মধ্যে সমান ভাগ হবে'**
  String get expenseSplitEqualHelp;

  /// No description provided for @expenseEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে এখনো কোনো খরচ নেই'**
  String get expenseEmpty;

  /// No description provided for @depositAdd.
  ///
  /// In bn, this message translates to:
  /// **'জমা যোগ করুন'**
  String get depositAdd;

  /// No description provided for @depositEdit.
  ///
  /// In bn, this message translates to:
  /// **'জমা এডিট করুন'**
  String get depositEdit;

  /// No description provided for @depositMember.
  ///
  /// In bn, this message translates to:
  /// **'কে জমা দিয়েছে'**
  String get depositMember;

  /// No description provided for @depositMethod.
  ///
  /// In bn, this message translates to:
  /// **'কীভাবে দিয়েছে'**
  String get depositMethod;

  /// No description provided for @depositCash.
  ///
  /// In bn, this message translates to:
  /// **'ক্যাশ'**
  String get depositCash;

  /// No description provided for @depositBkash.
  ///
  /// In bn, this message translates to:
  /// **'বিকাশ'**
  String get depositBkash;

  /// No description provided for @depositNagad.
  ///
  /// In bn, this message translates to:
  /// **'নগদ'**
  String get depositNagad;

  /// No description provided for @depositBank.
  ///
  /// In bn, this message translates to:
  /// **'ব্যাংক'**
  String get depositBank;

  /// No description provided for @depositOther.
  ///
  /// In bn, this message translates to:
  /// **'অন্যভাবে'**
  String get depositOther;

  /// No description provided for @depositTrxId.
  ///
  /// In bn, this message translates to:
  /// **'TrxID (না দিলেও চলবে)'**
  String get depositTrxId;

  /// No description provided for @depositAmountPositive.
  ///
  /// In bn, this message translates to:
  /// **'জমা ০ টাকার বেশি হতে হবে'**
  String get depositAmountPositive;

  /// No description provided for @depositPending.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই বাকি'**
  String get depositPending;

  /// No description provided for @depositRejected.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get depositRejected;

  /// No description provided for @depositEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে এখনো কোনো জমা নেই'**
  String get depositEmpty;

  /// No description provided for @balanceDue.
  ///
  /// In bn, this message translates to:
  /// **'বাকি'**
  String get balanceDue;

  /// No description provided for @balanceAdvance.
  ///
  /// In bn, this message translates to:
  /// **'অগ্রিম'**
  String get balanceAdvance;

  /// No description provided for @balanceSettled.
  ///
  /// In bn, this message translates to:
  /// **'মিটে গেছে'**
  String get balanceSettled;

  /// No description provided for @balanceMeals.
  ///
  /// In bn, this message translates to:
  /// **'{meals} মিল'**
  String balanceMeals(String meals);

  /// No description provided for @balanceEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে এখনো কারো হিসাব নেই'**
  String get balanceEmpty;

  /// No description provided for @balanceExplainTitle.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর হিসাব'**
  String balanceExplainTitle(String name);

  /// No description provided for @balanceOpening.
  ///
  /// In bn, this message translates to:
  /// **'আগের মাস থেকে'**
  String get balanceOpening;

  /// No description provided for @balanceCredit.
  ///
  /// In bn, this message translates to:
  /// **'জমা আর নিজের পকেট থেকে খরচ'**
  String get balanceCredit;

  /// No description provided for @balanceFood.
  ///
  /// In bn, this message translates to:
  /// **'খাবার খরচ ({meals} মিল × {rate})'**
  String balanceFood(String meals, String rate);

  /// No description provided for @balanceExtra.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য খরচের ভাগ'**
  String get balanceExtra;

  /// No description provided for @balanceClosing.
  ///
  /// In bn, this message translates to:
  /// **'এখনকার হিসাব'**
  String get balanceClosing;

  /// No description provided for @monthTitle.
  ///
  /// In bn, this message translates to:
  /// **'মাসের হিসাব'**
  String get monthTitle;

  /// No description provided for @monthClose.
  ///
  /// In bn, this message translates to:
  /// **'মাস বন্ধ করুন'**
  String get monthClose;

  /// No description provided for @monthCloseBody.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করলে এই মাসের মিল, বাজার, খরচ আর জমা আর বদলানো যাবে না। সবার শেষ হিসাব পরের মাসে চলে যাবে।'**
  String get monthCloseBody;

  /// No description provided for @monthThis.
  ///
  /// In bn, this message translates to:
  /// **'এই মাস'**
  String get monthThis;

  /// No description provided for @monthPrevious.
  ///
  /// In bn, this message translates to:
  /// **'আগের মাস'**
  String get monthPrevious;

  /// No description provided for @monthRange.
  ///
  /// In bn, this message translates to:
  /// **'{from} – {to}'**
  String monthRange(String from, String to);

  /// No description provided for @monthTotalMeals.
  ///
  /// In bn, this message translates to:
  /// **'মোট মিল'**
  String get monthTotalMeals;

  /// No description provided for @monthClosedDone.
  ///
  /// In bn, this message translates to:
  /// **'মাস বন্ধ হয়েছে'**
  String get monthClosedDone;

  /// No description provided for @monthStatusOpen.
  ///
  /// In bn, this message translates to:
  /// **'খোলা'**
  String get monthStatusOpen;

  /// No description provided for @monthStatusClosed.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ'**
  String get monthStatusClosed;

  /// No description provided for @monthReopen.
  ///
  /// In bn, this message translates to:
  /// **'আবার খুলুন'**
  String get monthReopen;

  /// No description provided for @monthReopenTitle.
  ///
  /// In bn, this message translates to:
  /// **'মাসটা আবার খুলবেন?'**
  String get monthReopenTitle;

  /// No description provided for @monthReopenReason.
  ///
  /// In bn, this message translates to:
  /// **'কেন খুলছেন'**
  String get monthReopenReason;

  /// No description provided for @monthReopenReasonHelp.
  ///
  /// In bn, this message translates to:
  /// **'অন্তত ৫ অক্ষর। মেসের সবাই এটা দেখতে পাবে।'**
  String get monthReopenReasonHelp;

  /// No description provided for @monthReopenReasonShort.
  ///
  /// In bn, this message translates to:
  /// **'কারণটা অন্তত ৫ অক্ষরে লিখুন'**
  String get monthReopenReasonShort;

  /// No description provided for @monthReopened.
  ///
  /// In bn, this message translates to:
  /// **'মাস আবার খোলা হয়েছে'**
  String get monthReopened;

  /// No description provided for @monthNoneClosed.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো মাস বন্ধ হয়নি'**
  String get monthNoneClosed;

  /// No description provided for @monthHistory.
  ///
  /// In bn, this message translates to:
  /// **'আগের মাসগুলো'**
  String get monthHistory;

  /// No description provided for @monthManagerOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধু ম্যানেজার মাস বন্ধ বা খুলতে পারেন'**
  String get monthManagerOnly;

  /// No description provided for @monthPreviousOpen.
  ///
  /// In bn, this message translates to:
  /// **'আগের মাসটা আগে বন্ধ করুন'**
  String get monthPreviousOpen;

  /// No description provided for @monthLaterClosed.
  ///
  /// In bn, this message translates to:
  /// **'পরের মাসটা আগে খুলুন'**
  String get monthLaterClosed;

  /// No description provided for @aiDraftLabel.
  ///
  /// In bn, this message translates to:
  /// **'AI খসড়া'**
  String get aiDraftLabel;

  /// No description provided for @aiMealTitle.
  ///
  /// In bn, this message translates to:
  /// **'এআই দিয়ে মিল লিখুন'**
  String get aiMealTitle;

  /// No description provided for @aiMealHint.
  ///
  /// In bn, this message translates to:
  /// **'আজ রহিম ২, করিম অফ, রাতে গেস্ট ১'**
  String get aiMealHint;

  /// No description provided for @aiSend.
  ///
  /// In bn, this message translates to:
  /// **'পাঠান'**
  String get aiSend;

  /// No description provided for @aiUnavailableDisabled.
  ///
  /// In bn, this message translates to:
  /// **'এআই বন্ধ আছে'**
  String get aiUnavailableDisabled;

  /// No description provided for @aiUnavailableQuota.
  ///
  /// In bn, this message translates to:
  /// **'আজকের এআই সীমা শেষ, হাতে লিখে দিন'**
  String get aiUnavailableQuota;

  /// No description provided for @aiUnavailableProviders.
  ///
  /// In bn, this message translates to:
  /// **'এআই এখন পাওয়া যাচ্ছে না'**
  String get aiUnavailableProviders;

  /// No description provided for @aiEdit.
  ///
  /// In bn, this message translates to:
  /// **'বদলান'**
  String get aiEdit;

  /// No description provided for @aiRemove.
  ///
  /// In bn, this message translates to:
  /// **'বাদ দিন'**
  String get aiRemove;

  /// No description provided for @aiUnmatchedNote.
  ///
  /// In bn, this message translates to:
  /// **'এগুলো বোঝা যায়নি, হাতে লিখে দিন'**
  String get aiUnmatchedNote;

  /// No description provided for @aiReject.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করুন'**
  String get aiReject;

  /// No description provided for @aiConfirmAll.
  ///
  /// In bn, this message translates to:
  /// **'সব নিশ্চিত করুন'**
  String get aiConfirmAll;

  /// No description provided for @aiNoMeals.
  ///
  /// In bn, this message translates to:
  /// **'কোনো মিল পাওয়া যায়নি'**
  String get aiNoMeals;

  /// No description provided for @aiMealsSaved.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি মিল সেভ হয়েছে'**
  String aiMealsSaved(String count);

  /// No description provided for @aiScanTitle.
  ///
  /// In bn, this message translates to:
  /// **'বাজারের রসিদ স্ক্যান'**
  String get aiScanTitle;

  /// No description provided for @aiCamera.
  ///
  /// In bn, this message translates to:
  /// **'ছবি তুলুন'**
  String get aiCamera;

  /// No description provided for @aiGallery.
  ///
  /// In bn, this message translates to:
  /// **'গ্যালারি থেকে নিন'**
  String get aiGallery;

  /// No description provided for @aiNotJpeg.
  ///
  /// In bn, this message translates to:
  /// **'এই ছবিটি পড়া যাচ্ছে না, ক্যামেরা দিয়ে ছবি তুলুন'**
  String get aiNotJpeg;

  /// No description provided for @aiItemName.
  ///
  /// In bn, this message translates to:
  /// **'জিনিস'**
  String get aiItemName;

  /// No description provided for @aiItemPrice.
  ///
  /// In bn, this message translates to:
  /// **'দাম'**
  String get aiItemPrice;

  /// No description provided for @aiNoItems.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ থেকে কোনো জিনিস পড়া যায়নি'**
  String get aiNoItems;

  /// No description provided for @aiTotalMismatch.
  ///
  /// In bn, this message translates to:
  /// **'রসিদের মোট আর জিনিসের যোগফল মিলছে না। কোনটা নেবেন?'**
  String get aiTotalMismatch;

  /// No description provided for @aiReceiptTotal.
  ///
  /// In bn, this message translates to:
  /// **'রসিদের মোট {amount}'**
  String aiReceiptTotal(String amount);

  /// No description provided for @aiItemsSum.
  ///
  /// In bn, this message translates to:
  /// **'জিনিসের যোগফল {amount}'**
  String aiItemsSum(String amount);

  /// No description provided for @aiUseDraft.
  ///
  /// In bn, this message translates to:
  /// **'বাজারে বসান'**
  String get aiUseDraft;

  /// No description provided for @reportTitle.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক রিপোর্ট'**
  String get reportTitle;

  /// No description provided for @reportFoodTotal.
  ///
  /// In bn, this message translates to:
  /// **'খাবারের মোট খরচ'**
  String get reportFoodTotal;

  /// No description provided for @reportTotalMeals.
  ///
  /// In bn, this message translates to:
  /// **'মোট মিল'**
  String get reportTotalMeals;

  /// No description provided for @reportMealRate.
  ///
  /// In bn, this message translates to:
  /// **'মিল রেট'**
  String get reportMealRate;

  /// No description provided for @reportExtraTotal.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য খরচ'**
  String get reportExtraTotal;

  /// No description provided for @reportDeposits.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমা'**
  String get reportDeposits;

  /// No description provided for @reportName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get reportName;

  /// No description provided for @reportMeals.
  ///
  /// In bn, this message translates to:
  /// **'মিল'**
  String get reportMeals;

  /// No description provided for @reportFoodCost.
  ///
  /// In bn, this message translates to:
  /// **'খাবার খরচ'**
  String get reportFoodCost;

  /// No description provided for @reportExtra.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get reportExtra;

  /// No description provided for @reportPaid.
  ///
  /// In bn, this message translates to:
  /// **'জমা'**
  String get reportPaid;

  /// No description provided for @reportBalance.
  ///
  /// In bn, this message translates to:
  /// **'ব্যালেন্স'**
  String get reportBalance;

  /// No description provided for @reportDue.
  ///
  /// In bn, this message translates to:
  /// **'বাকি'**
  String get reportDue;

  /// No description provided for @reportAdvance.
  ///
  /// In bn, this message translates to:
  /// **'অগ্রিম'**
  String get reportAdvance;

  /// No description provided for @reportFormula.
  ///
  /// In bn, this message translates to:
  /// **'মিল রেট = খাবারের মোট খরচ ÷ মোট মিল'**
  String get reportFormula;

  /// No description provided for @reportFooter.
  ///
  /// In bn, this message translates to:
  /// **'Meal Bazar · তৈরি {date}'**
  String reportFooter(String date);

  /// No description provided for @reportNoMembers.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে কোনো সদস্য নেই'**
  String get reportNoMembers;

  /// No description provided for @reportShare.
  ///
  /// In bn, this message translates to:
  /// **'রিপোর্ট শেয়ার করুন'**
  String get reportShare;

  /// No description provided for @reportPrint.
  ///
  /// In bn, this message translates to:
  /// **'রিপোর্ট প্রিন্ট করুন'**
  String get reportPrint;

  /// No description provided for @accountTitle.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট'**
  String get accountTitle;

  /// No description provided for @accountName.
  ///
  /// In bn, this message translates to:
  /// **'আপনার নাম'**
  String get accountName;

  /// No description provided for @accountNameSave.
  ///
  /// In bn, this message translates to:
  /// **'নাম সেভ করুন'**
  String get accountNameSave;

  /// No description provided for @accountNameSaved.
  ///
  /// In bn, this message translates to:
  /// **'নাম সেভ হয়েছে'**
  String get accountNameSaved;

  /// No description provided for @accountLanguage.
  ///
  /// In bn, this message translates to:
  /// **'ভাষা'**
  String get accountLanguage;

  /// No description provided for @accountLangBn.
  ///
  /// In bn, this message translates to:
  /// **'বাংলা'**
  String get accountLangBn;

  /// No description provided for @accountLangEn.
  ///
  /// In bn, this message translates to:
  /// **'English'**
  String get accountLangEn;

  /// No description provided for @accountDelete.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট মুছে ফেলুন'**
  String get accountDelete;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট মুছবেন?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteRemoved.
  ///
  /// In bn, this message translates to:
  /// **'যা মুছে যাবে: আপনার নাম, ফোন নম্বর ও ছবি। আপনি আর কোনো মেসে ঢুকতে পারবেন না।'**
  String get accountDeleteRemoved;

  /// No description provided for @accountDeleteKept.
  ///
  /// In bn, this message translates to:
  /// **'যা থাকবে: মেসের মিল, বাজার, জমা ও খরচের হিসাব আপনার মেসের নামেই থেকে যাবে, যাতে মেসের হিসাব না বদলায়।'**
  String get accountDeleteKept;

  /// No description provided for @accountDeleteManager.
  ///
  /// In bn, this message translates to:
  /// **'আপনি একমাত্র ম্যানেজার হলে আগে অন্য কাউকে ম্যানেজার করুন।'**
  String get accountDeleteManager;

  /// No description provided for @accountDeleteWord.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get accountDeleteWord;

  /// No description provided for @accountDeleteTypeHint.
  ///
  /// In bn, this message translates to:
  /// **'নিশ্চিত করতে লিখুন: {word}'**
  String accountDeleteTypeHint(String word);

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In bn, this message translates to:
  /// **'চিরতরে মুছুন'**
  String get accountDeleteConfirm;

  /// No description provided for @auditTitle.
  ///
  /// In bn, this message translates to:
  /// **'কার্যক্রম'**
  String get auditTitle;

  /// No description provided for @auditFilterAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get auditFilterAll;

  /// No description provided for @auditFilterMeals.
  ///
  /// In bn, this message translates to:
  /// **'মিল'**
  String get auditFilterMeals;

  /// No description provided for @auditFilterMoney.
  ///
  /// In bn, this message translates to:
  /// **'টাকা'**
  String get auditFilterMoney;

  /// No description provided for @auditFilterMembers.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get auditFilterMembers;

  /// No description provided for @auditEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো কার্যক্রম নেই'**
  String get auditEmpty;

  /// No description provided for @auditAi.
  ///
  /// In bn, this message translates to:
  /// **'এআই'**
  String get auditAi;

  /// No description provided for @auditLoadMore.
  ///
  /// In bn, this message translates to:
  /// **'আরও দেখুন'**
  String get auditLoadMore;

  /// No description provided for @auditReason.
  ///
  /// In bn, this message translates to:
  /// **'কারণ: {reason}'**
  String auditReason(String reason);

  /// No description provided for @auditSomeone.
  ///
  /// In bn, this message translates to:
  /// **'কেউ'**
  String get auditSomeone;

  /// No description provided for @auditSystem.
  ///
  /// In bn, this message translates to:
  /// **'সিস্টেম'**
  String get auditSystem;

  /// No description provided for @auditSentence.
  ///
  /// In bn, this message translates to:
  /// **'{actor} {thing} {verb}'**
  String auditSentence(String actor, String thing, String verb);

  /// No description provided for @auditAdded.
  ///
  /// In bn, this message translates to:
  /// **'যোগ করেছেন'**
  String get auditAdded;

  /// No description provided for @auditChanged.
  ///
  /// In bn, this message translates to:
  /// **'বদলেছেন'**
  String get auditChanged;

  /// No description provided for @auditDeleted.
  ///
  /// In bn, this message translates to:
  /// **'মুছেছেন'**
  String get auditDeleted;

  /// No description provided for @auditBazar.
  ///
  /// In bn, this message translates to:
  /// **'বাজার'**
  String get auditBazar;

  /// No description provided for @auditExpense.
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get auditExpense;

  /// No description provided for @auditDepositOf.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর জমা'**
  String auditDepositOf(String name);

  /// No description provided for @auditMealOf.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর মিল'**
  String auditMealOf(String name);

  /// No description provided for @auditMealType.
  ///
  /// In bn, this message translates to:
  /// **'মিলের ধরন {name}'**
  String auditMealType(String name);

  /// No description provided for @auditMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য {name}'**
  String auditMember(String name);

  /// No description provided for @auditMessSettings.
  ///
  /// In bn, this message translates to:
  /// **'মেসের সেটিংস'**
  String get auditMessSettings;

  /// No description provided for @auditMonthClosed.
  ///
  /// In bn, this message translates to:
  /// **'{actor} মাস বন্ধ করেছেন'**
  String auditMonthClosed(String actor);

  /// No description provided for @auditMonthReopened.
  ///
  /// In bn, this message translates to:
  /// **'{actor} মাস আবার খুলেছেন'**
  String auditMonthReopened(String actor);

  /// No description provided for @auditAccountDeleted.
  ///
  /// In bn, this message translates to:
  /// **'{name} অ্যাকাউন্ট মুছে ফেলেছেন'**
  String auditAccountDeleted(String name);

  /// No description provided for @todayAiEntry.
  ///
  /// In bn, this message translates to:
  /// **'লিখে বলুন: ‘আজ রহিম ২, করিম অফ’'**
  String get todayAiEntry;

  /// No description provided for @bazarScan.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ/ফর্দ স্ক্যান'**
  String get bazarScan;

  /// No description provided for @mealOffCutoffPassed.
  ///
  /// In bn, this message translates to:
  /// **'সময় শেষ — ম্যানেজারকে বলুন'**
  String get mealOffCutoffPassed;

  /// No description provided for @mealOffHint.
  ///
  /// In bn, this message translates to:
  /// **'কালকের মিল বন্ধ করতে আজ রাত {time}টার আগে'**
  String mealOffHint(String time);

  /// No description provided for @mealOffTomorrow.
  ///
  /// In bn, this message translates to:
  /// **'কাল মিল বন্ধ'**
  String get mealOffTomorrow;

  /// No description provided for @mealOffTomorrowTitle.
  ///
  /// In bn, this message translates to:
  /// **'কাল কোন মিল বন্ধ থাকবে?'**
  String get mealOffTomorrowTitle;

  /// No description provided for @mealOffSave.
  ///
  /// In bn, this message translates to:
  /// **'ঠিক আছে'**
  String get mealOffSave;

  /// No description provided for @mealOffSaved.
  ///
  /// In bn, this message translates to:
  /// **'কালকের মিল আপডেট হলো'**
  String get mealOffSaved;

  /// No description provided for @receiptAttach.
  ///
  /// In bn, this message translates to:
  /// **'রসিদের ছবি'**
  String get receiptAttach;

  /// No description provided for @receiptScreenshot.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্টের স্ক্রিনশট (না দিলেও চলবে)'**
  String get receiptScreenshot;

  /// No description provided for @receiptRemove.
  ///
  /// In bn, this message translates to:
  /// **'ছবি সরান'**
  String get receiptRemove;

  /// No description provided for @receiptView.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ দেখুন'**
  String get receiptView;

  /// No description provided for @depositVerifyMine.
  ///
  /// In bn, this message translates to:
  /// **'আমার জমা দিন'**
  String get depositVerifyMine;

  /// No description provided for @depositVerifyHelp.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার যাচাই না করা পর্যন্ত এই জমা হিসাবে ধরা হবে না।'**
  String get depositVerifyHelp;

  /// No description provided for @depositVerifySent.
  ///
  /// In bn, this message translates to:
  /// **'জমা পাঠানো হয়েছে, ম্যানেজার যাচাই করবেন'**
  String get depositVerifySent;

  /// No description provided for @depositVerifyApprove.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই করুন'**
  String get depositVerifyApprove;

  /// No description provided for @depositVerifyReject.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করুন'**
  String get depositVerifyReject;

  /// No description provided for @depositVerifyApproveTitle.
  ///
  /// In bn, this message translates to:
  /// **'জমা যাচাই করবেন?'**
  String get depositVerifyApproveTitle;

  /// No description provided for @depositVerifyApproveBody.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর {amount} জমা হিসাবে যোগ হবে।'**
  String depositVerifyApproveBody(String name, String amount);

  /// No description provided for @depositVerifyRejectTitle.
  ///
  /// In bn, this message translates to:
  /// **'জমা বাতিল করবেন?'**
  String get depositVerifyRejectTitle;

  /// No description provided for @depositVerifyRejectBody.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর {amount} জমা হিসাবে ধরা হবে না।'**
  String depositVerifyRejectBody(String name, String amount);

  /// No description provided for @depositVerifyDone.
  ///
  /// In bn, this message translates to:
  /// **'জমা যাচাই হয়েছে'**
  String get depositVerifyDone;

  /// No description provided for @depositVerifyRejected.
  ///
  /// In bn, this message translates to:
  /// **'জমা বাতিল হয়েছে'**
  String get depositVerifyRejected;
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
