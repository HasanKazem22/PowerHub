import 'package:flutter/material.dart';

/// Standard text input (names, notes, email, phone). Filled, no resting
/// border, brand outline when focused (see the input theme in AppTheme).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.icon,
    this.required = false,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;

  /// Optional icon at the start of the field.
  final IconData? icon;

  /// Shows "Enter <label>" when left empty. Ignored when [validator] is set.
  final bool required;

  /// Custom check; returns the error to show, or null when the value is fine.
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool enabled;
  final int? maxLength;
  final int maxLines;

  /// With [maxLines] above 1: starts this tall and grows up to [maxLines] as the text gets longer.
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Lets the keyboard offer saved values (name, email, phone).
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      enabled: enabled,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
      ),
      validator:
          validator ??
          (required ? (v) => (v == null || v.trim().isEmpty) ? 'Enter ${label.toLowerCase()}' : null : null),
    );
  }
}
