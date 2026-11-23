/// How a result value reads: neutral, fine (green) or a problem (red).
enum Tone { normal, ok, bad }

/// One "label ...... value" line of a result section.
class ResultRow {
  const ResultRow(this.label, this.value, {this.tone = Tone.normal});
  final String label;
  final String value;
  final Tone tone;
}

/// A titled block of results ("Transformer", "LV incomer").
class ResultSection {
  const ResultSection(this.title, this.rows, {this.note});
  final String title;
  final List<ResultRow> rows;

  /// Small print under the rows.
  final String? note;
}

/// The big answer at the top of the screen.
class CalcHeadline {
  const CalcHeadline(this.label, this.value, {this.caption});

  /// Small caps above the value ("TRANSFORMER").
  final String label;
  final String value;

  /// One line under it ("Loading 72 %").
  final String? caption;
}

/// A problem with the inputs or the design, with what to do about it.
/// [patch] (if given) is applied to the inputs by the "fix" button.
class CalcIssue {
  const CalcIssue(this.message, this.fix, {this.suggestion, this.patch, this.patchLabel});
  final String message;
  final String fix;

  /// A concrete value to use ("Use 2 × 630 kVA").
  final String? suggestion;
  final Map<String, Object?>? patch;
  final String? patchLabel;
}

/// One line of the step-by-step working.
class CalcStep {
  const CalcStep(this.title, this.formula, this.working, this.result);
  final String title;
  final String formula;
  final String working;
  final String result;
}

/// Everything a calculation produces.
class CalcResult {
  const CalcResult({
    required this.headline,
    this.metrics = const [],
    this.sections = const [],
    this.issues = const [],
    this.steps = const [],
  });

  final CalcHeadline headline;

  /// Up to three small figures under the headline.
  final List<ResultRow> metrics;
  final List<ResultSection> sections;
  final List<CalcIssue> issues;
  final List<CalcStep> steps;

  /// Saved with a project and shown in History ("2 × 630 kVA").
  String get summary => headline.value;

  CalcResult withIssues(List<CalcIssue> issues) =>
      CalcResult(headline: headline, metrics: metrics, sections: sections, issues: issues, steps: steps);
}

/// Formats a number for display: fixed [digits], or "-" when it isn't finite.
String fmt(num x, [int digits = 1]) => x.isFinite ? x.toStringAsFixed(digits) : '-';

/// The smallest entry of [list] that is ≥ [x] (a "next standard size"), or null if none is big enough.
T? nextUp<T extends num>(List<T> list, num x) {
  for (final v in list) {
    if (v >= x) return v;
  }
  return null;
}

/// Linear interpolation in a table of (x, y) pairs sorted by x; clamped at both ends.
double interp(List<List<double>> table, double x) {
  if (x <= table.first[0]) return table.first[1];
  for (var i = 1; i < table.length; i++) {
    if (x <= table[i][0]) {
      final a = table[i - 1], b = table[i];
      return a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]);
    }
  }
  return table.last[1];
}
