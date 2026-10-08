// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Meal Bazar';

  @override
  String get retry => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get loading => 'Loading';

  @override
  String get navToday => 'Today';

  @override
  String get navMeals => 'Meals';

  @override
  String get navMoney => 'Money';

  @override
  String get navMore => 'More';

  @override
  String get syncSynced => 'Saved';

  @override
  String get syncSyncing => 'Syncing';

  @override
  String get syncOffline => 'Saved offline';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get networkError =>
      'No internet connection. Turn on data and try again.';

  @override
  String get emptyGeneric => 'Nothing here yet';
}
