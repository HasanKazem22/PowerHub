import 'package:flutter/material.dart';

import 'calc_inputs.dart';
import 'calc_result.dart';

/// One option of a [ChoiceField]. [value] is what is stored in the inputs.
class CalcOption {
  const CalcOption(this.value, this.label, {this.detail});
  final String value;
  final String label;

  /// One line under the label in the choice sheet.
  final String? detail;
}

/// One input of a calculator. Shown only while [visibleIf] (if given) is true.
sealed class CalcField {
  const CalcField(this.key, this.label, {this.help, this.visibleIf});
  final String key;
  final String label;

  /// Helper line under the field.
  final String? help;
  final bool Function(CalcInputs inputs)? visibleIf;

  bool isVisible(CalcInputs inputs) => visibleIf?.call(inputs) ?? true;
}

/// A number, typed. [unit] is shown at the end of the field ("kW", "%").
class NumberField extends CalcField {
  const NumberField(
    super.key,
    super.label, {
    this.unit,
    this.integer = false,
    this.positive = false,
    super.help,
    super.visibleIf,
  });
  final String? unit;

  /// Whole numbers only (counts: transformers, poles, slots).
  final bool integer;

  /// Must be above zero (a voltage, a module's Voc): zero or less is replaced by the typical value, with an
  /// issue saying so, before the calculation runs. See [CalcModule.run].
  final bool positive;
}

/// One of a few fixed options: chips when short, a picker sheet when long.
class ChoiceField extends CalcField {
  const ChoiceField(super.key, super.label, this.options, {super.help, super.visibleIf});
  final List<CalcOption> options;
}

/// A titled block of inputs. [advanced] blocks start folded, so the first
/// screen shows only what most people need to change.
class FieldGroup {
  const FieldGroup(this.title, this.fields, {this.advanced = false, this.visibleIf});
  final String title;
  final List<CalcField> fields;
  final bool advanced;
  final bool Function(CalcInputs inputs)? visibleIf;

  bool isVisible(CalcInputs inputs) => visibleIf?.call(inputs) ?? true;
}

/// Changes inputs: the patch is merged into the current values.
typedef InputsPatcher = void Function(Map<String, Object?> patch);

/// Builds a custom input section for inputs a plain field can't hold (lists of units, boards).
typedef CustomEditorBuilder = Widget Function(BuildContext context, CalcInputs inputs, InputsPatcher patch);

/// A calculator: what it asks for and how it works out the answer.
///
/// Everything is data plus one pure function ([compute]), so the screen, the
/// save flow (History) and the PDF report are shared by every calculator, and
/// [compute] can be unit-tested without Flutter.
class CalcModule {
  const CalcModule({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.defaults,
    required this.groups,
    required this.compute,
    this.basis,
    this.customEditor,
    this.customEditorTitle,
  });

  /// Stored with saved projects: never change an existing id.
  final String id;
  final String title;

  /// Tile label on Home (two short lines at most).
  final String shortTitle;

  /// One line: what it sizes.
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Every input with its starting value. Inputs missing from a saved project fall back to these.
  final Map<String, Object?> defaults;
  final List<FieldGroup> groups;
  final CalcResult Function(CalcInputs inputs) compute;

  /// Codes and formulas the calculation follows (shown at the end and in reports).
  final String? basis;

  /// Shown above the field groups, under [customEditorTitle].
  final CustomEditorBuilder? customEditor;
  final String? customEditorTitle;

  CalcInputs inputs(Map<String, Object?> values) => CalcInputs(values, defaults);

  /// Works out [values]: what the screen, History and reports use.
  ///
  /// A [NumberField.positive] input that is zero or less (a half-typed value, a damaged project) is replaced by its
  /// typical value first, with an issue saying so, so [compute] never divides by zero.
  CalcResult run(Map<String, Object?> values) {
    final given = inputs(values);
    final fixed = <String, Object?>{};
    final issues = <CalcIssue>[];
    for (final g in groups) {
      // Hidden fields too: the calculation may still use them.
      for (final f in g.fields) {
        if (f is! NumberField || !f.positive || given.n(f.key) > 0) continue;
        if (fixed.containsKey(f.key)) continue;
        fixed[f.key] = defaults[f.key];
        final typical = '${defaults[f.key]}${f.unit == null ? '' : ' ${f.unit}'}';
        issues.add(CalcIssue('${f.label} must be above zero.', 'The typical value $typical is used until you enter one.'));
      }
    }
    final result = compute(fixed.isEmpty ? given : inputs({...values, ...fixed}));
    return issues.isEmpty ? result : result.withIssues([...issues, ...result.issues]);
  }
}
