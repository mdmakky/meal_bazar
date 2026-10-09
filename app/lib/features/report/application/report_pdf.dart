import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/format.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../month/domain/month.dart';

/// Everything the report shows. All figures come from the SQL providers.
class ReportData {
  const ReportData({
    required this.messName,
    required this.period,
    required this.totals,
    required this.balances,
    required this.locale,
    required this.generatedOn,
  });

  final String messName;
  final MonthPeriod period;
  final MonthTotals totals;
  final List<MemberBalance> balances;

  /// 'bn' or 'en'. Bangla also switches the digits.
  final String locale;
  final DateTime generatedOn;

  bool get banglaDigits => locale.startsWith('bn');
}

/// One table row, already formatted: name, meals, food, extra, paid, balance.
/// [due] marks a negative balance.
typedef ReportRow = ({List<String> cells, bool due});

List<ReportRow> reportRows(
  List<MemberBalance> balances, {
  required AppLocalizations l,
  bool banglaDigits = false,
}) {
  String money(double v) => Fmt.money(v, banglaDigits: banglaDigits);
  return [
    for (final b in balances)
      (
        cells: [
          b.displayName,
          Fmt.meals(b.meals, banglaDigits: banglaDigits),
          money(b.foodCost),
          money(b.extraCost),
          money(b.credit),
          b.closingBalance == 0
              ? money(0)
              : '${money(b.closingBalance.abs())} '
                    '${b.closingBalance < 0 ? l.reportDue : l.reportAdvance}',
        ],
        due: b.closingBalance < 0,
      ),
  ];
}

/// A4 portrait, monochrome.
///
/// Bengali text: the pdf package has no Indic shaping (no GSUB/GPOS for
/// conjuncts and pre-base vowel signs), so any string with Bengali letters is
/// laid out by Flutter's own text engine (which shapes correctly) and embedded
/// as a small high-dpi image. Everything else (Latin text, numbers, Bangla
/// digits and ৳, which need no shaping) stays vector text in Hind Siliguri.
Future<Uint8List> buildMonthReportPdf(ReportData data) async {
  final l = lookupAppLocalizations(ui.Locale(data.banglaDigits ? 'bn' : 'en'));
  final bd = data.banglaDigits;
  final t = data.totals;
  String money(double v) => Fmt.money(v, banglaDigits: bd);
  String date(DateTime d) =>
      Fmt.dateLong(d, locale: data.locale, banglaDigits: bd);

  final doc = pw.Document(
    title: '${data.messName} · ${l.reportTitle}',
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(
        await rootBundle.load('assets/fonts/HindSiliguri-Regular.ttf'),
      ),
      bold: pw.Font.ttf(
        await rootBundle.load('assets/fonts/HindSiliguri-SemiBold.ttf'),
      ),
    ),
  );

  final summary = [
    (l.reportFoodTotal, money(t.foodTotal)),
    (l.reportTotalMeals, Fmt.meals(t.totalMeals, banglaDigits: bd)),
    (
      l.reportMealRate,
      [money(t.mealRate), if (t.fixedRate) '(${l.rateFixed})'].join(' '),
    ),
    (l.reportExtraTotal, money(t.extraTotal)),
    (l.reportDeposits, money(t.creditTotal)),
  ];
  final header = [
    l.reportName,
    l.reportMeals,
    l.reportFoodCost,
    l.reportExtra,
    l.reportPaid,
    l.reportBalance,
  ];
  final rows = reportRows(data.balances, l: l, banglaDigits: bd);

  const grey = PdfColor.fromInt(0xFF5C5B57);
  const hairline = PdfColor.fromInt(0xFFCFCECA);
  final title = await _text(data.messName, 18, bold: true);
  final subtitle = await _text(
    '${l.reportTitle} · ${date(data.period.start)} – '
    '${date(data.period.end.subtract(const Duration(days: 1)))}',
    11,
    color: grey,
  );
  final summaryCells = [
    for (final (label, value) in summary)
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          await _text(label, 9, color: grey),
          pw.SizedBox(height: 2),
          await _text(value, 13, bold: true),
        ],
      ),
  ];
  final formula = await _text(l.reportFormula, 9, color: grey);
  final headerCells = [
    for (final h in header) await _text(h, 9, bold: true, color: grey),
  ];
  final bodyCells = [
    for (final r in rows)
      [
        for (final (i, c) in r.cells.indexed)
          await _text(c, 9.5, bold: i == 5 && r.due),
      ],
  ];
  final empty = rows.isEmpty
      ? await _text(l.reportNoMembers, 10, color: grey)
      : null;
  final footer = await _text(
    l.reportFooter(date(data.generatedOn)),
    8,
    color: grey,
  );

  pw.Widget cell(pw.Widget w, int col) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    alignment: col == 0 ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
    child: w,
  );
  pw.TableRow row(List<pw.Widget> cells, {bool head = false}) => pw.TableRow(
    decoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: head ? grey : hairline, width: 0.5),
      ),
    ),
    children: [for (final (i, w) in cells.indexed) cell(w, i)],
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (_) =>
          pw.Align(alignment: pw.Alignment.centerLeft, child: footer),
      build: (_) => [
        title,
        pw.SizedBox(height: 4),
        subtitle,
        pw.SizedBox(height: 18),
        pw.Wrap(spacing: 28, runSpacing: 10, children: summaryCells),
        pw.SizedBox(height: 8),
        formula,
        pw.SizedBox(height: 18),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            5: pw.FlexColumnWidth(1.8),
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          defaultColumnWidth: const pw.FlexColumnWidth(),
          children: [
            row(headerCells, head: true),
            for (final r in bodyCells) row(r),
          ],
        ),
        if (empty != null) ...[pw.SizedBox(height: 12), empty],
      ],
    ),
  );
  return doc.save();
}

/// Bengali letters/signs that need shaping. Bangla digits (U+09E6–09EF) and
/// ৳ (U+09F3) are single glyphs and render fine as vector text.
bool needsShaping(String s) => s.runes.any(
  (r) =>
      r >= 0x0980 &&
      r <= 0x09FF &&
      !(r >= 0x09E6 && r <= 0x09EF) &&
      r != 0x09F3,
);

const _rasterScale = 4.0; // 288 dpi: crisp in print, small after flate.

Future<pw.Widget> _text(
  String s,
  double size, {
  bool bold = false,
  PdfColor color = PdfColors.black,
}) async {
  if (!needsShaping(s)) {
    return pw.Text(
      s,
      style: pw.TextStyle(
        fontSize: size,
        color: color,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }
  final para =
      (ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontFamily: 'HindSiliguri',
                fontSize: size * _rasterScale,
                fontWeight: bold ? ui.FontWeight.w600 : ui.FontWeight.w400,
                maxLines: 1,
              ),
            )
            ..pushStyle(ui.TextStyle(color: ui.Color(color.toInt())))
            ..addText(s))
          .build()
        ..layout(const ui.ParagraphConstraints(width: double.infinity));
  final w = para.maxIntrinsicWidth.ceil().clamp(1, 1 << 14);
  final h = para.height.ceil().clamp(1, 1 << 14);
  para.layout(ui.ParagraphConstraints(width: w.toDouble()));
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawParagraph(para, ui.Offset.zero);
  final image = await rec.endRecording().toImage(w, h);
  final rgba = await image.toByteData();
  image.dispose();
  return pw.Image(
    pw.RawImage(bytes: rgba!.buffer.asUint8List(), width: w, height: h),
    width: w / _rasterScale,
    height: h / _rasterScale,
  );
}
