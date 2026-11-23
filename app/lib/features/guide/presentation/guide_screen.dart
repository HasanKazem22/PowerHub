import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/layouts/app_page.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/cards/app_info_banner.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/section_header.dart';
import '../domain/fault_guide.dart';

/// Fault finding and safety for common industrial equipment (in Bangla):
/// the five safety rules first, then the faults by equipment, searchable.
class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _group;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(faultGuideProvider);
    return AppPage(
      title: 'Fault & safety guide',
      children: switch (guide) {
        AsyncData(:final value) => _content(context, value),
        AsyncError() => const [AppInfoBanner(type: AppBannerType.error, message: 'The guide could not be opened.')],
        _ => const [
          Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      },
    );
  }

  List<Widget> _content(BuildContext context, FaultGuide guide) {
    final text = Theme.of(context).textTheme;
    final q = _query.trim().toLowerCase();
    final groups = [
      for (final g in guide.groups)
        if (_group == null || g.id == _group) (g, [for (final f in g.faults) if (q.isEmpty || f.matches(q)) f]),
    ].where((e) => e.$2.isNotEmpty).toList();

    return [
      // Safety first, always on top.
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety_outlined, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'আগে নিরাপত্তা: ৫ নিয়ম',
                  style: text.titleSmall?.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final rule in guide.safety)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(rule, style: text.bodyMedium),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Expandable(
        icon: Icons.emergency_outlined,
        color: AppColors.warning,
        title: 'জরুরি কাজে ধাপে ধাপে',
        children: [
          for (final step in guide.emergency)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(step, style: text.bodyMedium),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text('দরকারি যন্ত্র', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xxs),
          Text(guide.tools, style: text.bodySmall),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'খুঁজুন (যেমন: গরম, ট্রিপ, মেগার)',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _search.clear();
                    _query = '';
                  }),
                ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(label: const Text('সব যন্ত্র'), selected: _group == null, onSelected: (_) => setState(() => _group = null)),
            for (final g in guide.groups) ...[
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: Text(g.name),
                selected: _group == g.id,
                onSelected: (_) => setState(() => _group = _group == g.id ? null : g.id),
              ),
            ],
          ],
        ),
      ),
      if (groups.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: AppCard(child: EmptyState(icon: Icons.search_off_rounded, message: 'কিছু পাওয়া যায়নি। অন্য শব্দ লিখুন।')),
        ),
      for (final (group, faults) in groups) ...[
        SectionHeader(group.name),
        for (final f in faults) ...[
          _FaultCard(fault: f),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
      const SizedBox(height: AppSpacing.md),
      Text(
        'এই তথ্য সাধারণ ইঞ্জিনিয়ারিং চর্চা অনুযায়ী। প্রস্তুতকারকের ম্যানুয়াল ও আপনার সাইটের নিরাপত্তা বিধি সবসময় আগে।',
        style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    ];
  }
}

/// One fault, folded to its title until tapped.
class _FaultCard extends StatelessWidget {
  const _FaultCard({required this.fault});
  final Fault fault;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget part(IconData icon, Color color, String label, String body) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xxs),
                Text(body, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
    return _Expandable(
      icon: Icons.build_circle_outlined,
      color: AppColors.tileRed,
      title: fault.title,
      children: [
        part(Icons.visibility_outlined, AppColors.tileBlue, 'লক্ষণ', fault.symptom),
        part(Icons.troubleshoot_rounded, AppColors.tilePurple, 'চিহ্নিতকরণ', fault.check),
        part(Icons.report_problem_outlined, AppColors.warning, 'সম্ভাব্য কারণ', fault.cause),
        part(Icons.check_circle_outline_rounded, AppColors.ok, 'সমাধান', fault.fix),
      ],
    );
  }
}

/// A card that opens to show [children].
class _Expandable extends StatefulWidget {
  const _Expandable({required this.icon, required this.color, required this.title, required this.children});
  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
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
                  Icon(widget.icon, color: widget.color),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widget.children),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
