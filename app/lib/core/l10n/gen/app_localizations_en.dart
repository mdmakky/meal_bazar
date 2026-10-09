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
  String get navHome => 'Home';

  @override
  String get navMeals => 'Meals';

  @override
  String get navMoney => 'Money';

  @override
  String get navMore => 'More';

  @override
  String get syncSyncing => 'Syncing';

  @override
  String get syncOffline => 'Saved offline';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncDiscard => 'Discard';

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
  String get failureInvalidCredentials => 'Email or password did not match';

  @override
  String get failureEmailTaken =>
      'This email already has an account. Log in instead.';

  @override
  String get failureWeakPassword => 'Please choose a stronger password';

  @override
  String get failureEmailNotConfirmed =>
      'Confirm your account first with the link we emailed you';

  @override
  String get signInTitle => 'Sign in to Meal Bazar';

  @override
  String get signInHint => 'Your whole mess, from your phone';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get signInOrEmail => 'or with email';

  @override
  String get signInModeLogin => 'Log in';

  @override
  String get signInModeSignUp => 'New account';

  @override
  String get signInEmailLabel => 'Email';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInEmailInvalid => 'Enter a valid email';

  @override
  String get signInPasswordShort => 'Use at least 8 characters';

  @override
  String get signInSubmitLogin => 'Log in';

  @override
  String get signInSubmitSignUp => 'Create account';

  @override
  String get signInForgot => 'Forgot password?';

  @override
  String get signInResetSent => 'We emailed you a link to reset your password';

  @override
  String get signInConfirmTitle => 'Click the link we emailed you';

  @override
  String signInConfirmBody(String email) {
    return 'We sent a link to $email. Click it, then come back here and log in.';
  }

  @override
  String get signInBackToLogin => 'Back to log in';

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
  String moreSignOutUnsent(String count) {
    return '$count entries saved offline have not been sent yet — signing out will delete them';
  }

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
  String get settingsSave => 'Save settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsManagerOnly => 'Only a manager can change settings';

  @override
  String get mealCellOff => 'Off';

  @override
  String mealCellGuests(String count) {
    return '$count guests';
  }

  @override
  String get mealCellOwn => 'Own meals';

  @override
  String get mealCellGuestsLabel => 'Guests';

  @override
  String get mealCellSave => 'Save meal';

  @override
  String get mealCellDecrease => 'Decrease';

  @override
  String get mealCellIncrease => 'Increase';

  @override
  String get todayPrevDay => 'Previous day';

  @override
  String get todayNextDay => 'Next day';

  @override
  String get todayBackToToday => 'Back to today';

  @override
  String get todayIsToday => 'Today';

  @override
  String get todayHeadcountLabel => 'Meals today';

  @override
  String get todayDayHeadcountLabel => 'Meals this day';

  @override
  String todayGuestsProof(String count) {
    return 'Guests $count';
  }

  @override
  String get todayRateLabel => 'Meal rate this month';

  @override
  String todayRateProof(String food, String meals) {
    return '$food ÷ $meals meals';
  }

  @override
  String todayRateUnallocated(String food) {
    return '$food spent, but no meals yet. The rate appears once meals are in.';
  }

  @override
  String get todayNoEntries => 'No meals entered for this day yet';

  @override
  String get todayNoEntriesMember =>
      'The manager hasn\'t entered meals for this day yet';

  @override
  String get todayFillHelp =>
      'Copies yesterday\'s meals for every member, else their default meals, else 1 each. Tap to adjust after.';

  @override
  String get todayFill => 'Fill today\'s meals';

  @override
  String get todayFillDay => 'Fill this day\'s meals';

  @override
  String get todayNoMembers => 'No members in the mess yet';

  @override
  String get todayNoMealTypes => 'No meal types are on';

  @override
  String get todayNoMealTypesAction => 'Set up meal types';

  @override
  String get todayMemberColumn => 'Member';

  @override
  String get todayActionBazar => 'Bazar';

  @override
  String get todayActionExpense => 'Expense';

  @override
  String get todayActionDeposit => 'Deposit';

  @override
  String get todayActionGuest => 'Guest';

  @override
  String get todayActionMealOff => 'Meal off';

  @override
  String get todayPickMember => 'For whom?';

  @override
  String get todayPickMealType => 'Which meal?';

  @override
  String todayMealOffDone(String name, String meal) {
    return '$meal off for $name';
  }

  @override
  String get mealsTitle => 'Meals';

  @override
  String get mealsTotalLabel => 'Total meals this month';

  @override
  String mealsPeriod(String from, String to) {
    return '$from to $to';
  }

  @override
  String get mealsByMember => 'Meals by member';

  @override
  String mealsGuestNote(String count) {
    return 'incl. $count guest meals';
  }

  @override
  String get mealsEmpty => 'No meals this month yet';

  @override
  String mealsMemberEmpty(String name) {
    return 'No meals for $name this month';
  }

  @override
  String mealsMemberTotal(String count) {
    return '$count meals this month';
  }

  @override
  String get mealTypesTitle => 'Meal types';

  @override
  String get mealTypesHelp =>
      'Weight is how many meals one serving counts as, e.g. breakfast ×0.5.';

  @override
  String get mealTypesAdd => 'Add a meal type';

  @override
  String get mealTypesName => 'Name';

  @override
  String get mealTypesNameHint => 'e.g. Evening snack';

  @override
  String get mealTypesNameInvalid => 'Use 1 to 30 characters';

  @override
  String get mealTypesRename => 'Rename';

  @override
  String get mealTypesWeight => 'Weight';

  @override
  String mealTypesEnabled(String name) {
    return '$name on';
  }

  @override
  String get mealTypesEmpty => 'No meal types yet';

  @override
  String get mealTypesManagerOnly => 'Only the manager can change meal types';

  @override
  String get moneyFoodTotal => 'Food cost';

  @override
  String get moneyFoodProof => 'Bazar plus expenses split by meal';

  @override
  String get moneyMealRate => 'Meal rate';

  @override
  String moneyMealRateProof(String food, String meals) {
    return '$food ÷ $meals meals';
  }

  @override
  String get moneyExtraTotal => 'Other expenses';

  @override
  String get moneyExtraProof => 'Split equally among members';

  @override
  String get moneyDepositTotal => 'Deposits';

  @override
  String get moneyDepositProof => 'Verified deposits only';

  @override
  String get moneyNoMealsWarning =>
      'There is food cost but no meals yet, so nobody is charged';

  @override
  String get moneyTabMembers => 'Members';

  @override
  String get moneyTabBazar => 'Bazar';

  @override
  String get moneyTabExpense => 'Expenses';

  @override
  String get moneyTabDeposit => 'Deposits';

  @override
  String get moneyAmount => 'Amount';

  @override
  String get moneyAmountInvalid => 'Enter a valid amount, like 250 or 250.50';

  @override
  String get moneyChangeDate => 'Change date';

  @override
  String get moneyPaidFrom => 'Paid from';

  @override
  String get moneyPaidFund => 'Mess fund';

  @override
  String get moneyPaidPocket => 'Own pocket';

  @override
  String get moneyPaidPocketHelp => 'Counts as that member\'s deposit';

  @override
  String get moneyPickMember => 'Pick a member';

  @override
  String get moneyNote => 'Note (optional)';

  @override
  String get moneySave => 'Save';

  @override
  String get moneySaved => 'Saved';

  @override
  String get moneyDeleted => 'Deleted';

  @override
  String get moneyDeleteConfirmTitle => 'Delete this?';

  @override
  String get moneyDeleteConfirmBody =>
      'It will be removed from this month\'s accounts.';

  @override
  String get moneyLoadMore => 'Load more';

  @override
  String get moneyNoMess => 'Join a mess first';

  @override
  String get bazarAdd => 'Add bazar';

  @override
  String get bazarEdit => 'Edit bazar';

  @override
  String get bazarTitle => 'Bazar';

  @override
  String get bazarBuyer => 'Who shopped';

  @override
  String get bazarItems => 'Items (optional)';

  @override
  String get bazarAddItem => 'Add item';

  @override
  String get bazarRemoveItem => 'Remove item';

  @override
  String get bazarItemName => 'Name';

  @override
  String get bazarItemQty => 'Qty';

  @override
  String get bazarItemUnit => 'Unit';

  @override
  String get bazarItemPrice => 'Price';

  @override
  String get bazarItemInvalid => 'Enter both name and price';

  @override
  String bazarItemsSum(String sum) {
    return 'Items add up to $sum';
  }

  @override
  String get bazarUseSum => 'Use this';

  @override
  String bazarItemCount(String count) {
    return '$count items';
  }

  @override
  String get bazarEmpty => 'No bazar this month yet';

  @override
  String get bazarShare => 'Share';

  @override
  String bazarShareHeader(String date) {
    return 'Bazar · $date';
  }

  @override
  String bazarShareBuyer(String name) {
    return 'Shopped by: $name';
  }

  @override
  String bazarShareTotal(String total) {
    return 'Total: $total';
  }

  @override
  String get expenseAdd => 'Add expense';

  @override
  String get expenseEdit => 'Edit expense';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expensePickCategory => 'Pick a category';

  @override
  String get expenseSplit => 'How to split';

  @override
  String get expenseSplitMeal => 'Meal';

  @override
  String get expenseSplitEqual => 'Equal';

  @override
  String get expenseSplitMealHelp =>
      'Added to the meal rate; each pays by meals eaten. E.g. gas, cooking';

  @override
  String get expenseSplitEqualHelp =>
      'Split equally among members present that day. E.g. WiFi, rent';

  @override
  String get expenseEmpty => 'No expenses this month yet';

  @override
  String get depositAdd => 'Add deposit';

  @override
  String get depositEdit => 'Edit deposit';

  @override
  String get depositMember => 'Who paid';

  @override
  String get depositMethod => 'Method';

  @override
  String get depositCash => 'Cash';

  @override
  String get depositBkash => 'bKash';

  @override
  String get depositNagad => 'Nagad';

  @override
  String get depositBank => 'Bank';

  @override
  String get depositOther => 'Other';

  @override
  String get depositTrxId => 'TrxID (optional)';

  @override
  String get depositAmountPositive => 'A deposit must be more than 0';

  @override
  String get depositPending => 'Pending';

  @override
  String get depositRejected => 'Rejected';

  @override
  String get depositEmpty => 'No deposits this month yet';

  @override
  String get balanceDue => 'Due';

  @override
  String get balanceAdvance => 'Advance';

  @override
  String get balanceSettled => 'Settled';

  @override
  String balanceMeals(String meals) {
    return '$meals meals';
  }

  @override
  String get balanceEmpty => 'No balances this month yet';

  @override
  String balanceExplainTitle(String name) {
    return '$name\'s bill';
  }

  @override
  String get balanceOpening => 'From last month';

  @override
  String get balanceCredit => 'Deposits and own-pocket spending';

  @override
  String balanceFood(String meals, String rate) {
    return 'Food ($meals meals × $rate)';
  }

  @override
  String get balanceExtra => 'Share of other expenses';

  @override
  String get balanceClosing => 'Balance now';

  @override
  String get monthTitle => 'Months';

  @override
  String get monthClose => 'Close month';

  @override
  String get monthCloseBody =>
      'Once closed, this month\'s meals, bazar, expenses and deposits can\'t change. Everyone\'s balance carries into the next month.';

  @override
  String get monthThis => 'This month';

  @override
  String get monthPrevious => 'Last month';

  @override
  String monthRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get monthTotalMeals => 'Total meals';

  @override
  String get monthClosedDone => 'Month closed';

  @override
  String get monthStatusOpen => 'Open';

  @override
  String get monthStatusClosed => 'Closed';

  @override
  String get monthReopen => 'Reopen';

  @override
  String get monthReopenTitle => 'Reopen this month?';

  @override
  String get monthReopenReason => 'Reason';

  @override
  String get monthReopenReasonHelp =>
      'At least 5 characters. Everyone in the mess can see it.';

  @override
  String get monthReopenReasonShort =>
      'Write a reason of at least 5 characters';

  @override
  String get monthReopened => 'Month reopened';

  @override
  String get monthNoneClosed => 'No month has been closed yet';

  @override
  String get monthHistory => 'Past months';

  @override
  String get monthManagerOnly => 'Only a manager can close or reopen a month';

  @override
  String lastMonthNewMonth(String month) {
    return '$month has begun';
  }

  @override
  String get lastMonthFinalTitle => 'Last month\'s final account';

  @override
  String get lastMonthMeals => 'My meals';

  @override
  String get lastMonthCost => 'My cost';

  @override
  String lastMonthCostProof(String food, String extra) {
    return 'Food $food + other $extra';
  }

  @override
  String get lastMonthPaid => 'I paid';

  @override
  String get lastMonthOpening => 'Brought forward';

  @override
  String get lastMonthFinalBalance => 'Final balance';

  @override
  String get lastMonthAdvance => 'In credit';

  @override
  String get lastMonthDue => 'Due';

  @override
  String get lastMonthSettled => 'All settled';

  @override
  String get lastMonthCarried =>
      'This balance has been carried into the new month';

  @override
  String get lastMonthReport => 'Month PDF';

  @override
  String get lastMonthPay => 'Pay now';

  @override
  String get lastMonthHide => 'Hide';

  @override
  String get lastMonthNotFinal =>
      'Last month isn\'t final yet. Your final balance shows once the manager closes the month';

  @override
  String get closeMonthCtaTitle => 'Close last month';

  @override
  String closeMonthCtaBody(String month) {
    return 'Finalise $month. Closing carries everyone\'s balance into the new month.';
  }

  @override
  String get closeMonthPendingTitle => 'Resolve these before closing';

  @override
  String closeMonthPendingDeposits(String count) {
    return '$count deposits to verify';
  }

  @override
  String closeMonthPendingBazar(String count) {
    return '$count bazar requests to review';
  }

  @override
  String get closeMonthWhatHappens => 'When you close';

  @override
  String get closeMonthFinal => 'Everyone\'s balance becomes final';

  @override
  String get closeMonthLocked => 'Nothing in this month can be added or edited';

  @override
  String get closeMonthCarry => 'Each balance carries into the new month';

  @override
  String get closeMonthNotify => 'All members get a notification';

  @override
  String get closeMonthPendingItems =>
      'This month still has pending deposits or bazar requests. Approve or reject them first (deposits under Money, requests under Bazar), then close the month.';

  @override
  String get closeMonthDayLocked => 'This month is closed: view only';

  @override
  String get activityMoreTile => 'My activity';

  @override
  String get monthPreviousOpen => 'Close the earlier month first';

  @override
  String get monthLaterClosed => 'Reopen the later month first';

  @override
  String get aiDraftLabel => 'AI draft';

  @override
  String get aiMealTitle => 'Write meals with AI';

  @override
  String get aiMealHint => 'Today Rahim 2, Karim off, 1 guest at night';

  @override
  String get aiSend => 'Send';

  @override
  String get aiUnavailableDisabled => 'AI is turned off';

  @override
  String get aiUnavailableQuota =>
      'Today\'s AI limit is used up, please enter by hand';

  @override
  String get aiUnavailableProviders => 'AI isn\'t available right now';

  @override
  String get aiEdit => 'Edit';

  @override
  String get aiRemove => 'Remove';

  @override
  String get aiUnmatchedNote =>
      'Couldn\'t understand these, please enter them by hand';

  @override
  String get aiReject => 'Reject';

  @override
  String get aiConfirmAll => 'Confirm all';

  @override
  String get aiNoMeals => 'No meals found';

  @override
  String aiMealsSaved(String count) {
    return '$count meals saved';
  }

  @override
  String get aiScanTitle => 'Scan bazar receipt';

  @override
  String get aiCamera => 'Take a photo';

  @override
  String get aiGallery => 'Choose from gallery';

  @override
  String get aiNotJpeg => 'Can\'t read this photo, take one with the camera';

  @override
  String get aiItemName => 'Item';

  @override
  String get aiItemPrice => 'Price';

  @override
  String get aiNoItems => 'No items could be read from the receipt';

  @override
  String get aiTotalMismatch =>
      'The receipt total and the item sum differ. Which one?';

  @override
  String aiReceiptTotal(String amount) {
    return 'Receipt total $amount';
  }

  @override
  String aiItemsSum(String amount) {
    return 'Item sum $amount';
  }

  @override
  String get aiUseDraft => 'Use in bazar';

  @override
  String get reportTitle => 'Monthly report';

  @override
  String get reportFoodTotal => 'Food total';

  @override
  String get reportTotalMeals => 'Total meals';

  @override
  String get reportMealRate => 'Meal rate';

  @override
  String get reportExtraTotal => 'Extra total';

  @override
  String get reportDeposits => 'Deposits';

  @override
  String get reportName => 'Name';

  @override
  String get reportMeals => 'Meals';

  @override
  String get reportFoodCost => 'Meal cost';

  @override
  String get reportExtra => 'Extra';

  @override
  String get reportPaid => 'Paid + pocket';

  @override
  String get reportBalance => 'Balance';

  @override
  String get reportFormula => 'Meal rate = food total ÷ total meals';

  @override
  String get reportNoMembers => 'No members this month';

  @override
  String get reportShare => 'Share report';

  @override
  String get reportPrint => 'Print report';

  @override
  String reportFooter(String date) {
    return 'Made with Meal Bazar · $date';
  }

  @override
  String get reportPage => 'Page';

  @override
  String reportManager(String name) {
    return 'Manager: $name';
  }

  @override
  String get reportSectionMeals => 'Meals';

  @override
  String get reportSectionDaily => 'Daily meals (by member)';

  @override
  String get reportSectionBazar => 'Bazar';

  @override
  String get reportSectionMoney => 'Expenses, deposits & summary';

  @override
  String get reportMatrix => 'Meal matrix';

  @override
  String get reportMatrixHint =>
      'Rows = members, columns = days; darker = more meals';

  @override
  String get reportMember => 'Member';

  @override
  String get reportTotal => 'Total';

  @override
  String get reportDayTotal => 'Day total';

  @override
  String get reportOffShort => 'x';

  @override
  String get reportOffLegend => 'x = off';

  @override
  String get reportAbsentLegend => '· = not in the mess then';

  @override
  String get reportTypeBreakdown => 'Meal types by member';

  @override
  String get reportGuests => 'Guests';

  @override
  String get reportOffDays => 'Off days';

  @override
  String get reportBazarTrips => 'Bazar trips';

  @override
  String reportTimes(String count) {
    return '$count×';
  }

  @override
  String get reportWeightedMeals => 'Weighted meals';

  @override
  String get reportDaily => 'Who ate how many meals, day by day';

  @override
  String reportDailyHint(String types) {
    return 'Each member\'s $types, by day · ½ = half meal · +1 = guest · x = off';
  }

  @override
  String reportMealsCount(String meals) {
    return '$meals meals';
  }

  @override
  String get reportHalfMeal => 'Half meal';

  @override
  String get reportDoubleMeal => 'Double meal';

  @override
  String get reportOff => 'Off';

  @override
  String get reportCountNote =>
      'Total column counts without weights; weighted meals under the name';

  @override
  String get reportTimeline => 'Bazar timeline';

  @override
  String get reportMessFund => 'Mess fund';

  @override
  String reportOwnPocket(String name) {
    return '$name\'s pocket';
  }

  @override
  String get reportDate => 'Date';

  @override
  String get reportCategory => 'Category';

  @override
  String get reportSplit => 'Split';

  @override
  String get reportAmount => 'Amount';

  @override
  String reportEveryone(String count) {
    return 'Everyone ($count)';
  }

  @override
  String get reportExpenseTotal => 'Total other expenses';

  @override
  String get reportDepositsTitle => 'Deposits';

  @override
  String get reportMethod => 'Method';

  @override
  String get reportVerifiedTotal => 'Total deposits (verified)';

  @override
  String get reportSummary => 'Summary';

  @override
  String get reportOpening => 'Previous';

  @override
  String get reportNone => 'None';

  @override
  String get reportWeekdays =>
      'Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday';

  @override
  String get reportWeekdaysShort => 'S,M,T,W,T,F,S';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountName => 'Your name';

  @override
  String get accountNameSave => 'Save name';

  @override
  String get accountNameSaved => 'Name saved';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountLangBn => 'বাংলা';

  @override
  String get accountLangEn => 'English';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteTitle => 'Delete your account?';

  @override
  String get accountDeleteRemoved =>
      'Removed: your name, phone number and photo. You will lose access to every mess.';

  @override
  String get accountDeleteKept =>
      'Kept: the mess\'s meal, bazar, deposit and expense records stay under your mess name so the mess\'s accounts don\'t change.';

  @override
  String get accountDeleteManager =>
      'If you are the only manager, make someone else manager first.';

  @override
  String get accountDeleteWord => 'delete';

  @override
  String accountDeleteTypeHint(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get accountDeleteConfirm => 'Delete forever';

  @override
  String get auditTitle => 'Activity';

  @override
  String get auditFilterAll => 'All';

  @override
  String get auditFilterMeals => 'Meals';

  @override
  String get auditFilterMoney => 'Money';

  @override
  String get auditFilterMembers => 'Members';

  @override
  String get auditEmpty => 'No activity yet';

  @override
  String get auditAi => 'AI';

  @override
  String get auditLoadMore => 'Show more';

  @override
  String auditReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get auditSomeone => 'Someone';

  @override
  String get auditSystem => 'System';

  @override
  String auditSentence(String actor, String thing, String verb) {
    return '$actor $verb $thing';
  }

  @override
  String get auditAdded => 'added';

  @override
  String get auditChanged => 'changed';

  @override
  String get auditDeleted => 'deleted';

  @override
  String get auditBazar => 'a bazar';

  @override
  String get auditExpense => 'an expense';

  @override
  String auditDepositOf(String name) {
    return 'a deposit for $name';
  }

  @override
  String auditMealOf(String name) {
    return 'meals for $name';
  }

  @override
  String auditMealType(String name) {
    return 'meal type $name';
  }

  @override
  String auditMember(String name) {
    return 'member $name';
  }

  @override
  String get auditMessSettings => 'mess settings';

  @override
  String auditDutyOf(String name) {
    return 'bazar duty for $name';
  }

  @override
  String auditNotice(String title) {
    return 'notice $title';
  }

  @override
  String get auditRecurring => 'a monthly bill';

  @override
  String auditMonthClosed(String actor) {
    return '$actor closed the month';
  }

  @override
  String auditMonthReopened(String actor) {
    return '$actor reopened the month';
  }

  @override
  String auditAccountDeleted(String name) {
    return '$name deleted their account';
  }

  @override
  String get todayAiEntry => 'Just type it: ‘Rahim 2 today, Karim off’';

  @override
  String get bazarScan => 'Scan receipt or list';

  @override
  String get mealOffCutoffPassed => 'Too late — ask the manager';

  @override
  String mealOffHint(String time) {
    return 'To switch off tomorrow\'s meals, do it before $time pm today';
  }

  @override
  String get receiptAttach => 'Receipt photo';

  @override
  String get receiptScreenshot => 'Payment screenshot (optional)';

  @override
  String get receiptRemove => 'Remove photo';

  @override
  String get receiptView => 'View receipt';

  @override
  String get depositVerifyMine => 'Record my deposit';

  @override
  String get depositVerifyHelp =>
      'This deposit won\'t count until the manager verifies it.';

  @override
  String get depositVerifySent => 'Deposit sent. The manager will verify it';

  @override
  String get depositVerifyApprove => 'Verify';

  @override
  String get depositVerifyReject => 'Reject';

  @override
  String get depositVerifyApproveTitle => 'Verify this deposit?';

  @override
  String depositVerifyApproveBody(String name, String amount) {
    return '$amount from $name will count in the accounts.';
  }

  @override
  String get depositVerifyRejectTitle => 'Reject this deposit?';

  @override
  String depositVerifyRejectBody(String name, String amount) {
    return '$amount from $name will not count.';
  }

  @override
  String get depositVerifyDone => 'Deposit verified';

  @override
  String get depositVerifyRejected => 'Deposit rejected';

  @override
  String get resetTitle => 'Set a new password';

  @override
  String get resetHint => 'Choose a new password for this account';

  @override
  String get resetNewPasswordLabel => 'New password';

  @override
  String get resetConfirmLabel => 'Confirm new password';

  @override
  String get resetMismatch => 'Passwords don\'t match';

  @override
  String get resetSave => 'Save password';

  @override
  String get resetDone => 'Password changed';

  @override
  String get dashTitle => 'This month';

  @override
  String get dashMembers => 'Members';

  @override
  String get dashMembersProof => 'Active members';

  @override
  String dashMembersPending(String count) {
    return '$count awaiting approval';
  }

  @override
  String get dashBazar => 'Bazar total';

  @override
  String dashBazarProof(String food) {
    return 'Food cost with meal-split costs $food';
  }

  @override
  String get dashExtra => 'Other costs';

  @override
  String dashExtraProof(String total) {
    return 'Split equally · month\'s total cost $total';
  }

  @override
  String get dashDeposits => 'Deposits';

  @override
  String get dashDues => 'Total due';

  @override
  String dashDuesProof(String count) {
    return '$count members owe';
  }

  @override
  String get dashAdvances => 'Total advance';

  @override
  String dashAdvancesProof(String count) {
    return '$count members in advance';
  }

  @override
  String get dashMeals => 'Total meals';

  @override
  String dashPeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String get dashRate => 'Meal rate';

  @override
  String get dashWhoOwes => 'Who owes what';

  @override
  String get dashMine => 'My account';

  @override
  String get dashMyMeals => 'My meals';

  @override
  String get dashMyFood => 'Food cost';

  @override
  String dashMyFoodProof(String meals, String rate) {
    return '$meals meals × $rate';
  }

  @override
  String get dashMyPaid => 'Paid';

  @override
  String get dashExplain => 'Explain my bill';

  @override
  String get dashNotInMonth => 'You have nothing on this month\'s bill';

  @override
  String get dashDailyTitle => 'Daily meals';

  @override
  String dashDailySummary(String total, String max, String date) {
    return 'Daily meals: $total in all, most $max on $date';
  }

  @override
  String get dashCategoryTitle => 'Where the money went';

  @override
  String get dashMonthlyTitle => 'Meal rate by month';

  @override
  String get dashChartEmpty => 'Nothing this month yet';

  @override
  String get dashRecentBazar => 'Recent bazar';

  @override
  String get dashNobodyThatDay => 'Nobody was in the mess on this day';

  @override
  String get navBazar => 'Bazar';

  @override
  String mealGridManager(String name) {
    return 'Manager: $name';
  }

  @override
  String get mealGridPrevMonth => 'Previous month';

  @override
  String get mealGridNextMonth => 'Next month';

  @override
  String get mealGridTotalRow => 'Total meals';

  @override
  String get mealGridDayTotal => 'Total meals this day';

  @override
  String get mealGridHint => 'Tap a number to cycle 0, 0.5, 1, 1.5, 2';

  @override
  String get mealGridAllOne => 'Everyone 1';

  @override
  String get mealGridLikeYesterday => 'Same as yesterday';

  @override
  String get mealGridNothingToChange => 'Nothing to change';

  @override
  String get mealGridAdd => 'Add';

  @override
  String get mealGridAddTitle => 'What do you want to add?';

  @override
  String get mealGridAi => 'Type meals in words';

  @override
  String get mealGridToday => 'Today\'s meals';

  @override
  String get mealGridGoToMeals => 'Enter meals';

  @override
  String get bazarTabTotal => 'Bazar this month';

  @override
  String get bazarPickerFrequent => 'Bought often';

  @override
  String get bazarPickerStaples => 'Rice, lentils, oil';

  @override
  String get bazarPickerVeg => 'Vegetables';

  @override
  String get bazarPickerProtein => 'Fish, meat, eggs';

  @override
  String get bazarPickerSpice => 'Spices and other';

  @override
  String get bazarPickerCustom => 'New item';

  @override
  String get bazarPickerHelp => 'Tap to add an item, tap again to remove';

  @override
  String get setupTitle => 'Let\'s get started';

  @override
  String setupProgress(String done, String total) {
    return '$done/$total done';
  }

  @override
  String get setupLater => 'Later';

  @override
  String get setupStart => 'Start';

  @override
  String get setupMess => 'Mess created';

  @override
  String get setupMealTypes => 'Set up meal times';

  @override
  String get setupMembers => 'Add members';

  @override
  String get setupDeposit => 'Record opening deposits';

  @override
  String get setupMeals => 'Enter today\'s meals';

  @override
  String shareBillTitle(String mess) {
    return '*$mess* · Monthly bill';
  }

  @override
  String shareBillSummaryTitle(String mess) {
    return '*$mess* · Month summary';
  }

  @override
  String shareBillMeals(String meals, String rate, String cost) {
    return 'Meals: $meals × $rate = $cost';
  }

  @override
  String get shareBillPaid => 'Paid';

  @override
  String get shareBillFoodTotal => 'Total food cost';

  @override
  String get shareBillTotalMeals => 'Total meals';

  @override
  String get shareBillRate => 'Meal rate';

  @override
  String get shareBillExtraTotal => 'Other expenses';

  @override
  String get shareBillShare => 'Share bill';

  @override
  String get shareBillRemind => 'Remind';

  @override
  String get shareBillShareAll => 'Share everyone\'s balance';

  @override
  String get shareBillToneTitle => 'How should it sound?';

  @override
  String get shareBillTonePolite => 'Polite';

  @override
  String get shareBillToneShort => 'Short';

  @override
  String get shareBillToneFirm => 'Firm';

  @override
  String shareBillRemindPolite(String name, String amount) {
    return 'Hi $name, your mess balance this month shows $amount due. Please pay whenever convenient. Thank you!';
  }

  @override
  String shareBillRemindShort(String name, String amount) {
    return '$name, mess due: $amount. Please pay.';
  }

  @override
  String shareBillRemindFirm(String name, String amount) {
    return '$name, your mess due of $amount is still unpaid. Please pay within 3 days.';
  }

  @override
  String shareBillPayHint(String number) {
    return 'bKash/Nagad: $number';
  }

  @override
  String get noticeTitle => 'Notices';

  @override
  String get noticeEmpty => 'No notices yet';

  @override
  String get noticeAdd => 'Post a notice';

  @override
  String get noticeEdit => 'Edit notice';

  @override
  String get noticeTitleLabel => 'Title';

  @override
  String get noticeTitleRequired => 'Enter a title';

  @override
  String get noticeBodyLabel => 'Details';

  @override
  String get noticePin => 'Pin to the top';

  @override
  String get noticePinned => 'Pinned';

  @override
  String get noticeUnread => 'New';

  @override
  String get noticeExpiry => 'Expires';

  @override
  String get noticeNoExpiry => 'No expiry';

  @override
  String get noticeClearExpiry => 'Remove expiry';

  @override
  String noticeUntil(String date) {
    return 'Until $date';
  }

  @override
  String get noticeSave => 'Save notice';

  @override
  String get noticeSaved => 'Notice saved';

  @override
  String get noticeDeleted => 'Notice deleted';

  @override
  String get noticeDeleteConfirmTitle => 'Delete this notice?';

  @override
  String get noticeDeleteConfirmBody => 'It will disappear for everyone.';

  @override
  String get noticeGone => 'This notice is no longer available';

  @override
  String get dutyTitle => 'Bazar duty';

  @override
  String get dutyGenerate => 'Make a rota';

  @override
  String get dutyEmpty => 'Nobody has bazar duty this month';

  @override
  String get dutyMyUpcoming => 'Your upcoming duties';

  @override
  String get dutyThisMonth => 'This month\'s duties';

  @override
  String get dutyDone => 'Bazar done';

  @override
  String get dutyMarkDone => 'I did the bazar';

  @override
  String get dutyMembersLabel => 'Who goes: tap them in order';

  @override
  String get dutyPickMembers => 'Pick at least one member';

  @override
  String get dutyStart => 'Start date';

  @override
  String get dutyEveryLabel => 'How often';

  @override
  String dutyEvery(String n) {
    return 'Every $n days';
  }

  @override
  String get dutyDays => 'For how many days';

  @override
  String get dutyDaysInvalid => 'Enter 1 to 366 days';

  @override
  String dutyCreated(String count) {
    return '$count duties created';
  }

  @override
  String get dutyEditTitle => 'Change duty';

  @override
  String get dutyMember => 'Who does the bazar';

  @override
  String get dutyNote => 'Note';

  @override
  String get dutyDeleteConfirm => 'Delete this day\'s duty?';

  @override
  String get dutyTodayMine => 'Today is your bazar duty';

  @override
  String get dutyTomorrowMine => 'Tomorrow is your bazar duty';

  @override
  String dutyTodayOther(String name) {
    return '$name does the bazar today';
  }

  @override
  String dutyTomorrowOther(String name) {
    return '$name does the bazar tomorrow';
  }

  @override
  String get dutyNextMonth => 'Next month';

  @override
  String get splitEqualAll => 'Everyone';

  @override
  String get splitByMeal => 'By meals';

  @override
  String get splitSelected => 'Selected';

  @override
  String get splitSelectedHelp =>
      'Only the selected members pay, each by their share. E.g. one room\'s fan repair';

  @override
  String get splitPickMember => 'Pick at least one member';

  @override
  String splitWeight(String weight) {
    return 'Share $weight';
  }

  @override
  String get splitWeightLess => 'Smaller share';

  @override
  String get splitWeightMore => 'Bigger share';

  @override
  String get splitPreview =>
      'Preview: who pays how much (final figures come from the month)';

  @override
  String get exportTitle => 'Data export (CSV)';

  @override
  String get exportAction => 'Export CSV';

  @override
  String get exportPeriod => 'Which month';

  @override
  String get exportCurrent => 'Current month';

  @override
  String get exportHint =>
      'Balances, meals, bazar, expenses and deposits as 5 CSV files that open in Excel or Google Sheets.';

  @override
  String get exportButton => 'Export and share';

  @override
  String get exportDate => 'Date';

  @override
  String get exportMember => 'Member';

  @override
  String get exportGuests => 'Guests';

  @override
  String get exportOpening => 'Opening balance';

  @override
  String get exportAmount => 'Amount';

  @override
  String get exportBuyer => 'Buyer';

  @override
  String get exportPaidBy => 'Paid by';

  @override
  String get exportItems => 'Items';

  @override
  String get exportNote => 'Note';

  @override
  String get exportCategory => 'Category';

  @override
  String get exportSplit => 'Split';

  @override
  String get exportMethod => 'Method';

  @override
  String get exportStatus => 'Status';

  @override
  String get exportVerified => 'Verified';

  @override
  String get cookShare => 'Send tomorrow\'s meal count to the cook';

  @override
  String get remindTitle => 'Reminders';

  @override
  String get remindCutoffTitle => 'Meal-off cutoff soon';

  @override
  String get remindCutoffBody => 'Want tomorrow\'s meal off? Do it now';

  @override
  String get remindNudgeTitle => 'Today\'s meals not entered';

  @override
  String get remindNudgeBody => 'Haven\'t entered today\'s meals? Do it now';

  @override
  String get remindDutyTitle => 'Your bazar tomorrow';

  @override
  String remindDutyBody(String mess) {
    return '$mess: you\'re on bazar duty tomorrow';
  }

  @override
  String get remindCutoffToggle => 'Before the meal-off cutoff';

  @override
  String get remindCutoffToggleSub => '30 minutes before the cutoff';

  @override
  String get remindNudgeToggle => 'Evening meal entry';

  @override
  String get remindNudgeToggleSub => 'Every day at 9 PM, for managers';

  @override
  String get remindDutyToggle => 'Bazar duty';

  @override
  String get remindDutyToggleSub => '8 PM the day before your duty';

  @override
  String get remindPermissionOff => 'Notifications are off';

  @override
  String get remindPermissionBody => 'Turn on notifications to get reminders';

  @override
  String get remindPermissionButton => 'Turn on';

  @override
  String get recurringTitle => 'Monthly bills';

  @override
  String get recurringHelp =>
      'Write down bills that stay the same every month (rent, Wi-Fi, maid) once. Then post them as expenses each month with one tap.';

  @override
  String get recurringEmpty => 'No monthly bills yet';

  @override
  String get recurringAdd => 'New monthly bill';

  @override
  String get recurringEdit => 'Edit monthly bill';

  @override
  String get recurringDay => 'Day of the month to post on';

  @override
  String recurringDayValue(String day) {
    return 'Day $day of the month';
  }

  @override
  String recurringActive(String name) {
    return '$name on';
  }

  @override
  String get recurringApply => 'Post this month\'s bills';

  @override
  String recurringApplied(String count) {
    return '$count bills posted as expenses';
  }

  @override
  String get recurringNothingToApply =>
      'This month\'s bills are already posted';

  @override
  String recurringPending(String count) {
    return '$count monthly bills not posted yet this month';
  }

  @override
  String get recurringManagerOnly => 'Only a manager can change monthly bills';

  @override
  String get mealDefaultTitle => 'Default meals';

  @override
  String get mealDefaultHelp =>
      'When a member has no meal the day before, \"Fill today\" uses these.';

  @override
  String get mealDefaultEmpty => 'No active members or meal types';

  @override
  String get mealDefaultManagerOnly =>
      'Only a manager can change default meals';

  @override
  String get rateSection => 'Meal rate';

  @override
  String get rateHelp =>
      'Calculated: food cost ÷ total meals. Fixed: a rate announced up front that everyone pays per meal.';

  @override
  String get rateCalculated => 'Calculated';

  @override
  String get rateFixed => 'Fixed rate';

  @override
  String get rateAmountLabel => 'Rate per meal (৳)';

  @override
  String get rateAmountRequired => 'Enter a rate above 0';

  @override
  String rateSurplus(String amount) {
    return '$amount more collected than the bazar cost';
  }

  @override
  String rateDeficit(String amount) {
    return '$amount less collected than the bazar cost';
  }

  @override
  String rateBalanceFood(String meals, String rate) {
    return 'Food = $meals meals × $rate (fixed rate)';
  }

  @override
  String get platformMaintenanceTitle => 'We\'re doing some maintenance';

  @override
  String get platformMaintenanceBody =>
      'The app is paused for a little while. Please open it again soon; your data is safe.';

  @override
  String get platformMaintenanceRetry => 'Check again';

  @override
  String get platformSignOut => 'Sign out';

  @override
  String get platformUpdateTitle => 'A new version is out';

  @override
  String get platformUpdateBody =>
      'Update the app from the Play Store to keep things working well.';

  @override
  String get platformUpdateLater => 'Later';

  @override
  String get platformBannerDismiss => 'Dismiss';

  @override
  String get platformSupportTitle => 'Help';

  @override
  String get platformSupportEmail => 'Email';

  @override
  String get platformSupportWhatsapp => 'WhatsApp';

  @override
  String get platformPrivacy => 'Privacy policy';

  @override
  String get platformCopy => 'Copy';

  @override
  String get platformCopied => 'Copied';

  @override
  String get platformAboutTitle => 'About';

  @override
  String platformVersion(String version) {
    return 'Version $version';
  }

  @override
  String get adminTitle => 'Meal Bazar Admin';

  @override
  String get adminTitleShort => 'Admin';

  @override
  String get adminSignIn => 'Sign in';

  @override
  String get adminSignInGoogle => 'Sign in with Google';

  @override
  String get adminSignInHint => 'Only platform admins can use this panel.';

  @override
  String get adminSignOut => 'Sign out';

  @override
  String get adminAccessDenied => 'Access denied';

  @override
  String get adminAccessDeniedBody =>
      'This account is not a platform admin. Sign in with another account.';

  @override
  String get adminNavDashboard => 'Dashboard';

  @override
  String get adminNavMesses => 'Messes';

  @override
  String get adminNavUsers => 'Users';

  @override
  String get adminNavSettings => 'Settings';

  @override
  String get adminNavAi => 'AI';

  @override
  String get adminNavBranding => 'Branding';

  @override
  String get adminNavCredentials => 'Credentials';

  @override
  String get adminNavDeletion => 'Deletion queue';

  @override
  String get adminStatUsersTotal => 'Users';

  @override
  String get adminStatUsers7d => 'New users (7 days)';

  @override
  String get adminStatMessesTotal => 'Messes';

  @override
  String get adminStatMessesActive7d => 'Active messes (7 days)';

  @override
  String get adminStatMeals7d => 'Meals (7 days)';

  @override
  String get adminStatBazars7d => 'Bazars (7 days)';

  @override
  String get adminStatAiCalls7d => 'AI calls (7 days)';

  @override
  String get adminStatSuspendedMesses => 'Suspended messes';

  @override
  String get adminStatDeletionPending => 'Pending deletions';

  @override
  String get adminAiUsage30d => 'AI usage, last 30 days';

  @override
  String get adminAiUsageEmpty => 'No AI calls in this period';

  @override
  String get adminDeletionEmpty => 'No deletion requests';

  @override
  String get adminUserId => 'User ID';

  @override
  String get adminRequestedAt => 'Requested';

  @override
  String get adminProcessedAt => 'Processed';

  @override
  String get adminLastError => 'Last error';

  @override
  String get adminSearchMesses => 'Search by mess name, then press Enter';

  @override
  String get adminSearchUsers => 'Search by email or name, then press Enter';

  @override
  String get adminNoResults => 'No results';

  @override
  String adminPage(String page) {
    return 'Page $page';
  }

  @override
  String get adminName => 'Name';

  @override
  String get adminMembers => 'Members';

  @override
  String get adminManagers => 'Managers';

  @override
  String get adminCreated => 'Created';

  @override
  String get adminLastActivity => 'Last activity';

  @override
  String get adminLastSignIn => 'Last sign-in';

  @override
  String get adminMessCount => 'Messes';

  @override
  String get adminStatus => 'Status';

  @override
  String get adminRole => 'Role';

  @override
  String get adminRoleAdmin => 'Admin';

  @override
  String get adminActive => 'Active';

  @override
  String get adminSuspended => 'Suspended';

  @override
  String get adminSuspend => 'Suspend';

  @override
  String get adminUnsuspend => 'Unsuspend';

  @override
  String adminSuspendMess(String name) {
    return 'Suspend the mess \"$name\"?';
  }

  @override
  String adminUnsuspendMess(String name) {
    return 'Unsuspend the mess \"$name\"?';
  }

  @override
  String adminSuspendUser(String email) {
    return 'Suspend $email?';
  }

  @override
  String adminUnsuspendUser(String email) {
    return 'Unsuspend $email?';
  }

  @override
  String get adminReason => 'Reason';

  @override
  String get adminMakeAdmin => 'Make admin';

  @override
  String get adminRemoveAdmin => 'Remove admin';

  @override
  String get adminSaved => 'Saved';

  @override
  String get adminRawJson => 'Advanced: raw JSON';

  @override
  String get adminAdd => 'Add';

  @override
  String get adminMoveUp => 'Move up';

  @override
  String get adminMoveDown => 'Move down';

  @override
  String get adminErrRequired => 'Required';

  @override
  String get adminErrNumber => 'Enter a number';

  @override
  String get adminErrRange => 'Out of range';

  @override
  String get adminErrVersion => 'Use a version like 1.2.3';

  @override
  String get adminErrEmail => 'Enter a valid email';

  @override
  String get adminErrUrl => 'Enter a link starting with http(s)://';

  @override
  String get adminErrTime => 'Use HH:MM';

  @override
  String get adminErrHex => 'Use a #RRGGBB colour';

  @override
  String get adminErrMealTypes => 'Keep at least one meal type';

  @override
  String get adminErrChain => 'Each chain needs 1 to 5 models';

  @override
  String get adminFeatures => 'Features';

  @override
  String get adminFeaturesHelp =>
      'Turning a feature off hides every entry point in the app. Data stays in place.';

  @override
  String get adminAppSection => 'App';

  @override
  String get adminMaintenance => 'Maintenance mode';

  @override
  String get adminMaintenanceHelp => 'Shows a full-screen notice in the app';

  @override
  String get adminMessageBn => 'Message (Bangla)';

  @override
  String get adminMessageEn => 'Message (English)';

  @override
  String get adminVersions => 'Versions';

  @override
  String get adminMinVersion => 'Minimum version';

  @override
  String get adminMinVersionHelp => 'Older apps are asked to update';

  @override
  String get adminLatestVersion => 'Latest version';

  @override
  String get adminUpdateMessageBn => 'Update message (Bangla)';

  @override
  String get adminUpdateMessageEn => 'Update message (English)';

  @override
  String get adminSupport => 'Support';

  @override
  String get adminSupportEmail => 'Support email';

  @override
  String get adminSupportWhatsapp => 'Support WhatsApp';

  @override
  String get adminPrivacyUrl => 'Privacy policy URL';

  @override
  String get adminBanner => 'Banner';

  @override
  String get adminBannerActive => 'Show the banner on Home';

  @override
  String get adminBannerLevel => 'Level';

  @override
  String get adminDefaults => 'New mess defaults';

  @override
  String get adminDefaultsHelp => 'Applied only when a new mess is created';

  @override
  String get adminMonthStartDay => 'Month start day (1–28)';

  @override
  String get adminCutoff => 'Meal-off cutoff';

  @override
  String get adminMealTypes => 'Meal types';

  @override
  String get adminWeight => 'Weight';

  @override
  String get adminExpenseCategories => 'Expense categories';

  @override
  String get adminSplit => 'Split';

  @override
  String get adminSplitEqual => 'Equal';

  @override
  String get adminSplitMeal => 'By meals';

  @override
  String get adminCatalogue => 'Bazar catalogue';

  @override
  String get adminCatalogueHelp => 'Items offered in the bazar item picker';

  @override
  String get adminAddGroup => 'Add group';

  @override
  String get adminAddItem => 'Add item';

  @override
  String get adminGroupName => 'Group name';

  @override
  String get adminUnit => 'Unit';

  @override
  String get adminPaymentMethods => 'Payment methods';

  @override
  String get adminPaymentMethodsHelp =>
      'Keys are fixed; only labels and visibility change';

  @override
  String get adminLabelBn => 'Label (Bangla)';

  @override
  String get adminLabelEn => 'Label (English)';

  @override
  String get adminAppNameBn => 'App name (Bangla)';

  @override
  String get adminAppNameEn => 'App name (English)';

  @override
  String get adminTaglineBn => 'Tagline (Bangla)';

  @override
  String get adminTaglineEn => 'Tagline (English)';

  @override
  String get adminBrandingReleaseNote =>
      'Name, tagline, logo and colours change on the sign-in and account screens. The launcher icon and the home-screen app name need a new release (an Android limitation).';

  @override
  String get adminLogo => 'Logo';

  @override
  String get adminLogoUpload => 'Upload logo';

  @override
  String get adminLogoReplace => 'Replace logo';

  @override
  String get adminLogoRemove => 'Remove logo';

  @override
  String get adminLogoDefault =>
      'Without a logo the app shows its built-in ম mark';

  @override
  String get adminLogoSaveHint => 'Press Save to publish the uploaded logo';

  @override
  String get adminAccent => 'Accent colour';

  @override
  String get adminAccentLight => 'Light theme';

  @override
  String get adminAccentDark => 'Dark theme';

  @override
  String adminContrast(String ratio) {
    return 'Contrast $ratio:1';
  }

  @override
  String get adminContrastOk => 'Contrast passes (3:1 or more)';

  @override
  String get adminContrastLow =>
      'Low contrast (under 3:1): marks will be hard to see';

  @override
  String get adminSecretsHelp =>
      'Keys are write-only. Stored values are never shown, only their last 4 characters.';

  @override
  String get adminSecretNotSet => 'Not set (the env variable is used)';

  @override
  String get adminSecretSet => 'Set';

  @override
  String get adminSecretReplace => 'Replace';

  @override
  String get adminSecretValue => 'New value';

  @override
  String get adminSecretValueHelp => 'Replaces the stored value';

  @override
  String adminSecretDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get adminSecretDeleteBody =>
      'The gateway falls back to its env variable.';

  @override
  String adminUpdatedAt(String date) {
    return 'Updated $date';
  }

  @override
  String get adminAiSettings => 'AI settings';

  @override
  String get adminAiEnabled => 'AI enabled';

  @override
  String get adminAllowPaid => 'Allow paid models';

  @override
  String get adminAllowPaidHelp =>
      'When off, the gateway skips OpenRouter models that cost money';

  @override
  String get adminQuotaMeal => 'Daily meal draft quota (per mess)';

  @override
  String get adminQuotaBazar => 'Daily bazar scan quota (per mess)';

  @override
  String get adminTimeoutMs => 'Timeout (ms)';

  @override
  String get adminTemperature => 'Temperature';

  @override
  String get adminTextChain => 'Text chain (meal drafts)';

  @override
  String get adminVisionChain => 'Vision chain (receipt scans)';

  @override
  String get adminChains => 'Chains';

  @override
  String get adminChainEmpty => 'No models. Add one from the catalogue.';

  @override
  String get adminAddManually => 'Add model manually';

  @override
  String get adminProvider => 'Provider';

  @override
  String get adminModelId => 'Model ID';

  @override
  String get adminModel => 'Model';

  @override
  String get adminModelCatalogue => 'Model catalogue';

  @override
  String get adminAll => 'All';

  @override
  String get adminSearchModels => 'Search models';

  @override
  String get adminFree => 'Free';

  @override
  String get adminPaid => 'Paid';

  @override
  String get adminVision => 'Vision';

  @override
  String get adminText => 'Text';

  @override
  String get adminMinContext => 'Min context';

  @override
  String get adminMaxPrice => 'Max price \$/1M';

  @override
  String get adminContext => 'Context';

  @override
  String get adminInputPrice => 'Input \$/1M';

  @override
  String get adminOutputPrice => 'Output \$/1M';

  @override
  String get adminAddToText => 'Add to text chain';

  @override
  String get adminAddToVision => 'Add to vision chain';

  @override
  String get adminTest => 'Test';

  @override
  String adminTestOk(String ms, String sample) {
    return 'OK · $ms ms · $sample';
  }

  @override
  String get adminGatewayMissing =>
      'The AI gateway is not configured. Set AI_GATEWAY_URL in env.json, rebuild the panel, and allow this site\'s origin in the gateway\'s CORS.';

  @override
  String get adminPaidWarningTitle => 'Save paid models?';

  @override
  String get adminPaidWarningBody =>
      '\"Allow paid models\" is off, so the gateway will skip these models:';

  @override
  String get adminSaveAnyway => 'Save anyway';

  @override
  String get stampPaid => 'Paid';

  @override
  String get bazarBuyers => 'Who went to the bazar';

  @override
  String get bazarPickBuyer => 'Pick at least one person';

  @override
  String get bazarPayer => 'Who paid';

  @override
  String get bazarTotal => 'Total';

  @override
  String get bazarItemRemoved => 'Item removed';

  @override
  String get undo => 'Undo';

  @override
  String get bazarPickerTitle => 'Pick from the list';

  @override
  String get bazarPickerSearch => 'Search or type a new item';

  @override
  String bazarPickerAddNamed(String name) {
    return 'Add “$name”';
  }

  @override
  String get bazarUnitNone => 'No unit';

  @override
  String bazarQtyLabel(String qty) {
    return 'Quantity $qty, tap to change the unit';
  }

  @override
  String get bazarSwipeHint => 'Swipe left to remove';

  @override
  String get pushTitle => 'Notifications';

  @override
  String get pushIntro => 'Choose which mess updates reach your phone';

  @override
  String get pushPermissionBody =>
      'Turn on phone notifications to get mess updates';

  @override
  String get pushOpenSub => 'Bazar, expenses, deposits, notices';

  @override
  String get pushJoinRequest => 'Join requests';

  @override
  String get pushJoinRequestSub => 'When someone asks to join the mess';

  @override
  String get pushDepositPending => 'Deposits to verify';

  @override
  String get pushDepositPendingSub => 'When a member records a deposit';

  @override
  String get pushDepositVerified => 'Deposit verified';

  @override
  String get pushDepositVerifiedSub => 'When the manager verifies your deposit';

  @override
  String get pushDepositRejected => 'Deposit rejected';

  @override
  String get pushDepositRejectedSub => 'When the manager rejects your deposit';

  @override
  String get pushNotice => 'New notices';

  @override
  String get pushNoticeSub => 'When something is posted on the notice board';

  @override
  String get pushBazar => 'New bazar';

  @override
  String get pushBazarSub => 'When someone adds a bazar';

  @override
  String get pushExpense => 'New expenses';

  @override
  String get pushExpenseSub => 'When a bill or other expense is added';

  @override
  String get pushMonthClosed => 'Month closed';

  @override
  String get pushMonthClosedSub => 'When the month\'s accounts are final';

  @override
  String get pushDue => 'Payment reminders';

  @override
  String get pushDueSub => 'When the manager reminds you of a due';

  @override
  String get dueRemindButton => 'Remind members who owe';

  @override
  String get dueRemindConfirmTitle => 'Send payment reminders?';

  @override
  String get dueRemindConfirmBody =>
      'Everyone who owes money gets a notification on their phone with their own due amount.';

  @override
  String get dueRemindSend => 'Send';

  @override
  String dueRemindSent(String count) {
    return 'Reminder sent to $count';
  }

  @override
  String get dueRemindNone =>
      'Nobody to notify: members who owe don\'t have notifications on';

  @override
  String get msgTitle => 'Messages';

  @override
  String get msgMoreSub => 'Urgent notes and problem reports';

  @override
  String get msgEmpty =>
      'No messages yet. Write to the manager when something is urgent or an entry looks wrong.';

  @override
  String get msgEmptyManager => 'No messages from members';

  @override
  String get msgEmptyResolved => 'No resolved threads';

  @override
  String get msgNew => 'New message';

  @override
  String get msgFilterOpen => 'Open';

  @override
  String get msgResolved => 'Resolved';

  @override
  String get msgUnread => 'Unread';

  @override
  String msgYou(String text) {
    return 'You: $text';
  }

  @override
  String get msgComposeHint => 'Write a message…';

  @override
  String get msgSend => 'Send';

  @override
  String get msgSending => 'Sending…';

  @override
  String get msgNotSent => 'Not sent · tap to retry';

  @override
  String get msgResolve => 'Mark resolved';

  @override
  String get msgReopen => 'Reopen';

  @override
  String get msgResolvedNote => 'Marked resolved. Writing again reopens it.';

  @override
  String get msgGone => 'This conversation isn\'t available';

  @override
  String get msgSubject => 'Subject';

  @override
  String get msgSubjectRequired => 'Enter a subject';

  @override
  String get msgBody => 'Message';

  @override
  String get msgBodyRequired => 'Write a message';

  @override
  String get msgTo => 'To';

  @override
  String get msgToManagers =>
      'The mess managers will see this. It isn\'t a chat; you\'ll get a notification when they reply.';

  @override
  String get msgMemberRequired => 'Choose a member';

  @override
  String msgReportSubject(String label) {
    return 'Problem: $label';
  }

  @override
  String get msgReportStarter => 'This looks wrong to me, please fix it.';

  @override
  String get msgReport => 'Report a problem';

  @override
  String get msgSent => 'Message sent';

  @override
  String get msgAbout => 'About this entry';

  @override
  String get msgRefDeposit => 'Deposit';

  @override
  String get msgRefBazar => 'Bazar';

  @override
  String get msgRefExpense => 'Expense';

  @override
  String get msgRefMeal => 'Meal';

  @override
  String get msgRefOther => 'Other';

  @override
  String get msgDeletedUser => 'Former member';

  @override
  String get pushMessage => 'Messages';

  @override
  String get pushMessageSub => 'When a manager or member writes to you';

  @override
  String get auditVerified => 'verified';

  @override
  String get auditRejected => 'rejected';

  @override
  String get auditOff => 'off';

  @override
  String get attnTitle => 'Needs attention';

  @override
  String attnDeposits(String count) {
    return '$count deposits to verify';
  }

  @override
  String attnJoin(String count) {
    return '$count join requests';
  }

  @override
  String attnMessages(String count) {
    return '$count unread messages';
  }

  @override
  String attnMeals(String count) {
    return 'Today\'s meals not entered for $count';
  }

  @override
  String get cashTitle => 'Cash in hand (mess fund)';

  @override
  String cashProof(String deposits, String spent) {
    return 'Deposits $deposits − spent from the fund $spent';
  }

  @override
  String cashPending(String amount) {
    return '$amount pending, not counted yet';
  }

  @override
  String get dashSeeAll => 'See all';

  @override
  String get dashOthers => 'Others';

  @override
  String get dashAllSettled => 'Nobody owes anything';

  @override
  String get mineBalance => 'My balance';

  @override
  String get myTodayTitle => 'My meals today';

  @override
  String get transTitle => 'Everyone\'s account';

  @override
  String get transNote =>
      'This month · deposits, paid from own pocket, balance';

  @override
  String get transDeposits => 'Deposits';

  @override
  String get transOwnPocket => 'Own pocket';

  @override
  String get transBalance => 'Balance';

  @override
  String get activityTitle => 'Entries about me';

  @override
  String get activityEmpty =>
      'When the manager records your meals, deposits or bazar, it shows here';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get youTag => 'You';

  @override
  String get activitySeeAll => 'See all';

  @override
  String get auditMealMine => 'your meals';

  @override
  String get auditDepositMine => 'your deposit';

  @override
  String get messagesComingSoon =>
      'Messages are coming soon. Until then, tell the manager directly.';

  @override
  String get msgGroupShort => 'Mess group';

  @override
  String msgGroupTitle(String mess) {
    return '$mess group';
  }

  @override
  String msgGroupMembers(String count) {
    return '$count members';
  }

  @override
  String get msgGroupEmpty =>
      'No messages yet. Write below to tell the whole mess.';

  @override
  String get msgHidden => 'This message was removed';

  @override
  String get msgHide => 'Remove message';

  @override
  String get msgHideBody =>
      'The message will be removed for everyone. This can\'t be undone.';

  @override
  String get msgHideAction => 'Remove';

  @override
  String get msgDayToday => 'Today';

  @override
  String get msgDayYesterday => 'Yesterday';

  @override
  String get homeMsgManager => 'Message manager';

  @override
  String homeUnreadCount(String count) {
    return '$count unread';
  }

  @override
  String get pushGroup => 'Mess group';

  @override
  String get pushGroupSub =>
      'New messages in the mess group. Off mutes the group';

  @override
  String mealOffUntil(String time) {
    return 'until $time';
  }

  @override
  String myMealCount(String count) {
    return 'Meals: $count';
  }

  @override
  String get myMealOff => 'Off';

  @override
  String get myTomorrow => 'Tomorrow';

  @override
  String get dayTomorrow => 'tomorrow';

  @override
  String get dayYesterday => 'yesterday';

  @override
  String get settingsLeadTitle => 'Meal-off deadline';

  @override
  String get settingsLeadHelp =>
      'How long before a meal members can still switch their own meal off or on';

  @override
  String settingsLeadHours(String hours) {
    return '$hours h before the meal';
  }

  @override
  String settingsLeadPrevDay(String time) {
    return 'Day before, $time';
  }

  @override
  String get settingsLeadCustom => 'Custom';

  @override
  String get settingsLeadCustomLabel => 'Hours before the meal (0–48)';

  @override
  String get settingsLeadCustomInvalid => 'Enter 0 to 48 hours';

  @override
  String settingsLeadExample(String meal, String time) {
    return 'Today\'s $meal can be switched off until $time';
  }

  @override
  String get mealTypesServeTime => 'Serving time';

  @override
  String mealOffHintLead(String hours) {
    return 'You can switch your meal off up to $hours h before it';
  }

  @override
  String msgMealOff(String name, String day, String meal) {
    return '$name switched off $meal ($day)';
  }

  @override
  String msgMealOn(String name, String day, String meal) {
    return '$name switched $meal back on ($day)';
  }

  @override
  String get myMealNotEntered => 'Not entered yet';

  @override
  String mealOffConfirmTitle(Object day, Object meal) {
    return 'Turn off $meal meal $day?';
  }

  @override
  String get mealOffConfirmBody =>
      'Everyone in the mess group will be told, from you.';

  @override
  String get mealOffConfirmAction => 'Yes, turn off';
}
