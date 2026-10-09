import 'package:flutter/widgets.dart';

import 'errors.dart';
import 'l10n/gen/app_localizations.dart';

/// Localized, user-facing text for any error (mapped via [mapError]).
String failureText(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  return switch (mapError(error).kind) {
    FailureKind.network => l.networkError,
    FailureKind.notAuthenticated => l.failureNotAuthenticated,
    FailureKind.notManager => l.failureNotManager,
    FailureKind.invalidInvite => l.failureInvalidInvite,
    FailureKind.alreadyMember => l.failureAlreadyMember,
    FailureKind.lastManager => l.failureLastManager,
    FailureKind.monthClosed => l.failureMonthClosed,
    FailureKind.previousMonthOpen => l.monthPreviousOpen,
    FailureKind.laterMonthClosed => l.monthLaterClosed,
    FailureKind.cutoffPassed => l.mealOffCutoffPassed,
    FailureKind.pendingItems => l.closeMonthPendingItems,
    FailureKind.monthNotEnded => l.monthEndFailNotEnded,
    FailureKind.missingMeals => l.monthEndFailMissing,
    FailureKind.autoMealsPending => l.monthEndFailAuto,
    FailureKind.futureDate => l.bazarReqFailFutureDate,
    FailureKind.bazarRequestNotPending => l.bazarReqFailNotPending,
    FailureKind.itemsInvalid => l.bazarReqFailItemsInvalid,
    FailureKind.invalidOtp => l.failureInvalidOtp,
    FailureKind.invalidCredentials => l.failureInvalidCredentials,
    FailureKind.emailTaken => l.failureEmailTaken,
    FailureKind.weakPassword => l.failureWeakPassword,
    FailureKind.emailNotConfirmed => l.failureEmailNotConfirmed,
    FailureKind.rateLimited => l.failureRateLimited,
    FailureKind.validation => l.failureValidation,
    FailureKind.unknown => l.genericError,
  };
}
