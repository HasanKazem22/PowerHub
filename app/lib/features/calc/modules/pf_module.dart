import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../domain/electrical_tables.dart';

/// Power factor correction: capacitor bank size, steps and protection
/// (IEC 60831-1, IEC 61921, IEC 60947-4-1 AC-6b).
final pfModule = CalcModule(
  id: 'pf',
  title: 'Power factor correction',
  shortTitle: 'Power\nfactor',
  subtitle: 'Capacitor bank, steps, fuses, breaker',
  icon: Icons.speed_outlined,
  color: AppColors.tilePurple,
  defaults: const {
    'kw': 300,
    'pf1': 0.8,
    'pf2': 0.95,
    'v': 415,
    'ltype': 'factory',
    'nl': 10,
    'p': '7',
    'amb': 35,
    'fault': 25,
  },
  groups: const [
    FieldGroup('Load', [
      NumberField('kw', 'Load', positive: true, unit: 'kW'),
      NumberField('pf1', 'Power factor now'),
      NumberField('pf2', 'Target power factor', help: 'Usually 0.95; never aim for 1.0'),
      NumberField('v', 'System voltage', positive: true, unit: 'V'),
      ChoiceField('ltype', 'Load type', [
        CalcOption('commercial', 'Commercial building / mall'),
        CalcOption('factory', 'Factory with motors'),
        CalcOption('motor', 'Few large motors, steady'),
        CalcOption('swing', 'Rapid swings', detail: 'Welding, arc furnace'),
        CalcOption('resid', 'Residential building'),
      ]),
      NumberField('nl', 'Non-linear load share', unit: '%', help: 'VFD, UPS, LED, rectifier'),
    ]),
    FieldGroup('Panel', advanced: true, [
      ChoiceField('p', 'Detuning reactor', [
        CalcOption('7', '7 % (189 Hz)', detail: '5th harmonic'),
        CalcOption('5.67', '5.67 % (210 Hz)'),
        CalcOption('14', '14 % (134 Hz)', detail: '3rd harmonic'),
      ]),
      NumberField('amb', 'Panel ambient', unit: '°C'),
      NumberField('fault', 'Fault level at panel', unit: 'kA'),
    ]),
  ],
  compute: computePf,
  basis:
      'Non-linear load up to 15 %: plain capacitors; 15 to 50 %: detuned bank; above 50 %: filter / harmonic study. '
      'Capacitors carry 1.3 × current and 1.1 × voltage (IEC 60831-1), so protection and cables are sized at 1.43 × '
      '(1.5 × for detuned banks). Discharge below 75 V within 3 minutes. Bank standard IEC 61921:2017, step '
      'contactors AC-6b (IEC 60947-4-1). Utilities usually charge below PF 0.90: check your current tariff.',
);

const _steps = <double>[2.5, 5, 10, 12.5, 15, 20, 25, 30, 40, 50, 60, 75, 100];
const _ac6 = <double>[12.5, 15, 20, 25, 30, 33, 40, 50, 60, 75, 100];
const _nhFuse = <double>[16, 20, 25, 32, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630];
const _controllers = <double>[4, 6, 8, 12, 14];

String _scheme(String ltype, int n) => switch (ltype) {
  'swing' => 'Thyristor-switched capacitors (TSC) or SVG (static var generator)',
  'motor' => 'Individual compensation at the large motors, plus an automatic bank for the rest',
  'resid' => 'Small automatic bank at the main LV panel, only if the utility charges a penalty',
  _ => 'Automatic APFC panel ($n steps)',
};

CalcResult computePf(CalcInputs x) {
  final sq3 = math.sqrt(3);
  final v = x.n('v');
  final p0 = x.n('kw');
  final pf1 = x.n('pf1'), pf2 = x.n('pf2');
  final t1 = math.tan(math.acos(pf1.clamp(0.0, 1.0)));
  final t2 = math.tan(math.acos(pf2.clamp(0.0, 1.0)));
  final q = math.max(0.0, p0 * (t1 - t2));
  final nl = x.n('nl');

  final det = nl > 15 && nl <= 50;
  final filter = nl > 50;
  final p = det ? x.n('p') / 100 : 0.0;
  final vr = det ? 525.0 : (v <= 415 ? 440.0 : 480.0);
  final vc = v / (1 - p);
  final ratio = math.pow(vc / vr, 2).toDouble();
  final qr = q / ((1 - p) * ratio);
  final step = nextUp(_steps, math.max(5, qr / 12)) ?? 100;
  final n = math.max(1, (qr / step - 1e-9).ceil());
  final qrt = n * step;
  final qe = qrt * (1 - p) * ratio;
  final qs = qe / n;

  final iStep = qs * 1000 / (sq3 * v);
  final iBank = qe * 1000 / (sq3 * v);
  final kf = det ? 1.5 : 1.43;
  final iDesign = kf * iBank;
  final iStepDesign = kf * iStep;
  final ca = interp(ElecTables.ambientPvc, x.n('amb'));
  const tab = ElecTables.ratingPvc3;
  const sizes = ElecTables.cableSizes;

  double? stepCable;
  for (var i = 0; i < sizes.length; i++) {
    if (sizes[i] >= 2.5 && tab[i] * ca >= iStepDesign) {
      stepCable = sizes[i];
      break;
    }
  }
  final fuse = nextUp(_nhFuse, 1.6 * iStep);
  final ct6 = nextUp(_ac6, qs);
  final mainBreaker = nextUp(ElecTables.breakers, iDesign);
  ({int k, double s})? mainCable;
  for (var k = 1; k <= 4 && mainCable == null; k++) {
    final cg = interp(ElecTables.grouping, k.toDouble());
    for (var i = 0; i < sizes.length; i++) {
      if (sizes[i] >= 16 && k * tab[i] * ca * cg >= iDesign) {
        mainCable = (k: k, s: sizes[i]);
        break;
      }
    }
  }
  final iLine = p0 * 1000 / (sq3 * v * pf1);
  final ctr = nextUp(ElecTables.ctPrimaries, 1.2 * iLine) ?? ElecTables.ctPrimaries.last;
  final ctl = nextUp(_controllers, n);
  final icu = nextUp(ElecTables.lvIcu, x.n('fault'));
  final scheme = _scheme(x.s('ltype'), n);

  double tn(double qq) => p0 > 0 ? (p0 * t1 - qq) / p0 : 0;
  double pfOf(double qq) => math.cos(math.atan(tn(qq).abs()));
  final pfLo = pfOf(qe * 0.95), pfHi = pfOf(qe * 1.1);
  final leadHi = tn(qe * 1.1) < 0, leadLo = tn(qe * 0.95) < 0;
  final fr = p > 0 ? 50 / math.sqrt(p) : 0.0;
  final rx = p * step;

  final type = filter
      ? 'Active filter'
      : det
      ? 'Detuned ${x.s('p')} %'
      : 'Plain (standard duty)';
  String a(double? v, [String spec = 'Spec sheet']) => v == null ? spec : '${num0(v)} A';

  final issues = <CalcIssue>[
    if (!(p0 > 0)) const CalcIssue('The load is zero.', 'Enter the load in kW.'),
    if (!(pf1 > 0 && pf1 < 1))
      const CalcIssue('Present PF must be between 0 and 1.', 'Typical: 0.80.', patch: {'pf1': 0.8}, patchLabel: 'Use 0.80'),
    if (!(pf2 > pf1) || pf2 > 1)
      const CalcIssue(
        'Target PF must be above the present PF and not above 1.',
        'Use 0.95. Never aim for 1.0: at light load the PF turns leading.',
        patch: {'pf2': 0.95},
        patchLabel: 'Use 0.95',
      )
    else if (pf2 < 0.9)
      const CalcIssue(
        'Target PF is below 0.90; utilities usually charge below 0.90.',
        'Keep the target at 0.95.',
        patch: {'pf2': 0.95},
        patchLabel: 'Use 0.95',
      ),
    if (filter)
      const CalcIssue(
        'Non-linear load is above 50 %: plain or detuned capacitors are not enough.',
        'Do a harmonic study and consider an active filter.',
      ),
    if (leadHi && p0 > 0)
      CalcIssue(
        'At the +10 % tolerance the bank can push the PF leading.',
        'Take one step less and set the controller dead band correctly.',
        suggestion: 'Use ${math.max(1, n - 1)} × ${num0(step)} kVAR',
      ),
    if (mainCable == null)
      const CalcIssue('No main cable fits even with 4 runs.', 'Split the bank over more than one panel.'),
  ];

  return CalcResult(
    headline: CalcHeadline(
      'Capacitor bank',
      '${fmt(q, 0)} kVAR',
      caption: '$n × ${num0(step)} kVAR bank · PF ${num0(pf1)} → ${num0(pf2)}',
    ),
    metrics: [
      ResultRow('Bank current', '${fmt(iBank, 0)} A'),
      ResultRow('Main breaker', a(mainBreaker)),
      ResultRow('Line CT', '${num0(ctr)}/5 A'),
    ],
    sections: [
      ResultSection('Compensation', [
        ResultRow('Reactive power needed', '${fmt(q, 0)} kVAR'),
        ResultRow('Scheme', scheme),
        ResultRow('Capacitor type', type),
      ]),
      ResultSection('Capacitor bank', [
        ResultRow('Rated voltage', '${num0(vr)} V'),
        ResultRow('Steps', '$n × ${num0(step)} kVAR'),
        ResultRow('Total rated', '${num0(qrt)} kVAR'),
        ResultRow('Delivered at ${num0(v)} V', '${fmt(qe, 0)} kVAR'),
        ResultRow('Tolerance −5 % / +10 %', '${fmt(qe * 0.95, 0)} to ${fmt(qe * 1.1, 0)} kVAR'),
        ResultRow(
          'PF with tolerance',
          '${fmt(pfLo, 3)}${leadLo ? ' lead' : ''} to ${fmt(pfHi, 3)}${leadHi ? ' lead' : ''}',
          tone: leadHi ? Tone.bad : Tone.normal,
        ),
        ResultRow('Controller steps', ctl == null ? '2 controllers' : num0(ctl)),
        if (det) ResultRow('Reactor per step', '${fmt(rx, 1)} kVAR, tuned ${fmt(fr, 0)} Hz'),
      ]),
      ResultSection('Per step', [
        ResultRow('Step current', '${fmt(iStep, 1)} A'),
        ResultRow('HRC fuse (gG)', a(fuse)),
        ResultRow('Cable (Cu PVC)', stepCable == null ? '-' : '${num0(stepCable)} mm²'),
        ResultRow('Contactor AC-6b ≥', ct6 == null ? '> 100 kVAR' : '${num0(ct6)} kVAR'),
        const ResultRow('Discharge', '< 75 V in 3 min'),
      ]),
      ResultSection('Main incomer', [
        ResultRow('Bank current', '${fmt(iBank, 0)} A'),
        ResultRow('MCCB / ACB', '${a(mainBreaker)}, Icu ≥ ${icu == null ? '> 100' : num0(icu)} kA'),
        ResultRow('Cable', mainCable == null ? '-' : '${mainCable.k} × ${num0(mainCable.s)} mm²', tone: mainCable == null ? Tone.bad : Tone.normal),
        ResultRow('Busbar', mainBreaker == null ? 'Spec sheet' : ElecTables.busbarText(mainBreaker)),
        ResultRow('Line CT', '${num0(ctr)}/5 A'),
      ]),
    ],
    issues: issues,
    steps: [
      CalcStep(
        'Reactive power needed',
        'Q = P × (tan(acos PF1) − tan(acos PF2))',
        '${num0(p0)} × (${fmt(t1, 3)} − ${fmt(t2, 3)})',
        '${fmt(q, 0)} kVAR',
      ),
      CalcStep(
        'Capacitor type',
        'Non-linear ${num0(nl)} %: up to 15 % plain, 15 to 50 % detuned, above 50 % filter',
        'Rated voltage ${num0(vr)} V',
        filter ? 'Active filter / study' : (det ? 'Detuned ${x.s('p')} %' : 'Plain'),
      ),
      CalcStep(
        'Rated kVAR of capacitors',
        det ? 'Qr = Q / ((1 − p) × (Vc / Vr)²), Vc = V / (1 − p)' : 'Qr = Q × (Vr / V)²',
        det ? 'Vc = ${fmt(vc, 0)} V' : '${fmt(q, 0)} × (${num0(vr)} / ${num0(v)})²',
        '${fmt(qr, 0)} kVAR at ${num0(vr)} V',
      ),
      CalcStep('Steps', 'Step size so the bank has at most 12 steps', 'step = ${num0(step)} kVAR', '$n × ${num0(step)} = ${num0(qrt)} kVAR'),
      CalcStep(
        'Bank current',
        'I = kVAR × 1000 / (√3 × V)',
        '${fmt(qe, 0)} × 1000 / (1.732 × ${num0(v)})',
        '${fmt(iBank, 0)} A (step ${fmt(iStep, 1)} A)',
      ),
      CalcStep('Protection current', 'I design = $kf × I (IEC 60831-1)', '$kf × ${fmt(iBank, 0)}', '${fmt(iDesign, 0)} A'),
      CalcStep(
        'Step protection',
        'Fuse ≥ 1.6 × step current, cable ≥ $kf × step current',
        '1.6 × ${fmt(iStep, 1)} A',
        '${a(fuse)} fuse, ${stepCable == null ? '-' : num0(stepCable)} mm² cable',
      ),
      CalcStep('Main protection', 'Breaker ≥ $kf × bank current, next standard', '${fmt(iDesign, 0)} A', a(mainBreaker)),
      CalcStep(
        'Line CT for PF controller',
        'I = P / (√3 × V × PF), CT ≥ 1.2 × I',
        '${fmt(iLine, 0)} A × 1.2',
        '${num0(ctr)}/5 A',
      ),
      CalcStep(
        'Tolerance',
        'Capacitance −5 % to +10 % (IEC 60831-1)',
        '${fmt(qe * 0.95, 0)} to ${fmt(qe * 1.1, 0)} kVAR',
        'PF ${fmt(pfLo, 3)} to ${fmt(pfHi, 3)}',
      ),
    ],
  );
}
