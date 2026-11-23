import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../domain/electrical_tables.dart';
import 'load_editor.dart';

/// Building load: each flat or shop in three stages, then the FDBs
/// (commercial), the MDB and a standby generator. One calculator for what the
/// web version split over four tabs.
final loadModule = CalcModule(
  id: 'load',
  title: 'Building load',
  shortTitle: 'Building\nload',
  subtitle: 'Flats / shops → FDB → MDB → generator',
  icon: Icons.apartment_outlined,
  color: AppColors.tileBlue,
  defaults: {
    'bt': 'res',
    'units': [newLoadUnit(1, residential: true)],
    'fdbs': const <Object>[],
    'mdbDiv': 1,
    'genBk': 100,
    'genFut': 10,
    'genPf': 0.85,
    'genNl': 'none',
    'genNlp': 0,
    'genMotor': 30,
    'genStart': 'sd',
    'genDip': 30,
    'genXd': 0.25,
    'genDer': 1,
    'genDuty': 'esp',
  },
  customEditorTitle: 'Units',
  customEditor: (context, inputs, patch) => LoadEditor(inputs: inputs, patch: patch),
  groups: const [
    FieldGroup('Main panel (MDB)', [
      NumberField('mdbDiv', 'MDB diversity factor', help: 'Max demand = sum ÷ diversity. Residential 1.5-2.5'),
    ]),
    FieldGroup('Standby generator', advanced: true, [
      NumberField('genBk', 'Backup share of demand', unit: '%'),
      NumberField('genFut', 'Future growth', unit: '%'),
      NumberField('genPf', 'Load power factor'),
      NumberField('genMotor', 'Largest motor', unit: 'kW', help: '0 = none'),
      ChoiceField('genStart', 'Motor starting', [
        CalcOption('dol', 'DOL'),
        CalcOption('sd', 'Star-delta'),
        CalcOption('soft', 'Soft starter'),
        CalcOption('vfd', 'VFD'),
      ]),
      NumberField('genDip', 'Allowed voltage dip', unit: '%'),
      NumberField('genXd', "Transient reactance Xd'"),
      NumberField('genDer', 'Site derating', help: '1 = none'),
      ChoiceField('genNl', 'Non-linear load', [
        CalcOption('none', 'None'),
        CalcOption('igbt', 'IGBT drives / 12-pulse UPS'),
        CalcOption('six', '6-pulse UPS / drives'),
      ]),
      NumberField('genNlp', 'Non-linear share', unit: '%'),
      ChoiceField('genDuty', 'Duty (ISO 8528-1)', [
        CalcOption('esp', 'ESP', detail: 'Emergency standby (hospitals, buildings)'),
        CalcOption('prp', 'PRP', detail: 'Prime power, variable load'),
        CalcOption('cop', 'COP', detail: 'Continuous, steady load'),
      ]),
    ]),
  ],
  compute: computeLoad,
  basis:
      'Stage 1 lighting and fans × demand factor; stage 2 13 A sockets at 1300 W × 30 % = 390 W each; stage 3 20 A '
      'sockets at 2 kW each plus other loads × demand factor. Above 7.5 kW a unit is 3-phase. Current = kW × 5.68 '
      '(1-phase, 230 V) or × 1.68 (3-phase, 415 V) × safety factor; next standard breaker; busbar area = rating ÷ 1.6. '
      'FDB and MDB: max demand = connected load ÷ diversity factor, current = kW × 1.68. Typical diversity: '
      'residential 1.5-2.5, commercial 1.4-2.0, office 1.3-1.8, industry 1.1-1.5. Generator per ISO 8528-1: the '
      'larger of the running-load size and the motor-starting size (Sgen = Xd\' × Sstart × (1 - dip) ÷ dip); ATS per '
      'IEC 60947-6-1. Check BNBC 2020 Part 8 and the utility before final design.',
);

/// A new unit with typical points, numbered [n] ("Flat 3" / "Shop 3").
Map<String, Object?> newLoadUnit(int n, {required bool residential, String fdb = ''}) => {
  'id': '${DateTime.now().microsecondsSinceEpoch}-$n',
  'name': '${residential ? 'Flat' : 'Shop'} $n',
  'fdb': fdb,
  'ph': 'auto',
  'lightW': 20,
  'lightQ': 10,
  'fanW': 75,
  'fanQ': 4,
  'ldf': 80,
  's13': 6,
  's20': 2,
  'custW': 0,
  'hdf': 70,
  'sf': 1.25,
};

/// One unit worked out.
class UnitLoad {
  const UnitLoad({
    required this.lighting,
    required this.sockets,
    required this.power,
    required this.phases,
    required this.autoPhases,
    required this.amps,
    required this.breaker,
  });

  /// Stage 1, 2 and 3 after their demand factors (W).
  final double lighting, sockets, power;
  final int phases, autoPhases;
  final double amps, breaker;

  double get watts => lighting + sockets + power;
  double get kw => watts / 1000;
}

UnitLoad unitLoad(Map<String, Object?> u) {
  final s1 = (u.n('lightW') * u.n('lightQ') + u.n('fanW') * u.n('fanQ')) * u.n('ldf') / 100;
  final s2 = u.n('s13') * 390;
  final s3 = (u.n('s20') * 2000 + u.n('custW')) * u.n('hdf') / 100;
  final kw = (s1 + s2 + s3) / 1000;
  final auto = kw > 7.5 ? 3 : 1;
  final ph = switch (u.s('ph')) {
    '1' => 1,
    '3' => 3,
    _ => auto,
  };
  final amps = kw * (ph == 1 ? 5.68 : 1.68) * u.n('sf', 1);
  return UnitLoad(
    lighting: s1,
    sockets: s2,
    power: s3,
    phases: ph,
    autoPhases: auto,
    amps: amps,
    breaker: ElecTables.nextBreaker(amps),
  );
}

/// A board (FDB or MDB) worked out.
class BoardLoad {
  const BoardLoad(this.connectedKw, this.diversity);
  final double connectedKw;
  final double diversity;

  double get demandKw => connectedKw / (diversity > 0 ? diversity : 1);
  double get amps => demandKw * 1.68;
  double get breaker => ElecTables.nextBreaker(amps);
}

const _genSizes = <double>[
  20, 30, 40, 50, 60, 80, 100, 125, 150, 200, 250, 300, 350, 400, 500, 625, 750, 800, 1000, 1250, 1500, 1600, //
  2000, 2500, 3000,
];

CalcResult computeLoad(CalcInputs x) {
  final commercial = x.s('bt') == 'com';
  final units = x.list('units');
  final fdbs = commercial ? x.list('fdbs') : const <Map<String, Object?>>[];
  final fdbIds = {for (final f in fdbs) f.s('id')};
  String boardOf(Map<String, Object?> u) => commercial && fdbIds.contains(u.s('fdb')) ? u.s('fdb') : '';

  final loads = [for (final u in units) unitLoad(u)];

  // FDBs, then the MDB: units fed directly plus each FDB's demand.
  final boards = <String, BoardLoad>{};
  for (final f in fdbs) {
    var kw = 0.0;
    for (var i = 0; i < units.length; i++) {
      if (boardOf(units[i]) == f.s('id')) kw += loads[i].kw;
    }
    boards[f.s('id')] = BoardLoad(kw, f.n('div', 1));
  }
  var mdbKw = 0.0;
  for (var i = 0; i < units.length; i++) {
    if (boardOf(units[i]).isEmpty) mdbKw += loads[i].kw;
  }
  for (final b in boards.values) {
    mdbKw += b.demandKw;
  }
  final mdb = BoardLoad(mdbKw, x.n('mdbDiv'));

  // Generator (ISO 8528): the larger of the running-load and the motor-starting requirement.
  final sq3 = math.sqrt(3);
  final backup = mdb.demandKw * x.n('genBk') / 100 * (1 + x.n('genFut') / 100);
  final running = backup / (x.n('genPf') > 0 ? x.n('genPf') : 0.85);
  final nlFactor = {'igbt': 1.15, 'six': 1.4}[x.s('genNl')] ?? 1.0;
  final effective = running * (1 + x.n('genNlp') / 100 * (nlFactor - 1));
  final loading = {'prp': 80.0, 'cop': 70.0}[x.s('genDuty')] ?? 85.0;
  final der = x.n('genDer') > 0 ? x.n('genDer') : 1;
  final byLoad = effective / (loading / 100) / der;
  final k = {'dol': 7.0, 'soft': 3.5, 'vfd': 1.5}[x.s('genStart')] ?? 2.3;
  final startKva = x.n('genMotor') > 0 ? x.n('genMotor') / (0.92 * 0.85) * k : 0.0;
  final dip = x.n('genDip') / 100;
  final byStart = startKva > 0 && dip > 0 ? x.n('genXd') * startKva * (1 - dip) / dip / der : 0.0;
  final needed = math.max(byLoad, byStart);
  final tooBig = needed > _genSizes.last;
  final gen = nextUp(_genSizes, needed) ?? _genSizes.last;
  final genAmps = gen * 1000 / (sq3 * 415);
  final genBreaker = nextUp(ElecTables.breakers, genAmps);

  String cables(double cb) {
    final c = ElecTables.cablesFor(cb);
    return '${c.cable} · PE ${c.earth}';
  }

  final issues = <CalcIssue>[
    if (units.isEmpty) const CalcIssue('No units yet.', 'Add the flats or shops of the building under Units.'),
    if (commercial && fdbs.isEmpty)
      const CalcIssue('Commercial building without an FDB.', 'Add a distribution board, or feed shops from the MDB.'),
    for (var i = 0; i < units.length; i++)
      if (loads[i].phases == 1 && loads[i].autoPhases == 3)
        CalcIssue(
          '${units[i].s('name')} is ${fmt(loads[i].kw, 1)} kW on one phase.',
          'Above 7.5 kW a unit should be 3-phase.',
        ),
    if (tooBig) const CalcIssue('The generator needed is above 3000 kVA.', 'Run several generators in parallel.'),
    if (x.n('genDip') > 35)
      const CalcIssue(
        'A voltage dip above 35 % may stop motors starting.',
        'Allow 30 % or less.',
        patch: {'genDip': 30},
        patchLabel: 'Use 30 %',
      ),
    if (x.n('genMotor') > 0 && x.s('genStart') == 'dol' && byStart > byLoad)
      const CalcIssue(
        'DOL starting is what makes the generator this big.',
        'Star-delta, a soft starter or a VFD gives a smaller generator.',
        patch: {'genStart': 'sd'},
        patchLabel: 'Use star-delta',
      ),
  ];

  return CalcResult(
    headline: CalcHeadline(
      'Main panel (MDB)',
      '${fmt(mdb.breaker, 0)} A ${ElecTables.breakerType(mdb.breaker)}',
      caption: 'Max demand ${fmt(mdb.demandKw, 2)} kW · ${fmt(mdb.amps, 1)} A',
    ),
    metrics: [
      ResultRow('Units', '${units.length}'),
      ResultRow('Connected', '${fmt(mdb.connectedKw, 1)} kW'),
      ResultRow('Generator', '${fmt(gen, 0)} kVA'),
    ],
    sections: [
      ResultSection('Units', [
        for (var i = 0; i < units.length; i++)
          ResultRow(
            units[i].s('name'),
            '${fmt(loads[i].kw, 2)} kW · ${loads[i].phases}-ph · ${fmt(loads[i].amps, 1)} A → '
                '${fmt(loads[i].breaker, 0)} A',
          ),
      ], note: 'Tap a unit above to see its three stages, cable and busbar.'),
      for (final f in fdbs)
        ResultSection('${f.s('name')} (FDB)', [
          ResultRow('Connected load', '${fmt(boards[f.s('id')]!.connectedKw, 2)} kW'),
          ResultRow('Diversity factor', num0(f.n('div', 1))),
          ResultRow(
            'Max demand / current',
            '${fmt(boards[f.s('id')]!.demandKw, 2)} kW · ${fmt(boards[f.s('id')]!.amps, 1)} A',
          ),
          ResultRow(
            'Breaker',
            '${fmt(boards[f.s('id')]!.breaker, 0)} A ${ElecTables.breakerType(boards[f.s('id')]!.breaker)}',
          ),
          ResultRow('Cable', cables(boards[f.s('id')]!.breaker)),
          ResultRow('Busbar', ElecTables.busbarText(boards[f.s('id')]!.breaker)),
        ]),
      ResultSection('Main panel (MDB)', [
        ResultRow('Sum of connected load', '${fmt(mdb.connectedKw, 2)} kW'),
        ResultRow('Diversity factor', num0(x.n('mdbDiv'))),
        ResultRow('Max demand', '${fmt(mdb.demandKw, 2)} kW'),
        ResultRow('MDB current (× 1.68)', '${fmt(mdb.amps, 1)} A'),
        ResultRow('Breaker', '${fmt(mdb.breaker, 0)} A ${ElecTables.breakerType(mdb.breaker)}'),
        ResultRow('Cable', cables(mdb.breaker)),
        ResultRow('Busbar', ElecTables.busbarText(mdb.breaker)),
      ]),
      ResultSection('Standby generator (ISO 8528)', [
        ResultRow('Backup load', '${fmt(backup, 0)} kW'),
        ResultRow('Running load', '${fmt(effective, 0)} kVA'),
        ResultRow('Size by running load (${fmt(loading, 0)} %)', '${fmt(byLoad, 0)} kVA'),
        ResultRow('Size by motor starting', '${fmt(byStart, 0)} kVA'),
        ResultRow('Suggested generator', '${fmt(gen, 0)} kVA / ${fmt(gen * 0.8, 0)} kW (pf 0.8)'),
        ResultRow('Rated current', '${fmt(genAmps, 0)} A'),
        ResultRow('Breaker / ATS', genBreaker == null ? 'Spec sheet' : '${fmt(genBreaker, 0)} A'),
        ResultRow('Fuel at 75 % load', '${fmt(0.75 * gen * 0.8 * 0.25, 0)} L/h'),
      ]),
    ],
    issues: issues,
    steps: [
      const CalcStep('13 A socket', 'W = 1300 W × 30 %', '1300 × 0.3', '390 W'),
      const CalcStep('Unit current', 'I = kW × 5.68 (1-ph) or × 1.68 (3-ph) × safety factor', 'per unit', 'see Units'),
      CalcStep(
        'MDB max demand',
        'MD = Σ connected ÷ diversity',
        '${fmt(mdb.connectedKw, 2)} ÷ ${num0(x.n('mdbDiv'))}',
        '${fmt(mdb.demandKw, 2)} kW',
      ),
      CalcStep('MDB current', 'I = MD × 1.68', '${fmt(mdb.demandKw, 2)} × 1.68', '${fmt(mdb.amps, 1)} A'),
      CalcStep(
        'Generator by load',
        'S = P ÷ pf ÷ loading ÷ derating',
        '${fmt(backup, 0)} ÷ ${x.n('genPf')} ÷ ${fmt(loading / 100, 2)} ÷ $der',
        '${fmt(byLoad, 0)} kVA',
      ),
      CalcStep(
        'Generator by motor start',
        "Sgen = Xd' × Sstart × (1 - dip) ÷ dip",
        '${x.n('genXd')} × ${fmt(startKva, 0)} × ${fmt(1 - dip, 2)} ÷ ${fmt(dip, 2)}',
        '${fmt(byStart, 0)} kVA',
      ),
    ],
  );
}
