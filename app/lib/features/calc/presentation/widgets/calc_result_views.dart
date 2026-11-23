import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../../domain/calc_inputs.dart';
import '../../domain/calc_module.dart';
import '../../domain/calc_result.dart';
import 'calc_field_inputs.dart';

/// A group of inputs in a card. An advanced group starts folded behind its
/// title, so the first screen stays short.
class CalcGroupCard extends StatefulWidget {
  const CalcGroupCard({super.key, required this.group, required this.inputs, required this.onChanged});
  final FieldGroup group;
  final CalcInputs inputs;
  final void Function(String key, Object value) onChanged;

  @override
  State<CalcGroupCard> createState() => _CalcGroupCardState();
}

class _CalcGroupCardState extends State<CalcGroupCard> {
  late bool _open = !widget.group.advanced;

  @override
  Widget build(BuildContext context) {
    final grid = CalcFieldsGrid(fields: widget.group.fields, inputs: widget.inputs, onChanged: widget.onChanged);
    if (!widget.group.advanced) return AppCard(child: grid);
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _open ? 'Typical values are filled in' : 'Typical values used · tap to change',
                      style: text.bodyMedium,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
                    child: grid,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// "Label ...... value" rows of one result section.
class CalcResultCard extends StatelessWidget {
  const CalcResultCard({super.key, required this.section});
  final ResultSection section;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < section.rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(section.rows[i].label, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 6,
                    child: Text(
                      section.rows[i].value,
                      textAlign: TextAlign.right,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: switch (section.rows[i].tone) {
                          Tone.ok => AppColors.ok,
                          Tone.bad => AppColors.error,
                          Tone.normal => scheme.onSurface,
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (section.note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(section.note!, style: text.bodySmall?.copyWith(color: scheme.outline)),
          ],
        ],
      ),
    );
  }
}

/// What to check, each with what to do and, where it can, a one-tap fix.
class CalcIssuesCard extends StatelessWidget {
  const CalcIssuesCard({super.key, required this.issues, required this.onApply});
  final List<CalcIssue> issues;
  final ValueChanged<Map<String, Object?>> onApply;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = context.isDark ? Color.lerp(AppColors.warningText, Colors.white, 0.55)! : AppColors.warningText;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.warningText.withValues(alpha: 0.18) : AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Text(
                issues.length == 1 ? '1 thing to check' : '${issues.length} things to check',
                style: text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          for (final issue in issues) ...[
            const SizedBox(height: AppSpacing.md),
            Text(issue.message, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xxs),
            Text(issue.fix, style: text.bodySmall),
            if (issue.suggestion != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Suggested: ${issue.suggestion}', style: text.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
            ],
            if (issue.patch != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: issue.patchLabel ?? 'Fix it',
                icon: Icons.auto_fix_high_rounded,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                expanded: false,
                onPressed: () => onApply(issue.patch!),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The working, folded until opened.
class CalcStepsCard extends StatefulWidget {
  const CalcStepsCard({super.key, required this.steps});
  final List<CalcStep> steps;

  @override
  State<CalcStepsCard> createState() => _CalcStepsCardState();
}

class _CalcStepsCardState extends State<CalcStepsCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.functions_rounded, color: scheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Step-by-step calculation',
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('${widget.steps.length} steps', style: text.bodySmall),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.steps.length; i++) ...[
                    if (i > 0) const Divider(height: AppSpacing.xl),
                    Text('${i + 1}. ${widget.steps[i].title}', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(widget.steps[i].formula, style: text.bodySmall?.copyWith(color: scheme.primary)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(widget.steps[i].working, style: text.bodySmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('= ${widget.steps[i].result}', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The codes and formulas the calculation follows.
class CalcBasisCard extends StatelessWidget {
  const CalcBasisCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basis', style: style?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xxs),
          Text(text, style: style),
        ],
      ),
    );
  }
}
