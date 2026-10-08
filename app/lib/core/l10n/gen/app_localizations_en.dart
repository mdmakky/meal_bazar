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

  @override
  String get authPhoneTitle => 'Your phone number';

  @override
  String get authPhoneHint => 'We will send a 6-digit code to this number';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authPhoneInvalid =>
      'Enter a valid mobile number, like 01712345678';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authCodeTitle => 'Enter the 6-digit code';

  @override
  String authCodeSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get authCodeLabel => 'Code';

  @override
  String get authVerify => 'Sign in';

  @override
  String get authResend => 'Send code again';

  @override
  String authResendIn(int seconds) {
    return 'You can resend the code in ${seconds}s';
  }

  @override
  String get authChangeNumber => 'Change number';

  @override
  String get authProfileTitle => 'What is your name?';

  @override
  String get authProfileHint =>
      'Everyone in the mess will see you by this name';

  @override
  String get authNameLabel => 'Your name';

  @override
  String get authNameRequired => 'Enter your name';

  @override
  String get authLanguageLabel => 'App language';

  @override
  String get authProfileSave => 'Continue';

  @override
  String get shellComingSoon => 'Coming soon, in the next update';

  @override
  String get failureNotAuthenticated => 'Please sign in again';

  @override
  String get failureNotManager => 'Only a manager can do this';

  @override
  String get failureInvalidInvite =>
      'This code does not work. Ask the manager for a new one.';

  @override
  String get failureAlreadyMember => 'You are already in this mess';

  @override
  String get failureLastManager => 'The mess needs at least one manager';

  @override
  String get failureMonthClosed =>
      'This month is closed and can no longer be changed';

  @override
  String get failureInvalidOtp =>
      'That code did not match. Check it and try again.';

  @override
  String get failureRateLimited =>
      'Too many tries. Please wait a little and try again.';

  @override
  String get failureValidation =>
      'Some details are not right. Check them and try again.';

  @override
  String get configMissingTitle => 'Supabase config missing';

  @override
  String get configMissingBody =>
      'Run the app with --dart-define SUPABASE_URL and SUPABASE_ANON_KEY.';

  @override
  String get messOnboardingTitle => 'You need a mess to start';

  @override
  String get messOnboardingBody =>
      'If you are the manager, open a new mess. If your mess already uses the app, get a code from the manager and join.';

  @override
  String get messCreateAction => 'Open a new mess';

  @override
  String get messJoinAction => 'Join with a code';

  @override
  String get messCreateTitle => 'New mess';

  @override
  String get messNameLabel => 'Mess name';

  @override
  String get messNameHint => 'e.g. Mirpur 10 Bachelor Mess';

  @override
  String get messNameRequired => 'Enter a name';

  @override
  String get messYourNameLabel => 'Your name in the mess';

  @override
  String get messYourNameHelp => 'Everyone in the mess sees you by this name';

  @override
  String get messMonthStartLabel => 'Month starts on';

  @override
  String get messMonthStartHelp =>
      'Each month runs from this day to the same day next month';

  @override
  String messMonthStartDay(String day) {
    return 'Day $day';
  }

  @override
  String get messCreateSubmit => 'Open mess';

  @override
  String get messJoinTitle => 'Join a mess';

  @override
  String get messCodeLabel => 'Invite code';

  @override
  String get messCodeHelp => 'Get the 6-character code from your manager';

  @override
  String get messCodeInvalid => 'The code must be 6 characters';

  @override
  String get messScanQr => 'Scan QR';

  @override
  String get messScanTitle => 'Scan the QR code';

  @override
  String get messScanHint => 'Hold the manager\'s QR code inside the frame';

  @override
  String get messJoinSubmit => 'Send join request';

  @override
  String get messPendingTitle => 'Waiting for approval';

  @override
  String messPendingBody(String mess) {
    return 'You can see the mess accounts as soon as the manager of $mess approves your request.';
  }

  @override
  String get messPendingBodyNoName =>
      'You can see the mess accounts as soon as the manager approves your request.';

  @override
  String get messPendingRefresh => 'Check again';

  @override
  String get messPendingStill => 'Not approved yet';

  @override
  String get messPendingJoinOther => 'Join another mess';

  @override
  String get moreTitle => 'More';

  @override
  String get moreMembers => 'Members';

  @override
  String get moreInvite => 'Invite members';

  @override
  String get moreSettings => 'Mess settings';

  @override
  String get moreSwitchMess => 'Switch mess';

  @override
  String get moreRoleManager => 'Manager';

  @override
  String get moreRoleMember => 'Member';

  @override
  String get moreSignOut => 'Sign out';

  @override
  String get moreSignOutConfirmTitle => 'Sign out?';

  @override
  String get moreSignOutConfirmBody =>
      'You will need a code on your phone to sign back in. The mess accounts stay as they are.';

  @override
  String get membersTitle => 'Members';

  @override
  String get membersPending => 'Want to join';

  @override
  String get membersActive => 'Active';

  @override
  String get membersInactive => 'Inactive';

  @override
  String get membersLeft => 'Left';

  @override
  String get membersRoleManager => 'Manager';

  @override
  String get membersNoApp => 'No app';

  @override
  String get membersYou => '(you)';

  @override
  String membersRoom(String room) {
    return 'Room $room';
  }

  @override
  String membersLeftOn(String date) {
    return 'Left on $date';
  }

  @override
  String get membersEmpty => 'No members yet. Invite everyone with a code.';

  @override
  String get membersApprove => 'Approve';

  @override
  String membersApproved(String name) {
    return '$name is now a member';
  }

  @override
  String get membersReject => 'Decline';

  @override
  String get membersRejected => 'Request declined';

  @override
  String membersRejectConfirmTitle(String name) {
    return 'Decline $name\'s request?';
  }

  @override
  String get membersRejectConfirmBody =>
      'They can send a new request with a code later.';

  @override
  String get membersMakeManager => 'Make manager';

  @override
  String get membersMakeMember => 'Make regular member';

  @override
  String get membersMarkInactive => 'Mark inactive';

  @override
  String get membersInactiveHelp =>
      'Hidden from the meal list; money is counted as before';

  @override
  String get membersMarkActive => 'Make active again';

  @override
  String get membersMarkLeft => 'Has left the mess';

  @override
  String membersLeftConfirmTitle(String name) {
    return 'Has $name left the mess?';
  }

  @override
  String get membersLeftConfirmBody =>
      'From today they are not counted in new entries. All their past meals, bazar and deposits stay exactly as they are.';

  @override
  String get membersLeftConfirmAction => 'Yes, they left';

  @override
  String get membersSaved => 'Change saved';

  @override
  String get membersAdd => 'Add member';

  @override
  String get membersAddHelp =>
      'For someone without the app. You enter their meals and deposits.';

  @override
  String get membersAddName => 'Name';

  @override
  String get membersAddRoom => 'Room (optional)';

  @override
  String get membersAddSubmit => 'Add';

  @override
  String membersAdded(String name) {
    return '$name added';
  }

  @override
  String get inviteTitle => 'Invite members';

  @override
  String get inviteBody =>
      'Share this code or let them scan the QR. When their request comes in, approve it and they are in.';

  @override
  String get inviteValidity => 'Valid for 7 days';

  @override
  String get inviteQrLabel => 'QR code to join the mess';

  @override
  String get inviteCopy => 'Copy code';

  @override
  String get inviteCopied => 'Code copied';

  @override
  String get inviteShare => 'Share';

  @override
  String inviteShareMessage(String mess, String code, String link) {
    return 'Join our mess \"$mess\" on Meal Bazar.\nCode: $code\nLink: $link';
  }

  @override
  String get inviteRegenerate => 'New code';

  @override
  String get inviteManagerOnly => 'Only a manager can invite members';

  @override
  String get settingsTitle => 'Mess settings';

  @override
  String get settingsAddress => 'Address (optional)';

  @override
  String get settingsCutoff => 'Meal-off cutoff';

  @override
  String get settingsCutoffHelp =>
      'Members can switch a meal off until this time the day before';

  @override
  String get settingsSave => 'Save settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsManagerOnly => 'Only a manager can change settings';
}
