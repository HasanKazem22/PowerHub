import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../domain/electrical_tables.dart';

/// Three small tools in one: earth electrode resistance, bare copper earth
/// conductor size from fault current, and copper busbar size.
final earthingModule = CalcModule(
  id: 'earthing',
  title: 'Earthing & busbar',
  shortTitle: 'Earthing\n& busbar',
  subtitle: 'Earth rods, earth conductor, busbar size',
  icon: Icons.terrain_outlined,
  color: AppColors.tileGreen,
  defaults: const {
    'tool': 'earth',
    'soil': 'clay',
    'rho': 30,
    'type': 'square',
    'L': 3,
    'd': 0.0125,
    'S': 3,
    'n': '4',
    'tgt': '5',
    'mva': 10,
    'kv': 11,
    'xpu': 0.06,
    'isc': 0,
    't': 1,
    'k': 115,
    'bbI': 100,
    'bbT': '5',
  },
  groups: [
    const FieldGroup('Tool', [
      ChoiceField('tool', 'Calculate', [
        CalcOption('earth', 'Earth electrodes', detail: 'Rod resistance and number of rods'),
        CalcOption('conductor', 'Earth conductor', detail: 'Bare copper size from fault current'),
        CalcOption('busbar', 'Busbar', detail: 'Copper busbar from breaker rating'),
      ]),
    ]),
    FieldGroup('Soil and rods', visibleIf: _tool('earth'), [
      const ChoiceField('soil', 'Soil', [
        CalcOption('clay', 'Clay / loam', detail: '10 - 50 Ω·m, uses 30'),
        CalcOption('sand', 'Sandy', detail: '100 - 300 Ω·m, uses 200'),
        CalcOption('rock', 'Rocky / gravel', detail: '300 - 1000 Ω·m, uses 650'),
        CalcOption('custom', 'Measured value', detail: 'Enter ρ yourself'),
      ]),
      NumberField('rho', 'Soil resistivity ρ', unit: 'Ω·m', visibleIf: (x) => x.s('soil') == 'custom'),
      const ChoiceField('type', 'Configuration', [
        CalcOption('square', 'Square'),
        CalcOption('line', 'Line'),
        CalcOption('tri', 'Triangle'),
      ]),
      ChoiceField('n', 'Electrodes', _keys(_fsq), visibleIf: (x) => x.s('type') == 'square'),
      ChoiceField('n', 'Electrodes', _keys(_fln), visibleIf: (x) => x.s('type') == 'line'),
      const NumberField('L', 'Rod length L', positive: true, unit: 'm'),
      const NumberField('d', 'Rod diameter d', positive: true, unit: 'm'),
      const NumberField('S', 'Rod spacing S', positive: true, unit: 'm'),
      const ChoiceField('tgt', 'Target resistance', [
        CalcOption('1', '1 Ω', detail: 'Data centre, substation'),
        CalcOption('5', '5 Ω', detail: 'General, residential'),
      ]),
    ]),
    FieldGroup('Fault', visibleIf: _tool('conductor'), const [
      NumberField('mva', 'MVA base', unit: 'MVA'),
      NumberField('kv', 'kV base', positive: true, unit: 'kV'),
      NumberField('xpu', 'Reactance X', positive: true, unit: 'pu'),
      NumberField('isc', 'Fault current Isc', unit: 'A', help: '0 = calculate from MVA and X'),
      NumberField('t', 'Disconnection time t', unit: 's'),
      NumberField('k', 'Material factor k', positive: true, help: '115 bare copper (PVC), 143 XLPE'),
    ]),
    FieldGroup('Busbar', visibleIf: _tool('busbar'), [
      const NumberField('bbI', 'Breaker / current', unit: 'A'),
      ChoiceField('bbT', 'Thickness', [
        for (final t in ElecTables.busThickness) CalcOption(num0(t), '${num0(t)} mm'),
      ]),
    ]),
  ],
  compute: computeEarthing,
  basis:
      'Single rod: R = ρ / (2πL) × [ln(4L/d) − 1]. Square and line groups: Rn = R × (1 + λa) / n with a = ρ / (2πRS) '
      'and λ from the standard chart. Triangle: Re = ρ / (2πL) × ⅓ × [2(ln(8L/d) − 1) − 1 + 2L/S]. '
      'Earth conductor: Isc = MVA × 1000 / (1.73 × kV) / X, S = Isc × √t / k. '
      'Busbar: area = rating ÷ 1.6 A/mm², width = area ÷ thickness, next standard width.',
);

bool Function(CalcInputs) _tool(String t) =>
    (x) => x.s('tool') == t;

/// Chart factor λ for rods in a square / in a line, by number of rods.
const _fsq = <int, double>{
  2: 2.71, 3: 4.51, 4: 5.46, 5: 6.14, 6: 6.63, 7: 7.03, 8: 7.3, 9: 7.65, 10: 7.9, 12: 8.22, 14: 8.67, 16: 8.95, //
  18: 9.22, 20: 9.4,
};
const _fln = <int, double>{2: 1, 3: 1.66, 4: 2.15, 5: 2.54, 6: 2.87, 7: 3.15, 8: 3.39, 9: 3.61, 10: 3.81};
const _soil = {'clay': 30.0, 'sand': 200.0, 'rock': 650.0};

List<CalcOption> _keys(Map<int, double> t) => [for (final k in t.keys) CalcOption('$k', '$k rods')];

/// Earth resistance of [type] with [n] rods of length [l].
({double single, double group, double lambda, double a}) _earth(
  String type,
  int n,
  double rho,
  double l,
  double d,
  double s,
) {
  final r = rho / (2 * math.pi * l) * (math.log(4 * l / d) - 1);
  if (type == 'tri') {
    final re = rho / (2 * math.pi * l) * (1 / 3) * (2 * (math.log(8 * l / d) - 1) - 1 + 2 * l / s);
    return (single: r, group: re, lambda: 0, a: 0);
  }
  final lam = (type == 'line' ? _fln : _fsq)[n] ?? 0;
  final a = rho / (2 * math.pi * r * s);
  return (single: r, group: r * (1 + lam * a) / n, lambda: lam, a: a);
}

CalcResult computeEarthing(CalcInputs x) => switch (x.s('tool')) {
  'conductor' => _conductor(x),
  'busbar' => _busbar(x),
  _ => _electrodes(x),
};

CalcResult _electrodes(CalcInputs x) {
  final soil = x.s('soil');
  final rho = _soil[soil] ?? x.n('rho');
  final type = const {'square', 'line', 'tri'}.contains(x.s('type')) ? x.s('type') : 'square';
  final table = type == 'line' ? _fln : _fsq;
  final tri = type == 'tri';
  // Like the web version: a count the chart doesn't have falls back to 4.
  final n = tri ? 3 : (table.containsKey(x.i('n')) ? x.i('n') : 4);
  final l = x.n('L'), d = x.n('d'), s = x.n('S');
  final tgt = x.n('tgt') > 0 ? x.n('tgt') : 5.0;
  final e = _earth(type, n, rho, l, d, s);
  final ok = e.group <= tgt;

  final issues = <CalcIssue>[
    if (!(rho > 0 && l > 0 && d > 0 && s > 0))
      const CalcIssue('Soil resistivity, rod length, diameter and spacing must all be above 0.', 'Check the inputs.'),
    if (!ok && e.group.isFinite) _moreRods(type, n, rho, l, d, s, tgt),
  ];

  return CalcResult(
    headline: CalcHeadline(
      '${tri ? 'Triangle' : type == 'line' ? 'Line' : 'Square'} · $n rods',
      'R = ${fmt(e.group, 2)} Ω',
      caption: ok ? 'ACCEPTED (target ≤ ${num0(tgt)} Ω)' : 'NOT ACCEPTED · ADD MORE RODS',
    ),
    metrics: [
      ResultRow('Single rod', '${fmt(e.single, 2)} Ω'),
      ResultRow('Electrodes', '$n'),
      ResultRow('Target', '≤ ${num0(tgt)} Ω'),
    ],
    sections: [
      ResultSection('Earth resistance', [
        ResultRow('Soil resistivity ρ', '${num0(rho)} Ω·m'),
        ResultRow('Single rod R', '${fmt(e.single, 2)} Ω'),
        if (!tri) ResultRow('Chart factor λ', num0(e.lambda)),
        if (!tri) ResultRow('a = ρ / (2πRS)', fmt(e.a, 3)),
        ResultRow(tri ? 'Re (triangle)' : 'Rn (group of $n)', '${fmt(e.group, 2)} Ω'),
        ResultRow('Result', ok ? 'Accepted' : 'Not accepted', tone: ok ? Tone.ok : Tone.bad),
      ]),
    ],
    issues: issues,
    steps: [
      CalcStep(
        'Single rod',
        'R = ρ / (2πL) × [ln(4L/d) − 1]',
        '${num0(rho)} / (2π × ${num0(l)}) × [ln(${fmt(4 * l / d, 0)}) − 1]',
        '${fmt(e.single, 2)} Ω',
      ),
      if (tri)
        CalcStep(
          'Triangle',
          'Re = ρ / (2πL) × ⅓ × [2(ln(8L/d) − 1) − 1 + 2L/S]',
          'L ${num0(l)} m, d ${num0(d)} m, S ${num0(s)} m',
          '${fmt(e.group, 2)} Ω',
        )
      else
        CalcStep(
          'Group of rods',
          'Rn = R × (1 + λa) / n',
          '${fmt(e.single, 2)} × (1 + ${num0(e.lambda)} × ${fmt(e.a, 3)}) / $n',
          '${fmt(e.group, 2)} Ω',
        ),
    ],
  );
}

/// What to change when the target isn't met: more rods in this layout, else longer rods.
CalcIssue _moreRods(String type, int n, double rho, double l, double d, double s, double tgt) {
  const message = 'Earth resistance is above the target.';
  if (type != 'tri') {
    final table = type == 'line' ? _fln : _fsq;
    for (final k in table.keys.where((k) => k > n)) {
      final r = _earth(type, k, rho, l, d, s).group;
      if (r <= tgt) {
        return CalcIssue(
          message,
          'Add rods.',
          suggestion: '$k rods give ${fmt(r, 2)} Ω',
          patch: {'n': '$k'},
          patchLabel: 'Use $k rods',
        );
      }
    }
  }
  final layout = type == 'tri' ? 'square' : type;
  final count = type == 'tri' ? 4 : n;
  for (final len in const [4.0, 5.0, 6.0, 9.0, 12.0].where((v) => v > l)) {
    final r = _earth(layout, count, rho, len, d, s).group;
    if (r <= tgt) {
      return CalcIssue(
        message,
        'Use longer rods (and bentonite around them).',
        suggestion: '${num0(len)} m rods give ${fmt(r, 2)} Ω',
        patch: {'L': len, if (type == 'tri') 'type': 'square', if (type == 'tri') 'n': '4'},
        patchLabel: 'Use ${num0(len)} m rods',
      );
    }
  }
  return const CalcIssue(
    message,
    'Use a larger earth grid with bentonite, or treat the soil.',
    suggestion: 'More rods and longer rods are not enough here',
  );
}

CalcResult _conductor(CalcInputs x) {
  final mva = x.n('mva'), kv = x.n('kv'), xpu = x.n('xpu'), t = x.n('t'), k = x.n('k');
  final ir = mva * 1000 / (1.73 * kv);
  final msc = mva / xpu;
  final ic = ir / xpu;
  final entered = x.n('isc') > 0;
  final isc = entered ? x.n('isc') : ic;
  final area = isc * math.sqrt(t) / k;
  final size = nextUp(ElecTables.cableSizes, area);

  return CalcResult(
    headline: CalcHeadline(
      'Bare copper earth conductor',
      '${fmt(area, 1)} mm²',
      caption: 'Use ${size == null ? 'parallel conductors' : '${num0(size)} mm²'} · Isc ${fmt(isc / 1000, 2)} kA',
    ),
    metrics: [
      ResultRow('Fault MVA', fmt(msc, 1)),
      ResultRow('Isc', '${fmt(isc / 1000, 2)} kA'),
      ResultRow('Standard size', size == null ? '> 300 mm²' : '${num0(size)} mm²'),
    ],
    sections: [
      ResultSection('Cross-section of bare copper conductor', [
        ResultRow('MVAsc = MVA base / X', '${fmt(msc, 2)} MVA'),
        ResultRow('Rated current', '${fmt(ir, 1)} A'),
        ResultRow('Isc = I rated / X', '${fmt(ic, 1)} A'),
        if (entered) ResultRow('Isc used (entered)', '${fmt(isc, 1)} A'),
        ResultRow('S = Isc × √t / k', '${fmt(area, 1)} mm²'),
        ResultRow('Next standard size', size == null ? '> 300 mm²' : '${num0(size)} mm²'),
      ]),
    ],
    issues: [
      if (!(mva > 0 && kv > 0 && xpu > 0 && t > 0 && k > 0))
        const CalcIssue('MVA, kV, X, t and k must all be above 0.', 'Check the inputs.'),
    ],
    steps: [
      CalcStep('Fault level', 'MVAsc = MVA base / X pu', '${num0(mva)} / ${num0(xpu)}', '${fmt(msc, 2)} MVA'),
      CalcStep('Rated current', 'I = MVA × 1000 / (1.73 × kV)', '${num0(mva)} × 1000 / (1.73 × ${num0(kv)})', '${fmt(ir, 1)} A'),
      CalcStep('Fault current', 'Isc = I rated / X pu', '${fmt(ir, 1)} / ${num0(xpu)}', '${fmt(ic, 1)} A'),
      CalcStep('Conductor', 'S = Isc × √t / k', '${fmt(isc, 1)} × √${num0(t)} / ${num0(k)}', '${fmt(area, 1)} mm²'),
    ],
  );
}

CalcResult _busbar(CalcInputs x) {
  final amps = x.n('bbI');
  final t = x.n('bbT') > 0 ? x.n('bbT') : 5.0;
  final area = amps / ElecTables.busDensity;
  final width = area / t;
  final w = nextUp(ElecTables.busWidth, width);
  final auto = ElecTables.busbarText(amps);

  return CalcResult(
    headline: CalcHeadline(
      'Copper busbar · ${num0(amps)} A',
      w == null ? 'Thicker / 2 bars' : '${num0(w)} × ${num0(t)} mm',
      caption: 'Area ${fmt(area, 1)} mm² · smallest standard bar $auto',
    ),
    metrics: [
      ResultRow('Area', '${fmt(area, 1)} mm²'),
      ResultRow('Width', '${fmt(width, 1)} mm'),
      ResultRow('Thickness', '${num0(t)} mm'),
    ],
    sections: [
      ResultSection('Busbar', [
        ResultRow('Required area (I ÷ 1.6)', '${fmt(area, 1)} mm²'),
        ResultRow('Calculated width (area ÷ thickness)', '${fmt(width, 1)} mm'),
        ResultRow(
          'Suggested copper busbar',
          w == null ? 'Use thicker or multiple bars' : '${num0(w)} × ${num0(t)} mm',
          tone: w == null ? Tone.bad : Tone.ok,
        ),
        ResultRow('Smallest standard bar (any thickness)', auto),
      ]),
    ],
    issues: [
      if (!(amps > 0)) const CalcIssue('Current is zero.', 'Enter the breaker rating.'),
      if (w == null && amps > 0)
        CalcIssue(
          'No standard width up to 100 mm carries ${num0(amps)} A at ${num0(t)} mm.',
          'Use a thicker bar or two bars in parallel.',
          patch: t < ElecTables.busThickness.last ? {'bbT': num0(ElecTables.busThickness.last)} : null,
          patchLabel: t < ElecTables.busThickness.last ? 'Use ${num0(ElecTables.busThickness.last)} mm' : null,
        ),
    ],
    steps: [
      CalcStep('Area', 'A = I ÷ 1.6', '${num0(amps)} ÷ 1.6', '${fmt(area, 1)} mm²'),
      CalcStep('Width', 'W = A ÷ thickness', '${fmt(area, 1)} ÷ ${num0(t)}', '${fmt(width, 1)} mm'),
    ],
  );
}
