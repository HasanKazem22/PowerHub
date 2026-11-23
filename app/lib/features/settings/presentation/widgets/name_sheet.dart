import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../data/database.dart';
import '../../../../data/providers.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/dialogs/app_bottom_sheet.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

/// Edit the name Home greets the user with and the company printed on reports. Both optional.
Future<void> showNameSheet(BuildContext context) => showAppBottomSheet<void>(
  context,
  title: 'Your profile',
  subtitle: 'Shown on Home and printed on reports. It stays on your phone (and in your backup).',
  child: const _NameForm(),
);

class _NameForm extends ConsumerStatefulWidget {
  const _NameForm();

  @override
  ConsumerState<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends ConsumerState<_NameForm> {
  late final _name = TextEditingController(text: ref.read(userNameProvider).value ?? '');
  late final _company = TextEditingController(text: ref.read(companyProvider).value ?? '');

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(databaseProvider).setSettings({
      SettingKeys.userName: _name.text.trim(),
      SettingKeys.company: _company.text.trim(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _name,
          label: 'Name',
          icon: Icons.person_outline_rounded,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _company,
          label: 'Company or firm',
          hint: 'Optional, printed on reports',
          icon: Icons.business_outlined,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.organizationName],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}
