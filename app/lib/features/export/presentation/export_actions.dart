import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/dates.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../meals/application/meal_providers.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/presentation/meal_widgets.dart' show bnDigits, snackFailure;
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart' show showFailure;
import '../../money/application/money_providers.dart';
import '../../money/data/money_repository.dart' show allPages;
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../application/export_text.dart';

/// Writes [period]'s balances, meals, bazars, expenses and deposits as CSV
/// files in a temp dir and opens the share sheet. Failures show a snackbar.
Future<void> exportMonthCsv(
  BuildContext context, {
  required String messId,
  required MonthPeriod period,
}) async {
  final ref = ProviderScope.containerOf(context, listen: false);
  final l = AppLocalizations.of(context);
  try {
    final money = ref.read(moneyRepositoryProvider);
    final meals = ref.read(mealRepositoryProvider);
    final members = await ref.read(membersProvider(messId).future);
    final names = {for (final m in members) m.id: m.displayName};
    // ponytail: archived categories are not listed, so their cell is blank.
    final categories = {
      for (final c in await ref.read(expenseCategoriesProvider(messId).future))
        c.id: c.name,
    };
    final csv = {
      'balances': balancesCsv(
        l,
        await ref.read(monthRepositoryProvider).balances(messId, period),
      ),
      'meals': mealsCsv(
        l,
        period: period,
        members: members,
        mealTypes: await ref.read(mealTypesProvider(messId).future),
        entries: await meals.entriesForRange(messId, period.start, period.end),
      ),
      'bazar': bazarsCsv(
        l,
        await allPages((from) => money.bazars(messId, period, from: from)),
        names,
      ),
      'expenses': expensesCsv(
        l,
        await allPages((from) => money.expenses(messId, period, from: from)),
        categories,
        names,
      ),
      'deposits': depositsCsv(
        l,
        await allPages((from) => money.deposits(messId, period, from: from)),
        names,
      ),
    };
    final tag = 'meal-bazar-${isoDate(period.start)}';
    final dir = await Directory(
      '${(await getTemporaryDirectory()).path}/$tag',
    ).create(recursive: true);
    final files = [
      for (final MapEntry(:key, :value) in csv.entries)
        XFile(
          (await File('${dir.path}/$tag-$key.csv').writeAsString(value)).path,
          mimeType: 'text/csv',
        ),
    ];
    await SharePlus.instance.share(ShareParams(files: files, subject: tag));
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

/// App-bar action: exports the current month's CSV files.
class ExportCsvAction extends StatefulWidget {
  const ExportCsvAction({super.key, required this.messId});

  final String messId;

  @override
  State<ExportCsvAction> createState() => _ExportCsvActionState();
}

class _ExportCsvActionState extends State<ExportCsvAction> {
  var _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final period = await ProviderScope.containerOf(
        context,
        listen: false,
      ).read(currentPeriodProvider(widget.messId).future);
      if (mounted) {
        await exportMonthCsv(context, messId: widget.messId, period: period);
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).exportAction,
    icon: const Icon(Icons.file_download_outlined),
    onPressed: _busy ? null : _export,
  );
}

/// Shares [date]'s (default: tomorrow's) meal count with the cook as text.
class CookShareButton extends ConsumerStatefulWidget {
  const CookShareButton({super.key, required this.messId, this.date});

  final String messId;
  final DateTime? date;

  @override
  ConsumerState<CookShareButton> createState() => _CookShareButtonState();
}

class _CookShareButtonState extends ConsumerState<CookShareButton> {
  var _busy = false;

  Future<void> _share() async {
    final now = today();
    final date = widget.date ?? DateTime(now.year, now.month, now.day + 1);
    final bangla = bnDigits(context);
    setState(() => _busy = true);
    try {
      final text = cookMealCountText(
        date: date,
        mealTypes: await ref.read(mealTypesProvider(widget.messId).future),
        entries: await ref.read(
          dayEntriesProvider((
            messId: widget.messId,
            day: dayOnly(date),
          )).future,
        ),
        messName: ref.read(currentMessProvider)?.name ?? '',
        banglaDigits: bangla,
      );
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      if (mounted) snackFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => !ref.featureOn('cook_share')
      ? const SizedBox.shrink()
      : PressableScale(
          enabled: !_busy,
          haptic: true,
          child: DecoratedBox(
            // Matches the raised bulk-action chips beside it.
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.palette.surfaceRaised,
              boxShadow: AppElevation.button(context.palette),
            ),
            child: IconButton(
              tooltip: AppLocalizations.of(context).cookShare,
              icon: Icon(
                Icons.soup_kitchen_outlined,
                color: context.palette.ink,
              ),
              onPressed: _busy ? null : _share,
            ),
          ),
        );
}
