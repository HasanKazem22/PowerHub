import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/dialogs/app_choice_sheet.dart';
import '../../../../shared/widgets/inputs/app_choice_chips.dart';
import '../../../../shared/widgets/inputs/app_picker_field.dart';
import '../../domain/calc_inputs.dart';
import '../../domain/calc_module.dart';

/// A number input that calculates as you type. Keeps its own text while you
/// edit ("1." stays "1."), but follows [value] when it changes from outside
/// (a fix button, Reset, opening a project).
class CalcNumberInput extends StatefulWidget {
  const CalcNumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.unit,
    this.help,
    this.integer = false,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? unit;
  final String? help;
  final bool integer;

  @override
  State<CalcNumberInput> createState() => _CalcNumberInputState();
}

class _CalcNumberInputState extends State<CalcNumberInput> {
  late final _controller = TextEditingController(text: _format(widget.value));

  static String _format(double v) {
    if (!v.isFinite) return '';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    // Up to 6 decimals without trailing zeros (0.0125 stays 0.0125).
    return v.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '');
  }

  static double? _parse(String text) => double.tryParse(text.replaceAll(',', '').trim());

  @override
  void didUpdateWidget(CalcNumberInput old) {
    super.didUpdateWidget(old);
    if (_parse(_controller.text) != widget.value) _controller.text = _format(widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !widget.integer, signed: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(widget.integer ? r'[0-9-]' : r'[0-9.,-]'))],
      textInputAction: TextInputAction.next,
      onChanged: (text) => widget.onChanged(_parse(text) ?? 0),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.unit,
        helperText: widget.help,
        helperMaxLines: 2,
      ),
    );
  }
}

/// One of a few options: chips when they fit on a line or two, otherwise a
/// field that opens the choice sheet (the app's rule for choosing values).
class CalcChoiceInput extends StatelessWidget {
  const CalcChoiceInput({super.key, required this.field, required this.value, required this.onChanged});

  final ChoiceField field;
  final String value;
  final ValueChanged<String> onChanged;

  bool get _asChips =>
      field.options.length <= 3 && field.options.every((o) => o.label.length <= 14 && o.detail == null);

  @override
  Widget build(BuildContext context) {
    final current = field.options.where((o) => o.value == value).firstOrNull ?? field.options.first;
    if (_asChips) {
      return AppChoiceChips<CalcOption>(
        label: field.label,
        items: field.options,
        value: current,
        itemLabel: (o) => o.label,
        onChanged: (o) => onChanged(o.value),
        footer: field.help == null ? null : Text(field.help!, style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return AppPickerField(
      label: field.label,
      value: current.label,
      onTap: () async {
        final picked = await showAppChoiceSheet<String>(
          context,
          title: field.label,
          selected: current.value,
          options: [
            for (final o in field.options)
              AppChoice(
                value: o.value,
                label: o.label,
                subtitle: o.detail,
                icon: Icons.tune_rounded,
                color: AppColors.brand,
              ),
          ],
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// The visible fields of a group, laid out two numbers per row on a phone
/// (choices take the full width), so long forms stay short.
class CalcFieldsGrid extends StatelessWidget {
  const CalcFieldsGrid({super.key, required this.fields, required this.inputs, required this.onChanged});

  final List<CalcField> fields;
  final CalcInputs inputs;
  final void Function(String key, Object value) onChanged;

  @override
  Widget build(BuildContext context) {
    final visible = fields.where((f) => f.isVisible(inputs)).toList();
    return LayoutBuilder(
      builder: (context, box) {
        final half = (box.maxWidth - AppSpacing.md) / 2;
        // Wider screens fit three numbers per row.
        final numberWidth = box.maxWidth >= 600 ? (box.maxWidth - 2 * AppSpacing.md) / 3 : half;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.lg,
          children: [
            for (final f in visible)
              switch (f) {
                NumberField() => SizedBox(
                  width: numberWidth,
                  child: CalcNumberInput(
                    key: ValueKey(f.key),
                    label: f.label,
                    unit: f.unit,
                    help: f.help,
                    integer: f.integer,
                    value: inputs.n(f.key),
                    onChanged: (v) => onChanged(f.key, f.integer ? v.round() : v),
                  ),
                ),
                ChoiceField() => SizedBox(
                  width: box.maxWidth,
                  child: CalcChoiceInput(
                    key: ValueKey(f.key),
                    field: f,
                    value: inputs.s(f.key),
                    onChanged: (v) => onChanged(f.key, v),
                  ),
                ),
              },
          ],
        );
      },
    );
  }
}
