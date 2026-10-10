import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/format.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../money/domain/money.dart';
import '../../money/presentation/money_sheets.dart' show methodLabel;
import 'report_data.dart';

export 'report_data.dart';

// Design C "matrix + timeline": monochrome ink with a turmeric tint.
const _ink = PdfColor.fromInt(0xFF141416);
const _ink2 = PdfColor.fromInt(0xFF55545A);
const _rule = PdfColor.fromInt(0xFFE4E2DC);
const _rule2 = PdfColor.fromInt(0xFFF3F1EC);
const _turmeric = PdfColor.fromInt(0xFFC98A0B);
const _turmericInk = PdfColor.fromInt(0xFF8A5D00);
const _tint = PdfColor.fromInt(0xFFFBF3DF);
const _good = PdfColor.fromInt(0xFF1F7A4D);
const _bad = PdfColor.fromInt(0xFFB4372B);
const _faint = PdfColor.fromInt(0xFFB9B6AE);
const _zero = PdfColor.fromInt(0xFFC9C6BD);
const _absent = PdfColor.fromInt(0xFFADAAA2);
const _heat = [
  PdfColor.fromInt(0xFFF4F3EF),
  PdfColor.fromInt(0xFFF6EAD0),
  PdfColor.fromInt(0xFFECD29A),
  PdfColor.fromInt(0xFFDDB055),
  _ink,
];

/// 12.7 mm on every side: inside any printer's unprintable edge.
const reportMargin = 36.0;
const _cellText = 7.5; // never below 7 pt anywhere in the day grids
const _subRow = 12.0; // one meal type's line in the daily grid

int _heatLevel(double v) => v == 0
    ? 0
    : v <= 1
    ? 1
    : v <= 2
    ? 2
    : v <= 2.5
    ? 3
    : 4;

/// The A4 report as bytes.
Future<Uint8List> buildMonthReportPdf(ReportData data) async =>
    (await buildMonthReport(data)).save();

/// Four sections, each its own run of pages: the two day grids on A4
/// landscape (31 day columns fit at ≥ 20 pt each), the bazar timeline and
/// the money pages on A4 portrait. Table headers repeat on every page; a
/// member's block and a bazar's row never split across pages.
///
/// Bengali text: the pdf package has no Indic shaping (no GSUB/GPOS for
/// conjuncts and pre-base vowel signs), so any string with Bengali letters is
/// laid out by Flutter's own text engine (which shapes correctly) and embedded
/// as a high-dpi image, wrapped to its cell width. Everything else (Latin
/// text, numbers, Bangla digits and ৳, which need no shaping) stays vector
/// text in Hind Siliguri.
Future<pw.Document> buildMonthReport(ReportData d) async {
  final l = lookupAppLocalizations(ui.Locale(d.banglaDigits ? 'bn' : 'en'));
  final bd = d.banglaDigits;
  final tx = _Tx();
  final members = reportMembers(d);
  final types = d.shownTypes;
  final days = d.days;
  final weekdays = l.reportWeekdays.split(',');
  final weekdaysShort = l.reportWeekdaysShort.split(',');
  String n(Object v) => Fmt.digits('$v', bangla: bd);
  String meals(num v) => Fmt.meals(v, banglaDigits: bd);
  String money(num v) => Fmt.money(v, banglaDigits: bd);
  String long(DateTime x) =>
      Fmt.dateLong(x, locale: d.locale, banglaDigits: bd);
  String dayMonth(DateTime x) => long(x).replaceFirst(RegExp(r' \S+$'), '');
  String weekday(DateTime x) => weekdays[x.weekday % 7];
  final last = days.isEmpty ? d.period.start : days.last;
  final oneMonth = d.period.start.month == last.month;
  String shortDate(DateTime x) =>
      oneMonth ? n(x.day) : n('${x.day}/${x.month}');

  final doc = pw.Document(
    title: '${d.messName} · ${l.reportTitle}',
    theme:
        pw.ThemeData.withFont(
          base: pw.Font.ttf(
            await rootBundle.load('assets/fonts/HindSiliguri-Regular.ttf'),
          ),
          bold: pw.Font.ttf(
            await rootBundle.load('assets/fonts/HindSiliguri-SemiBold.ttf'),
          ),
        ).copyWith(
          defaultTextStyle: const pw.TextStyle(color: _ink, fontSize: 8.5),
        ),
  );

  // ---- shared page chrome -------------------------------------------------
  final monthLabel = long(
    d.period.start,
  ).replaceFirst(RegExp(r'^\S+ '), ''); // "সেপ্টেম্বর ২০২৬"
  final range =
      '${dayMonth(d.period.start)} – ${dayMonth(last)} · '
      '${d.closed ? l.monthStatusClosed : l.monthStatusOpen}';
  final footerText = l.reportFooter(long(d.generatedOn));
  await tx.warm(footerText, 7.5, color: _ink2);
  await tx.warm(l.reportPage, 7.5, color: _ink2);
  await tx.warm('ম', 13, bold: true, color: PdfColors.white);
  for (final t in [l.reportTitle, range]) {
    await tx.warm(t, 7.5, color: _ink2);
  }
  await tx.warm(monthLabel, 10.5, bold: true);

  Future<pw.Widget Function(pw.Context)> header(
    String section,
    double width,
  ) async {
    final textWidth = width - 180;
    final sub = [
      if (d.address?.trim().isNotEmpty ?? false) d.address!.trim(),
      if (d.managerName?.isNotEmpty ?? false) l.reportManager(d.managerName!),
      section,
    ].join(' · ');
    await tx.warm(d.messName, 15, bold: true, maxWidth: textWidth);
    await tx.warm(sub, 8.5, color: _ink2, maxWidth: textWidth);
    return (_) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Stack(
            children: [
              pw.Container(
                width: 24,
                height: 24,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: _ink,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: tx.get('ম', 13, bold: true, color: PdfColors.white),
              ),
              pw.Positioned(
                right: 4,
                top: 4,
                child: pw.Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: const pw.BoxDecoration(
                    color: _turmeric,
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                tx.get(d.messName, 15, bold: true, maxWidth: textWidth),
                pw.SizedBox(height: 1),
                tx.get(sub, 8.5, color: _ink2, maxWidth: textWidth),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              tx.get(l.reportTitle, 7.5, color: _ink2),
              tx.get(monthLabel, 10.5, bold: true),
              tx.get(range, 7.5, color: _ink2),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget footer(pw.Context c) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.only(top: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _rule, width: 0.75)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        tx.get(footerText, 7.5, color: _ink2),
        pw.Row(
          children: [
            tx.get(l.reportPage, 7.5, color: _ink2),
            pw.Text(
              ' ${n(c.pageNumber)} / ${n(c.pagesCount)}',
              style: const pw.TextStyle(fontSize: 7.5, color: _ink2),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> addSection(
    PdfPageFormat format,
    String section,
    List<pw.Widget> body,
  ) async {
    final head = await header(section, format.width - 2 * reportMargin);
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(reportMargin),
        maxPages: 200,
        header: head,
        footer: footer,
        build: (_) => body,
      ),
    );
  }

  // ---- building blocks ----------------------------------------------------
  Future<pw.Widget> h3(String title, double width, {String? hint}) async =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            await tx(title, 10, bold: true, maxWidth: width * 0.36),
            if (hint != null)
              await tx(hint, 8, color: _ink2, maxWidth: width * 0.6),
          ],
        ),
      );

  Future<pw.Widget> tag(String s, {bool own = false}) async => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 3.5, vertical: 0.5),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: own ? _turmeric : _rule, width: 0.75),
      borderRadius: pw.BorderRadius.circular(2.5),
    ),
    child: await tx(s, 7, color: own ? _turmericInk : _ink2, maxWidth: 200),
  );

  Future<pw.Widget> legend(List<(PdfColor?, String)> items) async => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 5),
    child: pw.Wrap(
      spacing: 10,
      runSpacing: 3,
      crossAxisAlignment: pw.WrapCrossAlignment.center,
      children: [
        for (final (color, label) in items)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (color != null) ...[
                pw.Container(
                  width: 12,
                  height: 8,
                  decoration: pw.BoxDecoration(
                    color: color,
                    border: pw.Border.all(color: _rule, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(1.5),
                  ),
                ),
                pw.SizedBox(width: 3),
              ],
              await tx(label, 7.5, color: _ink2),
            ],
          ),
      ],
    ),
  );

  pw.Widget cell(
    pw.Widget child, {
    bool left = false,
    PdfColor? color,
    pw.EdgeInsets pad = const pw.EdgeInsets.symmetric(
      vertical: 3,
      horizontal: 4,
    ),
  }) => pw.Container(
    color: color,
    padding: pad,
    alignment: left ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
    child: child,
  );

  /// A ledger table: header repeats on each page, optional bold total row.
  Future<pw.Widget> ledger({
    required List<String> head,
    required Map<int, pw.TableColumnWidth> widths,
    required List<List<pw.Widget>> rows,
    required Set<int> leftCols,
    List<pw.Widget>? total,
    List<bool> dimmed = const [],
  }) async {
    final headCells = [
      for (final h in head) await tx(h, 7.5, bold: true, color: _ink2),
    ];
    pw.TableRow row(
      List<pw.Widget> cells, {
      PdfColor line = _rule,
      double width = 0.5,
      bool top = false,
      bool repeat = false,
    }) => pw.TableRow(
      repeat: repeat,
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      decoration: pw.BoxDecoration(
        border: top
            ? pw.Border(
                top: pw.BorderSide(color: line, width: width),
              )
            : pw.Border(
                bottom: pw.BorderSide(color: line, width: width),
              ),
      ),
      children: [
        for (final (i, w) in cells.indexed) cell(w, left: leftCols.contains(i)),
      ],
    );
    return pw.Table(
      columnWidths: widths,
      defaultColumnWidth: const pw.FlexColumnWidth(),
      children: [
        row(headCells, line: _ink, width: 1.2, repeat: true),
        for (final r in rows) row(r),
        if (total != null) row(total, line: _ink, width: 1.2, top: true),
      ],
    );
  }

  String signed(double v) =>
      v == 0 ? money(0) : '${v > 0 ? '+' : '−'}${money(v.abs())}';

  // ---- 1. meal matrix + meal types by member (landscape) -----------------
  final land = PdfPageFormat(PdfPageFormat.a4.height, PdfPageFormat.a4.width);
  final landW = land.width - 2 * reportMargin;
  const nameCol = 78.0;
  final dayTotal = {
    for (final t in d.dayTotals)
      DateTime(t.date.year, t.date.month, t.date.day): t.meals,
  };
  const tight = pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 0.5);
  pw.Widget small(
    String s, {
    bool bold = false,
    PdfColor color = _ink,
    double size = _cellText,
  }) => pw.Text(
    s,
    textAlign: pw.TextAlign.center,
    style: pw.TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  );
  final dayHead = [
    for (final x in days)
      pw.Column(
        children: [
          small(n(x.day), bold: true, color: _ink2),
          await tx(weekdaysShort[x.weekday % 7], 7, color: _ink2),
        ],
      ),
  ];
  final offMark = await tx(l.reportOffShort, _cellText, color: _faint);
  pw.Widget centered(pw.Widget w, {PdfColor? color}) => pw.Container(
    color: color,
    padding: tight,
    alignment: pw.Alignment.center,
    child: w,
  );

  final matrix = pw.Table(
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: PdfColors.white, width: 1),
      verticalInside: pw.BorderSide(color: PdfColors.white, width: 1),
    ),
    columnWidths: {
      0: const pw.FixedColumnWidth(nameCol),
      days.length + 1: const pw.FixedColumnWidth(34),
    },
    defaultColumnWidth: const pw.FlexColumnWidth(),
    children: [
      pw.TableRow(
        repeat: true,
        verticalAlignment: pw.TableCellVerticalAlignment.bottom,
        children: [
          cell(
            await tx(l.reportMember, 7.5, bold: true, color: _ink2),
            left: true,
            pad: tight,
          ),
          for (final h in dayHead) centered(h),
          centered(await tx(l.reportTotal, 7.5, bold: true, color: _ink2)),
        ],
      ),
      for (final m in members)
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            cell(
              await tx(m.name, 8, maxWidth: nameCol - 4),
              left: true,
              pad: const pw.EdgeInsets.fromLTRB(1, 2, 3, 2),
            ),
            for (final x in m.days)
              x.out
                  ? centered(small('·', color: _absent))
                  : centered(
                      x.off
                          ? offMark
                          : small(
                              x.weighted == 0 ? '–' : meals(x.weighted),
                              color: x.weighted == 0
                                  ? _faint
                                  : _heatLevel(x.weighted) == 4
                                  ? PdfColors.white
                                  : _ink,
                            ),
                      color: _heat[_heatLevel(x.off ? 0 : x.weighted)],
                    ),
            centered(small(meals(m.balance.meals), bold: true)),
          ],
        ),
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _ink, width: 1)),
        ),
        children: [
          cell(
            await tx(l.reportDayTotal, 7.5, bold: true),
            left: true,
            pad: tight,
          ),
          for (final x in days)
            centered(small(meals(dayTotal[x] ?? 0), bold: true)),
          centered(small(meals(d.totals.totalMeals), bold: true)),
        ],
      ),
    ],
  );

  final typeTable = await ledger(
    head: [
      l.reportMember,
      for (final t in types) t.name,
      l.reportGuests,
      l.reportOffDays,
      l.reportBazarTrips,
      l.reportWeightedMeals,
    ],
    widths: {0: const pw.FlexColumnWidth(2)},
    leftCols: {0},
    rows: [
      for (final m in members)
        [
          await tx(m.name, 8.5, maxWidth: landW * 0.2),
          for (final c in m.typeCounts) pw.Text(meals(c)),
          pw.Text(n(m.guests)),
          pw.Text(n(m.offDays)),
          await tx(l.reportTimes(n(m.bazarTrips)), 8.5),
          pw.Text(
            meals(m.balance.meals),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
    ],
  );
  final noMembers = await tx(l.reportNoMembers, 9, color: _ink2);

  await addSection(land, l.reportSectionMeals, [
    await h3(l.reportMatrix, landW, hint: l.reportMatrixHint),
    matrix,
    if (members.isEmpty) noMembers,
    await legend([
      (_heat[0], n(0)),
      (_heat[1], '≤${n(1)}'),
      (_heat[2], '≤${n(2)}'),
      (_heat[3], '≤${n(2.5)}'),
      (_heat[4], '${n(3)}+'),
      (null, l.reportOffLegend),
      (null, l.reportAbsentLegend),
    ]),
    await h3(l.reportTypeBreakdown, landW),
    typeTable,
  ]);

  // ---- 2. who ate what, day by day (landscape) ---------------------------
  const dlName = 74.0, dlType = 40.0, dlSum = 30.0;
  final typeLabels = [
    for (final t in types)
      await tx(t.name, 7, color: _ink2, maxWidth: dlType - 4),
  ];
  pw.Widget sub(
    pw.Widget child, {
    PdfColor? color,
    pw.Alignment align = pw.Alignment.center,
  }) => pw.Container(
    height: _subRow,
    color: color,
    margin: const pw.EdgeInsets.symmetric(horizontal: 0.4, vertical: 0.3),
    alignment: align,
    child: child,
  );
  pw.Widget value(ReportDay x, String typeId) {
    if (x.out) return sub(small('·', color: _absent));
    final e = x.entries[typeId];
    if (x.off || (e?.isOff ?? false)) return sub(offMark, color: _rule2);
    final v = e?.count ?? 0;
    final g = e?.guestCount ?? 0;
    final (PdfColor? bg, PdfColor fg, bool bold) = v == 0
        ? (null, _zero, false)
        : v % 1 != 0
        ? (_tint, _turmericInk, true)
        : v > 1
        ? (_ink, PdfColors.white, true)
        : (null, _ink, true);
    // Day cells use plain 1 / ½ / 2: a Bangla ১ at this size prints as a
    // squiggle. Totals keep the locale's digits.
    final whole = v.truncate();
    final cellText = v % 1 == 0 ? '$whole' : (whole == 0 ? '½' : '$whole½');
    final text = small(
      v == 0 ? '–' : cellText,
      bold: bold,
      color: fg,
      size: 8.5,
    );
    return sub(
      g == 0
          ? text
          : pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                text,
                pw.Text(
                  '+$g',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: bg == _ink ? _tint : _turmericInk,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
      color: bg,
    );
  }

  final daily = pw.Table(
    columnWidths: {
      0: const pw.FixedColumnWidth(dlName),
      1: const pw.FixedColumnWidth(dlType),
      days.length + 2: const pw.FixedColumnWidth(dlSum),
    },
    defaultColumnWidth: const pw.FlexColumnWidth(),
    children: [
      pw.TableRow(
        repeat: true,
        verticalAlignment: pw.TableCellVerticalAlignment.bottom,
        children: [
          cell(
            await tx(l.reportMember, 7.5, bold: true, color: _ink2),
            left: true,
            pad: tight,
          ),
          pw.SizedBox(),
          for (final x in days) centered(small(n(x.day), color: _ink2)),
          centered(await tx(l.reportTotal, 7.5, bold: true, color: _ink2)),
        ],
      ),
      for (final m in members)
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _ink, width: 1.2)),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(1, 3, 4, 3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  await tx(m.name, 8.5, bold: true, maxWidth: dlName - 6),
                  await tx(
                    l.reportMealsCount(meals(m.balance.meals)),
                    7,
                    color: _ink2,
                    maxWidth: dlName - 6,
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Column(
                children: [
                  for (final w in typeLabels)
                    sub(w, align: pw.Alignment.centerLeft),
                ],
              ),
            ),
            for (final x in m.days)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Column(
                  children: [for (final t in types) value(x, t.id)],
                ),
              ),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _rule)),
              ),
              child: pw.Column(
                children: [
                  for (final c in m.typeCounts)
                    sub(small(meals(c), bold: true)),
                ],
              ),
            ),
          ],
        ),
    ],
  );

  await addSection(land, l.reportSectionDaily, [
    await h3(
      l.reportDaily,
      landW,
      hint: l.reportDailyHint(types.map((t) => t.name).join(' / ')),
    ),
    daily,
    if (members.isEmpty) noMembers,
    await legend([
      (_tint, l.reportHalfMeal),
      (_ink, l.reportDoubleMeal),
      (_rule2, l.reportOff),
      (null, l.reportAbsentLegend),
      (null, l.reportCountNote),
    ]),
  ]);

  // ---- 3. bazar timeline (portrait) --------------------------------------
  const port = PdfPageFormat.a4;
  final portW = port.width - 2 * reportMargin;
  const tlDate = 66.0, tlAmount = 64.0;
  final tlMain = portW - tlDate - tlAmount - 12;
  String qty(double q) =>
      n(q.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''));
  final timeline = pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(tlDate),
      2: pw.FixedColumnWidth(tlAmount),
    },
    defaultColumnWidth: const pw.FlexColumnWidth(),
    children: [
      for (final b in d.bazars)
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  await tx(
                    dayMonth(b.date),
                    9.5,
                    bold: true,
                    maxWidth: tlDate - 6,
                  ),
                  await tx(weekday(b.date), 7.5, color: _ink2),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 6,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Wrap(
                    spacing: 5,
                    runSpacing: 2,
                    crossAxisAlignment: pw.WrapCrossAlignment.center,
                    children: [
                      await tx(
                        d.buyerIdsOf(b).map(d.nameOf).join(', '),
                        9,
                        bold: true,
                        maxWidth: tlMain,
                      ),
                      b.paidByMemberId == null
                          ? await tag(l.reportMessFund)
                          : await tag(
                              l.reportOwnPocket(d.nameOf(b.paidByMemberId)),
                              own: true,
                            ),
                    ],
                  ),
                  if (b.note?.trim().isNotEmpty ?? false)
                    await tx(
                      b.note!.trim(),
                      7.5,
                      color: _ink2,
                      maxWidth: tlMain,
                    ),
                  if (b.items.isNotEmpty) pw.SizedBox(height: 3),
                  pw.Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      for (final i in b.items)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1.5,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _rule2,
                            borderRadius: pw.BorderRadius.circular(2.5),
                          ),
                          child: await tx(
                            [
                              i.name,
                              if (i.qty != null)
                                [qty(i.qty!), ?i.unit].join(' '),
                              '· ${money(i.price)}',
                            ].join(' '),
                            7.5,
                            maxWidth: tlMain - 8,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  money(b.amount),
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
    ],
  );
  final none = await tx(l.reportNone, 9, color: _ink2);
  // Display total of the listed rows; the billed food total is SQL's.
  final bazarSum = itemsTotal(d.bazars.map((b) => b.amount));

  await addSection(port, l.reportSectionBazar, [
    await h3(
      l.reportTimeline,
      portW,
      hint: '${l.reportTimes(n(d.bazars.length))} · ${money(bazarSum)}',
    ),
    if (d.bazars.isEmpty) none else timeline,
  ]);

  // ---- 4. expenses, deposits, short summary (portrait) -------------------
  final dateCol = {0: const pw.FixedColumnWidth(50)};
  final expenseTable = await ledger(
    head: [l.reportDate, l.reportCategory, l.reportSplit, l.reportAmount],
    widths: {
      ...dateCol,
      1: const pw.FlexColumnWidth(1.3),
      2: const pw.FlexColumnWidth(1.7),
      3: const pw.FixedColumnWidth(70),
    },
    leftCols: {0, 1, 2},
    rows: [
      for (final e in d.expenses)
        [
          pw.Text(shortDate(e.date)),
          pw.Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            children: [
              await tx(
                d.categories[e.categoryId] ?? '',
                8.5,
                maxWidth: portW * 0.26,
              ),
              if (e.note?.trim().isNotEmpty ?? false) await tag(e.note!.trim()),
              if (e.paidByMemberId != null)
                await tag(
                  l.reportOwnPocket(d.nameOf(e.paidByMemberId)),
                  own: true,
                ),
            ],
          ),
          await tx(
            e.shares.isNotEmpty
                ? [
                    for (final s in e.shares.entries)
                      s.value == 1
                          ? d.nameOf(s.key)
                          : '${d.nameOf(s.key)} ×${meals(s.value)}',
                  ].join(', ')
                : e.split == SplitMethod.meal
                ? l.expenseSplitMeal
                : l.reportEveryone(n(d.presentCount(e.date))),
            8.5,
            maxWidth: portW * 0.34,
          ),
          pw.Text(money(e.amount)),
        ],
    ],
    total: [
      pw.SizedBox(),
      await tx(l.reportExpenseTotal, 8.5, bold: true),
      pw.SizedBox(),
      pw.Text(
        money(itemsTotal(d.expenses.map((e) => e.amount))),
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    ],
  );

  final deposits = [
    for (final x in d.deposits)
      if (x.status != DepositStatus.rejected) x,
  ];
  final depositTable = await ledger(
    head: [l.reportDate, l.reportMember, l.reportMethod, l.reportAmount],
    widths: {
      ...dateCol,
      1: const pw.FlexColumnWidth(1.3),
      2: const pw.FlexColumnWidth(1.7),
      3: const pw.FixedColumnWidth(70),
    },
    leftCols: {0, 1, 2},
    rows: [
      for (final x in deposits)
        [
          pw.Text(shortDate(x.date)),
          await tx(d.nameOf(x.memberId), 8.5, maxWidth: portW * 0.26),
          pw.Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            children: [
              await tx(methodLabel(l, x.method), 8.5),
              if (x.trxId?.trim().isNotEmpty ?? false) await tag(x.trxId!),
              if (x.isWithdrawal) await tag(l.withdrawTag, own: true),
              if (x.status == DepositStatus.pending)
                await tag(l.depositPending, own: true),
            ],
          ),
          pw.Text(
            money(x.amount),
            style: pw.TextStyle(
              color: x.status == DepositStatus.pending ? _faint : _ink,
            ),
          ),
        ],
    ],
    total: [
      pw.SizedBox(),
      await tx(l.reportVerifiedTotal, 8.5, bold: true),
      pw.SizedBox(),
      pw.Text(
        money(d.totals.creditTotal),
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    ],
  );

  final t = d.totals;
  final gap = rateGapText(l, t, money);
  final strip = pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _rule, width: 0.75),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Row(
      children: [
        for (final (i, (label, v)) in [
          (l.reportFoodTotal, money(t.foodTotal)),
          (l.reportTotalMeals, meals(t.totalMeals)),
          (l.reportMealRate, money(t.mealRate)),
          (l.reportExtraTotal, money(t.extraTotal)),
        ].indexed)
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: i == 3
                  ? null
                  : const pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: _rule, width: 0.75),
                      ),
                    ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  await tx(label, 7.5, color: _ink2, maxWidth: portW / 4 - 16),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    v,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  final summaryTable = await ledger(
    head: [
      l.reportMember,
      l.reportMeals,
      l.reportFoodCost,
      l.reportExtra,
      l.reportPaid,
      l.reportOpening,
      l.reportBalance,
    ],
    widths: {0: const pw.FlexColumnWidth(1.6)},
    leftCols: {0},
    rows: [
      for (final b in d.balances)
        [
          await tx(b.displayName, 8.5, maxWidth: portW * 0.18),
          pw.Text(meals(b.meals)),
          pw.Text(money(b.foodCost)),
          pw.Text(money(b.extraCost)),
          pw.Text(money(b.credit)),
          pw.Text(money(b.openingBalance)),
          pw.Text(
            signed(b.closingBalance),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: b.closingBalance > 0
                  ? _good
                  : b.closingBalance < 0
                  ? _bad
                  : _ink,
            ),
          ),
        ],
    ],
  );

  await addSection(port, l.reportSectionMoney, [
    await h3(l.reportExtraTotal, portW),
    if (d.expenses.isEmpty) none else expenseTable,
    await h3(l.reportDepositsTitle, portW),
    if (deposits.isEmpty) none else depositTable,
    await h3(
      l.reportSummary,
      portW,
      hint: t.fixedRate ? [l.rateFixed, ?gap].join(' · ') : l.reportFormula,
    ),
    strip,
    pw.SizedBox(height: 8),
    if (d.balances.isEmpty) noMembers else summaryTable,
  ]);

  return doc;
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

typedef _Raster = ({pw.ImageProvider image, double width, double height});

/// Text as a widget: vector when it needs no shaping, otherwise a shaped
/// image wrapped to [maxWidth]. Each distinct image is embedded once.
class _Tx {
  final _cache = <String, _Raster>{};

  static String _key(
    String s,
    double size,
    bool bold,
    PdfColor color,
    double? maxWidth,
  ) => '$size|$bold|${color.toInt()}|$maxWidth|$s';

  Future<pw.Widget> call(
    String s,
    double size, {
    bool bold = false,
    PdfColor color = _ink,
    double? maxWidth,
  }) async {
    await warm(s, size, bold: bold, color: color, maxWidth: maxWidth);
    return get(s, size, bold: bold, color: color, maxWidth: maxWidth);
  }

  Future<void> warm(
    String s,
    double size, {
    bool bold = false,
    PdfColor color = _ink,
    double? maxWidth,
  }) async {
    if (!needsShaping(s)) return;
    final key = _key(s, size, bold, color, maxWidth);
    if (_cache.containsKey(key)) return;
    _cache[key] = await _raster(s, size, bold, color, maxWidth);
  }

  /// Sync, for page headers/footers: Bengali text must be [warm]ed first.
  pw.Widget get(
    String s,
    double size, {
    bool bold = false,
    PdfColor color = _ink,
    double? maxWidth,
  }) {
    if (!needsShaping(s)) {
      final text = pw.Text(
        s,
        style: pw.TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      );
      return maxWidth == null
          ? text
          : pw.ConstrainedBox(
              constraints: pw.BoxConstraints(maxWidth: maxWidth),
              child: text,
            );
    }
    final r = _cache[_key(s, size, bold, color, maxWidth)]!;
    return pw.Image(r.image, width: r.width, height: r.height);
  }

  static Future<_Raster> _raster(
    String s,
    double size,
    bool bold,
    PdfColor color,
    double? maxWidth,
  ) async {
    final para =
        (ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: size * _rasterScale,
                  fontWeight: bold ? ui.FontWeight.w600 : ui.FontWeight.w400,
                ),
              )
              ..pushStyle(ui.TextStyle(color: ui.Color(color.toInt())))
              ..addText(s))
            .build()
          ..layout(const ui.ParagraphConstraints(width: double.infinity));
    final limit = maxWidth == null ? double.infinity : maxWidth * _rasterScale;
    var width = para.maxIntrinsicWidth;
    if (width > limit) {
      para.layout(ui.ParagraphConstraints(width: limit));
      width = para.longestLine;
    } else {
      para.layout(ui.ParagraphConstraints(width: width.ceilToDouble()));
    }
    final w = width.ceil().clamp(1, 1 << 14);
    final h = para.height.ceil().clamp(1, 1 << 14);
    final rec = ui.PictureRecorder();
    ui.Canvas(rec).drawParagraph(para, ui.Offset.zero);
    final image = await rec.endRecording().toImage(w, h);
    final rgba = await image.toByteData();
    image.dispose();
    // An unbreakable word wider than the cell scales down rather than spill.
    final scale = w / _rasterScale > limit / _rasterScale
        ? limit / w
        : 1 / _rasterScale;
    return (
      image: pw.RawImage(
        bytes: rgba!.buffer.asUint8List(),
        width: w,
        height: h,
      ),
      width: w * scale,
      height: h * scale,
    );
  }
}
