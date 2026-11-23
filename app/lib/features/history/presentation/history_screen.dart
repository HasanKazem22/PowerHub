import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/app_actions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../shared/layouts/app_page.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/lists/app_list_card.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/section_header.dart';
import '../../calc/modules/modules.dart';
import 'widgets/project_tile.dart';

/// Every saved project, newest first, grouped by month, with a search box and
/// a filter per calculator.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// A calculator id, or null for all.
  String? _module;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Project> _filter(List<Project> all) {
    final q = _query.trim().toLowerCase();
    return [
      for (final p in all)
        if ((_module == null || p.module == _module) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.summary.toLowerCase().contains(q) ||
                (calcModuleById(p.module)?.title.toLowerCase().contains(q) ?? false)))
          p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(projectsProvider);
    final all = async.value ?? const <Project>[];
    final shown = _filter(all);
    final used = {for (final p in all) p.module};

    return AppPage(
      title: 'History',
      children: [
        if (all.isNotEmpty) ...[
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search projects',
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
                ChoiceChip(
                  label: Text('All (${all.length})'),
                  selected: _module == null,
                  onSelected: (_) => setState(() => _module = null),
                ),
                for (final m in calcModules)
                  if (used.contains(m.id)) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      avatar: Icon(m.icon, size: 18, color: m.color),
                      label: Text(m.title),
                      selected: _module == m.id,
                      onSelected: (_) => setState(() => _module = _module == m.id ? null : m.id),
                    ),
                  ],
              ],
            ),
          ),
        ],
        if (async.isLoading && all.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (all.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No saved projects yet',
              message: 'Work out a design, then tap Save and give it a project name. It shows up here.',
              actionLabel: 'New calculation',
              actionIcon: Icons.add_rounded,
              onAction: () => AppActions.showNewMenu(context),
            ),
          )
        else if (shown.isEmpty)
          const AppCard(
            child: EmptyState(icon: Icons.search_off_rounded, message: 'No project matches. Try another word.'),
          )
        else
          for (final group in _byMonth(shown)) ...[
            SectionHeader(group.$1),
            AppListCard(children: [for (final p in group.$2) ProjectTile(project: p)]),
          ],
      ],
    );
  }

  /// "November 2026" → its projects, in the list's order.
  static List<(String, List<Project>)> _byMonth(List<Project> projects) {
    final groups = <String, List<Project>>{};
    for (final p in projects) {
      final key = DateFormat('MMMM yyyy').format(p.updatedAt);
      (groups[key] ??= []).add(p);
    }
    return [for (final e in groups.entries) (e.key, e.value)];
  }
}
