import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/cards/summary_lines.dart';
import '../../../shared/widgets/dialogs/app_bottom_sheet.dart';
import '../../../shared/widgets/indicators/app_icon_badge.dart';
import '../../../shared/widgets/inputs/app_choice_chips.dart';
import '../../../shared/widgets/inputs/app_field_label.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/lists/app_list_card.dart';
import '../../../shared/widgets/lists/app_list_tile.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/navigation/app_segmented_tabs.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../domain/electrical_tables.dart';
import '../presentation/widgets/calc_field_inputs.dart';
import 'load_module.dart';

/// Building type, the distribution boards (commercial) and the list of units
/// for [loadModule]. A unit opens in a sheet with its own live result.
class LoadEditor extends StatelessWidget {
  const LoadEditor({super.key, required this.inputs, required this.patch});
  final CalcInputs inputs;
  final InputsPatcher patch;

  bool get _commercial => inputs.s('bt') == 'com';

  @override
  Widget build(BuildContext context) {
    final units = inputs.list('units');
    final fdbs = inputs.list('fdbs');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSegmentedTabs<String>(
          items: const [
            AppTabItem('res', 'Residential', icon: Icons.home_outlined),
            AppTabItem('com', 'Commercial', icon: Icons.storefront_outlined),
          ],
          value: _commercial ? 'com' : 'res',
          onChanged: (v) => _setType(v),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_commercial) ...[
          _BoardsCard(fdbs: fdbs, onEdit: (i) => _editBoard(context, i), onAdd: _addBoard),
          const SizedBox(height: AppSpacing.md),
        ],
        if (units.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.apartment_outlined,
              message: 'Add the flats or shops of the building.',
              actionLabel: 'Add unit',
              onAction: _addUnit,
            ),
          )
        else
          AppListCard(
            children: [
              for (var i = 0; i < units.length; i++)
                Builder(
                  builder: (context) {
                    final u = units[i];
                    final r = unitLoad(u);
                    final board = fdbs.where((f) => f.s('id') == u.s('fdb')).firstOrNull;
                    return AppListTile(
                      leading: AppIconBadge(
                        icon: _commercial ? Icons.storefront_outlined : Icons.home_outlined,
                        color: AppColors.tileBlue,
                      ),
                      title: u.s('name'),
                      subtitle:
                          '${fmt(r.kw, 2)} kW · ${r.phases}-ph · ${fmt(r.amps, 1)} A'
                          '${_commercial ? ' · ${board?.s('name') ?? 'MDB'}' : ''}',
                      trailing: Text(
                        '${fmt(r.breaker, 0)} A',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      trailingCaption: ElecTables.breakerType(r.breaker),
                      onTap: () => _editUnit(context, i),
                    );
                  },
                ),
            ],
          ),
        if (units.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Add unit',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.tonal,
              size: AppButtonSize.small,
              expanded: false,
              onPressed: _addUnit,
            ),
          ),
        ],
      ],
    );
  }

  List<Map<String, Object?>> get _units => [for (final u in inputs.list('units')) {...u}];
  List<Map<String, Object?>> get _boards => [for (final f in inputs.list('fdbs')) {...f}];

  void _setType(String type) {
    final change = <String, Object?>{'bt': type};
    if (type == 'com' && _boards.isEmpty) {
      final board = _newBoard(1);
      change['fdbs'] = [board];
      change['units'] = [for (final u in _units) {...u, 'fdb': u.s('fdb').isEmpty ? board['id'] : u['fdb']}];
    }
    patch(change);
  }

  void _addUnit() {
    final boards = _boards;
    patch({
      'units': [
        ..._units,
        newLoadUnit(
          _units.length + 1,
          residential: !_commercial,
          fdb: _commercial && boards.isNotEmpty ? boards.first.s('id') : '',
        ),
      ],
    });
  }

  Map<String, Object?> _newBoard(int n) => {'id': 'f${DateTime.now().microsecondsSinceEpoch}', 'name': 'FDB-$n', 'div': 1};

  void _addBoard() => patch({
    'fdbs': [..._boards, _newBoard(_boards.length + 1)],
  });

  Future<void> _editUnit(BuildContext context, int index) async {
    final result = await showAppBottomSheet<_UnitEdit>(
      context,
      title: 'Edit unit',
      child: _UnitSheet(unit: _units[index], boards: _commercial ? _boards : const []),
    );
    if (result == null) return;
    final units = _units;
    switch (result) {
      case _UnitSaved(:final unit):
        units[index] = unit;
      case _UnitDuplicated(:final unit):
        units[index] = unit;
        units.insert(index + 1, {
          ...unit,
          'id': '${DateTime.now().microsecondsSinceEpoch}',
          'name': '${unit.s('name')} (copy)',
        });
      case _UnitRemoved():
        units.removeAt(index);
    }
    patch({'units': units});
  }

  Future<void> _editBoard(BuildContext context, int index) async {
    final board = _boards[index];
    final name = TextEditingController(text: board.s('name'));
    var div = board.n('div', 1);
    final action = await showAppBottomSheet<String>(
      context,
      title: 'Distribution board',
      child: Builder(
        builder: (sheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(controller: name, label: 'Name', icon: Icons.dashboard_outlined),
            const SizedBox(height: AppSpacing.lg),
            CalcNumberInput(
              label: 'Diversity factor',
              value: div,
              help: 'Max demand = connected ÷ diversity. Commercial 1.4-2.0',
              onChanged: (v) => div = v,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'Save', onPressed: () => Navigator.pop(sheet, 'save')),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Remove board',
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.pop(sheet, 'remove'),
            ),
          ],
        ),
      ),
    );
    final boards = _boards;
    if (action == 'save') {
      boards[index] = {...board, 'name': name.text.trim().isEmpty ? board['name'] : name.text.trim(), 'div': div};
      patch({'fdbs': boards});
    } else if (action == 'remove') {
      boards.removeAt(index);
      // Its units are fed from the MDB from now on.
      patch({
        'fdbs': boards,
        'units': [for (final u in _units) u.s('fdb') == board.s('id') ? {...u, 'fdb': ''} : u],
      });
    }
    name.dispose();
  }
}

class _BoardsCard extends StatelessWidget {
  const _BoardsCard({required this.fdbs, required this.onEdit, required this.onAdd});
  final List<Map<String, Object?>> fdbs;
  final ValueChanged<int> onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppFieldLabel('Distribution boards (FDB)'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < fdbs.length; i++)
                ActionChip(
                  avatar: const Icon(Icons.dashboard_outlined, size: 18),
                  label: Text('${fdbs[i].s('name')} · ÷${num0(fdbs[i].n('div', 1))}'),
                  onPressed: () => onEdit(i),
                ),
              ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: const Text('Add FDB'), onPressed: onAdd),
            ],
          ),
        ],
      ),
    );
  }
}

sealed class _UnitEdit {}

class _UnitSaved extends _UnitEdit {
  _UnitSaved(this.unit);
  final Map<String, Object?> unit;
}

class _UnitDuplicated extends _UnitEdit {
  _UnitDuplicated(this.unit);
  final Map<String, Object?> unit;
}

class _UnitRemoved extends _UnitEdit {}

const _unitFields = [
  NumberField('lightQ', 'Light points', integer: true),
  NumberField('lightW', 'Watt / light', unit: 'W'),
  NumberField('fanQ', 'Fan points', integer: true),
  NumberField('fanW', 'Watt / fan', unit: 'W'),
  NumberField('ldf', 'Lighting demand', unit: '%'),
  NumberField('s13', '13 A sockets', integer: true, help: '390 W each'),
  NumberField('s20', '20 A sockets', integer: true, help: '2 kW each'),
  NumberField('custW', 'Other loads', unit: 'W', help: 'AC, geyser, pump…'),
  NumberField('hdf', 'Power demand', unit: '%'),
  NumberField('sf', 'Safety factor'),
];

/// One unit: its points, phase and FDB, with the result updating live.
class _UnitSheet extends StatefulWidget {
  const _UnitSheet({required this.unit, required this.boards});
  final Map<String, Object?> unit;
  final List<Map<String, Object?>> boards;

  @override
  State<_UnitSheet> createState() => _UnitSheetState();
}

class _UnitSheetState extends State<_UnitSheet> {
  late final Map<String, Object?> _u = {...widget.unit};
  late final _name = TextEditingController(text: widget.unit.s('name'));

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Map<String, Object?> get _result => {..._u, 'name': _name.text.trim().isEmpty ? widget.unit['name'] : _name.text.trim()};

  @override
  Widget build(BuildContext context) {
    final r = unitLoad(_u);
    final cables = ElecTables.cablesFor(r.breaker);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(controller: _name, label: 'Name', icon: Icons.label_outline_rounded),
        if (widget.boards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppChoiceChips<String>(
            label: 'Fed from',
            items: ['', for (final b in widget.boards) b.s('id')],
            value: widget.boards.any((b) => b.s('id') == _u.s('fdb')) ? _u.s('fdb') : '',
            itemLabel: (id) => id.isEmpty ? 'MDB (direct)' : widget.boards.firstWhere((b) => b.s('id') == id).s('name'),
            onChanged: (id) => setState(() => _u['fdb'] = id),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppChoiceChips<String>(
          label: 'Phase',
          items: const ['auto', '1', '3'],
          value: _u.s('ph', 'auto'),
          itemLabel: (p) => switch (p) {
            '1' => '1-phase 230 V',
            '3' => '3-phase 415 V',
            _ => 'Auto (${r.autoPhases}-phase)',
          },
          onChanged: (p) => setState(() => _u['ph'] = p),
        ),
        const SizedBox(height: AppSpacing.lg),
        CalcFieldsGrid(
          fields: _unitFields,
          inputs: CalcInputs(_u, const {}),
          onChanged: (k, v) => setState(() => _u[k] = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        SummaryLines(
          lines: [
            SummaryLine('Stage 1 lighting & fans', '${fmt(r.lighting, 0)} W'),
            SummaryLine('Stage 2 13 A sockets', '${fmt(r.sockets, 0)} W'),
            SummaryLine('Stage 3 power & other', '${fmt(r.power, 0)} W'),
            SummaryLine('Maximum demand', '${fmt(r.kw, 2)} kW', bold: true),
            SummaryLine('Current (${r.phases}-phase)', '${fmt(r.amps, 1)} A', bold: true),
            SummaryLine('Breaker', '${fmt(r.breaker, 0)} A ${ElecTables.breakerType(r.breaker)}'),
            SummaryLine('Cable / earth', '${cables.cable} / ${cables.earth}'),
            SummaryLine('Busbar', ElecTables.busbarText(r.breaker)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Save unit', onPressed: () => Navigator.pop(context, _UnitSaved(_result))),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Duplicate',
                icon: Icons.copy_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.pop(context, _UnitDuplicated(_result)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Remove',
                variant: AppButtonVariant.danger,
                onPressed: () => Navigator.pop(context, _UnitRemoved()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
