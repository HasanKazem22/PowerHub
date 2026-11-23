import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/dialogs/app_bottom_sheet.dart';
import '../../../../shared/widgets/lists/app_list_tile.dart';

/// The electrical engineer behind PowerHub's calculations (the original web calculator).
abstract final class Engineer {
  static const name = 'Abdullah-Al-Foysal';
  static const title = 'Electrical Engineer';
  static const photo = 'assets/images/Abdullah_Al_Foysal.jpeg';
  static const firm = 'Prodhan Design & Construction';
  static const firmMotto = 'Dream, Innovate, Economic & Safe';
  static const education = [
    'B.Sc. in Electrical & Electronic Engineering, Eastern University',
    'Diploma in Electrical Technology, Institute of Computer Science & Technology',
  ];
  static const services = [
    'Electrical design',
    'Load calculation & panel schedule',
    'Single line diagram',
    'Substation design',
    'ELV design',
    'Lighting & DIALux',
    'AutoCAD drawings',
    'As-built drawings',
  ];
  static const phones = ['+8801984701895', '+8809697129199'];
  static const email = 'engineer.mdfoysal@gmail.com';
  static const office = '94/3 Joshna Villa, Indira Road, Farmgate, Dhaka-1215';
}

/// Round photo of the engineer, framed to the face.
class EngineerPhoto extends StatelessWidget {
  const EngineerPhoto({super.key, required this.size, this.ring = false});
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final photo = ClipOval(
      child: Image.asset(
        Engineer.photo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.3),
        cacheWidth: (size * dpr).round(),
        semanticLabel: Engineer.name,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: AppColors.primarySoft,
          child: Icon(Icons.engineering_rounded, color: AppColors.primary, size: size * 0.5),
        ),
      ),
    );
    if (!ring) return photo;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold, AppColors.brand],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surface),
        child: photo,
      ),
    );
  }
}

/// Settings row: photo on the left, name and title on the right. Tap for the profile.
class EngineerTile extends StatelessWidget {
  const EngineerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: const EngineerPhoto(size: AppSpacing.listIcon),
      title: Engineer.name,
      subtitle: '${Engineer.title} · ${Engineer.firm}',
      subtitleMaxLines: 2,
      trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: () => showEngineerProfile(context),
    );
  }
}

Future<void> showEngineerProfile(BuildContext context) => showAppBottomSheet<void>(
  context,
  title: 'Engineer profile',
  subtitle: 'The calculations in PowerHub were prepared by',
  child: const _EngineerProfile(),
);

class _EngineerProfile extends StatelessWidget {
  const _EngineerProfile();

  Future<void> _open(BuildContext context, Uri uri, String copy) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final opened = await launchUrl(uri).catchError((_) => false);
    if (opened) return;
    // No phone or mail app (e.g. a tablet): copy it instead.
    await Clipboard.setData(ClipboardData(text: copy));
    messenger?.showSnackBar(SnackBar(content: Text('Copied $copy')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget heading(String label) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(label.toUpperCase(), style: text.labelSmall?.copyWith(color: muted, letterSpacing: 0.8)),
    );
    Widget line(IconData icon, String value, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.brand),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(value, style: text.bodyMedium)),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Center(child: EngineerPhoto(size: 112, ring: true)),
        const SizedBox(height: AppSpacing.md),
        Text(Engineer.name, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xxs),
        Text(Engineer.title, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: AppColors.brand)),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(
              Engineer.firm,
              style: text.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          Engineer.firmMotto,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: muted, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Call',
                icon: Icons.call_rounded,
                onPressed: () => _open(context, Uri(scheme: 'tel', path: Engineer.phones.first), Engineer.phones.first),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                variant: AppButtonVariant.tonal,
                onPressed: () => _open(context, Uri(scheme: 'mailto', path: Engineer.email), Engineer.email),
              ),
            ),
          ],
        ),
        heading('Education'),
        for (final e in Engineer.education) line(Icons.school_outlined, e),
        heading('Services'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in Engineer.services)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(s, style: text.labelMedium),
              ),
          ],
        ),
        heading('Contact'),
        for (final p in Engineer.phones)
          line(Icons.call_outlined, p, onTap: () => _open(context, Uri(scheme: 'tel', path: p), p)),
        line(
          Icons.mail_outline_rounded,
          Engineer.email,
          onTap: () => _open(context, Uri(scheme: 'mailto', path: Engineer.email), Engineer.email),
        ),
        line(Icons.location_on_outlined, Engineer.office),
      ],
    );
  }
}
