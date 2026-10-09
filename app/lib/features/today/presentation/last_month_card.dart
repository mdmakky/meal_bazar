import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/prefs.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../money/presentation/money_sheets.dart'
    show showAddDepositSheet, showMyDepositSheet;
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../../report/presentation/report_actions.dart';

/// Days into a new period that the closed month's final account stays up.
const lastMonthShowDays = 10;

/// Home: the month just ended (`my_last_month`), for both roles.
/// Closed → my final account for the first [lastMonthShowDays] days
/// (dismissible per month). Not closed → the same card with provisional
/// figures (and a note while the month is being corrected); closing itself
/// is the manager's chip, not a card here. Nothing while loading, on error,
/// or with no previous month.
class LastMonthCard extends ConsumerWidget {
  const LastMonthCard({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastMonthProvider(messId)).value;
    final flags = ref.watch(messFlagsProvider(messId)).value ?? const {};
    final days = today().difference(last?.end ?? today()).inDays;
    final fresh = last != null && days >= 0 && days < lastMonthShowDays;

    final Widget? card = switch (last) {
      null => null,
      LastMonth(closed: true) when !fresh || flags.contains(_flag(last)) =>
        null,
      LastMonth(closed: true, closingBalance: null) => null,
      LastMonth(closed: true) => _FinalAccount(messId: messId, last: last),
      // Not closed yet: the figures are shown, labelled provisional.
      LastMonth(closingBalance: != null) => _FinalAccount(
        messId: messId,
        last: last,
      ),
      _ => _NotFinal(last: last, fresh: fresh),
    };
    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.base),
      curve: AppMotion.state,
      alignment: Alignment.topCenter,
      child: card == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.gutter,
                0,
              ),
              child: card,
            ),
    );
  }
}

String _flag(LastMonth m) => 'lastMonth:${isoDate(m.start)}';

String _monthYear(BuildContext context, DateTime d) => Fmt.digits(
  '${Fmt.monthName(d, locale: Localizations.localeOf(context).languageCode)} '
  '${d.year}',
  bangla: _bn(context),
);

bool _bn(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'bn';

/// "অক্টোবর মাস শুরু হয়েছে": the new period's name, early in it only.
class _NewMonthLine extends StatelessWidget {
  const _NewMonthLine({required this.last});

  final LastMonth last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = Fmt.monthName(
      last.end,
      locale: Localizations.localeOf(context).languageCode,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        spacing: AppSpace.sm,
        children: [
          Container(
            width: AppSize.dot,
            height: AppSize.dot,
            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
          ),
          Flexible(
            child: Text(
              AppLocalizations.of(context).lastMonthNewMonth(name),
              style: AppType.overline(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// My closed month: meals, cost, what I paid, and the final balance that
/// carried into this month. PDF, and "জমা দিন" when I owe.
class _FinalAccount extends ConsumerWidget {
  const _FinalAccount({required this.messId, required this.last});

  final String messId;
  final LastMonth last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = _bn(context);
    final balance = last.closingBalance!;
    final provisional = !last.closed;
    final food = last.foodCost ?? 0;
    final extra = last.extraCost ?? 0;
    final opening = last.openingBalance ?? 0;
    final manager = ref.watch(amIManagerProvider);
    final canPay = manager || ref.featureOn('member_deposits');

    Widget figure(String label, String value, {String? proof}) => Expanded(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(label, style: AppType.overline(context)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: text.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return AppCard.raised(
      key: const Key('last-month-final'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xs,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NewMonthLine(last: last),
                      Semantics(
                        header: true,
                        child: Text(
                          provisional
                              ? l.monthEndProvisionalTitle
                              : l.lastMonthFinalTitle,
                          style: text.titleMedium,
                        ),
                      ),
                      Text(
                        _monthYear(context, last.start),
                        style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              if (!provisional)
                IconButton(
                  tooltip: l.lastMonthHide,
                  icon: Icon(Icons.close, size: 20, color: p.inkTertiary),
                  onPressed: () => setMessFlag(ref, messId, _flag(last)),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: AppSpace.md,
                  children: [
                    figure(
                      l.lastMonthMeals,
                      Fmt.meals(last.meals ?? 0, banglaDigits: bn),
                    ),
                    figure(
                      l.lastMonthCost,
                      Fmt.money(food + extra, banglaDigits: bn),
                    ),
                    figure(
                      l.lastMonthPaid,
                      Fmt.money(last.credit ?? 0, banglaDigits: bn),
                    ),
                  ],
                ),
                if (extra != 0 || opening != 0) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    [
                      if (extra != 0)
                        l.lastMonthCostProof(
                          Fmt.money(food, banglaDigits: bn),
                          Fmt.money(extra, banglaDigits: bn),
                        ),
                      if (opening != 0)
                        '${l.lastMonthOpening} '
                            '${opening > 0 ? '+' : ''}'
                            '${Fmt.money(opening, banglaDigits: bn)}',
                    ].join(' · '),
                    style: text.bodySmall?.copyWith(
                      color: p.inkTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  child: Divider(height: 1, color: p.border),
                ),
                MergeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: AppSpace.md,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(
                              provisional
                                  ? l.monthEndProvisionalBalance
                                  : l.lastMonthFinalBalance,
                              style: AppType.overline(context),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Money(
                                balance.abs(),
                                banglaDigits: bn,
                                style: AppType.figure(
                                  text.displaySmall!,
                                  banglaDigits: bn,
                                ).copyWith(color: _tone(p, balance)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: Text(
                          balance > 0
                              ? l.lastMonthAdvance
                              : balance < 0
                              ? l.lastMonthDue
                              : l.lastMonthSettled,
                          style: text.titleSmall?.copyWith(
                            color: _tone(p, balance),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                // The carry-forward, set apart as a quiet note of its own.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    child: Row(
                      spacing: AppSpace.sm,
                      children: [
                        Icon(
                          provisional
                              ? Icons.hourglass_empty
                              : Icons.subdirectory_arrow_right,
                          size: 18,
                          color: p.inkSecondary,
                        ),
                        Expanded(
                          child: Text(
                            !provisional
                                ? l.lastMonthCarried
                                : last.reopenedAt != null
                                ? l.monthEndCorrectionNote
                                : l.monthEndProvisionalNote,
                            style: text.bodySmall?.copyWith(
                              color: p.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  spacing: AppSpace.sm,
                  children: [
                    if (!provisional && ref.featureOn('pdf_report'))
                      Expanded(
                        child: AppButton(
                          label: l.lastMonthReport,
                          icon: Icons.picture_as_pdf_outlined,
                          variant: AppButtonVariant.secondary,
                          expand: true,
                          onPressed: () => shareMonthReport(
                            context,
                            messId: messId,
                            day: last.start,
                          ),
                        ),
                      ),
                    if (balance < 0 && canPay)
                      Expanded(
                        child: AppButton(
                          label: l.lastMonthPay,
                          icon: Icons.savings_outlined,
                          expand: true,
                          onPressed: () => manager
                              ? showAddDepositSheet(context)
                              : showMyDepositSheet(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The sign is carried by the word (জমা আছে / বাকি) and the colour.
  Color? _tone(AppPalette p, double v) =>
      v > 0 ? p.advance : (v < 0 ? p.due : null);
}

/// Member: last month is not final yet. Quiet, no action.
class _NotFinal extends StatelessWidget {
  const _NotFinal({required this.last, required this.fresh});

  final LastMonth last;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      key: const Key('last-month-open'),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fresh) _NewMonthLine(last: last),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.sm,
            children: [
              Icon(Icons.hourglass_empty, size: 18, color: p.inkTertiary),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).lastMonthNotFinal,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: p.inkSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
