import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../data/backup/backup_crypto.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/app_info_banner.dart';
import '../../../../shared/widgets/dialogs/app_bottom_sheet.dart';
import '../../../../shared/widgets/inputs/app_password_field.dart';

/// A new backup password, and the current one when changing it.
typedef NewBackupPassword = ({String? current, String password});

/// Asks for a new backup password (twice), and for the current one when [changing].
Future<NewBackupPassword?> showSetBackupPasswordSheet(BuildContext context, {required bool changing}) =>
    showAppBottomSheet<NewBackupPassword>(
      context,
      title: changing ? 'Change backup password' : 'Set a backup password',
      subtitle: changing ? null : 'You will need it to restore your backup on a new phone.',
      child: _SetPasswordForm(changing: changing),
    );

/// What the user answered when asked for the backup password.
typedef BackupPasswordAnswer = ({String? password, bool forgot});

/// Asks for the current backup password, e.g. before restoring or removing it. Null when closed; with
/// [offerForgot], a "Forgot password?" button answers `forgot: true`.
Future<BackupPasswordAnswer?> askBackupPassword(
  BuildContext context, {
  required String title,
  String? subtitle,
  String confirmLabel = 'Continue',
  bool offerForgot = false,
}) => showAppBottomSheet<BackupPasswordAnswer>(
  context,
  title: title,
  subtitle: subtitle,
  child: _AskPasswordForm(confirmLabel: confirmLabel, offerForgot: offerForgot),
);

class _SetPasswordForm extends StatefulWidget {
  const _SetPasswordForm({required this.changing});
  final bool changing;

  @override
  State<_SetPasswordForm> createState() => _SetPasswordFormState();
}

class _SetPasswordFormState extends State<_SetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop<NewBackupPassword>(context, (
      current: widget.changing ? _current.text : null,
      password: _password.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.changing) ...[
              AppPasswordField(
                controller: _current,
                label: 'Current password',
                autofocus: true,
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').isEmpty ? 'Enter your current password' : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppPasswordField(
              controller: _password,
              label: widget.changing ? 'New password' : 'Password',
              helper: 'At least ${BackupKeyFile.minPasswordLength} characters. A short sentence is easy to remember.',
              autofocus: !widget.changing,
              newPassword: true,
              textInputAction: TextInputAction.next,
              validator: (v) => (v ?? '').length < BackupKeyFile.minPasswordLength
                  ? 'Use at least ${BackupKeyFile.minPasswordLength} characters'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppPasswordField(
              controller: _repeat,
              label: 'Type it again',
              newPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              validator: (v) => v != _password.text ? "The passwords don't match" : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppInfoBanner(
              type: AppBannerType.warning,
              icon: Icons.key_rounded,
              message:
                  "Write it down somewhere safe. If you forget it, your backup can't be restored: "
                  'PowerHub never sees your password and cannot reset it.',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: widget.changing ? 'Change password' : 'Set password', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _AskPasswordForm extends StatefulWidget {
  const _AskPasswordForm({required this.confirmLabel, required this.offerForgot});
  final String confirmLabel;
  final bool offerForgot;

  @override
  State<_AskPasswordForm> createState() => _AskPasswordFormState();
}

class _AskPasswordFormState extends State<_AskPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop<BackupPasswordAnswer>(context, (password: _password.text, forgot: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPasswordField(
            controller: _password,
            label: 'Backup password',
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (v) => (v ?? '').isEmpty ? 'Enter your backup password' : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: widget.confirmLabel, onPressed: _submit),
          if (widget.offerForgot) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop<BackupPasswordAnswer>(context, (password: null, forgot: true)),
              child: const Text('Forgot password?'),
            ),
          ],
        ],
      ),
    );
  }
}
