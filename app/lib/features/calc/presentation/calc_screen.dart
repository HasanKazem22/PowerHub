import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../shared/layouts/app_page.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_info_banner.dart';
import '../../../shared/widgets/cards/app_summary_card.dart';
import '../../../shared/widgets/dialogs/app_action_sheet.dart';
import '../../../shared/widgets/dialogs/app_bottom_sheet.dart';
import '../../../shared/widgets/dialogs/app_confirm_dialog.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/misc/section_header.dart';
import '../../../shared/widgets/navigation/app_header_action.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../modules/modules.dart';
import '../report/share_report.dart';
import 'widgets/calc_result_views.dart';

/// Any calculator: the live result on top, then the inputs, the results and
/// the working. What is typed is kept as a draft on the phone; Save puts it in
/// History under a project name.
class CalcScreen extends ConsumerStatefulWidget {
  const CalcScreen({super.key, required this.moduleId, this.projectId});
  final String moduleId;

  /// Open this saved project instead of the calculator's draft.
  final String? projectId;

  @override
  ConsumerState<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends ConsumerState<CalcScreen> {
  late final CalcModule? _module = calcModuleById(widget.moduleId);
  late final AppDatabase _db = ref.read(databaseProvider);

  Map<String, Object?> _values = {};
  String? _projectId;
  String? _projectName;
  bool _loading = true;

  /// Changed since the last save (or since it was opened).
  bool _dirty = false;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final module = _module;
    if (module == null) return;
    Map<String, Object?> values = {};
    String? projectId;
    String? name;
    if (widget.projectId != null) {
      final p = await _db.getProject(widget.projectId!);
      if (p != null) {
        values = AppDatabase.decodeInputs(p.inputs);
        projectId = p.id;
        name = p.name;
        await _db.saveDraft(module.id, values, projectId: p.id);
      }
    } else {
      final draft = await _db.getDraft(module.id);
      if (draft != null) {
        values = AppDatabase.decodeInputs(draft.inputs);
        if (draft.projectId != null) {
          final p = await _db.getProject(draft.projectId!);
          projectId = p?.id;
          name = p?.name;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _values = values;
      _projectId = projectId;
      _projectName = name;
      _loading = false;
    });
  }

  @override
  void dispose() {
    if (_draftTimer?.isActive ?? false) {
      _draftTimer!.cancel();
      _writeDraft();
    }
    super.dispose();
  }

  void _patch(Map<String, Object?> patch) {
    setState(() {
      _values = {..._values, ...patch};
      _dirty = true;
    });
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 600), _writeDraft);
  }

  Future<void> _writeDraft() async {
    final module = _module;
    if (module == null) return;
    await _db.saveDraft(module.id, module.inputs(_values).merged, projectId: _projectId);
  }

  CalcResult _compute(CalcModule module) {
    try {
      return module.run(_values);
    } catch (e, st) {
      // A calculation must never take the screen down: show the problem instead.
      debugPrint('PowerHub: ${module.id} failed: $e\n$st');
      return const CalcResult(
        headline: CalcHeadline('Check the inputs', '-'),
        issues: [CalcIssue('These inputs can\'t be calculated.', 'Check for zero or empty values, or start again.')],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = _module;
    if (module == null) {
      return const AppPage(
        title: 'Calculator',
        children: [AppInfoBanner(message: 'This calculator is not in this version of PowerHub. Update the app.')],
      );
    }
    if (_loading) {
      return AppPage(title: module.title, body: const Center(child: CircularProgressIndicator()));
    }
    final inputs = module.inputs(_values);
    final result = _compute(module);

    return AppPage(
      title: _projectName ?? module.title,
      actions: [
        AppHeaderAction(icon: Icons.ios_share_rounded, tooltip: 'Share report', onPressed: _share),
        AppHeaderAction(icon: Icons.more_horiz_rounded, tooltip: 'More', onPressed: () => _more(result)),
      ],
      children: [
        if (_projectName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '${module.title}${_dirty ? ' · unsaved changes' : ' · saved'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _dirty ? AppColors.warning : null),
            ),
          ),
        AppSummaryCard(
          label: result.headline.label,
          value: result.headline.value,
          caption: result.headline.caption,
          actionLabel: _projectId == null ? 'Save' : (_dirty ? 'Save' : 'Saved'),
          actionIcon: _projectId != null && !_dirty ? Icons.check_rounded : Icons.bookmark_add_outlined,
          onAction: () => _save(result),
          metrics: [for (final m in result.metrics.take(3)) AppSummaryMetric(m.label, m.value)],
        ),
        if (result.issues.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          CalcIssuesCard(issues: result.issues, onApply: _patch),
        ],
        if (module.customEditor != null) ...[
          SectionHeader(module.customEditorTitle ?? 'Inputs'),
          module.customEditor!(context, inputs, _patch),
        ],
        for (final group in module.groups)
          if (group.isVisible(inputs)) ...[
            SectionHeader(group.title),
            CalcGroupCard(
              group: group,
              inputs: inputs,
              onChanged: (key, value) => _patch({key: value}),
            ),
          ],
        for (final section in result.sections) ...[
          SectionHeader(section.title),
          CalcResultCard(section: section),
        ],
        if (result.steps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          CalcStepsCard(steps: result.steps),
        ],
        if (module.basis != null) ...[
          const SizedBox(height: AppSpacing.md),
          CalcBasisCard(text: module.basis!),
        ],
      ],
    );
  }

  // ── Save ─────────────────────────────────────────────────

  Future<void> _save(CalcResult result, {bool asNew = false}) async {
    final module = _module!;
    final editing = _projectId != null && !asNew;
    final name = TextEditingController(
      text: editing
          ? _projectName
          : asNew && _projectName != null
          ? '$_projectName (copy)'
          : '${module.title} · ${DateFormat('d MMM yyyy').format(DateTime.now())}',
    );
    final picked = await showAppBottomSheet<String>(
      context,
      title: editing ? 'Save changes' : 'Save to History',
      subtitle: 'Saved on this phone, and in Google Drive when backup is on.',
      child: Builder(
        builder: (sheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: name,
              label: 'Project name',
              hint: 'e.g. Rahman Tower, Mirpur',
              icon: Icons.folder_outlined,
              maxLength: 80,
              autofocus: !editing,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: editing ? 'Save changes' : 'Save',
              icon: Icons.bookmark_added_outlined,
              onPressed: () => Navigator.pop(sheet, name.text.trim()),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    if (picked == null || picked.isEmpty || !mounted) return;

    final id = await _db.saveProject(
      id: editing ? _projectId : null,
      name: picked,
      module: module.id,
      inputs: module.inputs(_values).merged,
      summary: result.summary,
    );
    await _db.saveDraft(module.id, module.inputs(_values).merged, projectId: id);
    if (!mounted) return;
    setState(() {
      _projectId = id;
      _projectName = picked;
      _dirty = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Saved "$picked" to History.')));
  }

  // ── Report ───────────────────────────────────────────────

  Future<void> _share() =>
      shareCalcReport(context, ref, module: _module!, values: _values, projectName: _projectName);

  // ── More ─────────────────────────────────────────────────

  Future<void> _more(CalcResult result) {
    return showAppActionSheet(
      context,
      actions: [
        if (_projectId != null)
          AppSheetAction(
            icon: Icons.library_add_outlined,
            label: 'Save as a new project',
            subtitle: 'Keep "$_projectName" as it is',
            color: AppColors.tileBlue,
            onTap: () => _save(result, asNew: true),
          ),
        AppSheetAction(
          icon: Icons.restart_alt_rounded,
          label: 'New calculation',
          subtitle: 'Start again from the typical values',
          color: AppColors.tileOrange,
          onTap: _reset,
        ),
      ],
    );
  }

  Future<void> _reset() async {
    if (_dirty) {
      final ok = await showAppConfirmDialog(
        context,
        title: 'Start a new calculation?',
        message: 'Changes not saved to History are lost.',
        confirmLabel: 'Start new',
      );
      if (!ok) return;
    }
    await _db.clearDraft(_module!.id);
    if (!mounted) return;
    setState(() {
      _values = {};
      _projectId = null;
      _projectName = null;
      _dirty = false;
    });
  }
}
