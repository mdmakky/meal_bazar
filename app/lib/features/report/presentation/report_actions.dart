import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../mess/application/mess_providers.dart';
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
    final data = ReportData(
      messName: ref.read(currentMessProvider)?.name ?? '',
      period: period,
      totals: await ref.read(monthTotalsProvider(messId).future),
      balances: await ref.read(memberBalancesProvider(messId).future),
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
