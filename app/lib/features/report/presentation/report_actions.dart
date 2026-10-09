import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../meals/application/meal_providers.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../money/application/money_providers.dart';
import '../../money/data/money_repository.dart' show allPages;
import '../../month/application/month_providers.dart';
import '../application/report_pdf.dart';

/// Builds the current month's report and opens the system share sheet.
Future<void> shareMonthReport(BuildContext context, {required String messId}) =>
    _run(
      context,
      messId,
      (bytes, name) => Printing.sharePdf(bytes: bytes, filename: name),
    );

/// Builds the current month's report and opens the system print dialog.
Future<void> printMonthReport(BuildContext context, {required String messId}) =>
    _run(
      context,
      messId,
      (bytes, name) => Printing.layoutPdf(onLayout: (_) => bytes, name: name),
    );

Future<void> _run(
  BuildContext context,
  String messId,
  Future<Object?> Function(Uint8List bytes, String filename) deliver,
) async {
  final ref = ProviderScope.containerOf(context, listen: false);
  final locale = Localizations.localeOf(context).languageCode;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final period = await ref.read(currentPeriodProvider(messId).future);
    final money = ref.read(moneyRepositoryProvider);
    final members = await ref.read(membersProvider(messId).future);
    final data = ReportData(
      messName: ref.read(currentMessProvider)?.name ?? '',
      address: ref.read(currentMessProvider)?.address,
      managerName: [
        for (final m in members)
          if (m.role == MemberRole.manager && m.status == MemberStatus.active)
            m.displayName,
      ].join(', '),
      period: period,
      closed: (await ref.read(
        monthsProvider(messId).future,
      )).any((m) => m.closed && m.start == period.start),
      totals: await ref.read(monthTotalsProvider(messId).future),
      balances: await ref.read(memberBalancesProvider(messId).future),
      members: members,
      mealTypes: await ref.read(mealTypesProvider(messId).future),
      entries: await ref
          .read(mealRepositoryProvider)
          .entriesForRange(messId, period.start, period.end),
      dayTotals: await ref.read(dailyMealsProvider(messId).future),
      bazars: await allPages(
        (from) => money.bazars(messId, period, from: from),
      ),
      expenses: await allPages(
        (from) => money.expenses(messId, period, from: from),
      ),
      deposits: await allPages(
        (from) => money.deposits(messId, period, from: from),
      ),
      // ponytail: archived categories are not listed, so their cell is blank.
      categories: {
        for (final c in await ref.read(
          expenseCategoriesProvider(messId).future,
        ))
          c.id: c.name,
      },
      locale: locale,
      generatedOn: DateTime.now(),
    );
    final bytes = await buildMonthReportPdf(data);
    await deliver(bytes, 'meal-bazar-${isoDate(period.start)}.pdf');
  } catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(SnackBar(content: Text(failureText(context, e))));
  }
}
