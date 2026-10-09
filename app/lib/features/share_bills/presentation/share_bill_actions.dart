import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/presentation/meal_widgets.dart' show pickOne;
import '../../mess/application/mess_providers.dart';
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../domain/share_text.dart';

/// Opens the system share sheet (WhatsApp, Messenger, …) with [text].
Future<void> shareText(BuildContext context, String text) {
  final box = context.findRenderObject() as RenderBox?;
  return SharePlus.instance.share(
    ShareParams(
      text: text,
      // iPad needs an anchor for the share popover.
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// Bottom sheet with the three reminder tones; null when dismissed.
Future<ReminderTone?> pickReminderTone(BuildContext context) {
  final l = AppLocalizations.of(context);
  return pickOne(
    context,
    title: l.shareBillToneTitle,
    options: [
      for (final t in ReminderTone.values) (t, reminderToneLabel(l, t)),
    ],
  );
}

String _locale(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// The month's SQL figures needed for the bill texts, once all have loaded.
({MonthTotals totals, MonthPeriod period, String mess})? _monthData(
  WidgetRef ref,
  String messId,
) {
  final totals = ref.watch(monthTotalsProvider(messId)).value;
  final period = ref.watch(currentPeriodProvider(messId)).value;
  if (totals == null || period == null) return null;
  return (
    totals: totals,
    period: period,
    mess: ref.watch(currentMessProvider)?.name ?? '',
  );
}

/// "Share everyone's balance" for the money screen. Disabled until loaded.
class ShareMessSummaryButton extends ConsumerWidget {
  const ShareMessSummaryButton({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = _monthData(ref, messId);
    final balances = ref.watch(memberBalancesProvider(messId)).value;
    return AppButton(
      label: AppLocalizations.of(context).shareBillShareAll,
      icon: Icons.share_outlined,
      variant: AppButtonVariant.secondary,
      onPressed: data == null || balances == null || balances.isEmpty
          ? null
          : () => shareText(
              context,
              messSummaryText(
                balances,
                data.totals,
                mess: data.mess,
                period: data.period,
                locale: _locale(context),
              ),
            ),
    );
  }
}

/// "Share bill" and, for a due, "Remind" (tone picker → share).
class MemberShareActions extends ConsumerWidget {
  const MemberShareActions({super.key, required this.balance});

  final MemberBalance balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final data = messId == null ? null : _monthData(ref, messId);
    return Row(
      spacing: AppSpace.sm,
      children: [
        Expanded(
          child: AppButton(
            label: l.shareBillShare,
            icon: Icons.share_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: data == null
                ? null
                : () => shareText(
                    context,
                    memberBillText(
                      balance,
                      data.totals,
                      mess: data.mess,
                      period: data.period,
                      locale: _locale(context),
                    ),
                  ),
          ),
        ),
        if (balance.closingBalance < 0 && ref.featureOn('due_reminders'))
          Expanded(
            child: AppButton(
              label: l.shareBillRemind,
              icon: Icons.notifications_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                final tone = await pickReminderTone(context);
                if (tone == null || !context.mounted) return;
                await shareText(
                  context,
                  // ponytail: no mess payment-number setting yet; pass
                  // paymentNumber here once one exists.
                  dueReminderText(
                    balance,
                    tone: tone,
                    locale: _locale(context),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
