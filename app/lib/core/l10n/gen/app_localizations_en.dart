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
  String get settingsCutoffHelp =>
      'Members can switch a meal off until this time the day before';

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
      'Copies yesterday\'s meals for every member, or 1 each. Tap to adjust after.';

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
      'Added to the meal rate; each pays by meals eaten';

  @override
  String get expenseSplitEqualHelp =>
      'Split equally among members present that day';

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
  String get reportFoodCost => 'Food cost';

  @override
  String get reportExtra => 'Extra';

  @override
  String get reportPaid => 'Paid';

  @override
  String get reportBalance => 'Balance';

  @override
  String get reportDue => 'due';

  @override
  String get reportAdvance => 'advance';

  @override
  String get reportFormula => 'Meal rate = food total ÷ total meals';

  @override
  String reportFooter(String date) {
    return 'Meal Bazar · generated $date';
  }

  @override
  String get reportNoMembers => 'No members this month';

  @override
  String get reportShare => 'Share report';

  @override
  String get reportPrint => 'Print report';

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
  String get mealOffTomorrow => 'Tomorrow off';

  @override
  String get mealOffTomorrowTitle => 'Which meals are off tomorrow?';

  @override
  String get mealOffSave => 'Done';

  @override
  String get mealOffSaved => 'Tomorrow\'s meals updated';

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
  String get dashMonthlyTitle => 'Meal rate, last 6 months';

  @override
  String get dashChartEmpty => 'Nothing this month yet';

  @override
  String get dashRecentBazar => 'Recent bazar';

  @override
  String get dashNobodyThatDay => 'Nobody was in the mess on this day';

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
}
