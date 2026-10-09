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

  /// No description provided for @navHome.
  ///
  /// In bn, this message translates to:
  /// **'হোম'**
  String get navHome;

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

  /// No description provided for @syncDiscard.
  ///
  /// In bn, this message translates to:
  /// **'বাদ দিন'**
  String get syncDiscard;

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

  /// No description provided for @failureInvalidCredentials.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল বা পাসওয়ার্ড মেলেনি'**
  String get failureInvalidCredentials;

  /// No description provided for @failureEmailTaken.
  ///
  /// In bn, this message translates to:
  /// **'এই ইমেইলে আগেই অ্যাকাউন্ট আছে। লগইন করুন।'**
  String get failureEmailTaken;

  /// No description provided for @failureWeakPassword.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ডটা আরও শক্ত করুন'**
  String get failureWeakPassword;

  /// No description provided for @failureEmailNotConfirmed.
  ///
  /// In bn, this message translates to:
  /// **'আগে ইমেইলে পাঠানো লিংকে ক্লিক করে অ্যাকাউন্ট নিশ্চিত করুন'**
  String get failureEmailNotConfirmed;

  /// No description provided for @signInTitle.
  ///
  /// In bn, this message translates to:
  /// **'মিল বাজারে ঢুকুন'**
  String get signInTitle;

  /// No description provided for @signInHint.
  ///
  /// In bn, this message translates to:
  /// **'মেসের পুরো হিসাব, ফোন থেকেই'**
  String get signInHint;

  /// No description provided for @signInGoogle.
  ///
  /// In bn, this message translates to:
  /// **'Google দিয়ে চালিয়ে যান'**
  String get signInGoogle;

  /// No description provided for @signInOrEmail.
  ///
  /// In bn, this message translates to:
  /// **'অথবা ইমেইল দিয়ে'**
  String get signInOrEmail;

  /// No description provided for @signInModeLogin.
  ///
  /// In bn, this message translates to:
  /// **'লগইন'**
  String get signInModeLogin;

  /// No description provided for @signInModeSignUp.
  ///
  /// In bn, this message translates to:
  /// **'নতুন অ্যাকাউন্ট'**
  String get signInModeSignUp;

  /// No description provided for @signInEmailLabel.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get signInEmailLabel;

  /// No description provided for @signInPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড'**
  String get signInPasswordLabel;

  /// No description provided for @signInEmailInvalid.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ইমেইল দিন'**
  String get signInEmailInvalid;

  /// No description provided for @signInPasswordShort.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড অন্তত ৮ অক্ষরের দিন'**
  String get signInPasswordShort;

  /// No description provided for @signInSubmitLogin.
  ///
  /// In bn, this message translates to:
  /// **'লগইন করুন'**
  String get signInSubmitLogin;

  /// No description provided for @signInSubmitSignUp.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকাউন্ট খুলুন'**
  String get signInSubmitSignUp;

  /// No description provided for @signInForgot.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড ভুলে গেছেন?'**
  String get signInForgot;

  /// No description provided for @signInResetSent.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড বদলানোর লিংক ইমেইলে পাঠানো হয়েছে'**
  String get signInResetSent;

  /// No description provided for @signInConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইলে পাঠানো লিংকে ক্লিক করুন'**
  String get signInConfirmTitle;

  /// No description provided for @signInConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'{email} ঠিকানায় একটা লিংক পাঠিয়েছি। লিংকে ক্লিক করে এখানে ফিরে লগইন করুন।'**
  String signInConfirmBody(String email);

  /// No description provided for @signInBackToLogin.
  ///
  /// In bn, this message translates to:
  /// **'লগইনে ফিরে যান'**
  String get signInBackToLogin;

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

  /// No description provided for @moreSignOutUnsent.
  ///
  /// In bn, this message translates to:
  /// **'অফলাইনে সেভ করা {count} টি এন্ট্রি এখনো পাঠানো হয়নি — সাইন আউট করলে মুছে যাবে'**
  String moreSignOutUnsent(String count);

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
  /// **'সব সদস্যের মিল গতকালের মতো বসবে, না থাকলে তাদের ডিফল্ট মিল (তাও না থাকলে ১টা)। পরে ট্যাপ করে বদলাবেন।'**
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
  /// **'মিল রেটে যোগ হবে, যে যত মিল খেয়েছে সে তত দেবে। যেমন: গ্যাস, রান্নার খরচ'**
  String get expenseSplitMealHelp;

  /// No description provided for @expenseSplitEqualHelp.
  ///
  /// In bn, this message translates to:
  /// **'সেদিন মেসে থাকা সবার মধ্যে সমান ভাগ হবে। যেমন: ওয়াইফাই, বাসা ভাড়া'**
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
  /// **'মিল খরচ'**
  String get reportFoodCost;

  /// No description provided for @reportExtra.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get reportExtra;

  /// No description provided for @reportPaid.
  ///
  /// In bn, this message translates to:
  /// **'জমা + পকেট'**
  String get reportPaid;

  /// No description provided for @reportBalance.
  ///
  /// In bn, this message translates to:
  /// **'ব্যালেন্স'**
  String get reportBalance;

  /// No description provided for @reportFormula.
  ///
  /// In bn, this message translates to:
  /// **'মিল রেট = খাবারের মোট খরচ ÷ মোট মিল'**
  String get reportFormula;

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

  /// No description provided for @reportFooter.
  ///
  /// In bn, this message translates to:
  /// **'মিল বাজার দিয়ে তৈরি · {date}'**
  String reportFooter(String date);

  /// No description provided for @reportPage.
  ///
  /// In bn, this message translates to:
  /// **'পৃষ্ঠা'**
  String get reportPage;

  /// No description provided for @reportManager.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার: {name}'**
  String reportManager(String name);

  /// No description provided for @reportSectionMeals.
  ///
  /// In bn, this message translates to:
  /// **'মিল'**
  String get reportSectionMeals;

  /// No description provided for @reportSectionDaily.
  ///
  /// In bn, this message translates to:
  /// **'দৈনিক মিল (সদস্যভিত্তিক)'**
  String get reportSectionDaily;

  /// No description provided for @reportSectionBazar.
  ///
  /// In bn, this message translates to:
  /// **'বাজার'**
  String get reportSectionBazar;

  /// No description provided for @reportSectionMoney.
  ///
  /// In bn, this message translates to:
  /// **'খরচ, জমা ও সারসংক্ষেপ'**
  String get reportSectionMoney;

  /// No description provided for @reportMatrix.
  ///
  /// In bn, this message translates to:
  /// **'মিল ম্যাট্রিক্স'**
  String get reportMatrix;

  /// No description provided for @reportMatrixHint.
  ///
  /// In bn, this message translates to:
  /// **'সারি = সদস্য, কলাম = তারিখ; রং যত গাঢ় তত বেশি মিল'**
  String get reportMatrixHint;

  /// No description provided for @reportMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get reportMember;

  /// No description provided for @reportTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট'**
  String get reportTotal;

  /// No description provided for @reportDayTotal.
  ///
  /// In bn, this message translates to:
  /// **'দিনের মোট'**
  String get reportDayTotal;

  /// No description provided for @reportOffShort.
  ///
  /// In bn, this message translates to:
  /// **'অ'**
  String get reportOffShort;

  /// No description provided for @reportOffLegend.
  ///
  /// In bn, this message translates to:
  /// **'অ = অফ'**
  String get reportOffLegend;

  /// No description provided for @reportAbsentLegend.
  ///
  /// In bn, this message translates to:
  /// **'· = তখন মেসে ছিল না'**
  String get reportAbsentLegend;

  /// No description provided for @reportTypeBreakdown.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যভিত্তিক মিলের ধরন'**
  String get reportTypeBreakdown;

  /// No description provided for @reportGuests.
  ///
  /// In bn, this message translates to:
  /// **'গেস্ট'**
  String get reportGuests;

  /// No description provided for @reportOffDays.
  ///
  /// In bn, this message translates to:
  /// **'অফ দিন'**
  String get reportOffDays;

  /// No description provided for @reportBazarTrips.
  ///
  /// In bn, this message translates to:
  /// **'বাজারে গেছে'**
  String get reportBazarTrips;

  /// No description provided for @reportTimes.
  ///
  /// In bn, this message translates to:
  /// **'{count} বার'**
  String reportTimes(String count);

  /// No description provided for @reportWeightedMeals.
  ///
  /// In bn, this message translates to:
  /// **'ওজনসহ মিল'**
  String get reportWeightedMeals;

  /// No description provided for @reportDaily.
  ///
  /// In bn, this message translates to:
  /// **'কে কবে কয়টা মিল খেয়েছে'**
  String get reportDaily;

  /// No description provided for @reportDailyHint.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি সদস্যের {types}, দিন ধরে · ½ = হাফ মিল · +১ = গেস্ট · অ = অফ'**
  String reportDailyHint(String types);

  /// No description provided for @reportMealsCount.
  ///
  /// In bn, this message translates to:
  /// **'{meals} মিল'**
  String reportMealsCount(String meals);

  /// No description provided for @reportHalfMeal.
  ///
  /// In bn, this message translates to:
  /// **'হাফ মিল'**
  String get reportHalfMeal;

  /// No description provided for @reportDoubleMeal.
  ///
  /// In bn, this message translates to:
  /// **'ডাবল মিল'**
  String get reportDoubleMeal;

  /// No description provided for @reportOff.
  ///
  /// In bn, this message translates to:
  /// **'অফ'**
  String get reportOff;

  /// No description provided for @reportCountNote.
  ///
  /// In bn, this message translates to:
  /// **'মোট কলামে ওজন ছাড়া গোনা; ওজনসহ মিল নামের নিচে'**
  String get reportCountNote;

  /// No description provided for @reportTimeline.
  ///
  /// In bn, this message translates to:
  /// **'বাজার টাইমলাইন'**
  String get reportTimeline;

  /// No description provided for @reportMessFund.
  ///
  /// In bn, this message translates to:
  /// **'মেস ফান্ড'**
  String get reportMessFund;

  /// No description provided for @reportOwnPocket.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর পকেট'**
  String reportOwnPocket(String name);

  /// No description provided for @reportDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get reportDate;

  /// No description provided for @reportCategory.
  ///
  /// In bn, this message translates to:
  /// **'খাত'**
  String get reportCategory;

  /// No description provided for @reportSplit.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ'**
  String get reportSplit;

  /// No description provided for @reportAmount.
  ///
  /// In bn, this message translates to:
  /// **'টাকা'**
  String get reportAmount;

  /// No description provided for @reportEveryone.
  ///
  /// In bn, this message translates to:
  /// **'সবাই ({count} জন)'**
  String reportEveryone(String count);

  /// No description provided for @reportExpenseTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট অন্যান্য খরচ'**
  String get reportExpenseTotal;

  /// No description provided for @reportDepositsTitle.
  ///
  /// In bn, this message translates to:
  /// **'জমা'**
  String get reportDepositsTitle;

  /// No description provided for @reportMethod.
  ///
  /// In bn, this message translates to:
  /// **'মাধ্যম'**
  String get reportMethod;

  /// No description provided for @reportVerifiedTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমা (যাচাই করা)'**
  String get reportVerifiedTotal;

  /// No description provided for @reportSummary.
  ///
  /// In bn, this message translates to:
  /// **'সারসংক্ষেপ'**
  String get reportSummary;

  /// No description provided for @reportOpening.
  ///
  /// In bn, this message translates to:
  /// **'আগের'**
  String get reportOpening;

  /// No description provided for @reportNone.
  ///
  /// In bn, this message translates to:
  /// **'কিছু নেই'**
  String get reportNone;

  /// No description provided for @reportWeekdays.
  ///
  /// In bn, this message translates to:
  /// **'রবিবার,সোমবার,মঙ্গলবার,বুধবার,বৃহস্পতিবার,শুক্রবার,শনিবার'**
  String get reportWeekdays;

  /// No description provided for @reportWeekdaysShort.
  ///
  /// In bn, this message translates to:
  /// **'র,সো,ম,বু,বৃ,শু,শ'**
  String get reportWeekdaysShort;

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

  /// No description provided for @auditDutyOf.
  ///
  /// In bn, this message translates to:
  /// **'{name}-এর বাজার ডিউটি'**
  String auditDutyOf(String name);

  /// No description provided for @auditNotice.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ {title}'**
  String auditNotice(String title);

  /// No description provided for @auditRecurring.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক বিল'**
  String get auditRecurring;

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

  /// No description provided for @resetTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড দিন'**
  String get resetTitle;

  /// No description provided for @resetHint.
  ///
  /// In bn, this message translates to:
  /// **'এই অ্যাকাউন্টের জন্য একটা নতুন পাসওয়ার্ড ঠিক করুন'**
  String get resetHint;

  /// No description provided for @resetNewPasswordLabel.
  ///
  /// In bn, this message translates to:
  /// **'নতুন পাসওয়ার্ড'**
  String get resetNewPasswordLabel;

  /// No description provided for @resetConfirmLabel.
  ///
  /// In bn, this message translates to:
  /// **'আবার নতুন পাসওয়ার্ড'**
  String get resetConfirmLabel;

  /// No description provided for @resetMismatch.
  ///
  /// In bn, this message translates to:
  /// **'দুটো পাসওয়ার্ড মিলছে না'**
  String get resetMismatch;

  /// No description provided for @resetSave.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড সেভ করুন'**
  String get resetSave;

  /// No description provided for @resetDone.
  ///
  /// In bn, this message translates to:
  /// **'পাসওয়ার্ড বদলানো হয়েছে'**
  String get resetDone;

  /// No description provided for @dashTitle.
  ///
  /// In bn, this message translates to:
  /// **'এই মাস'**
  String get dashTitle;

  /// No description provided for @dashMembers.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get dashMembers;

  /// No description provided for @dashMembersProof.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয় সদস্য'**
  String get dashMembersProof;

  /// No description provided for @dashMembersPending.
  ///
  /// In bn, this message translates to:
  /// **'{count} জন অনুমোদনের অপেক্ষায়'**
  String dashMembersPending(String count);

  /// No description provided for @dashBazar.
  ///
  /// In bn, this message translates to:
  /// **'মোট বাজার'**
  String get dashBazar;

  /// No description provided for @dashBazarProof.
  ///
  /// In bn, this message translates to:
  /// **'মিলে ভাগের খরচসহ খাবার খরচ {food}'**
  String dashBazarProof(String food);

  /// No description provided for @dashExtra.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য খরচ'**
  String get dashExtra;

  /// No description provided for @dashExtraProof.
  ///
  /// In bn, this message translates to:
  /// **'সমান ভাগে · মাসের মোট খরচ {total}'**
  String dashExtraProof(String total);

  /// No description provided for @dashDeposits.
  ///
  /// In bn, this message translates to:
  /// **'মোট জমা'**
  String get dashDeposits;

  /// No description provided for @dashDues.
  ///
  /// In bn, this message translates to:
  /// **'মোট বাকি'**
  String get dashDues;

  /// No description provided for @dashDuesProof.
  ///
  /// In bn, this message translates to:
  /// **'{count} জনের বাকি'**
  String dashDuesProof(String count);

  /// No description provided for @dashAdvances.
  ///
  /// In bn, this message translates to:
  /// **'মোট অগ্রিম'**
  String get dashAdvances;

  /// No description provided for @dashAdvancesProof.
  ///
  /// In bn, this message translates to:
  /// **'{count} জনের অগ্রিম'**
  String dashAdvancesProof(String count);

  /// No description provided for @dashMeals.
  ///
  /// In bn, this message translates to:
  /// **'মোট মিল'**
  String get dashMeals;

  /// No description provided for @dashPeriod.
  ///
  /// In bn, this message translates to:
  /// **'{from} – {to}'**
  String dashPeriod(String from, String to);

  /// No description provided for @dashRate.
  ///
  /// In bn, this message translates to:
  /// **'মিল রেট'**
  String get dashRate;

  /// No description provided for @dashWhoOwes.
  ///
  /// In bn, this message translates to:
  /// **'কার কত বাকি'**
  String get dashWhoOwes;

  /// No description provided for @dashMine.
  ///
  /// In bn, this message translates to:
  /// **'আমার হিসাব'**
  String get dashMine;

  /// No description provided for @dashMyMeals.
  ///
  /// In bn, this message translates to:
  /// **'আমার মিল'**
  String get dashMyMeals;

  /// No description provided for @dashMyFood.
  ///
  /// In bn, this message translates to:
  /// **'খাবার খরচ'**
  String get dashMyFood;

  /// No description provided for @dashMyFoodProof.
  ///
  /// In bn, this message translates to:
  /// **'{meals} মিল × {rate}'**
  String dashMyFoodProof(String meals, String rate);

  /// No description provided for @dashMyPaid.
  ///
  /// In bn, this message translates to:
  /// **'জমা দিয়েছি'**
  String get dashMyPaid;

  /// No description provided for @dashExplain.
  ///
  /// In bn, this message translates to:
  /// **'হিসাবটা বুঝিয়ে দিন'**
  String get dashExplain;

  /// No description provided for @dashNotInMonth.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে আপনার কোনো হিসাব নেই'**
  String get dashNotInMonth;

  /// No description provided for @dashDailyTitle.
  ///
  /// In bn, this message translates to:
  /// **'দৈনিক মিল'**
  String get dashDailyTitle;

  /// No description provided for @dashDailySummary.
  ///
  /// In bn, this message translates to:
  /// **'দৈনিক মিল: মোট {total}, সবচেয়ে বেশি {max} ({date})'**
  String dashDailySummary(String total, String max, String date);

  /// No description provided for @dashCategoryTitle.
  ///
  /// In bn, this message translates to:
  /// **'কোথায় খরচ হলো'**
  String get dashCategoryTitle;

  /// No description provided for @dashMonthlyTitle.
  ///
  /// In bn, this message translates to:
  /// **'মাসে মাসে মিল রেট'**
  String get dashMonthlyTitle;

  /// No description provided for @dashChartEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে এখনো কিছু নেই'**
  String get dashChartEmpty;

  /// No description provided for @dashRecentBazar.
  ///
  /// In bn, this message translates to:
  /// **'সাম্প্রতিক বাজার'**
  String get dashRecentBazar;

  /// No description provided for @dashNobodyThatDay.
  ///
  /// In bn, this message translates to:
  /// **'এই দিনে কেউ মেসে ছিল না'**
  String get dashNobodyThatDay;

  /// No description provided for @navBazar.
  ///
  /// In bn, this message translates to:
  /// **'বাজার'**
  String get navBazar;

  /// No description provided for @mealGridManager.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার: {name}'**
  String mealGridManager(String name);

  /// No description provided for @mealGridPrevMonth.
  ///
  /// In bn, this message translates to:
  /// **'আগের মাস'**
  String get mealGridPrevMonth;

  /// No description provided for @mealGridNextMonth.
  ///
  /// In bn, this message translates to:
  /// **'পরের মাস'**
  String get mealGridNextMonth;

  /// No description provided for @mealGridTotalRow.
  ///
  /// In bn, this message translates to:
  /// **'মোট মিল'**
  String get mealGridTotalRow;

  /// No description provided for @mealGridDayTotal.
  ///
  /// In bn, this message translates to:
  /// **'এই দিনের মোট মিল'**
  String get mealGridDayTotal;

  /// No description provided for @mealGridHint.
  ///
  /// In bn, this message translates to:
  /// **'সংখ্যায় ট্যাপ করলে ০, ০.৫, ১, ১.৫, ২ ঘুরে আসবে'**
  String get mealGridHint;

  /// No description provided for @mealGridAllOne.
  ///
  /// In bn, this message translates to:
  /// **'সবাই ১'**
  String get mealGridAllOne;

  /// No description provided for @mealGridLikeYesterday.
  ///
  /// In bn, this message translates to:
  /// **'গতকালের মতো'**
  String get mealGridLikeYesterday;

  /// No description provided for @mealGridNothingToChange.
  ///
  /// In bn, this message translates to:
  /// **'বদলানোর কিছু নেই'**
  String get mealGridNothingToChange;

  /// No description provided for @mealGridAdd.
  ///
  /// In bn, this message translates to:
  /// **'যোগ করুন'**
  String get mealGridAdd;

  /// No description provided for @mealGridAddTitle.
  ///
  /// In bn, this message translates to:
  /// **'কী যোগ করবেন?'**
  String get mealGridAddTitle;

  /// No description provided for @mealGridAi.
  ///
  /// In bn, this message translates to:
  /// **'মিল লিখে বলুন'**
  String get mealGridAi;

  /// No description provided for @mealGridToday.
  ///
  /// In bn, this message translates to:
  /// **'আজকের মিল'**
  String get mealGridToday;

  /// No description provided for @mealGridGoToMeals.
  ///
  /// In bn, this message translates to:
  /// **'মিল বসান'**
  String get mealGridGoToMeals;

  /// No description provided for @bazarTabTotal.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের বাজার'**
  String get bazarTabTotal;

  /// No description provided for @bazarPickerFrequent.
  ///
  /// In bn, this message translates to:
  /// **'বেশি কেনা হয়'**
  String get bazarPickerFrequent;

  /// No description provided for @bazarPickerStaples.
  ///
  /// In bn, this message translates to:
  /// **'চাল-ডাল-তেল'**
  String get bazarPickerStaples;

  /// No description provided for @bazarPickerVeg.
  ///
  /// In bn, this message translates to:
  /// **'সবজি'**
  String get bazarPickerVeg;

  /// No description provided for @bazarPickerProtein.
  ///
  /// In bn, this message translates to:
  /// **'মাছ-মাংস-ডিম'**
  String get bazarPickerProtein;

  /// No description provided for @bazarPickerSpice.
  ///
  /// In bn, this message translates to:
  /// **'মসলা ও অন্যান্য'**
  String get bazarPickerSpice;

  /// No description provided for @bazarPickerCustom.
  ///
  /// In bn, this message translates to:
  /// **'নতুন আইটেম'**
  String get bazarPickerCustom;

  /// No description provided for @bazarPickerHelp.
  ///
  /// In bn, this message translates to:
  /// **'ট্যাপ করে আইটেম যোগ করুন, আবার ট্যাপে বাদ'**
  String get bazarPickerHelp;

  /// No description provided for @setupTitle.
  ///
  /// In bn, this message translates to:
  /// **'শুরু করি'**
  String get setupTitle;

  /// No description provided for @setupProgress.
  ///
  /// In bn, this message translates to:
  /// **'{done}/{total} হয়েছে'**
  String setupProgress(String done, String total);

  /// No description provided for @setupLater.
  ///
  /// In bn, this message translates to:
  /// **'পরে করব'**
  String get setupLater;

  /// No description provided for @setupStart.
  ///
  /// In bn, this message translates to:
  /// **'শুরু'**
  String get setupStart;

  /// No description provided for @setupMess.
  ///
  /// In bn, this message translates to:
  /// **'মেস খোলা হয়েছে'**
  String get setupMess;

  /// No description provided for @setupMealTypes.
  ///
  /// In bn, this message translates to:
  /// **'মিলের বেলা ঠিক করুন'**
  String get setupMealTypes;

  /// No description provided for @setupMembers.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য যোগ করুন'**
  String get setupMembers;

  /// No description provided for @setupDeposit.
  ///
  /// In bn, this message translates to:
  /// **'শুরুর জমা লিখুন'**
  String get setupDeposit;

  /// No description provided for @setupMeals.
  ///
  /// In bn, this message translates to:
  /// **'আজকের মিল বসান'**
  String get setupMeals;

  /// No description provided for @shareBillTitle.
  ///
  /// In bn, this message translates to:
  /// **'*{mess}* · মাসের বিল'**
  String shareBillTitle(String mess);

  /// No description provided for @shareBillSummaryTitle.
  ///
  /// In bn, this message translates to:
  /// **'*{mess}* · মাসের হিসাব'**
  String shareBillSummaryTitle(String mess);

  /// No description provided for @shareBillMeals.
  ///
  /// In bn, this message translates to:
  /// **'মিল: {meals} × {rate} = {cost}'**
  String shareBillMeals(String meals, String rate, String cost);

  /// No description provided for @shareBillPaid.
  ///
  /// In bn, this message translates to:
  /// **'জমা দিয়েছেন'**
  String get shareBillPaid;

  /// No description provided for @shareBillFoodTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট খাবার খরচ'**
  String get shareBillFoodTotal;

  /// No description provided for @shareBillTotalMeals.
  ///
  /// In bn, this message translates to:
  /// **'মোট মিল'**
  String get shareBillTotalMeals;

  /// No description provided for @shareBillRate.
  ///
  /// In bn, this message translates to:
  /// **'মিল রেট'**
  String get shareBillRate;

  /// No description provided for @shareBillExtraTotal.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য খরচ'**
  String get shareBillExtraTotal;

  /// No description provided for @shareBillShare.
  ///
  /// In bn, this message translates to:
  /// **'বিল শেয়ার'**
  String get shareBillShare;

  /// No description provided for @shareBillRemind.
  ///
  /// In bn, this message translates to:
  /// **'মনে করিয়ে দিন'**
  String get shareBillRemind;

  /// No description provided for @shareBillShareAll.
  ///
  /// In bn, this message translates to:
  /// **'সবার হিসাব শেয়ার'**
  String get shareBillShareAll;

  /// No description provided for @shareBillToneTitle.
  ///
  /// In bn, this message translates to:
  /// **'কীভাবে বলবেন?'**
  String get shareBillToneTitle;

  /// No description provided for @shareBillTonePolite.
  ///
  /// In bn, this message translates to:
  /// **'ভদ্রভাবে'**
  String get shareBillTonePolite;

  /// No description provided for @shareBillToneShort.
  ///
  /// In bn, this message translates to:
  /// **'ছোট করে'**
  String get shareBillToneShort;

  /// No description provided for @shareBillToneFirm.
  ///
  /// In bn, this message translates to:
  /// **'জোর দিয়ে'**
  String get shareBillToneFirm;

  /// No description provided for @shareBillRemindPolite.
  ///
  /// In bn, this message translates to:
  /// **'আসসালামু আলাইকুম {name}, এই মাসের মেসের হিসাবে আপনার {amount} বাকি আছে। সুবিধামতো সময়ে দিয়ে দিলে খুব উপকার হয়। ধন্যবাদ!'**
  String shareBillRemindPolite(String name, String amount);

  /// No description provided for @shareBillRemindShort.
  ///
  /// In bn, this message translates to:
  /// **'{name}, মেসের বাকি {amount}। দয়া করে দিয়ে দিন।'**
  String shareBillRemindShort(String name, String amount);

  /// No description provided for @shareBillRemindFirm.
  ///
  /// In bn, this message translates to:
  /// **'{name}, আপনার মেসের বাকি {amount} এখনো জমা হয়নি। দয়া করে ৩ দিনের মধ্যে পরিশোধ করুন।'**
  String shareBillRemindFirm(String name, String amount);

  /// No description provided for @shareBillPayHint.
  ///
  /// In bn, this message translates to:
  /// **'বিকাশ/নগদ: {number}'**
  String shareBillPayHint(String number);

  /// No description provided for @noticeTitle.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ'**
  String get noticeTitle;

  /// No description provided for @noticeEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো নোটিশ নেই'**
  String get noticeEmpty;

  /// No description provided for @noticeAdd.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ দিন'**
  String get noticeAdd;

  /// No description provided for @noticeEdit.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ বদলান'**
  String get noticeEdit;

  /// No description provided for @noticeTitleLabel.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম'**
  String get noticeTitleLabel;

  /// No description provided for @noticeTitleRequired.
  ///
  /// In bn, this message translates to:
  /// **'শিরোনাম লিখুন'**
  String get noticeTitleRequired;

  /// No description provided for @noticeBodyLabel.
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত'**
  String get noticeBodyLabel;

  /// No description provided for @noticePin.
  ///
  /// In bn, this message translates to:
  /// **'সবার উপরে পিন করুন'**
  String get noticePin;

  /// No description provided for @noticePinned.
  ///
  /// In bn, this message translates to:
  /// **'পিন করা'**
  String get noticePinned;

  /// No description provided for @noticeUnread.
  ///
  /// In bn, this message translates to:
  /// **'নতুন'**
  String get noticeUnread;

  /// No description provided for @noticeExpiry.
  ///
  /// In bn, this message translates to:
  /// **'মেয়াদ'**
  String get noticeExpiry;

  /// No description provided for @noticeNoExpiry.
  ///
  /// In bn, this message translates to:
  /// **'মেয়াদ নেই'**
  String get noticeNoExpiry;

  /// No description provided for @noticeClearExpiry.
  ///
  /// In bn, this message translates to:
  /// **'মেয়াদ সরান'**
  String get noticeClearExpiry;

  /// No description provided for @noticeUntil.
  ///
  /// In bn, this message translates to:
  /// **'{date} পর্যন্ত'**
  String noticeUntil(String date);

  /// No description provided for @noticeSave.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ সেভ করুন'**
  String get noticeSave;

  /// No description provided for @noticeSaved.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ সেভ হয়েছে'**
  String get noticeSaved;

  /// No description provided for @noticeDeleted.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ মুছে ফেলা হয়েছে'**
  String get noticeDeleted;

  /// No description provided for @noticeDeleteConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশটি মুছবেন?'**
  String get noticeDeleteConfirmTitle;

  /// No description provided for @noticeDeleteConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'সবার কাছ থেকে নোটিশটি সরে যাবে।'**
  String get noticeDeleteConfirmBody;

  /// No description provided for @noticeGone.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশটি আর নেই'**
  String get noticeGone;

  /// No description provided for @dutyTitle.
  ///
  /// In bn, this message translates to:
  /// **'বাজারের পালা'**
  String get dutyTitle;

  /// No description provided for @dutyGenerate.
  ///
  /// In bn, this message translates to:
  /// **'পালা বানান'**
  String get dutyGenerate;

  /// No description provided for @dutyEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসে কারও বাজারের পালা নেই'**
  String get dutyEmpty;

  /// No description provided for @dutyMyUpcoming.
  ///
  /// In bn, this message translates to:
  /// **'আপনার সামনের পালা'**
  String get dutyMyUpcoming;

  /// No description provided for @dutyThisMonth.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের পালা'**
  String get dutyThisMonth;

  /// No description provided for @dutyDone.
  ///
  /// In bn, this message translates to:
  /// **'বাজার হয়ে গেছে'**
  String get dutyDone;

  /// No description provided for @dutyMarkDone.
  ///
  /// In bn, this message translates to:
  /// **'বাজার করেছি'**
  String get dutyMarkDone;

  /// No description provided for @dutyMembersLabel.
  ///
  /// In bn, this message translates to:
  /// **'কে কে করবে, ক্রম অনুযায়ী ট্যাপ করুন'**
  String get dutyMembersLabel;

  /// No description provided for @dutyPickMembers.
  ///
  /// In bn, this message translates to:
  /// **'অন্তত একজনকে বাছুন'**
  String get dutyPickMembers;

  /// No description provided for @dutyStart.
  ///
  /// In bn, this message translates to:
  /// **'শুরুর দিন'**
  String get dutyStart;

  /// No description provided for @dutyEveryLabel.
  ///
  /// In bn, this message translates to:
  /// **'কত দিন পরপর'**
  String get dutyEveryLabel;

  /// No description provided for @dutyEvery.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি {n} দিনে'**
  String dutyEvery(String n);

  /// No description provided for @dutyDays.
  ///
  /// In bn, this message translates to:
  /// **'কত দিনের জন্য'**
  String get dutyDays;

  /// No description provided for @dutyDaysInvalid.
  ///
  /// In bn, this message translates to:
  /// **'১ থেকে ৩৬৬ দিনের মধ্যে দিন'**
  String get dutyDaysInvalid;

  /// No description provided for @dutyCreated.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি পালা তৈরি হয়েছে'**
  String dutyCreated(String count);

  /// No description provided for @dutyEditTitle.
  ///
  /// In bn, this message translates to:
  /// **'পালা বদলান'**
  String get dutyEditTitle;

  /// No description provided for @dutyMember.
  ///
  /// In bn, this message translates to:
  /// **'কে বাজার করবে'**
  String get dutyMember;

  /// No description provided for @dutyNote.
  ///
  /// In bn, this message translates to:
  /// **'নোট'**
  String get dutyNote;

  /// No description provided for @dutyDeleteConfirm.
  ///
  /// In bn, this message translates to:
  /// **'এই দিনের পালা মুছে ফেলবেন?'**
  String get dutyDeleteConfirm;

  /// No description provided for @dutyTodayMine.
  ///
  /// In bn, this message translates to:
  /// **'আজ আপনার বাজারের পালা'**
  String get dutyTodayMine;

  /// No description provided for @dutyTomorrowMine.
  ///
  /// In bn, this message translates to:
  /// **'কাল আপনার বাজারের পালা'**
  String get dutyTomorrowMine;

  /// No description provided for @dutyTodayOther.
  ///
  /// In bn, this message translates to:
  /// **'আজ বাজার করবেন {name}'**
  String dutyTodayOther(String name);

  /// No description provided for @dutyTomorrowOther.
  ///
  /// In bn, this message translates to:
  /// **'কাল বাজার করবেন {name}'**
  String dutyTomorrowOther(String name);

  /// No description provided for @dutyNextMonth.
  ///
  /// In bn, this message translates to:
  /// **'পরের মাস'**
  String get dutyNextMonth;

  /// No description provided for @splitEqualAll.
  ///
  /// In bn, this message translates to:
  /// **'সবাই সমান'**
  String get splitEqualAll;

  /// No description provided for @splitByMeal.
  ///
  /// In bn, this message translates to:
  /// **'মিল অনুযায়ী'**
  String get splitByMeal;

  /// No description provided for @splitSelected.
  ///
  /// In bn, this message translates to:
  /// **'কয়েকজন'**
  String get splitSelected;

  /// No description provided for @splitSelectedHelp.
  ///
  /// In bn, this message translates to:
  /// **'শুধু বাছাই করা সদস্যরা দেবেন, যার যত ভাগ সে তত দেবে। যেমন: এক রুমের ফ্যান মেরামত'**
  String get splitSelectedHelp;

  /// No description provided for @splitPickMember.
  ///
  /// In bn, this message translates to:
  /// **'অন্তত একজন সদস্য বাছুন'**
  String get splitPickMember;

  /// No description provided for @splitWeight.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ {weight}'**
  String splitWeight(String weight);

  /// No description provided for @splitWeightLess.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ কমান'**
  String get splitWeightLess;

  /// No description provided for @splitWeightMore.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ বাড়ান'**
  String get splitWeightMore;

  /// No description provided for @splitPreview.
  ///
  /// In bn, this message translates to:
  /// **'প্রিভিউ: কে কত দেবে (আসল হিসাব মাস শেষে)'**
  String get splitPreview;

  /// No description provided for @exportTitle.
  ///
  /// In bn, this message translates to:
  /// **'ডেটা এক্সপোর্ট (CSV)'**
  String get exportTitle;

  /// No description provided for @exportAction.
  ///
  /// In bn, this message translates to:
  /// **'CSV এক্সপোর্ট'**
  String get exportAction;

  /// No description provided for @exportPeriod.
  ///
  /// In bn, this message translates to:
  /// **'কোন মাসের হিসাব'**
  String get exportPeriod;

  /// No description provided for @exportCurrent.
  ///
  /// In bn, this message translates to:
  /// **'চলতি মাস'**
  String get exportCurrent;

  /// No description provided for @exportHint.
  ///
  /// In bn, this message translates to:
  /// **'ব্যালেন্স, মিল, বাজার, খরচ আর জমা — ৫টি CSV ফাইল। Excel বা Google Sheets-এ খোলা যায়।'**
  String get exportHint;

  /// No description provided for @exportButton.
  ///
  /// In bn, this message translates to:
  /// **'এক্সপোর্ট করে শেয়ার করুন'**
  String get exportButton;

  /// No description provided for @exportDate.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get exportDate;

  /// No description provided for @exportMember.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get exportMember;

  /// No description provided for @exportGuests.
  ///
  /// In bn, this message translates to:
  /// **'অতিথি'**
  String get exportGuests;

  /// No description provided for @exportOpening.
  ///
  /// In bn, this message translates to:
  /// **'আগের ব্যালেন্স'**
  String get exportOpening;

  /// No description provided for @exportAmount.
  ///
  /// In bn, this message translates to:
  /// **'টাকা'**
  String get exportAmount;

  /// No description provided for @exportBuyer.
  ///
  /// In bn, this message translates to:
  /// **'বাজারকারী'**
  String get exportBuyer;

  /// No description provided for @exportPaidBy.
  ///
  /// In bn, this message translates to:
  /// **'টাকা দিয়েছে'**
  String get exportPaidBy;

  /// No description provided for @exportItems.
  ///
  /// In bn, this message translates to:
  /// **'জিনিসপত্র'**
  String get exportItems;

  /// No description provided for @exportNote.
  ///
  /// In bn, this message translates to:
  /// **'নোট'**
  String get exportNote;

  /// No description provided for @exportCategory.
  ///
  /// In bn, this message translates to:
  /// **'খাত'**
  String get exportCategory;

  /// No description provided for @exportSplit.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ'**
  String get exportSplit;

  /// No description provided for @exportMethod.
  ///
  /// In bn, this message translates to:
  /// **'মাধ্যম'**
  String get exportMethod;

  /// No description provided for @exportStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get exportStatus;

  /// No description provided for @exportVerified.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই হয়েছে'**
  String get exportVerified;

  /// No description provided for @cookShare.
  ///
  /// In bn, this message translates to:
  /// **'রাঁধুনিকে কালকের মিল পাঠান'**
  String get cookShare;

  /// No description provided for @remindTitle.
  ///
  /// In bn, this message translates to:
  /// **'রিমাইন্ডার'**
  String get remindTitle;

  /// No description provided for @remindCutoffTitle.
  ///
  /// In bn, this message translates to:
  /// **'মিল বন্ধের সময় শেষ হচ্ছে'**
  String get remindCutoffTitle;

  /// No description provided for @remindCutoffBody.
  ///
  /// In bn, this message translates to:
  /// **'কালকের মিল বন্ধ করতে চাইলে এখনই করুন'**
  String get remindCutoffBody;

  /// No description provided for @remindNudgeTitle.
  ///
  /// In bn, this message translates to:
  /// **'আজকের মিল বসানো হয়নি'**
  String get remindNudgeTitle;

  /// No description provided for @remindNudgeBody.
  ///
  /// In bn, this message translates to:
  /// **'আজকের মিল বসানো হয়নি? এখনই বসিয়ে দিন'**
  String get remindNudgeBody;

  /// No description provided for @remindDutyTitle.
  ///
  /// In bn, this message translates to:
  /// **'কাল আপনার বাজার'**
  String get remindDutyTitle;

  /// No description provided for @remindDutyBody.
  ///
  /// In bn, this message translates to:
  /// **'{mess}: কাল বাজারের দায়িত্ব আপনার'**
  String remindDutyBody(String mess);

  /// No description provided for @remindCutoffToggle.
  ///
  /// In bn, this message translates to:
  /// **'মিল বন্ধের সময়ের আগে'**
  String get remindCutoffToggle;

  /// No description provided for @remindCutoffToggleSub.
  ///
  /// In bn, this message translates to:
  /// **'শেষ সময়ের ৩০ মিনিট আগে মনে করিয়ে দেবে'**
  String get remindCutoffToggleSub;

  /// No description provided for @remindNudgeToggle.
  ///
  /// In bn, this message translates to:
  /// **'রাতে মিল বসানোর কথা'**
  String get remindNudgeToggle;

  /// No description provided for @remindNudgeToggleSub.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিদিন রাত ৯টায়, ম্যানেজারদের জন্য'**
  String get remindNudgeToggleSub;

  /// No description provided for @remindDutyToggle.
  ///
  /// In bn, this message translates to:
  /// **'বাজারের দায়িত্ব'**
  String get remindDutyToggle;

  /// No description provided for @remindDutyToggleSub.
  ///
  /// In bn, this message translates to:
  /// **'দায়িত্বের আগের দিন রাত ৮টায়'**
  String get remindDutyToggleSub;

  /// No description provided for @remindPermissionOff.
  ///
  /// In bn, this message translates to:
  /// **'নোটিফিকেশন বন্ধ আছে'**
  String get remindPermissionOff;

  /// No description provided for @remindPermissionBody.
  ///
  /// In bn, this message translates to:
  /// **'রিমাইন্ডার পেতে নোটিফিকেশন চালু করুন'**
  String get remindPermissionBody;

  /// No description provided for @remindPermissionButton.
  ///
  /// In bn, this message translates to:
  /// **'চালু করুন'**
  String get remindPermissionButton;

  /// No description provided for @recurringTitle.
  ///
  /// In bn, this message translates to:
  /// **'নিয়মিত মাসিক বিল'**
  String get recurringTitle;

  /// No description provided for @recurringHelp.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া, ওয়াইফাই, বুয়ার মতো যে বিল প্রতি মাসে একই থাকে, একবার লিখে রাখুন। তারপর প্রতি মাসে এক চাপে খরচে বসান।'**
  String get recurringHelp;

  /// No description provided for @recurringEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো নিয়মিত বিল নেই'**
  String get recurringEmpty;

  /// No description provided for @recurringAdd.
  ///
  /// In bn, this message translates to:
  /// **'নতুন নিয়মিত বিল'**
  String get recurringAdd;

  /// No description provided for @recurringEdit.
  ///
  /// In bn, this message translates to:
  /// **'নিয়মিত বিল বদলান'**
  String get recurringEdit;

  /// No description provided for @recurringDay.
  ///
  /// In bn, this message translates to:
  /// **'মাসের কততম দিনে বসবে'**
  String get recurringDay;

  /// No description provided for @recurringDayValue.
  ///
  /// In bn, this message translates to:
  /// **'মাসের {day} নম্বর দিন'**
  String recurringDayValue(String day);

  /// No description provided for @recurringActive.
  ///
  /// In bn, this message translates to:
  /// **'{name} চালু'**
  String recurringActive(String name);

  /// No description provided for @recurringApply.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের বিল বসান'**
  String get recurringApply;

  /// No description provided for @recurringApplied.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি বিল খরচে বসানো হলো'**
  String recurringApplied(String count);

  /// No description provided for @recurringNothingToApply.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের সব নিয়মিত বিল আগেই বসানো হয়েছে'**
  String get recurringNothingToApply;

  /// No description provided for @recurringPending.
  ///
  /// In bn, this message translates to:
  /// **'এই মাসের {count}টি নিয়মিত বিল বসানো বাকি'**
  String recurringPending(String count);

  /// No description provided for @recurringManagerOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধু ম্যানেজার নিয়মিত বিল বদলাতে পারেন'**
  String get recurringManagerOnly;

  /// No description provided for @mealDefaultTitle.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের ডিফল্ট মিল'**
  String get mealDefaultTitle;

  /// No description provided for @mealDefaultHelp.
  ///
  /// In bn, this message translates to:
  /// **'আগের দিনের মিল না থাকলে \"আজকের মিল বসান\" এই হিসাবে মিল বসাবে।'**
  String get mealDefaultHelp;

  /// No description provided for @mealDefaultEmpty.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সক্রিয় সদস্য বা চালু বেলা নেই'**
  String get mealDefaultEmpty;

  /// No description provided for @mealDefaultManagerOnly.
  ///
  /// In bn, this message translates to:
  /// **'শুধু ম্যানেজার ডিফল্ট মিল বদলাতে পারেন'**
  String get mealDefaultManagerOnly;

  /// No description provided for @rateSection.
  ///
  /// In bn, this message translates to:
  /// **'মিল রেট'**
  String get rateSection;

  /// No description provided for @rateHelp.
  ///
  /// In bn, this message translates to:
  /// **'হিসাব করে: বাজার খরচ ÷ মোট মিল। নির্দিষ্ট রেট: আগে থেকে ঘোষণা করা রেট, সবাই প্রতি মিলে এটাই দেবে।'**
  String get rateHelp;

  /// No description provided for @rateCalculated.
  ///
  /// In bn, this message translates to:
  /// **'হিসাব করে'**
  String get rateCalculated;

  /// No description provided for @rateFixed.
  ///
  /// In bn, this message translates to:
  /// **'নির্দিষ্ট রেট'**
  String get rateFixed;

  /// No description provided for @rateAmountLabel.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি মিলের রেট (৳)'**
  String get rateAmountLabel;

  /// No description provided for @rateAmountRequired.
  ///
  /// In bn, this message translates to:
  /// **'০-এর বেশি একটি রেট লিখুন'**
  String get rateAmountRequired;

  /// No description provided for @rateSurplus.
  ///
  /// In bn, this message translates to:
  /// **'বাজার খরচের চেয়ে {amount} বেশি উঠেছে'**
  String rateSurplus(String amount);

  /// No description provided for @rateDeficit.
  ///
  /// In bn, this message translates to:
  /// **'বাজার খরচের চেয়ে {amount} কম উঠেছে'**
  String rateDeficit(String amount);

  /// No description provided for @rateBalanceFood.
  ///
  /// In bn, this message translates to:
  /// **'খাবার খরচ = {meals} মিল × {rate} (নির্দিষ্ট রেট)'**
  String rateBalanceFood(String meals, String rate);

  /// No description provided for @platformMaintenanceTitle.
  ///
  /// In bn, this message translates to:
  /// **'একটু কাজ চলছে'**
  String get platformMaintenanceTitle;

  /// No description provided for @platformMaintenanceBody.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপটি কিছুক্ষণের জন্য বন্ধ আছে। একটু পরে আবার খুলুন, আপনার হিসাব নিরাপদ আছে।'**
  String get platformMaintenanceBody;

  /// No description provided for @platformMaintenanceRetry.
  ///
  /// In bn, this message translates to:
  /// **'আবার দেখুন'**
  String get platformMaintenanceRetry;

  /// No description provided for @platformSignOut.
  ///
  /// In bn, this message translates to:
  /// **'সাইন আউট'**
  String get platformSignOut;

  /// No description provided for @platformUpdateTitle.
  ///
  /// In bn, this message translates to:
  /// **'নতুন ভার্সন এসেছে'**
  String get platformUpdateTitle;

  /// No description provided for @platformUpdateBody.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকঠাক চালাতে Play Store থেকে অ্যাপটি আপডেট করে নিন।'**
  String get platformUpdateBody;

  /// No description provided for @platformUpdateLater.
  ///
  /// In bn, this message translates to:
  /// **'পরে করব'**
  String get platformUpdateLater;

  /// No description provided for @platformBannerDismiss.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করুন'**
  String get platformBannerDismiss;

  /// No description provided for @platformSupportTitle.
  ///
  /// In bn, this message translates to:
  /// **'সাহায্য'**
  String get platformSupportTitle;

  /// No description provided for @platformSupportEmail.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল'**
  String get platformSupportEmail;

  /// No description provided for @platformSupportWhatsapp.
  ///
  /// In bn, this message translates to:
  /// **'WhatsApp'**
  String get platformSupportWhatsapp;

  /// No description provided for @platformPrivacy.
  ///
  /// In bn, this message translates to:
  /// **'প্রাইভেসি পলিসি'**
  String get platformPrivacy;

  /// No description provided for @platformCopy.
  ///
  /// In bn, this message translates to:
  /// **'কপি করুন'**
  String get platformCopy;

  /// No description provided for @platformCopied.
  ///
  /// In bn, this message translates to:
  /// **'কপি হয়েছে'**
  String get platformCopied;

  /// No description provided for @platformAboutTitle.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ সম্পর্কে'**
  String get platformAboutTitle;

  /// No description provided for @platformVersion.
  ///
  /// In bn, this message translates to:
  /// **'ভার্সন {version}'**
  String platformVersion(String version);

  /// No description provided for @adminTitle.
  ///
  /// In bn, this message translates to:
  /// **'মিল বাজার অ্যাডমিন'**
  String get adminTitle;

  /// No description provided for @adminTitleShort.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিন'**
  String get adminTitleShort;

  /// No description provided for @adminSignIn.
  ///
  /// In bn, this message translates to:
  /// **'লগইন করুন'**
  String get adminSignIn;

  /// No description provided for @adminSignInGoogle.
  ///
  /// In bn, this message translates to:
  /// **'গুগল দিয়ে লগইন'**
  String get adminSignInGoogle;

  /// No description provided for @adminSignInHint.
  ///
  /// In bn, this message translates to:
  /// **'শুধু প্ল্যাটফর্ম অ্যাডমিনরা এখানে ঢুকতে পারেন।'**
  String get adminSignInHint;

  /// No description provided for @adminSignOut.
  ///
  /// In bn, this message translates to:
  /// **'লগআউট'**
  String get adminSignOut;

  /// No description provided for @adminAccessDenied.
  ///
  /// In bn, this message translates to:
  /// **'প্রবেশাধিকার নেই'**
  String get adminAccessDenied;

  /// No description provided for @adminAccessDeniedBody.
  ///
  /// In bn, this message translates to:
  /// **'এই অ্যাকাউন্ট প্ল্যাটফর্ম অ্যাডমিন নয়। অন্য অ্যাকাউন্টে লগইন করুন।'**
  String get adminAccessDeniedBody;

  /// No description provided for @adminNavDashboard.
  ///
  /// In bn, this message translates to:
  /// **'ড্যাশবোর্ড'**
  String get adminNavDashboard;

  /// No description provided for @adminNavMesses.
  ///
  /// In bn, this message translates to:
  /// **'মেস'**
  String get adminNavMesses;

  /// No description provided for @adminNavUsers.
  ///
  /// In bn, this message translates to:
  /// **'ইউজার'**
  String get adminNavUsers;

  /// No description provided for @adminNavSettings.
  ///
  /// In bn, this message translates to:
  /// **'সেটিংস'**
  String get adminNavSettings;

  /// No description provided for @adminNavAi.
  ///
  /// In bn, this message translates to:
  /// **'এআই'**
  String get adminNavAi;

  /// No description provided for @adminNavBranding.
  ///
  /// In bn, this message translates to:
  /// **'ব্র্যান্ডিং'**
  String get adminNavBranding;

  /// No description provided for @adminNavCredentials.
  ///
  /// In bn, this message translates to:
  /// **'ক্রেডেনশিয়াল'**
  String get adminNavCredentials;

  /// No description provided for @adminNavDeletion.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলার সারি'**
  String get adminNavDeletion;

  /// No description provided for @adminStatUsersTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট ইউজার'**
  String get adminStatUsersTotal;

  /// No description provided for @adminStatUsers7d.
  ///
  /// In bn, this message translates to:
  /// **'নতুন ইউজার (৭ দিন)'**
  String get adminStatUsers7d;

  /// No description provided for @adminStatMessesTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট মেস'**
  String get adminStatMessesTotal;

  /// No description provided for @adminStatMessesActive7d.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয় মেস (৭ দিন)'**
  String get adminStatMessesActive7d;

  /// No description provided for @adminStatMeals7d.
  ///
  /// In bn, this message translates to:
  /// **'মিল (৭ দিন)'**
  String get adminStatMeals7d;

  /// No description provided for @adminStatBazars7d.
  ///
  /// In bn, this message translates to:
  /// **'বাজার (৭ দিন)'**
  String get adminStatBazars7d;

  /// No description provided for @adminStatAiCalls7d.
  ///
  /// In bn, this message translates to:
  /// **'এআই কল (৭ দিন)'**
  String get adminStatAiCalls7d;

  /// No description provided for @adminStatSuspendedMesses.
  ///
  /// In bn, this message translates to:
  /// **'স্থগিত মেস'**
  String get adminStatSuspendedMesses;

  /// No description provided for @adminStatDeletionPending.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলার অপেক্ষায়'**
  String get adminStatDeletionPending;

  /// No description provided for @adminAiUsage30d.
  ///
  /// In bn, this message translates to:
  /// **'এআই ব্যবহার, শেষ ৩০ দিন'**
  String get adminAiUsage30d;

  /// No description provided for @adminAiUsageEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এই সময়ে কোনো এআই কল হয়নি'**
  String get adminAiUsageEmpty;

  /// No description provided for @adminDeletionEmpty.
  ///
  /// In bn, this message translates to:
  /// **'মুছে ফেলার কোনো অনুরোধ নেই'**
  String get adminDeletionEmpty;

  /// No description provided for @adminUserId.
  ///
  /// In bn, this message translates to:
  /// **'ইউজার আইডি'**
  String get adminUserId;

  /// No description provided for @adminRequestedAt.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধের সময়'**
  String get adminRequestedAt;

  /// No description provided for @adminProcessedAt.
  ///
  /// In bn, this message translates to:
  /// **'সম্পন্ন'**
  String get adminProcessedAt;

  /// No description provided for @adminLastError.
  ///
  /// In bn, this message translates to:
  /// **'শেষ ত্রুটি'**
  String get adminLastError;

  /// No description provided for @adminSearchMesses.
  ///
  /// In bn, this message translates to:
  /// **'মেসের নাম দিয়ে খুঁজুন, তারপর Enter'**
  String get adminSearchMesses;

  /// No description provided for @adminSearchUsers.
  ///
  /// In bn, this message translates to:
  /// **'ইমেইল বা নাম দিয়ে খুঁজুন, তারপর Enter'**
  String get adminSearchUsers;

  /// No description provided for @adminNoResults.
  ///
  /// In bn, this message translates to:
  /// **'কিছু পাওয়া যায়নি'**
  String get adminNoResults;

  /// No description provided for @adminPage.
  ///
  /// In bn, this message translates to:
  /// **'পৃষ্ঠা {page}'**
  String adminPage(String page);

  /// No description provided for @adminName.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get adminName;

  /// No description provided for @adminMembers.
  ///
  /// In bn, this message translates to:
  /// **'সদস্য'**
  String get adminMembers;

  /// No description provided for @adminManagers.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার'**
  String get adminManagers;

  /// No description provided for @adminCreated.
  ///
  /// In bn, this message translates to:
  /// **'তৈরি'**
  String get adminCreated;

  /// No description provided for @adminLastActivity.
  ///
  /// In bn, this message translates to:
  /// **'শেষ কাজ'**
  String get adminLastActivity;

  /// No description provided for @adminLastSignIn.
  ///
  /// In bn, this message translates to:
  /// **'শেষ লগইন'**
  String get adminLastSignIn;

  /// No description provided for @adminMessCount.
  ///
  /// In bn, this message translates to:
  /// **'মেস'**
  String get adminMessCount;

  /// No description provided for @adminStatus.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get adminStatus;

  /// No description provided for @adminRole.
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা'**
  String get adminRole;

  /// No description provided for @adminRoleAdmin.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিন'**
  String get adminRoleAdmin;

  /// No description provided for @adminActive.
  ///
  /// In bn, this message translates to:
  /// **'চালু'**
  String get adminActive;

  /// No description provided for @adminSuspended.
  ///
  /// In bn, this message translates to:
  /// **'স্থগিত'**
  String get adminSuspended;

  /// No description provided for @adminSuspend.
  ///
  /// In bn, this message translates to:
  /// **'স্থগিত করুন'**
  String get adminSuspend;

  /// No description provided for @adminUnsuspend.
  ///
  /// In bn, this message translates to:
  /// **'আবার চালু করুন'**
  String get adminUnsuspend;

  /// No description provided for @adminSuspendMess.
  ///
  /// In bn, this message translates to:
  /// **'\"{name}\" মেস স্থগিত করবেন?'**
  String adminSuspendMess(String name);

  /// No description provided for @adminUnsuspendMess.
  ///
  /// In bn, this message translates to:
  /// **'\"{name}\" মেস আবার চালু করবেন?'**
  String adminUnsuspendMess(String name);

  /// No description provided for @adminSuspendUser.
  ///
  /// In bn, this message translates to:
  /// **'{email} স্থগিত করবেন?'**
  String adminSuspendUser(String email);

  /// No description provided for @adminUnsuspendUser.
  ///
  /// In bn, this message translates to:
  /// **'{email} আবার চালু করবেন?'**
  String adminUnsuspendUser(String email);

  /// No description provided for @adminReason.
  ///
  /// In bn, this message translates to:
  /// **'কারণ'**
  String get adminReason;

  /// No description provided for @adminMakeAdmin.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিন বানান'**
  String get adminMakeAdmin;

  /// No description provided for @adminRemoveAdmin.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডমিন থেকে সরান'**
  String get adminRemoveAdmin;

  /// No description provided for @adminSaved.
  ///
  /// In bn, this message translates to:
  /// **'সেভ হয়েছে'**
  String get adminSaved;

  /// No description provided for @adminRawJson.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাডভান্সড: কাঁচা JSON'**
  String get adminRawJson;

  /// No description provided for @adminAdd.
  ///
  /// In bn, this message translates to:
  /// **'যোগ করুন'**
  String get adminAdd;

  /// No description provided for @adminMoveUp.
  ///
  /// In bn, this message translates to:
  /// **'ওপরে নিন'**
  String get adminMoveUp;

  /// No description provided for @adminMoveDown.
  ///
  /// In bn, this message translates to:
  /// **'নিচে নিন'**
  String get adminMoveDown;

  /// No description provided for @adminErrRequired.
  ///
  /// In bn, this message translates to:
  /// **'এটা দিতে হবে'**
  String get adminErrRequired;

  /// No description provided for @adminErrNumber.
  ///
  /// In bn, this message translates to:
  /// **'একটা সংখ্যা দিন'**
  String get adminErrNumber;

  /// No description provided for @adminErrRange.
  ///
  /// In bn, this message translates to:
  /// **'সীমার বাইরে'**
  String get adminErrRange;

  /// No description provided for @adminErrVersion.
  ///
  /// In bn, this message translates to:
  /// **'১.২.৩ ধরনের ভার্সন দিন'**
  String get adminErrVersion;

  /// No description provided for @adminErrEmail.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ইমেইল দিন'**
  String get adminErrEmail;

  /// No description provided for @adminErrUrl.
  ///
  /// In bn, this message translates to:
  /// **'http(s):// দিয়ে শুরু হওয়া লিংক দিন'**
  String get adminErrUrl;

  /// No description provided for @adminErrTime.
  ///
  /// In bn, this message translates to:
  /// **'HH:MM ধরনে সময় দিন'**
  String get adminErrTime;

  /// No description provided for @adminErrHex.
  ///
  /// In bn, this message translates to:
  /// **'#RRGGBB ধরনে রং দিন'**
  String get adminErrHex;

  /// No description provided for @adminErrMealTypes.
  ///
  /// In bn, this message translates to:
  /// **'অন্তত একটা বেলা রাখুন'**
  String get adminErrMealTypes;

  /// No description provided for @adminErrChain.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিটি চেইনে ১ থেকে ৫টি মডেল রাখুন'**
  String get adminErrChain;

  /// No description provided for @adminFeatures.
  ///
  /// In bn, this message translates to:
  /// **'ফিচার'**
  String get adminFeatures;

  /// No description provided for @adminFeaturesHelp.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করলে অ্যাপে ওই ফিচারের সব পথ লুকিয়ে যায়। ডেটা থেকে যায়।'**
  String get adminFeaturesHelp;

  /// No description provided for @adminAppSection.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ'**
  String get adminAppSection;

  /// No description provided for @adminMaintenance.
  ///
  /// In bn, this message translates to:
  /// **'রক্ষণাবেক্ষণ মোড'**
  String get adminMaintenance;

  /// No description provided for @adminMaintenanceHelp.
  ///
  /// In bn, this message translates to:
  /// **'চালু থাকলে অ্যাপে পুরো পর্দার নোটিশ দেখায়'**
  String get adminMaintenanceHelp;

  /// No description provided for @adminMessageBn.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা (বাংলা)'**
  String get adminMessageBn;

  /// No description provided for @adminMessageEn.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা (ইংরেজি)'**
  String get adminMessageEn;

  /// No description provided for @adminVersions.
  ///
  /// In bn, this message translates to:
  /// **'ভার্সন'**
  String get adminVersions;

  /// No description provided for @adminMinVersion.
  ///
  /// In bn, this message translates to:
  /// **'ন্যূনতম ভার্সন'**
  String get adminMinVersion;

  /// No description provided for @adminMinVersionHelp.
  ///
  /// In bn, this message translates to:
  /// **'এর নিচে থাকলে আপডেট করতে বলা হয়'**
  String get adminMinVersionHelp;

  /// No description provided for @adminLatestVersion.
  ///
  /// In bn, this message translates to:
  /// **'সর্বশেষ ভার্সন'**
  String get adminLatestVersion;

  /// No description provided for @adminUpdateMessageBn.
  ///
  /// In bn, this message translates to:
  /// **'আপডেট বার্তা (বাংলা)'**
  String get adminUpdateMessageBn;

  /// No description provided for @adminUpdateMessageEn.
  ///
  /// In bn, this message translates to:
  /// **'আপডেট বার্তা (ইংরেজি)'**
  String get adminUpdateMessageEn;

  /// No description provided for @adminSupport.
  ///
  /// In bn, this message translates to:
  /// **'সহায়তা'**
  String get adminSupport;

  /// No description provided for @adminSupportEmail.
  ///
  /// In bn, this message translates to:
  /// **'সহায়তার ইমেইল'**
  String get adminSupportEmail;

  /// No description provided for @adminSupportWhatsapp.
  ///
  /// In bn, this message translates to:
  /// **'সহায়তার হোয়াটসঅ্যাপ'**
  String get adminSupportWhatsapp;

  /// No description provided for @adminPrivacyUrl.
  ///
  /// In bn, this message translates to:
  /// **'প্রাইভেসি পলিসির লিংক'**
  String get adminPrivacyUrl;

  /// No description provided for @adminBanner.
  ///
  /// In bn, this message translates to:
  /// **'ব্যানার'**
  String get adminBanner;

  /// No description provided for @adminBannerActive.
  ///
  /// In bn, this message translates to:
  /// **'হোমে ব্যানার দেখান'**
  String get adminBannerActive;

  /// No description provided for @adminBannerLevel.
  ///
  /// In bn, this message translates to:
  /// **'ধরন'**
  String get adminBannerLevel;

  /// No description provided for @adminDefaults.
  ///
  /// In bn, this message translates to:
  /// **'নতুন মেসের ডিফল্ট'**
  String get adminDefaults;

  /// No description provided for @adminDefaultsHelp.
  ///
  /// In bn, this message translates to:
  /// **'শুধু নতুন মেস তৈরির সময় কাজে লাগে'**
  String get adminDefaultsHelp;

  /// No description provided for @adminMonthStartDay.
  ///
  /// In bn, this message translates to:
  /// **'মাস শুরুর দিন (১–২৮)'**
  String get adminMonthStartDay;

  /// No description provided for @adminCutoff.
  ///
  /// In bn, this message translates to:
  /// **'মিল বন্ধের শেষ সময়'**
  String get adminCutoff;

  /// No description provided for @adminMealTypes.
  ///
  /// In bn, this message translates to:
  /// **'বেলা'**
  String get adminMealTypes;

  /// No description provided for @adminWeight.
  ///
  /// In bn, this message translates to:
  /// **'ওজন'**
  String get adminWeight;

  /// No description provided for @adminExpenseCategories.
  ///
  /// In bn, this message translates to:
  /// **'খরচের ধরন'**
  String get adminExpenseCategories;

  /// No description provided for @adminSplit.
  ///
  /// In bn, this message translates to:
  /// **'ভাগ'**
  String get adminSplit;

  /// No description provided for @adminSplitEqual.
  ///
  /// In bn, this message translates to:
  /// **'সমান ভাগ'**
  String get adminSplitEqual;

  /// No description provided for @adminSplitMeal.
  ///
  /// In bn, this message translates to:
  /// **'মিল অনুযায়ী'**
  String get adminSplitMeal;

  /// No description provided for @adminCatalogue.
  ///
  /// In bn, this message translates to:
  /// **'বাজারের তালিকা'**
  String get adminCatalogue;

  /// No description provided for @adminCatalogueHelp.
  ///
  /// In bn, this message translates to:
  /// **'বাজার যোগ করার সময় যে জিনিসগুলো বাছাই করা যায়'**
  String get adminCatalogueHelp;

  /// No description provided for @adminAddGroup.
  ///
  /// In bn, this message translates to:
  /// **'গ্রুপ যোগ করুন'**
  String get adminAddGroup;

  /// No description provided for @adminAddItem.
  ///
  /// In bn, this message translates to:
  /// **'জিনিস যোগ করুন'**
  String get adminAddItem;

  /// No description provided for @adminGroupName.
  ///
  /// In bn, this message translates to:
  /// **'গ্রুপের নাম'**
  String get adminGroupName;

  /// No description provided for @adminUnit.
  ///
  /// In bn, this message translates to:
  /// **'একক'**
  String get adminUnit;

  /// No description provided for @adminPaymentMethods.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্টের মাধ্যম'**
  String get adminPaymentMethods;

  /// No description provided for @adminPaymentMethodsHelp.
  ///
  /// In bn, this message translates to:
  /// **'কী বদলানো যায় না, শুধু নাম আর দেখানো/লুকানো'**
  String get adminPaymentMethodsHelp;

  /// No description provided for @adminLabelBn.
  ///
  /// In bn, this message translates to:
  /// **'নাম (বাংলা)'**
  String get adminLabelBn;

  /// No description provided for @adminLabelEn.
  ///
  /// In bn, this message translates to:
  /// **'নাম (ইংরেজি)'**
  String get adminLabelEn;

  /// No description provided for @adminAppNameBn.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপের নাম (বাংলা)'**
  String get adminAppNameBn;

  /// No description provided for @adminAppNameEn.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপের নাম (ইংরেজি)'**
  String get adminAppNameEn;

  /// No description provided for @adminTaglineBn.
  ///
  /// In bn, this message translates to:
  /// **'ট্যাগলাইন (বাংলা)'**
  String get adminTaglineBn;

  /// No description provided for @adminTaglineEn.
  ///
  /// In bn, this message translates to:
  /// **'ট্যাগলাইন (ইংরেজি)'**
  String get adminTaglineEn;

  /// No description provided for @adminBrandingReleaseNote.
  ///
  /// In bn, this message translates to:
  /// **'লগইন ও অ্যাকাউন্ট পর্দায় নাম, ট্যাগলাইন, লোগো আর রং বদলায়। লঞ্চার আইকন আর হোম স্ক্রিনের নাম বদলাতে নতুন রিলিজ লাগবে (অ্যান্ড্রয়েডের সীমাবদ্ধতা)।'**
  String get adminBrandingReleaseNote;

  /// No description provided for @adminLogo.
  ///
  /// In bn, this message translates to:
  /// **'লোগো'**
  String get adminLogo;

  /// No description provided for @adminLogoUpload.
  ///
  /// In bn, this message translates to:
  /// **'লোগো আপলোড'**
  String get adminLogoUpload;

  /// No description provided for @adminLogoReplace.
  ///
  /// In bn, this message translates to:
  /// **'লোগো বদলান'**
  String get adminLogoReplace;

  /// No description provided for @adminLogoRemove.
  ///
  /// In bn, this message translates to:
  /// **'লোগো সরান'**
  String get adminLogoRemove;

  /// No description provided for @adminLogoDefault.
  ///
  /// In bn, this message translates to:
  /// **'লোগো না থাকলে অ্যাপ নিজের \"ম\" চিহ্ন দেখায়'**
  String get adminLogoDefault;

  /// No description provided for @adminLogoSaveHint.
  ///
  /// In bn, this message translates to:
  /// **'আপলোডের পর সেভ চাপলে অ্যাপে দেখাবে'**
  String get adminLogoSaveHint;

  /// No description provided for @adminAccent.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাকসেন্ট রং'**
  String get adminAccent;

  /// No description provided for @adminAccentLight.
  ///
  /// In bn, this message translates to:
  /// **'লাইট থিম'**
  String get adminAccentLight;

  /// No description provided for @adminAccentDark.
  ///
  /// In bn, this message translates to:
  /// **'ডার্ক থিম'**
  String get adminAccentDark;

  /// No description provided for @adminContrast.
  ///
  /// In bn, this message translates to:
  /// **'কনট্রাস্ট {ratio}:১'**
  String adminContrast(String ratio);

  /// No description provided for @adminContrastOk.
  ///
  /// In bn, this message translates to:
  /// **'কনট্রাস্ট ঠিক আছে (৩:১ বা বেশি)'**
  String get adminContrastOk;

  /// No description provided for @adminContrastLow.
  ///
  /// In bn, this message translates to:
  /// **'কনট্রাস্ট কম (৩:১ এর নিচে): চিহ্ন ঝাপসা দেখাবে'**
  String get adminContrastLow;

  /// No description provided for @adminSecretsHelp.
  ///
  /// In bn, this message translates to:
  /// **'কী শুধু লেখা যায়, পড়া যায় না। সেভ করা মান কখনো দেখানো হয় না, শুধু শেষ ৪ অক্ষর।'**
  String get adminSecretsHelp;

  /// No description provided for @adminSecretNotSet.
  ///
  /// In bn, this message translates to:
  /// **'সেট করা নেই (এনভ ভ্যারিয়েবল ব্যবহার হবে)'**
  String get adminSecretNotSet;

  /// No description provided for @adminSecretSet.
  ///
  /// In bn, this message translates to:
  /// **'সেট করুন'**
  String get adminSecretSet;

  /// No description provided for @adminSecretReplace.
  ///
  /// In bn, this message translates to:
  /// **'বদলান'**
  String get adminSecretReplace;

  /// No description provided for @adminSecretValue.
  ///
  /// In bn, this message translates to:
  /// **'নতুন মান'**
  String get adminSecretValue;

  /// No description provided for @adminSecretValueHelp.
  ///
  /// In bn, this message translates to:
  /// **'আগের মান মুছে এটা বসবে'**
  String get adminSecretValueHelp;

  /// No description provided for @adminSecretDeleteTitle.
  ///
  /// In bn, this message translates to:
  /// **'{name} মুছবেন?'**
  String adminSecretDeleteTitle(String name);

  /// No description provided for @adminSecretDeleteBody.
  ///
  /// In bn, this message translates to:
  /// **'মুছলে গেটওয়ে আবার এনভ ভ্যারিয়েবল ব্যবহার করবে।'**
  String get adminSecretDeleteBody;

  /// No description provided for @adminUpdatedAt.
  ///
  /// In bn, this message translates to:
  /// **'আপডেট {date}'**
  String adminUpdatedAt(String date);

  /// No description provided for @adminAiSettings.
  ///
  /// In bn, this message translates to:
  /// **'এআই সেটিংস'**
  String get adminAiSettings;

  /// No description provided for @adminAiEnabled.
  ///
  /// In bn, this message translates to:
  /// **'এআই চালু'**
  String get adminAiEnabled;

  /// No description provided for @adminAllowPaid.
  ///
  /// In bn, this message translates to:
  /// **'পেইড মডেল চলতে দিন'**
  String get adminAllowPaid;

  /// No description provided for @adminAllowPaidHelp.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ থাকলে গেটওয়ে দাম আছে এমন OpenRouter মডেল বাদ দেয়'**
  String get adminAllowPaidHelp;

  /// No description provided for @adminQuotaMeal.
  ///
  /// In bn, this message translates to:
  /// **'দৈনিক মিল খসড়া কোটা (মেস প্রতি)'**
  String get adminQuotaMeal;

  /// No description provided for @adminQuotaBazar.
  ///
  /// In bn, this message translates to:
  /// **'দৈনিক বাজার স্ক্যান কোটা (মেস প্রতি)'**
  String get adminQuotaBazar;

  /// No description provided for @adminTimeoutMs.
  ///
  /// In bn, this message translates to:
  /// **'টাইমআউট (মিলিসেকেন্ড)'**
  String get adminTimeoutMs;

  /// No description provided for @adminTemperature.
  ///
  /// In bn, this message translates to:
  /// **'টেম্পারেচার'**
  String get adminTemperature;

  /// No description provided for @adminTextChain.
  ///
  /// In bn, this message translates to:
  /// **'টেক্সট চেইন (মিলের খসড়া)'**
  String get adminTextChain;

  /// No description provided for @adminVisionChain.
  ///
  /// In bn, this message translates to:
  /// **'ভিশন চেইন (রসিদ স্ক্যান)'**
  String get adminVisionChain;

  /// No description provided for @adminChains.
  ///
  /// In bn, this message translates to:
  /// **'চেইন'**
  String get adminChains;

  /// No description provided for @adminChainEmpty.
  ///
  /// In bn, this message translates to:
  /// **'কোনো মডেল নেই। তালিকা থেকে যোগ করুন।'**
  String get adminChainEmpty;

  /// No description provided for @adminAddManually.
  ///
  /// In bn, this message translates to:
  /// **'হাতে মডেল যোগ'**
  String get adminAddManually;

  /// No description provided for @adminProvider.
  ///
  /// In bn, this message translates to:
  /// **'প্রোভাইডার'**
  String get adminProvider;

  /// No description provided for @adminModelId.
  ///
  /// In bn, this message translates to:
  /// **'মডেল আইডি'**
  String get adminModelId;

  /// No description provided for @adminModel.
  ///
  /// In bn, this message translates to:
  /// **'মডেল'**
  String get adminModel;

  /// No description provided for @adminModelCatalogue.
  ///
  /// In bn, this message translates to:
  /// **'মডেল তালিকা'**
  String get adminModelCatalogue;

  /// No description provided for @adminAll.
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get adminAll;

  /// No description provided for @adminSearchModels.
  ///
  /// In bn, this message translates to:
  /// **'মডেল খুঁজুন'**
  String get adminSearchModels;

  /// No description provided for @adminFree.
  ///
  /// In bn, this message translates to:
  /// **'ফ্রি'**
  String get adminFree;

  /// No description provided for @adminPaid.
  ///
  /// In bn, this message translates to:
  /// **'পেইড'**
  String get adminPaid;

  /// No description provided for @adminVision.
  ///
  /// In bn, this message translates to:
  /// **'ভিশন'**
  String get adminVision;

  /// No description provided for @adminText.
  ///
  /// In bn, this message translates to:
  /// **'টেক্সট'**
  String get adminText;

  /// No description provided for @adminMinContext.
  ///
  /// In bn, this message translates to:
  /// **'ন্যূনতম কনটেক্সট'**
  String get adminMinContext;

  /// No description provided for @adminMaxPrice.
  ///
  /// In bn, this message translates to:
  /// **'সর্বোচ্চ দাম \$/১M'**
  String get adminMaxPrice;

  /// No description provided for @adminContext.
  ///
  /// In bn, this message translates to:
  /// **'কনটেক্সট'**
  String get adminContext;

  /// No description provided for @adminInputPrice.
  ///
  /// In bn, this message translates to:
  /// **'ইনপুট \$/১M'**
  String get adminInputPrice;

  /// No description provided for @adminOutputPrice.
  ///
  /// In bn, this message translates to:
  /// **'আউটপুট \$/১M'**
  String get adminOutputPrice;

  /// No description provided for @adminAddToText.
  ///
  /// In bn, this message translates to:
  /// **'টেক্সট চেইনে যোগ'**
  String get adminAddToText;

  /// No description provided for @adminAddToVision.
  ///
  /// In bn, this message translates to:
  /// **'ভিশন চেইনে যোগ'**
  String get adminAddToVision;

  /// No description provided for @adminTest.
  ///
  /// In bn, this message translates to:
  /// **'টেস্ট'**
  String get adminTest;

  /// No description provided for @adminTestOk.
  ///
  /// In bn, this message translates to:
  /// **'ঠিক আছে · {ms} ms · {sample}'**
  String adminTestOk(String ms, String sample);

  /// No description provided for @adminGatewayMissing.
  ///
  /// In bn, this message translates to:
  /// **'এআই গেটওয়ে সেট করা নেই। env.json-এ AI_GATEWAY_URL দিয়ে প্যানেল আবার বিল্ড করুন, আর গেটওয়ের CORS-এ এই সাইটের ঠিকানা যোগ করুন।'**
  String get adminGatewayMissing;

  /// No description provided for @adminPaidWarningTitle.
  ///
  /// In bn, this message translates to:
  /// **'পেইড মডেল সেভ করবেন?'**
  String get adminPaidWarningTitle;

  /// No description provided for @adminPaidWarningBody.
  ///
  /// In bn, this message translates to:
  /// **'\"পেইড মডেল চলতে দিন\" বন্ধ, তাই গেটওয়ে এই মডেলগুলো বাদ দেবে:'**
  String get adminPaidWarningBody;

  /// No description provided for @adminSaveAnyway.
  ///
  /// In bn, this message translates to:
  /// **'তবুও সেভ করুন'**
  String get adminSaveAnyway;

  /// No description provided for @stampPaid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get stampPaid;

  /// No description provided for @bazarBuyers.
  ///
  /// In bn, this message translates to:
  /// **'কে কে বাজারে গেছে'**
  String get bazarBuyers;

  /// No description provided for @bazarPickBuyer.
  ///
  /// In bn, this message translates to:
  /// **'অন্তত একজন বাছুন'**
  String get bazarPickBuyer;

  /// No description provided for @bazarPayer.
  ///
  /// In bn, this message translates to:
  /// **'কে টাকা দিয়েছে'**
  String get bazarPayer;

  /// No description provided for @bazarTotal.
  ///
  /// In bn, this message translates to:
  /// **'মোট'**
  String get bazarTotal;

  /// No description provided for @bazarItemRemoved.
  ///
  /// In bn, this message translates to:
  /// **'আইটেম বাদ দেওয়া হলো'**
  String get bazarItemRemoved;

  /// No description provided for @undo.
  ///
  /// In bn, this message translates to:
  /// **'ফিরিয়ে আনুন'**
  String get undo;

  /// No description provided for @bazarPickerTitle.
  ///
  /// In bn, this message translates to:
  /// **'তালিকা থেকে বাছুন'**
  String get bazarPickerTitle;

  /// No description provided for @bazarPickerSearch.
  ///
  /// In bn, this message translates to:
  /// **'খুঁজুন বা নতুন নাম লিখুন'**
  String get bazarPickerSearch;

  /// No description provided for @bazarPickerAddNamed.
  ///
  /// In bn, this message translates to:
  /// **'“{name}” যোগ করুন'**
  String bazarPickerAddNamed(String name);

  /// No description provided for @bazarUnitNone.
  ///
  /// In bn, this message translates to:
  /// **'একক ছাড়া'**
  String get bazarUnitNone;

  /// No description provided for @bazarQtyLabel.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ {qty}, একক বদলাতে ট্যাপ করুন'**
  String bazarQtyLabel(String qty);

  /// No description provided for @bazarSwipeHint.
  ///
  /// In bn, this message translates to:
  /// **'বাদ দিতে বাঁয়ে সরান'**
  String get bazarSwipeHint;

  /// No description provided for @pushTitle.
  ///
  /// In bn, this message translates to:
  /// **'নোটিফিকেশন'**
  String get pushTitle;

  /// No description provided for @pushIntro.
  ///
  /// In bn, this message translates to:
  /// **'মেসের কোন খবর ফোনে পেতে চান, বেছে নিন'**
  String get pushIntro;

  /// No description provided for @pushPermissionBody.
  ///
  /// In bn, this message translates to:
  /// **'মেসের খবর পেতে ফোনের নোটিফিকেশন চালু করুন'**
  String get pushPermissionBody;

  /// No description provided for @pushOpenSub.
  ///
  /// In bn, this message translates to:
  /// **'বাজার, খরচ, জমা, নোটিশ'**
  String get pushOpenSub;

  /// No description provided for @pushJoinRequest.
  ///
  /// In bn, this message translates to:
  /// **'যোগদানের অনুরোধ'**
  String get pushJoinRequest;

  /// No description provided for @pushJoinRequestSub.
  ///
  /// In bn, this message translates to:
  /// **'কেউ মেসে যোগ দিতে চাইলে'**
  String get pushJoinRequestSub;

  /// No description provided for @pushDepositPending.
  ///
  /// In bn, this message translates to:
  /// **'যাচাইয়ের অপেক্ষায় জমা'**
  String get pushDepositPending;

  /// No description provided for @pushDepositPendingSub.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সদস্য টাকা জমা দিলে'**
  String get pushDepositPendingSub;

  /// No description provided for @pushDepositVerified.
  ///
  /// In bn, this message translates to:
  /// **'জমা গৃহীত হলে'**
  String get pushDepositVerified;

  /// No description provided for @pushDepositVerifiedSub.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার আপনার জমা যাচাই করলে'**
  String get pushDepositVerifiedSub;

  /// No description provided for @pushDepositRejected.
  ///
  /// In bn, this message translates to:
  /// **'জমা বাতিল হলে'**
  String get pushDepositRejected;

  /// No description provided for @pushDepositRejectedSub.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার আপনার জমা বাতিল করলে'**
  String get pushDepositRejectedSub;

  /// No description provided for @pushNotice.
  ///
  /// In bn, this message translates to:
  /// **'নতুন নোটিশ'**
  String get pushNotice;

  /// No description provided for @pushNoticeSub.
  ///
  /// In bn, this message translates to:
  /// **'নোটিশ বোর্ডে কিছু লেখা হলে'**
  String get pushNoticeSub;

  /// No description provided for @pushBazar.
  ///
  /// In bn, this message translates to:
  /// **'নতুন বাজার'**
  String get pushBazar;

  /// No description provided for @pushBazarSub.
  ///
  /// In bn, this message translates to:
  /// **'কেউ বাজারের হিসাব যোগ করলে'**
  String get pushBazarSub;

  /// No description provided for @pushExpense.
  ///
  /// In bn, this message translates to:
  /// **'নতুন খরচ'**
  String get pushExpense;

  /// No description provided for @pushExpenseSub.
  ///
  /// In bn, this message translates to:
  /// **'বিল বা অন্য খরচ যোগ হলে'**
  String get pushExpenseSub;

  /// No description provided for @pushMonthClosed.
  ///
  /// In bn, this message translates to:
  /// **'মাস বন্ধ'**
  String get pushMonthClosed;

  /// No description provided for @pushMonthClosedSub.
  ///
  /// In bn, this message translates to:
  /// **'মাসের হিসাব চূড়ান্ত হলে'**
  String get pushMonthClosedSub;

  /// No description provided for @pushDue.
  ///
  /// In bn, this message translates to:
  /// **'বকেয়ার রিমাইন্ডার'**
  String get pushDue;

  /// No description provided for @pushDueSub.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার বকেয়া মনে করিয়ে দিলে'**
  String get pushDueSub;

  /// No description provided for @dueRemindButton.
  ///
  /// In bn, this message translates to:
  /// **'বকেয়া মনে করিয়ে দিন'**
  String get dueRemindButton;

  /// No description provided for @dueRemindConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'বকেয়া রিমাইন্ডার পাঠাবেন?'**
  String get dueRemindConfirmTitle;

  /// No description provided for @dueRemindConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'যাদের বকেয়া আছে, তারা ফোনে নিজের বকেয়ার পরিমাণসহ নোটিফিকেশন পাবেন।'**
  String get dueRemindConfirmBody;

  /// No description provided for @dueRemindSend.
  ///
  /// In bn, this message translates to:
  /// **'পাঠান'**
  String get dueRemindSend;

  /// No description provided for @dueRemindSent.
  ///
  /// In bn, this message translates to:
  /// **'{count} জনকে রিমাইন্ডার পাঠানো হয়েছে'**
  String dueRemindSent(String count);

  /// No description provided for @dueRemindNone.
  ///
  /// In bn, this message translates to:
  /// **'কাউকে পাঠানো যায়নি: বকেয়া থাকা সদস্যদের ফোনে নোটিফিকেশন চালু নেই'**
  String get dueRemindNone;

  /// No description provided for @msgTitle.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা'**
  String get msgTitle;

  /// No description provided for @msgMoreSub.
  ///
  /// In bn, this message translates to:
  /// **'জরুরি কথা ও সমস্যা জানানো'**
  String get msgMoreSub;

  /// No description provided for @msgEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো বার্তা নেই। জরুরি কিছু হলে বা কোনো হিসাব ভুল মনে হলে ম্যানেজারকে লিখুন।'**
  String get msgEmpty;

  /// No description provided for @msgEmptyManager.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যদের কোনো বার্তা নেই'**
  String get msgEmptyManager;

  /// No description provided for @msgEmptyResolved.
  ///
  /// In bn, this message translates to:
  /// **'কোনো মীমাংসিত বার্তা নেই'**
  String get msgEmptyResolved;

  /// No description provided for @msgNew.
  ///
  /// In bn, this message translates to:
  /// **'নতুন বার্তা'**
  String get msgNew;

  /// No description provided for @msgFilterOpen.
  ///
  /// In bn, this message translates to:
  /// **'খোলা'**
  String get msgFilterOpen;

  /// No description provided for @msgResolved.
  ///
  /// In bn, this message translates to:
  /// **'মীমাংসিত'**
  String get msgResolved;

  /// No description provided for @msgUnread.
  ///
  /// In bn, this message translates to:
  /// **'অপঠিত'**
  String get msgUnread;

  /// No description provided for @msgYou.
  ///
  /// In bn, this message translates to:
  /// **'আপনি: {text}'**
  String msgYou(String text);

  /// No description provided for @msgComposeHint.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা লিখুন…'**
  String get msgComposeHint;

  /// No description provided for @msgSend.
  ///
  /// In bn, this message translates to:
  /// **'পাঠান'**
  String get msgSend;

  /// No description provided for @msgSending.
  ///
  /// In bn, this message translates to:
  /// **'পাঠানো হচ্ছে…'**
  String get msgSending;

  /// No description provided for @msgNotSent.
  ///
  /// In bn, this message translates to:
  /// **'পাঠানো যায়নি · আবার চেষ্টা করুন'**
  String get msgNotSent;

  /// No description provided for @msgResolve.
  ///
  /// In bn, this message translates to:
  /// **'মীমাংসিত করুন'**
  String get msgResolve;

  /// No description provided for @msgReopen.
  ///
  /// In bn, this message translates to:
  /// **'আবার খুলুন'**
  String get msgReopen;

  /// No description provided for @msgResolvedNote.
  ///
  /// In bn, this message translates to:
  /// **'বিষয়টি মীমাংসিত। আবার লিখলে খুলে যাবে।'**
  String get msgResolvedNote;

  /// No description provided for @msgGone.
  ///
  /// In bn, this message translates to:
  /// **'বার্তাটি পাওয়া যায়নি'**
  String get msgGone;

  /// No description provided for @msgSubject.
  ///
  /// In bn, this message translates to:
  /// **'বিষয়'**
  String get msgSubject;

  /// No description provided for @msgSubjectRequired.
  ///
  /// In bn, this message translates to:
  /// **'বিষয় লিখুন'**
  String get msgSubjectRequired;

  /// No description provided for @msgBody.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা'**
  String get msgBody;

  /// No description provided for @msgBodyRequired.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা লিখুন'**
  String get msgBodyRequired;

  /// No description provided for @msgTo.
  ///
  /// In bn, this message translates to:
  /// **'কাকে'**
  String get msgTo;

  /// No description provided for @msgToManagers.
  ///
  /// In bn, this message translates to:
  /// **'মেসের ম্যানেজার বার্তাটি দেখবেন। এটা চ্যাট নয়, উত্তর এলে নোটিফিকেশন পাবেন।'**
  String get msgToManagers;

  /// No description provided for @msgMemberRequired.
  ///
  /// In bn, this message translates to:
  /// **'একজন সদস্য বাছুন'**
  String get msgMemberRequired;

  /// No description provided for @msgReportSubject.
  ///
  /// In bn, this message translates to:
  /// **'সমস্যা: {label}'**
  String msgReportSubject(String label);

  /// No description provided for @msgReportStarter.
  ///
  /// In bn, this message translates to:
  /// **'এই তথ্যটি ভুল মনে হচ্ছে, দয়া করে ঠিক করে দিন।'**
  String get msgReportStarter;

  /// No description provided for @msgReport.
  ///
  /// In bn, this message translates to:
  /// **'সমস্যা জানান'**
  String get msgReport;

  /// No description provided for @msgSent.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা পাঠানো হয়েছে'**
  String get msgSent;

  /// No description provided for @msgAbout.
  ///
  /// In bn, this message translates to:
  /// **'যে এন্ট্রি নিয়ে'**
  String get msgAbout;

  /// No description provided for @msgRefDeposit.
  ///
  /// In bn, this message translates to:
  /// **'জমা'**
  String get msgRefDeposit;

  /// No description provided for @msgRefBazar.
  ///
  /// In bn, this message translates to:
  /// **'বাজার'**
  String get msgRefBazar;

  /// No description provided for @msgRefExpense.
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get msgRefExpense;

  /// No description provided for @msgRefMeal.
  ///
  /// In bn, this message translates to:
  /// **'মিল'**
  String get msgRefMeal;

  /// No description provided for @msgRefOther.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get msgRefOther;

  /// No description provided for @msgDeletedUser.
  ///
  /// In bn, this message translates to:
  /// **'সাবেক সদস্য'**
  String get msgDeletedUser;

  /// No description provided for @pushMessage.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা'**
  String get pushMessage;

  /// No description provided for @pushMessageSub.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার বা সদস্য আপনাকে লিখলে'**
  String get pushMessageSub;

  /// No description provided for @auditVerified.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই করেছেন'**
  String get auditVerified;

  /// No description provided for @auditRejected.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল করেছেন'**
  String get auditRejected;

  /// No description provided for @auditOff.
  ///
  /// In bn, this message translates to:
  /// **'অফ'**
  String get auditOff;

  /// No description provided for @attnTitle.
  ///
  /// In bn, this message translates to:
  /// **'এখন যা দেখতে হবে'**
  String get attnTitle;

  /// No description provided for @attnDeposits.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি জমা যাচাই বাকি'**
  String attnDeposits(String count);

  /// No description provided for @attnJoin.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি যোগদানের অনুরোধ'**
  String attnJoin(String count);

  /// No description provided for @attnMessages.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি নতুন বার্তা'**
  String attnMessages(String count);

  /// No description provided for @attnMeals.
  ///
  /// In bn, this message translates to:
  /// **'আজ {count} জনের মিল বসানো হয়নি'**
  String attnMeals(String count);

  /// No description provided for @cashTitle.
  ///
  /// In bn, this message translates to:
  /// **'হাতে নগদ (মেস ফান্ড)'**
  String get cashTitle;

  /// No description provided for @cashProof.
  ///
  /// In bn, this message translates to:
  /// **'জমা {deposits} − ফান্ড থেকে খরচ {spent}'**
  String cashProof(String deposits, String spent);

  /// No description provided for @cashPending.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই বাকি {amount}, এখনো ধরা হয়নি'**
  String cashPending(String amount);

  /// No description provided for @dashSeeAll.
  ///
  /// In bn, this message translates to:
  /// **'সবাই দেখুন'**
  String get dashSeeAll;

  /// No description provided for @dashOthers.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get dashOthers;

  /// No description provided for @dashAllSettled.
  ///
  /// In bn, this message translates to:
  /// **'কারো বকেয়া নেই'**
  String get dashAllSettled;

  /// No description provided for @mineBalance.
  ///
  /// In bn, this message translates to:
  /// **'আমার হিসাব'**
  String get mineBalance;

  /// No description provided for @myTodayTitle.
  ///
  /// In bn, this message translates to:
  /// **'আজ আমার মিল'**
  String get myTodayTitle;

  /// No description provided for @transTitle.
  ///
  /// In bn, this message translates to:
  /// **'সবার হিসাব'**
  String get transTitle;

  /// No description provided for @transNote.
  ///
  /// In bn, this message translates to:
  /// **'এই মাস · জমা, নিজের পকেট থেকে দেওয়া টাকা আর ব্যালেন্স'**
  String get transNote;

  /// No description provided for @transDeposits.
  ///
  /// In bn, this message translates to:
  /// **'জমা'**
  String get transDeposits;

  /// No description provided for @transOwnPocket.
  ///
  /// In bn, this message translates to:
  /// **'নিজে দিয়েছেন'**
  String get transOwnPocket;

  /// No description provided for @transBalance.
  ///
  /// In bn, this message translates to:
  /// **'ব্যালেন্স'**
  String get transBalance;

  /// No description provided for @activityTitle.
  ///
  /// In bn, this message translates to:
  /// **'আমার বিষয়ে এন্ট্রি'**
  String get activityTitle;

  /// No description provided for @activityEmpty.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার আপনার মিল, জমা বা বাজার নিয়ে কিছু লিখলে এখানে দেখাবে'**
  String get activityEmpty;

  /// No description provided for @reportProblem.
  ///
  /// In bn, this message translates to:
  /// **'সমস্যা জানান'**
  String get reportProblem;

  /// No description provided for @youTag.
  ///
  /// In bn, this message translates to:
  /// **'আপনি'**
  String get youTag;

  /// No description provided for @activitySeeAll.
  ///
  /// In bn, this message translates to:
  /// **'সব দেখুন'**
  String get activitySeeAll;

  /// No description provided for @auditMealMine.
  ///
  /// In bn, this message translates to:
  /// **'আপনার মিল'**
  String get auditMealMine;

  /// No description provided for @auditDepositMine.
  ///
  /// In bn, this message translates to:
  /// **'আপনার জমা'**
  String get auditDepositMine;

  /// No description provided for @messagesComingSoon.
  ///
  /// In bn, this message translates to:
  /// **'বার্তা পাঠানোর সুবিধা শিগগিরই আসছে। ততক্ষণ ম্যানেজারকে সরাসরি জানান।'**
  String get messagesComingSoon;

  /// No description provided for @msgGroupShort.
  ///
  /// In bn, this message translates to:
  /// **'মেস গ্রুপ'**
  String get msgGroupShort;

  /// No description provided for @msgGroupTitle.
  ///
  /// In bn, this message translates to:
  /// **'{mess} গ্রুপ'**
  String msgGroupTitle(String mess);

  /// No description provided for @msgGroupMembers.
  ///
  /// In bn, this message translates to:
  /// **'{count} জন সদস্য'**
  String msgGroupMembers(String count);

  /// No description provided for @msgGroupEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো বার্তা নেই। মেসের সবাইকে কিছু জানাতে নিচে লিখুন।'**
  String get msgGroupEmpty;

  /// No description provided for @msgHidden.
  ///
  /// In bn, this message translates to:
  /// **'বার্তাটি মুছে ফেলা হয়েছে'**
  String get msgHidden;

  /// No description provided for @msgHide.
  ///
  /// In bn, this message translates to:
  /// **'বার্তাটি মুছুন'**
  String get msgHide;

  /// No description provided for @msgHideBody.
  ///
  /// In bn, this message translates to:
  /// **'বার্তাটি সবার কাছ থেকে সরে যাবে। এটা ফেরানো যাবে না।'**
  String get msgHideBody;

  /// No description provided for @msgHideAction.
  ///
  /// In bn, this message translates to:
  /// **'মুছুন'**
  String get msgHideAction;

  /// No description provided for @msgDayToday.
  ///
  /// In bn, this message translates to:
  /// **'আজ'**
  String get msgDayToday;

  /// No description provided for @msgDayYesterday.
  ///
  /// In bn, this message translates to:
  /// **'গতকাল'**
  String get msgDayYesterday;

  /// No description provided for @homeMsgManager.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজারকে বার্তা'**
  String get homeMsgManager;

  /// No description provided for @homeUnreadCount.
  ///
  /// In bn, this message translates to:
  /// **'{count}টি অপঠিত'**
  String homeUnreadCount(String count);

  /// No description provided for @pushGroup.
  ///
  /// In bn, this message translates to:
  /// **'মেস গ্রুপ'**
  String get pushGroup;

  /// No description provided for @pushGroupSub.
  ///
  /// In bn, this message translates to:
  /// **'গ্রুপে নতুন বার্তা এলে। বন্ধ করলে গ্রুপ মিউট থাকবে'**
  String get pushGroupSub;

  /// No description provided for @mealOffUntil.
  ///
  /// In bn, this message translates to:
  /// **'{time} পর্যন্ত'**
  String mealOffUntil(String time);

  /// No description provided for @myMealCount.
  ///
  /// In bn, this message translates to:
  /// **'{count} মিল'**
  String myMealCount(String count);

  /// No description provided for @myMealOff.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ'**
  String get myMealOff;

  /// No description provided for @myTomorrow.
  ///
  /// In bn, this message translates to:
  /// **'কাল'**
  String get myTomorrow;

  /// No description provided for @dayTomorrow.
  ///
  /// In bn, this message translates to:
  /// **'কাল'**
  String get dayTomorrow;

  /// No description provided for @dayYesterday.
  ///
  /// In bn, this message translates to:
  /// **'গতকাল'**
  String get dayYesterday;

  /// No description provided for @settingsLeadTitle.
  ///
  /// In bn, this message translates to:
  /// **'মিল বন্ধের সময়সীমা'**
  String get settingsLeadTitle;

  /// No description provided for @settingsLeadHelp.
  ///
  /// In bn, this message translates to:
  /// **'খাবারের কতক্ষণ আগ পর্যন্ত সদস্যরা নিজের মিল বন্ধ বা চালু করতে পারবেন'**
  String get settingsLeadHelp;

  /// No description provided for @settingsLeadHours.
  ///
  /// In bn, this message translates to:
  /// **'খাবারের {hours} ঘণ্টা আগে'**
  String settingsLeadHours(String hours);

  /// No description provided for @settingsLeadPrevDay.
  ///
  /// In bn, this message translates to:
  /// **'আগের দিন {time}'**
  String settingsLeadPrevDay(String time);

  /// No description provided for @settingsLeadCustom.
  ///
  /// In bn, this message translates to:
  /// **'নিজে ঠিক করুন'**
  String get settingsLeadCustom;

  /// No description provided for @settingsLeadCustomLabel.
  ///
  /// In bn, this message translates to:
  /// **'খাবারের কত ঘণ্টা আগে (০–৪৮)'**
  String get settingsLeadCustomLabel;

  /// No description provided for @settingsLeadCustomInvalid.
  ///
  /// In bn, this message translates to:
  /// **'০ থেকে ৪৮ ঘণ্টার মধ্যে দিন'**
  String get settingsLeadCustomInvalid;

  /// No description provided for @settingsLeadExample.
  ///
  /// In bn, this message translates to:
  /// **'আজ {meal} মিল বন্ধ করা যাবে {time} পর্যন্ত'**
  String settingsLeadExample(String meal, String time);

  /// No description provided for @mealTypesServeTime.
  ///
  /// In bn, this message translates to:
  /// **'খাবারের সময়'**
  String get mealTypesServeTime;

  /// No description provided for @mealOffHintLead.
  ///
  /// In bn, this message translates to:
  /// **'খাবারের {hours} ঘণ্টা আগ পর্যন্ত নিজের মিল বন্ধ করা যায়'**
  String mealOffHintLead(String hours);

  /// No description provided for @msgMealOff.
  ///
  /// In bn, this message translates to:
  /// **'{name} {day} {meal} মিল বন্ধ করেছেন'**
  String msgMealOff(String name, String day, String meal);

  /// No description provided for @msgMealOn.
  ///
  /// In bn, this message translates to:
  /// **'{name} {day} {meal} মিল আবার চালু করেছেন'**
  String msgMealOn(String name, String day, String meal);

  /// No description provided for @myMealNotEntered.
  ///
  /// In bn, this message translates to:
  /// **'এখনো দেওয়া হয়নি'**
  String get myMealNotEntered;

  /// No description provided for @mealOffConfirmTitle.
  ///
  /// In bn, this message translates to:
  /// **'{day} {meal} মিল বন্ধ করবেন?'**
  String mealOffConfirmTitle(Object day, Object meal);

  /// No description provided for @mealOffConfirmBody.
  ///
  /// In bn, this message translates to:
  /// **'বন্ধ করলে মেস গ্রুপে আপনার পক্ষ থেকে সবাইকে জানানো হবে।'**
  String get mealOffConfirmBody;

  /// No description provided for @mealOffConfirmAction.
  ///
  /// In bn, this message translates to:
  /// **'হ্যাঁ, বন্ধ করুন'**
  String get mealOffConfirmAction;

  /// No description provided for @homeNoticeAll.
  ///
  /// In bn, this message translates to:
  /// **'সব নোটিশ'**
  String get homeNoticeAll;

  /// No description provided for @inboxTitle.
  ///
  /// In bn, this message translates to:
  /// **'বিজ্ঞপ্তি'**
  String get inboxTitle;

  /// No description provided for @inboxMoreSub.
  ///
  /// In bn, this message translates to:
  /// **'যা যা জানানো হয়েছে, এক জায়গায়'**
  String get inboxMoreSub;

  /// No description provided for @inboxMarkAllRead.
  ///
  /// In bn, this message translates to:
  /// **'সব পড়া হয়েছে'**
  String get inboxMarkAllRead;

  /// No description provided for @inboxEmpty.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো বিজ্ঞপ্তি নেই। জমা, বাজার বা নোটিশে কিছু হলে এখানে দেখবেন।'**
  String get inboxEmpty;

  /// No description provided for @inboxUnread.
  ///
  /// In bn, this message translates to:
  /// **'অপঠিত'**
  String get inboxUnread;

  /// No description provided for @inboxPushDepositAdded.
  ///
  /// In bn, this message translates to:
  /// **'আপনার নামে জমা'**
  String get inboxPushDepositAdded;

  /// No description provided for @inboxPushDepositAddedSub.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার আপনার জমা লিখলে'**
  String get inboxPushDepositAddedSub;

  /// No description provided for @inboxPushBazarRequest.
  ///
  /// In bn, this message translates to:
  /// **'সদস্যের বাজার'**
  String get inboxPushBazarRequest;

  /// No description provided for @inboxPushBazarRequestSub.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সদস্য নিজের বাজার অনুমোদনের জন্য পাঠালে'**
  String get inboxPushBazarRequestSub;

  /// No description provided for @inboxPushBazarReviewed.
  ///
  /// In bn, this message translates to:
  /// **'আমার বাজারের সিদ্ধান্ত'**
  String get inboxPushBazarReviewed;

  /// No description provided for @inboxPushBazarReviewedSub.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানেজার আপনার বাজার মেনে নিলে বা ফিরিয়ে দিলে'**
  String get inboxPushBazarReviewedSub;
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
