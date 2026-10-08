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
