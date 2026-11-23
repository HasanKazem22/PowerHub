import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../domain/electrical_tables.dart';

/// Stator rewinding of a 3-phase squirrel-cage induction motor: winding
/// layout, turns, wire, resistance and copper (IEC 60034-1 ratings, IEC 60317 wire sizes).
final rewindModule = CalcModule(
  id: 'rewind',
  title: 'Motor rewinding',
  shortTitle: 'Motor\nrewinding',
  subtitle: 'Stator winding: turns, wire, coil span, phase slots',
  icon: Icons.cyclone_outlined,
  color: AppColors.tileRose,
  defaults: rewindDefaults,
  groups: [
    const FieldGroup('Motor', [
      ChoiceField('unit', 'Power unit', [CalcOption('kW', 'kW'), CalcOption('hp', 'HP')]),
      NumberField('p', 'Motor power'),
      NumberField('v', 'Voltage', unit: 'V'),
      NumberField('f', 'Frequency', unit: 'Hz'),
      NumberField('poles', 'Poles', integer: true),
      ChoiceField('conn', 'Connection', [CalcOption('star', 'Star'), CalcOption('delta', 'Delta')]),
      NumberField('eff', 'Efficiency', help: '0 to 1'),
      NumberField('pf', 'Power factor'),
      ChoiceField('ic', 'Insulation class', [
        CalcOption('B', 'B (130 °C)'),
        CalcOption('F', 'F (155 °C)'),
        CalcOption('H', 'H (180 °C)'),
      ]),
    ]),
    const FieldGroup('Stator', [
      NumberField('Z', 'Stator slots', integer: true),
      NumberField('D', 'Bore diameter', unit: 'mm'),
      NumberField('L', 'Core length', unit: 'mm'),
      NumberField('span', 'Coil span', unit: 'slots', integer: true, help: '0 = 5/6 pitch'),
      ChoiceField('layers', 'Winding layers', [CalcOption('2', 'Double layer'), CalcOption('1', 'Single layer')]),
      NumberField('a', 'Parallel paths', integer: true),
    ]),
    const FieldGroup('Design values', advanced: true, [
      NumberField('Bav', 'Air-gap flux density', unit: 'T', help: 'Usually 0.4 - 0.65'),
      NumberField('Ke', 'EMF ratio Ke', help: 'About 0.95 - 0.98'),
      NumberField('J', 'Current density', unit: 'A/mm²', help: 'Usually 3 - 6.5'),
      NumberField('maxd', 'Max single wire', unit: 'mm'),
      NumberField('slotA', 'Net slot area', unit: 'mm²', help: '0 = skip the slot-fill check'),
    ]),
    FieldGroup('Wire data', [
      const ChoiceField('mode', 'Wire data source', [
        CalcOption('design', 'Calculate new winding'),
        CalcOption('existing', 'Use existing coil data'),
      ]),
      NumberField('Tc', 'Turns per coil', integer: true, visibleIf: _existing),
      NumberField('dold', 'Wire diameter', unit: 'mm', visibleIf: _existing),
      NumberField('nold', 'Strands in parallel', integer: true, visibleIf: _existing),
    ]),
  ],
  compute: computeRewind,
  basis:
      'Ns = 120 f / P. Slots per pole per phase q = Z / (3P); coil span short-pitched to about 5/6 of the pole '
      'pitch. Pitch factor kp = sin(span / pole pitch × 90°), distribution factor kd = sin(qα/2) / (q sin(α/2)), '
      'winding factor kw = kp × kd. Turns from E = 4.44 f Φ T kw with E = Ke × phase voltage and Φ = Bav × pole '
      'pitch × core length; turns per coil rounded and the flux density rechecked. Wire area = phase current / '
      '(a × J), nearest IEC 60317 enamelled wire, thin strands in parallel above the max diameter. Slot fill above '
      '40-45 % will not insert. Resistance at 20 °C from the mean turn length; copper loss at 75 °C (234.5 factor). '
      'Phases start 120 electrical degrees (2q slots) apart. Insulation class per IEC 60085. Use the original '
      'winding data when available and confirm with the maker.',
);

bool _existing(CalcInputs x) => x.s('mode') == 'existing';

const rewindDefaults = <String, Object?>{
  'unit': 'kW',
  'p': 7.5,
  'v': 415,
  'f': 50,
  'poles': 4,
  'conn': 'star',
  'eff': 0.9,
  'pf': 0.85,
  'Z': 36,
  'D': 125,
  'L': 130,
  'span': 0,
  'layers': '2',
  'Bav': 0.5,
  'Ke': 0.96,
  'J': 5,
  'a': 1,
  'maxd': 1.6,
  'slotA': 0,
  'mode': 'design',
  'Tc': 0,
  'dold': 0,
  'nold': 1,
  'ic': 'F',
};

/// IEC 60317 enamelled copper wire diameters (mm).
const _wireSizes = <double>[
  0.28, 0.32, 0.36, 0.4, 0.45, 0.5, 0.56, 0.63, 0.71, 0.8, 0.9, 1, 1.06, 1.12, 1.18, 1.25, 1.32, 1.4, 1.5, 1.6, //
  1.7, 1.8, 1.9, 2, 2.12, 2.24, 2.36, 2.5,
];
const _insulationTemp = {'B': 130, 'F': 155, 'H': 180};

/// Input problems that make the winding meaningless (the HTML's rwErr).
List<CalcIssue> _inputErrors(CalcInputs m) {
  bool pos(String k) => m.n(k) > 0;
  final poles = m.n('poles'), z = m.n('Z'), a = m.n('a');
  return [
    if (!pos('p')) const CalcIssue('Motor power is zero or empty.', 'Enter the kW or HP from the nameplate.'),
    if (!pos('v')) const CalcIssue('Voltage is zero or empty.', 'Enter 415 or 400 V.', patch: {'v': 415}, patchLabel: 'Use 415 V'),
    if (!pos('f')) const CalcIssue('Frequency is zero or empty.', 'Enter 50 Hz.', patch: {'f': 50}, patchLabel: 'Use 50 Hz'),
    if (!(poles >= 2 && poles <= 48 && poles % 2 == 0))
      const CalcIssue('Poles must be an even number (2, 4, 6, 8 …).', 'Work it out from the nameplate speed: P = 120 f / Ns.'),
    if (!(z >= 6 && z <= 360 && z == z.roundToDouble()))
      const CalcIssue('Slots must be a whole number from 6 to 360.', 'Count the stator slots.'),
    if (!(m.n('eff') > 0 && m.n('eff') <= 1))
      const CalcIssue('Efficiency must be between 0 and 1.', 'For example 0.90.', patch: {'eff': 0.9}, patchLabel: 'Use 0.90'),
    if (!(m.n('pf') > 0 && m.n('pf') <= 1))
      const CalcIssue('Power factor must be between 0 and 1.', 'For example 0.85.', patch: {'pf': 0.85}, patchLabel: 'Use 0.85'),
    if (!pos('D') || !pos('L')) const CalcIssue('Bore diameter and core length are needed.', 'Measure both in mm (not 0).'),
    if (!pos('Bav') || !pos('J') || !pos('Ke'))
      const CalcIssue(
        'Flux density, current density and EMF ratio cannot be 0.',
        'Defaults: 0.5 T, 5 A/mm², 0.96.',
        patch: {'Bav': 0.5, 'J': 5, 'Ke': 0.96},
        patchLabel: 'Use defaults',
      ),
    if (!(a >= 1 && a == a.roundToDouble()))
      const CalcIssue('Parallel paths must be a whole number, 1 or more.', 'Usually 1.', patch: {'a': 1}, patchLabel: 'Use 1'),
    if (!pos('maxd'))
      const CalcIssue('Max wire diameter cannot be 0.', 'For example 1.6 mm.', patch: {'maxd': 1.6}, patchLabel: 'Use 1.6 mm'),
    if (_existing(m) && !(m.n('Tc') > 0 && m.n('dold') > 0 && m.n('nold') >= 1))
      const CalcIssue('Existing coil data is incomplete.', 'Enter the old turns per coil, wire diameter and strands.'),
  ];
}

/// Coil-group start slots for each phase (the HTML's psl).
({double d, int sA, int sB, int sC, int groups, List<List<int>> slots, bool whole}) phaseSlots(CalcInputs m) {
  final z = m.i('Z'), p = m.i('poles');
  final double layers = m.n('layers');
  final d = 2 * z / (3 * p);
  int wrap(double x) => ((x.round() - 1) % z + z) % z + 1;
  final sp = layers == 2 ? z / p : 2 * z / p;
  final g = layers == 2 ? p : p ~/ 2;
  final slots = [
    for (var i = 0; i < 3; i++) [for (var k = 0; k < g; k++) wrap(1 + i * d + k * sp)],
  ];
  return (
    d: d,
    sA: 1,
    sB: wrap(1 + d),
    sC: wrap(1 + 2 * d),
    groups: g,
    slots: slots,
    whole: (d - d.round()).abs() < 1e-6,
  );
}

CalcResult computeRewind(CalcInputs input) {
  final errors = _inputErrors(input);
  // Invalid inputs: work the defaults out instead, so the screen still shows a layout (as the web version did).
  final m = errors.isEmpty ? input : CalcInputs(const {}, input.defaults.isEmpty ? rewindDefaults : input.defaults);
  final sq3 = math.sqrt(3);

  final p = m.s('unit') == 'hp' ? m.n('p') * 0.746 : m.n('p');
  final v = m.n('v'), fr = m.n('f');
  final pn = m.i('poles'), z = m.i('Z');
  final ns = 120 * fr / pn;
  final current = p * 1000 / (sq3 * v * m.n('eff') * m.n('pf'));
  final star = m.s('conn') != 'delta';
  final iph = star ? current : current / sq3;
  final vph = star ? v / sq3 : v;

  final q = z / (pn * 3);
  final tau = z / pn;
  final autoSpan = (5 * tau / 6).round();
  final span = m.n('span') > 0 ? m.i('span') : (autoSpan != 0 ? autoSpan : tau.round());
  final al = math.pi * pn / z;
  final kp = math.sin(span / tau * math.pi / 2);
  final kd = math.sin(q * al / 2) / (q * math.sin(al / 2));
  final kw = kp * kd;

  final taup = math.pi * m.n('D') / 1000 / pn;
  final lm = m.n('L') / 1000;
  final phi = m.n('Bav') * taup * lm;
  final e = m.n('Ke') * vph;
  final tphd = e / (4.44 * fr * phi * kw);
  final doubleLayer = m.n('layers') == 2;
  final coils = doubleLayer ? z.toDouble() : z / 2;
  final cpp = coils / 3;
  final a = m.n('a');
  final tcd = tphd * a / cpp;
  final ex = _existing(m);
  final tc = ex ? m.i('Tc') : math.max(1, tcd.round());
  final tph = tc * cpp / a;
  final phi2 = e / (4.44 * fr * tph * kw);
  final b2 = phi2 / (taup * lm);

  final areq = iph / (a * m.n('J'));
  final aw1 = math.pi / 4 * m.n('maxd') * m.n('maxd');
  final nd = math.max(1, (areq / aw1 - 1e-9).ceil());
  final di = math.sqrt(4 * areq / (nd * math.pi));
  final dd = nextUp(_wireSizes, di - 1e-9) ?? _wireSizes.last;
  final d = ex ? m.n('dold') : dd;
  final n = ex ? m.i('nold') : nd;
  final acu = n * math.pi / 4 * d * d;
  final ja = iph / (a * acu);
  final cs = tc * (doubleLayer ? 2 : 1);
  final fill = m.n('slotA') > 0 ? cs * acu / m.n('slotA') : 0.0;

  final tauc = math.pi * m.n('D') / 1000 * span / z;
  final lmt = 2 * lm + 2.3 * tauc + 0.24;
  final r20 = 0.01724 * tph * lmt / (acu * a);
  final r75 = r20 * (234.5 + 75) / (234.5 + 20);
  final rl = star ? 2 * r20 : 2 / 3 * r20;
  final cu = 3 * iph * iph * r75;
  final kg = 3 * tph * a * lmt * acu * 0.00896 * 1.05;
  final groups = doubleLayer ? 3 * pn : 1.5 * pn;
  final fractional = z % (3 * pn) != 0;
  final ps = phaseSlots(m);
  final ic = _insulationTemp.containsKey(m.s('ic')) ? m.s('ic') : 'F';

  final issues = <CalcIssue>[
    ...errors,
    if (fractional)
      const CalcIssue(
        'Slots are not divisible by 3 × poles (fractional-slot winding).',
        'Check the original connection diagram.',
      ),
    if (b2 < 0.4 || b2 > 0.65)
      CalcIssue(
        'Air-gap flux density ${fmt(b2, 2)} T is outside the usual 0.4 - 0.65 T.',
        'Change the turns per coil or check the bore and core length.',
      ),
    if (ja < 2.5 || ja > 7)
      CalcIssue(
        'Current density ${fmt(ja, 2)} A/mm² is outside the usual 3 - 6.5 A/mm².',
        'Change the wire size or the number of strands.',
      ),
    if (fill > 0.45)
      CalcIssue(
        'Copper slot fill ${fmt(fill * 100, 0)} % is too high for random winding.',
        'Keep it below about 40 - 45 %: thinner wire or fewer turns.',
      ),
    if (pn % a.round() != 0)
      const CalcIssue('Parallel paths should divide the number of poles.', 'Use 1 or a divisor of the poles.', patch: {'a': 1}, patchLabel: 'Use 1'),
  ];

  String mm(double v) => '${num0(v)} mm';

  return CalcResult(
    headline: CalcHeadline('Winding · ${num0(z)} slots, ${num0(pn)} poles', '$tc turns/coil', caption: 'Wire $n × ${mm(d)}'),
    metrics: [
      ResultRow('Speed', '${fmt(ns, 0)} rpm'),
      ResultRow('Coil span', '1 - ${span + 1}'),
      ResultRow('Copper', '${fmt(kg, 2)} kg'),
    ],
    sections: [
      ResultSection('Motor data', [
        ResultRow('Synchronous speed', '${fmt(ns, 0)} rpm'),
        ResultRow('Rated line current', '${fmt(current, 1)} A'),
        ResultRow('Phase current', '${fmt(iph, 1)} A'),
        ResultRow('Phase voltage', '${fmt(vph, 0)} V'),
      ]),
      ResultSection('Winding layout', [
        ResultRow('Slots / pole / phase (q)', fmt(q, 2), tone: fractional ? Tone.bad : Tone.normal),
        ResultRow('Pole pitch', '${fmt(tau, 2)} slots'),
        ResultRow('Coil span', '1 - ${span + 1} ($span slots)'),
        ResultRow('Coils / coil groups', '${num0(coils)} / ${num0(groups)}'),
        ResultRow('Coils per phase', fmt(cpp, 1)),
      ]),
      ResultSection(
        'Phase start slots',
        [
          ResultRow('Slots per 120° (elec.)', fmt(ps.d, 2)),
          ResultRow('Phase U (U1) starts at slot', '${ps.sA}'),
          ResultRow('Phase V (V1) starts at slot', '${ps.sB}'),
          ResultRow('Phase W (W1) starts at slot', '${ps.sC}'),
          ResultRow('U group start slots', ps.slots[0].join(', ')),
          ResultRow('V group start slots', ps.slots[1].join(', ')),
          ResultRow('W group start slots', ps.slots[2].join(', ')),
        ],
        note:
            '${ps.groups} groups per phase, 120 electrical degrees apart (IEC 60034-8: U1 V1 W1). Adjacent groups of a '
            'phase are connected in reverse so the poles alternate N and S. Each coil spans slot to slot + $span.'
            '${ps.whole ? '' : ' Slots per 120° is not a whole number, so positions are rounded; check the original winding.'}',
      ),
      ResultSection('Winding factors', [
        ResultRow('Pitch factor kp', fmt(kp, 3)),
        ResultRow('Distribution factor kd', fmt(kd, 3)),
        ResultRow('Winding factor kw', fmt(kw, 3)),
      ]),
      ResultSection('Turns', [
        ResultRow('Turns per phase (calc)', fmt(tphd, 1)),
        ResultRow('Turns per coil (calc)', fmt(tcd, 1)),
        ResultRow('Turns per coil (use)', '$tc'),
        ResultRow('Series turns per phase', fmt(tph, 1)),
        ResultRow('Actual air-gap flux density', '${fmt(b2, 3)} T', tone: b2 < 0.4 || b2 > 0.65 ? Tone.bad : Tone.ok),
      ]),
      ResultSection('Winding wire (IEC 60317)', [
        ResultRow('Wire', '$n × ${mm(d)}'),
        ResultRow('Copper area', '${fmt(acu, 3)} mm²'),
        ResultRow('Current density', '${fmt(ja, 2)} A/mm²', tone: ja < 2.5 || ja > 7 ? Tone.bad : Tone.ok),
        ResultRow('Conductors per slot', '$cs'),
        if (fill > 0) ResultRow('Copper slot fill', '${fmt(fill * 100, 0)} %', tone: fill > 0.45 ? Tone.bad : Tone.ok),
      ]),
      ResultSection('Resistance & copper', [
        ResultRow('Mean length of turn', '${fmt(lmt, 2)} m'),
        ResultRow('Phase resistance at 20 °C', '${fmt(r20, 3)} Ω'),
        ResultRow('Expected line-to-line at 20 °C', '${fmt(rl, 3)} Ω'),
        ResultRow('Copper loss at 75 °C', '${fmt(cu, 0)} W'),
        ResultRow('Copper wire needed (+5 %)', '${fmt(kg, 2)} kg'),
        ResultRow('Wire thermal class', '$ic or higher (${_insulationTemp[ic]} °C)'),
      ]),
    ],
    issues: issues,
    steps: [
      CalcStep('Synchronous speed', 'Ns = 120 f / P', '120 × ${num0(fr)} / $pn', '${fmt(ns, 0)} rpm'),
      CalcStep('Slots per pole per phase', 'q = Z / (3 P)', '$z / (3 × $pn)', fmt(q, 2)),
      CalcStep('Pitch factor', 'kp = sin(span / τ × 90°)', 'sin($span / ${fmt(tau, 2)} × 90°)', fmt(kp, 3)),
      CalcStep('Distribution factor', 'kd = sin(qα/2) / (q sin(α/2))', 'q ${fmt(q, 2)}, α ${fmt(al * 180 / math.pi, 1)}°', fmt(kd, 3)),
      CalcStep('Winding factor', 'kw = kp × kd', '${fmt(kp, 3)} × ${fmt(kd, 3)}', fmt(kw, 3)),
      CalcStep(
        'Turns per phase',
        'T = E / (4.44 f Φ kw), Φ = Bav × τp × L',
        '${fmt(e, 1)} / (4.44 × ${num0(fr)} × ${fmt(phi * 1000, 3)} mWb × ${fmt(kw, 3)})',
        fmt(tphd, 1),
      ),
      CalcStep('Wire area', 'A = Iph / (a × J)', '${fmt(iph, 2)} / (${num0(a)} × ${num0(m.n('J'))})', '${fmt(areq, 3)} mm²'),
    ],
  );
}
