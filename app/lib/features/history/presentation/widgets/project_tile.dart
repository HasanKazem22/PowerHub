import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/database.dart';
import '../../../../data/providers.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/dialogs/app_action_sheet.dart';
import '../../../../shared/widgets/dialogs/app_bottom_sheet.dart';
import '../../../../shared/widgets/dialogs/app_confirm_dialog.dart';
import '../../../../shared/widgets/indicators/app_icon_badge.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/lists/app_list_tile.dart';
import '../../../calc/modules/modules.dart';
import '../../../calc/report/share_report.dart';

/// "Today 14:05", "Yesterday", "12 Nov", "3 Mar 2025".
String projectDate(DateTime d, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(d);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today ${DateFormat('HH:mm').format(d)}';
  if (diff == 1) return 'Yesterday';
  return DateFormat(day.year == today.year ? 'd MMM' : 'd MMM yyyy').format(d);
}

/// One saved project: its calculator's icon, name, calculator and date, and
/// its headline result. Tap opens it; long-press (or ⋯) shows what else can be done.
class ProjectTile extends ConsumerWidget {
  const ProjectTile({super.key, required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = calcModuleById(project.module);
    return GestureDetector(
      onLongPress: () => showProjectActions(context, ref, project),
      child: AppListTile(
        leading: AppIconBadge(
          icon: module?.icon ?? Icons.help_outline_rounded,
          color: module?.color ?? AppColors.neutral,
        ),
        title: project.name,
        subtitle: '${module?.title ?? 'Unknown calculator'} · ${projectDate(project.updatedAt)}',
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Text(
            project.summary,
            maxLines: 2,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        onTap: module == null ? null : () => AppActions.openProject(context, project),
      ),
    );
  }
}

/// Open, rename, duplicate, share or delete a saved project.
Future<void> showProjectActions(BuildContext context, WidgetRef ref, Project project) {
  final module = calcModuleById(project.module);
  final db = ref.read(databaseProvider);
  return showAppActionSheet(
    context,
    title: project.name,
    actions: [
      if (module != null) ...[
        AppSheetAction(
          icon: Icons.open_in_new_rounded,
          label: 'Open',
          subtitle: module.title,
          color: module.color,
          onTap: () => AppActions.openProject(context, project),
        ),
        AppSheetAction(
          icon: Icons.ios_share_rounded,
          label: 'Share report (PDF)',
          subtitle: 'For the designer or the customer',
          color: AppColors.tileBlue,
          onTap: () => shareCalcReport(
            context,
            ref,
            module: module,
            values: AppDatabase.decodeInputs(project.inputs),
            projectName: project.name,
          ),
        ),
      ],
      AppSheetAction(
        icon: Icons.drive_file_rename_outline_rounded,
        label: 'Rename',
        color: AppColors.tileSlate,
        onTap: () => _rename(context, db, project),
      ),
      AppSheetAction(
        icon: Icons.copy_rounded,
        label: 'Duplicate',
        subtitle: 'Start a variant from this one',
        color: AppColors.tileTeal,
        onTap: () async {
          await db.duplicateProject(project);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied "${project.name}".')));
          }
        },
      ),
      AppSheetAction(
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        color: AppColors.error,
        onTap: () async {
          final ok = await showAppConfirmDialog(
            context,
            title: 'Delete "${project.name}"?',
            message: 'It is removed from History on this phone, and from Google Drive at the next backup.',
          );
          if (ok) await db.deleteProject(project.id);
        },
      ),
    ],
  );
}

Future<void> _rename(BuildContext context, AppDatabase db, Project project) async {
  final name = TextEditingController(text: project.name);
  final picked = await showAppBottomSheet<String>(
    context,
    title: 'Rename project',
    child: Builder(
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: name,
            label: 'Project name',
            icon: Icons.folder_outlined,
            maxLength: 80,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Save', onPressed: () => Navigator.pop(sheet, name.text.trim())),
        ],
      ),
    ),
  );
  name.dispose();
  if (picked != null && picked.isNotEmpty) await db.renameProject(project.id, picked);
}
