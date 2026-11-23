import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';

/// Who the report is for: the designer gets inputs, warnings and the
/// step-by-step working; the customer gets the inputs and results only.
enum ReportAudience { designer, customer }

/// The inputs a person entered, as "label → value" lines (visible fields only).
List<(String, String)> describeInputs(CalcModule module, CalcInputs inputs) => [
  for (final g in module.groups)
    if (g.isVisible(inputs))
      for (final f in g.fields)
        if (f.isVisible(inputs))
          (
            f.label,
            switch (f) {
              NumberField(:final unit) => '${_number(inputs.n(f.key))}${unit == null ? '' : ' $unit'}',
              ChoiceField(:final options) =>
                options.where((o) => o.value == inputs.s(f.key)).firstOrNull?.label ?? inputs.s(f.key),
            },
          ),
];

String _number(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');

/// A4 PDF of one calculation, made on the phone. Uses the app's own fonts (Ubuntu, with Noto Sans Bengali for
/// Bangla), so Ω, ², ≥ and Bangla names print correctly.
Future<Uint8List> buildCalcReport({
  required CalcModule module,
  required CalcInputs inputs,
  required CalcResult result,
  required ReportAudience audience,
  String? projectName,
  String preparedBy = '',
  String company = '',
  DateTime? now,
}) async {
  Future<pw.Font> font(String file) async => pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
  final regular = await font('Ubuntu-Regular.ttf');
  final bold = await font('Ubuntu-Bold.ttf');
  final bengali = await font('NotoSansBengali.ttf');

  const brand = PdfColor.fromInt(0xFF1656D6);
  const deep = PdfColor.fromInt(0xFF0B3B8C);
  const muted = PdfColor.fromInt(0xFF5B6270);
  const line = PdfColor.fromInt(0xFFDDE2EC);
  const soft = PdfColor.fromInt(0xFFF1F4FA);
  const bad = PdfColor.fromInt(0xFFBA1A1A);
  const ok = PdfColor.fromInt(0xFF16A34A);
  final designer = audience == ReportAudience.designer;
  final date = DateFormat('d MMM yyyy').format(now ?? DateTime.now());

  // Glyphs the fonts don't have.
  String t(String s) => s.replaceAll('√', 'sqrt ').replaceAll('✔', 'OK').replaceAll('✘', 'NO');

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
    child: pw.Text(t(text), style: pw.TextStyle(font: bold, fontSize: 12, color: deep)),
  );

  pw.Widget rows(List<(String, String, Tone)> items) => pw.Table(
    columnWidths: const {0: pw.FlexColumnWidth(5), 1: pw.FlexColumnWidth(6)},
    border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: line, width: 0.5)),
    children: [
      for (final (label, value, tone) in items)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(t(label), style: const pw.TextStyle(fontSize: 9.5, color: muted)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                t(value),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 9.5,
                  color: switch (tone) {
                    Tone.bad => bad,
                    Tone.ok => ok,
                    Tone.normal => PdfColors.black,
                  },
                ),
              ),
            ),
          ],
        ),
    ],
  );

  final inputLines = describeInputs(module, inputs);
  final doc = pw.Document(
    title: projectName ?? module.title,
    author: preparedBy.isEmpty ? AppConstants.appName : preparedBy,
    creator: '${AppConstants.appName} by ${AppConstants.company}',
    theme: pw.ThemeData.withFont(base: regular, bold: bold, fontFallback: [bengali]),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: brand, width: 1.2))),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: 'Power', style: pw.TextStyle(font: bold, fontSize: 16, color: brand)),
                  pw.TextSpan(
                    text: 'Hub',
                    style: pw.TextStyle(font: regular, fontSize: 16, color: const PdfColor.fromInt(0xFFF5A10F)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text('by ${AppConstants.company}', style: const pw.TextStyle(fontSize: 8, color: muted)),
            pw.Spacer(),
            pw.Text(
              '${AppConstants.standards} · ${designer ? 'Design report' : 'Summary'} · $date',
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ),
      ),
      footer: (context) => pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Calculated with ${AppConstants.appName}. Confirm against manufacturer data, site conditions and the '
              'utility before construction.',
              style: const pw.TextStyle(fontSize: 7, color: muted),
            ),
          ),
          pw.Text('${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: muted)),
        ],
      ),
      build: (context) => [
        pw.Text(t(projectName ?? module.title), style: pw.TextStyle(font: bold, fontSize: 18)),
        pw.SizedBox(height: 2),
        pw.Text(
          [
            module.title,
            if (preparedBy.isNotEmpty) 'Prepared by $preparedBy',
            if (company.isNotEmpty) company,
          ].join(' · '),
          style: const pw.TextStyle(fontSize: 9.5, color: muted),
        ),
        pw.SizedBox(height: 12),
        // The headline result.
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: soft, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(t(result.headline.label.toUpperCase()), style: const pw.TextStyle(fontSize: 8, color: muted)),
                    pw.SizedBox(height: 2),
                    pw.Text(t(result.headline.value), style: pw.TextStyle(font: bold, fontSize: 16, color: deep)),
                    if (result.headline.caption != null)
                      pw.Text(t(result.headline.caption!), style: const pw.TextStyle(fontSize: 9, color: muted)),
                  ],
                ),
              ),
              for (final m in result.metrics)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(t(m.label), style: const pw.TextStyle(fontSize: 8, color: muted)),
                      pw.Text(t(m.value), style: pw.TextStyle(font: bold, fontSize: 10.5)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (inputLines.isNotEmpty) ...[
          heading('Inputs'),
          rows([for (final (l, v) in inputLines) (l, v, Tone.normal)]),
        ],
        for (final s in result.sections) ...[
          heading(s.title),
          rows([for (final r in s.rows) (r.label, r.value, r.tone)]),
          if (s.note != null && designer)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(t(s.note!), style: const pw.TextStyle(fontSize: 8, color: muted)),
            ),
        ],
        if (designer && result.issues.isNotEmpty) ...[
          heading('To check'),
          for (final i in result.issues)
            pw.Bullet(
              text: t('${i.message} ${i.fix}${i.suggestion == null ? '' : ' (${i.suggestion})'}'),
              style: const pw.TextStyle(fontSize: 9),
            ),
        ],
        if (designer && result.steps.isNotEmpty) ...[
          heading('Step-by-step calculation'),
          pw.TableHelper.fromTextArray(
            headers: const ['Calculation', 'Formula', 'Working', 'Result'],
            data: [
              for (final s in result.steps) [t(s.title), t(s.formula), t(s.working), t(s.result)],
            ],
            headerStyle: pw.TextStyle(font: bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: deep),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(5),
              2: pw.FlexColumnWidth(5),
              3: pw.FlexColumnWidth(3),
            },
            border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: line, width: 0.5)),
          ),
        ],
        if (module.basis != null) ...[
          heading('Basis'),
          pw.Text(t(module.basis!), style: const pw.TextStyle(fontSize: 8, color: muted)),
        ],
      ],
    ),
  );
  return doc.save();
}
