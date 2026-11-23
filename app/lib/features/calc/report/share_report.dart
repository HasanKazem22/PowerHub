import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/dialogs/app_action_sheet.dart';
import '../domain/calc_module.dart';
import 'calc_report.dart';

/// Asks who the report is for, makes the PDF and opens the share sheet (WhatsApp, email, Drive, print…).
/// Used by the calculator screen and by History.
Future<void> shareCalcReport(
  BuildContext context,
  WidgetRef ref, {
  required CalcModule module,
  required Map<String, Object?> values,
  String? projectName,
}) async {
  final audience = await _pickAudience(context);
  if (audience == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final inputs = module.inputs(values);
    final bytes = await buildCalcReport(
      module: module,
      inputs: inputs,
      result: module.run(values),
      audience: audience,
      projectName: projectName,
      preparedBy: ref.read(userNameProvider).value ?? '',
      company: ref.read(companyProvider).value ?? '',
    );
    final title = projectName ?? module.title;
    final safe = title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim().replaceAll(RegExp(r'\s+'), '-');
    final file = '${safe.isEmpty ? 'PowerHub' : safe}-${audience == ReportAudience.designer ? 'design' : 'summary'}.pdf';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: file)],
        fileNameOverrides: [file],
        subject: '$title · PowerHub report',
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not make the report. ($e)')));
  }
}

Future<ReportAudience?> _pickAudience(BuildContext context) {
  final picked = Completer<ReportAudience?>();
  showAppActionSheet(
    context,
    title: 'Share report (PDF)',
    actions: [
      AppSheetAction(
        icon: Icons.engineering_outlined,
        label: 'For designer',
        subtitle: 'Inputs, results, warnings and step-by-step working',
        color: AppColors.tileBlue,
        onTap: () => picked.complete(ReportAudience.designer),
      ),
      AppSheetAction(
        icon: Icons.person_outline_rounded,
        label: 'For customer',
        subtitle: 'Inputs and results only',
        color: AppColors.tileGreen,
        onTap: () => picked.complete(ReportAudience.customer),
      ),
    ],
  ).then((_) {
    if (!picked.isCompleted) picked.complete(null);
  });
  return picked.future;
}
