import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../domain/electrical_tables.dart';

/// Motor starter and feeder: breaker, contactor, overload relay and cable from
/// the motor's data (IEC 60947-4-1, IEC 60364-5-52).
final motorModule = CalcModule(
  id: 'motor',
  title: 'Motor starter & feeder',
  shortTitle: 'Motor\nstarter',
  subtitle: 'Breaker, contactor, overload relay, cable',
  icon: Icons.settings_suggest_outlined,
  color: AppColors.tileOrange,
  defaults: const {
    'unit': 'kW',
    'p': 15,
    'v': 415,
    'ph': '3',
    'eff': 0.92,
    'pf': 0.86,
    'flc': 0,
    'start': 'dol',
    'cls': '10',
    'len': 50,
    'ins': 'pvc',
    'amb': 35,
    'grp': 1,
    'mar': 1.25,
    'vdr': 5,
    'vds': 15,
    'minc': 2.5,
    'fault': 25,
  },
  groups: const [
    FieldGroup('Motor', [
      ChoiceField('unit', 'Power unit', [CalcOption('kW', 'kW'), CalcOption('hp', 'HP')]),
      NumberField('p', 'Motor power'),
      NumberField('v', 'Voltage', positive: true, unit: 'V'),
      ChoiceField('ph', 'Phase', [CalcOption('3', '3-phase'), CalcOption('1', '1-phase')]),
      NumberField('eff', 'Efficiency', help: '0 to 1'),
      NumberField('pf', 'Power factor'),
      NumberField('flc', 'Nameplate FLC', unit: 'A', help: '0 = calculate from power'),
    ]),
    FieldGroup('Starting', [
      ChoiceField('start', 'Starting method', [
        CalcOption('dol', 'DOL', detail: 'Direct on line, about 7 × FLC'),
        CalcOption('sd', 'Star-delta', detail: 'About 2.3 × FLC'),
        CalcOption('soft', 'Soft starter', detail: 'With bypass, about 3.5 × FLC'),
      ]),
      ChoiceField('cls', 'Overload trip class', [
        CalcOption('10', 'Class 10', detail: 'Normal start'),
        CalcOption('20', 'Class 20', detail: 'Heavy start: fan, crusher'),
      ]),
    ]),
    FieldGroup('Cable', [
      NumberField('len', 'Cable length', unit: 'm'),
      ChoiceField('ins', 'Insulation', [CalcOption('pvc', 'PVC 70 °C'), CalcOption('xlpe', 'XLPE 90 °C')]),
      NumberField('amb', 'Ambient', unit: '°C'),
      NumberField('grp', 'Circuits grouped', integer: true),
    ]),
    FieldGroup('Limits', advanced: true, [
      NumberField('mar', 'Cable margin factor'),
      NumberField('vdr', 'Max drop, running', unit: '%'),
      NumberField('vds', 'Max drop, starting', unit: '%'),
      NumberField('minc', 'Minimum cable', unit: 'mm²'),
      NumberField('fault', 'Fault level', unit: 'kA'),
    ]),
  ],
  compute: computeMotor,
  basis:
      'FLC = P ÷ (√3 × V × η × PF). Overload relay set to FLC (0.58 × FLC for star-delta, relay in the delta loop). '
      'Contactors by AC-3 rating ≥ current: star-delta main and delta 0.58 × FLC, star 0.33 × FLC. '
      'Breaker In ≥ 1.25 × FLC and magnetic trip ≥ 14 × FLC (10 × for a soft starter) so starting does not trip it; '
      'limit 250 % of FLC (NEC 430.52). Cable: tabulated rating × temperature and grouping factors ≥ FLC × margin, '
      'plus voltage drop at running and starting current (IEC 60364-5-52). PE per IEC 60364-5-54. '
      'Confirm with the nameplate, the maker\'s Type-2 coordination tables and the cable datasheet.',
);

const _relayRanges = <List<double>>[
  [0.1, 0.16], [0.16, 0.25], [0.25, 0.4], [0.4, 0.63], [0.63, 1], [1, 1.6], [1.6, 2.5], [2.5, 4], [4, 6], //
  [5.5, 8], [7, 10], [9, 13], [12, 18], [17, 25], [23, 32], [30, 40], [37, 50], [48, 65], [55, 70], [63, 80],
  [80, 104], [95, 120], [110, 140],
];
const _ac3 = <double>[9, 12, 18, 25, 32, 40, 50, 65, 80, 95, 115, 150, 185, 225, 265, 330, 400, 500, 630, 800];
const _icu = <double>[6, 10, 16, 25, 36, 50, 70, 100];
const _startFactor = {'dol': 7.0, 'sd': 2.3, 'soft': 3.5};
const _startName = {'dol': 'DOL', 'sd': 'Star-delta', 'soft': 'Soft starter'};

CalcResult computeMotor(CalcInputs x) {
  final sq3 = math.sqrt(3);
  final p = x.s('unit') == 'hp' ? x.n('p') * 0.746 : x.n('p');
  final three = x.s('ph') == '3';
  final v = x.n('v');
  final eff = x.n('eff'), pf = x.n('pf');
  final calc = three ? p * 1000 / (sq3 * v * eff * pf) : p * 1000 / (v * eff * pf);
  final nameplate = x.n('flc') > 0;
  final flc = nameplate ? x.n('flc') : calc;
  final start = _startFactor.containsKey(x.s('start')) ? x.s('start') : 'dol';
  final sd = start == 'sd';
  final k = _startFactor[start]!;
  final ist = k * flc;

  // Overload relay and contactors.
  final iset = sd ? 0.58 * flc : flc;
  final relay = _relayRanges.where((r) => iset >= r[0] && iset <= r[1]).firstOrNull;
  final contactors = sd
      ? [
          ('Main (KM1)', nextUp(_ac3, 0.58 * flc)),
          ('Delta (KM3)', nextUp(_ac3, 0.58 * flc)),
          ('Star (KM2)', nextUp(_ac3, 0.33 * flc)),
        ]
      : [('Line contactor', nextUp(_ac3, flc))];

  // Breaker.
  final inst = (start == 'soft' ? 10 : 14) * flc;
  final breaker = ElecTables.nextBreaker(math.max(1.25 * flc, inst / 10));
  final icu = nextUp(_icu, x.n('fault'));
  final withinNec = breaker <= 2.5 * flc;

  // Cable: smallest size whose derated rating carries FLC × margin and whose drops are within limits.
  final xlpe = x.s('ins') == 'xlpe';
  final ca = interp(xlpe ? ElecTables.ambientXlpe : ElecTables.ambientPvc, x.n('amb'));
  final cg = interp(ElecTables.grouping, x.n('grp'));
  final table = xlpe
      ? (three ? ElecTables.ratingXlpe3 : ElecTables.ratingXlpe1)
      : (three ? ElecTables.ratingPvc3 : ElecTables.ratingPvc1);
  final need = flc * x.n('mar') / (ca * cg);
  final rho = xlpe ? 0.025 : 0.0225;
  final sinRun = math.sqrt(math.max(0, 1 - pf * pf));
  const cosStart = 0.35;
  final sinStart = math.sqrt(1 - cosStart * cosStart);
  final ff = three ? sq3 : 2.0;
  double drop(double s, double i, double c, double sn) => ff * i * x.n('len') * (rho / s * c + 0.00008 * sn) / v * 100;

  final sizes = ElecTables.cableSizes;
  final byCurrent = [
    for (var i = 0; i < sizes.length; i++)
      if (sizes[i] >= x.n('minc') && table[i] >= need) i,
  ].firstOrNull;
  int? chosen;
  if (byCurrent != null) {
    for (var i = byCurrent; i < sizes.length; i++) {
      if (drop(sizes[i], flc, pf, sinRun) <= x.n('vdr') && drop(sizes[i], ist, cosStart, sinStart) <= x.n('vds')) {
        chosen = i;
        break;
      }
    }
  }
  final cable = chosen == null ? null : sizes[chosen];

  final issues = <CalcIssue>[
    if (!(p > 0)) const CalcIssue('Motor power is zero.', 'Enter the power from the nameplate.'),
    if (!(eff > 0 && eff <= 1)) const CalcIssue('Efficiency must be between 0 and 1.', 'Typical: 0.90.', patch: {'eff': 0.9}, patchLabel: 'Use 0.90'),
    if (!(pf > 0 && pf <= 1)) const CalcIssue('Power factor must be between 0 and 1.', 'Typical: 0.85.', patch: {'pf': 0.85}, patchLabel: 'Use 0.85'),
    if (!withinNec)
      const CalcIssue(
        'The breaker is above 250 % of FLC.',
        'Use an adjustable motor-protection breaker (MPCB) or an MCCB with a motor trip unit.',
      ),
    if (cable == null && p > 0)
      const CalcIssue(
        'No cable up to 300 mm² meets the limits.',
        'Use parallel cables, a shorter run, or relax the voltage-drop limits.',
      ),
    if (start == 'dol' && p > 7.5)
      const CalcIssue(
        'DOL start above 7.5 kW draws a large starting current.',
        'Many utilities want star-delta or a soft starter above 7.5 kW.',
        patch: {'start': 'sd'},
        patchLabel: 'Use star-delta',
      ),
  ];

  String a(double? v, [int d = 0]) => v == null ? 'Spec sheet' : '${fmt(v, d)} A';

  return CalcResult(
    headline: CalcHeadline(
      'Motor ${fmt(p, 1)} kW · ${_startName[start]}',
      '${fmt(breaker, 0)} A breaker',
      caption: 'FLC ${fmt(flc, 1)} A · cable ${cable == null ? '-' : '${num0(cable)} mm²'}',
    ),
    metrics: [
      ResultRow('Full load', '${fmt(flc, 1)} A'),
      ResultRow('Starting', '${fmt(ist, 0)} A'),
      ResultRow('Cable', cable == null ? '-' : '${num0(cable)} mm²'),
    ],
    sections: [
      ResultSection('Motor current', [
        ResultRow('Full load current', '${fmt(flc, 1)} A${nameplate ? ' (nameplate)' : ''}'),
        ResultRow('Calculated from power', '${fmt(calc, 1)} A'),
        ResultRow('Starting (${_startName[start]}, ≈ ${num0(k)} ×)', '${fmt(ist, 0)} A'),
      ]),
      ResultSection('Overload relay', [
        ResultRow('Range', relay == null ? 'CT / electronic relay' : '${num0(relay[0])} - ${num0(relay[1])} A'),
        ResultRow(sd ? 'Set at (0.58 × FLC, in delta)' : 'Set at (= FLC)', '${fmt(iset, 1)} A'),
        ResultRow('Trip class', x.s('cls')),
      ]),
      ResultSection('Magnetic contactor (AC-3)', [for (final c in contactors) ResultRow(c.$1, a(c.$2))]),
      ResultSection('Circuit breaker', [
        ResultRow('Rating In', '${fmt(breaker, 0)} A (${ElecTables.breakerType(breaker)})'),
        ResultRow('Magnetic trip ≥', '${fmt(inst, 0)} A'),
        ResultRow('Breaking capacity Icu ≥', icu == null ? '> 100 kA' : '${num0(icu)} kA'),
        ResultRow('Within 250 % of FLC', withinNec ? 'Yes' : 'No', tone: withinNec ? Tone.ok : Tone.bad),
      ]),
      ResultSection(
        'Cable (3C Cu ${xlpe ? 'XLPE' : 'PVC'}, method C, ${num0(x.n('len'))} m)',
        cable == null
            ? [const ResultRow('Cable', 'No size up to 300 mm²', tone: Tone.bad)]
            : [
                ResultRow('Cable size', '${num0(cable)} mm²'),
                ResultRow('Earth (PE)', '${num0(ElecTables.peFor(cable))} mm²'),
                ResultRow('Rating after derating', '${fmt(table[chosen!] * ca * cg, 0)} A'),
                ResultRow(
                  'Voltage drop run / start',
                  '${fmt(drop(cable, flc, pf, sinRun), 2)} % / ${fmt(drop(cable, ist, cosStart, sinStart), 2)} %',
                ),
              ],
        note: 'By current alone: ${byCurrent == null ? '-' : '${num0(sizes[byCurrent])} mm²'} · '
            'Ca ${fmt(ca, 2)} · Cg ${fmt(cg, 2)}',
      ),
    ],
    issues: issues,
    steps: [
      CalcStep(
        'Full load current',
        three ? 'FLC = P × 1000 / (√3 × V × η × PF)' : 'FLC = P × 1000 / (V × η × PF)',
        '${fmt(p, 2)} × 1000 / (${three ? '1.732 × ' : ''}${num0(v)} × $eff × $pf)',
        '${fmt(calc, 1)} A',
      ),
      CalcStep('Starting current', 'Ist = k × FLC', '${num0(k)} × ${fmt(flc, 1)}', '${fmt(ist, 0)} A'),
      CalcStep(
        'Breaker',
        'In ≥ max(1.25 × FLC, magnetic trip / 10)',
        'max(${fmt(1.25 * flc, 1)}, ${fmt(inst / 10, 1)})',
        '${fmt(breaker, 0)} A',
      ),
      CalcStep(
        'Cable by current',
        'Iz ≥ FLC × margin / (Ca × Cg)',
        '${fmt(flc, 1)} × ${x.n('mar')} / (${fmt(ca, 2)} × ${fmt(cg, 2)})',
        '${fmt(need, 1)} A',
      ),
    ],
  );
}
