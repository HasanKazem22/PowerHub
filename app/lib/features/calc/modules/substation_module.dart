import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../domain/electrical_tables.dart';

/// 11 / 33 kV substation: transformer, HV and LV switchgear, short circuit,
/// CT / PT and relay settings, earthing, lightning protection and power-factor
/// correction (BNBC 2020 Part 8, IEC 60076, IEC 62271, IEC 60909).
final substationModule = CalcModule(
  id: 'substation',
  title: 'Substation sizing',
  shortTitle: 'Sub-\nstation',
  subtitle: 'Transformer, switchgear, relay, earthing',
  icon: Icons.electrical_services_outlined,
  color: AppColors.tileTeal,
  defaults: const {
    'kw': 300,
    'lf': 80,
    'fut': 20,
    'pf1': 0.85,
    'pf2': 0.95,
    'n': 1,
    'red': 'no',
    'hv': '11',
    'hvt': 'oh',
    'ovr': 0,
    'tt': 'oil',
    'zp': 0,
    'sf': 1,
    'pfc': 'yes',
    'hvd': 'auto',
    'dolim': 250,
    'hvlim': 500,
    'lvd': 'auto',
    'lvlim': 800,
    'lv': 415,
    'lvl': 10,
    'lvamb': 35,
    'lvg': 1,
    'lvvd': 1,
    'ssc': 250,
    'kap': 1.7,
    'cts': '5',
    'ctr': 0,
    'pk': 0,
    'tacb': 0.3,
    'gm': 0.3,
    'rho': 30,
    'rodL': 3,
    'rodD': 0.0125,
    'rodS': 3,
    'etg': 1,
    'et': 1,
    'ek': 143,
    'la': 'no',
    'lps': 'no',
    'spd': 'no',
    'thr': 50,
  },
  groups: const [
    FieldGroup('Basic', [
      NumberField('kw', 'Connected load', unit: 'kW'),
      NumberField('lf', 'Load factor', unit: '%'),
      NumberField('fut', 'Future expansion', unit: '%'),
      NumberField('pf1', 'Power factor now'),
      NumberField('pf2', 'Target power factor'),
      NumberField('n', 'Transformers', integer: true),
      ChoiceField('red', 'Backup', [
        CalcOption('no', 'None', detail: 'Units share the load'),
        CalcOption('yes', 'N-1', detail: 'One unit can carry everything'),
      ]),
      ChoiceField('hv', 'HV supply', [CalcOption('11', '11 kV'), CalcOption('33', '33 kV')]),
      ChoiceField('hvt', 'HV supply line', [CalcOption('oh', 'Overhead'), CalcOption('ug', 'Underground cable')]),
    ]),
    FieldGroup('Transformer & protection', advanced: true, [
      NumberField('ovr', 'Size override', unit: 'kVA', help: '0 = auto'),
      ChoiceField('tt', 'Transformer type', [CalcOption('oil', 'Oil, ONAN'), CalcOption('dry', 'Cast resin dry')]),
      NumberField('zp', 'Impedance Z', unit: '%', help: '0 = typical (4 % up to 630 kVA, else 6 %)'),
      NumberField('sf', 'Derating factor', help: '1 = none'),
      ChoiceField('pfc', 'PF correction installed', [
        CalcOption('yes', 'Yes', detail: 'Size on the target PF'),
        CalcOption('no', 'No', detail: 'Size on the present PF'),
      ]),
      ChoiceField('hvd', 'HV protection', [
        CalcOption('auto', 'Auto by size'),
        CalcOption('do', 'Drop-out fuse only'),
        CalcOption('lbs', 'LBS + drop-out fuse'),
        CalcOption('vcb', 'VCB + relay'),
      ]),
      NumberField('dolim', 'No switchgear up to', unit: 'kVA'),
      NumberField('hvlim', 'Use VCB above', unit: 'kVA'),
      ChoiceField('lvd', 'LV incomer', [
        CalcOption('auto', 'Auto by current'),
        CalcOption('mccb', 'MCCB'),
        CalcOption('acb', 'ACB'),
        CalcOption('mcb', 'MCB', detail: '≤ 125 A, ≤ 25 kA'),
        CalcOption('nh', 'NH fuse-switch', detail: '≤ 1000 A'),
      ]),
      NumberField('lvlim', 'Use ACB above', unit: 'A'),
      NumberField('thr', 'Substation required above', unit: 'kW'),
    ]),
    FieldGroup('LV cable', advanced: true, [
      NumberField('lv', 'LV voltage', positive: true, unit: 'V'),
      NumberField('lvl', 'Cable length', unit: 'm'),
      NumberField('lvamb', 'Cable ambient', unit: '°C'),
      NumberField('lvg', 'Cable grouping', integer: true),
      NumberField('lvvd', 'Max voltage drop', unit: '%'),
    ]),
    FieldGroup('Fault & relay', advanced: true, [
      NumberField('ssc', 'HV source fault level', positive: true, unit: 'MVA'),
      NumberField('kap', 'Peak factor κ'),
      ChoiceField('cts', 'CT secondary', [CalcOption('1', '1 A'), CalcOption('5', '5 A')]),
      NumberField('ctr', 'CT primary override', unit: 'A', help: '0 = auto'),
      NumberField('pk', 'Relay pickup override', unit: 'A', help: 'Primary amps, 0 = auto'),
      NumberField('tacb', 'LV ACB clearing time', unit: 's'),
      NumberField('gm', 'Relay grading margin', unit: 's'),
    ]),
    FieldGroup('Earthing & lightning', advanced: true, [
      NumberField('rho', 'Soil resistivity', unit: 'Ω·m'),
      NumberField('rodL', 'Rod length', unit: 'm'),
      NumberField('rodD', 'Rod diameter', unit: 'm'),
      NumberField('rodS', 'Rod spacing', unit: 'm'),
      NumberField('etg', 'Earth resistance target', unit: 'Ω'),
      NumberField('et', 'Earth fault duration', unit: 's'),
      NumberField('ek', 'k for earth conductor'),
      ChoiceField('la', 'Lightning arrester installed', [CalcOption('no', 'No'), CalcOption('yes', 'Yes')]),
      ChoiceField('lps', 'Building lightning protection', [CalcOption('no', 'No'), CalcOption('yes', 'Yes')]),
      ChoiceField('spd', 'LV surge protector installed', [CalcOption('no', 'No'), CalcOption('yes', 'Yes')]),
    ]),
  ],
  compute: computeSubstation,
  basis:
      'Bangladesh: BNBC 2020 Part 8, Chapter 1 (load estimation, substation and transformer, earthing, lightning '
      'protection). The 80 % load factor and 50 kW substation limit are BNBC 2006 values: check the BNBC 2020 text '
      'and change them if it differs, and confirm with the utility (DPDC, DESCO, BPDB, PBS). International: '
      'transformer IEC 60076 (Dyn11), HV switchgear IEC 62271, instrument transformers IEC 61869, surge arresters '
      'IEC 60099-4, lightning protection IEC 62305, short circuit IEC 60909 (infinite-bus method). Relay curve IEC '
      'Standard Inverse: t = TMS × 0.14 / ((I/Is)^0.02 − 1). LBS up to 500 kVA and VCB above is common practice; '
      'the utility has the final word. Finalise relay and CT settings with the maker\'s data and utility approval.',
);

const _trs = <double>[100, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1500, 1600, 2000, 2500, 3150];
const _nhl = <double>[63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000];
const _hvi = <double>[16, 20, 25, 31.5, 40];
const _hvb = <double>[630, 1250, 2000];
const _dropOut = <double>[6, 8, 10, 12, 15, 20, 25, 30, 40, 50, 65, 80, 100, 140, 200];
const _mcbIcu = <double>[6, 10, 16, 25];
const _alf = <double>[10, 15, 20, 30];
const _tape = <(double, String)>[(75, '25 × 3 mm'), (100, '25 × 4 mm'), (160, '40 × 4 mm'), (300, '50 × 6 mm')];

/// Rod-group factor λ for a square arrangement, by number of rods.
const _fsq = <int, double>{
  2: 2.71, 3: 4.51, 4: 5.46, 5: 6.14, 6: 6.63, 7: 7.03, 8: 7.3, 9: 7.65, 10: 7.9, 12: 8.22, 14: 8.67, //
  16: 8.95, 18: 9.22, 20: 9.4,
};

double _idmt(double i, double iset, double tms) =>
    i > iset ? tms * 0.14 / (math.pow(i / iset, 0.02) - 1) : double.infinity;

/// Single-rod resistance, then the fewest rods (square layout) that reach [target]; null rods when 20 aren't enough.
({double r1, int? rods, double rn}) _rods(double rho, double l, double d, double s, double target) {
  final r1 = rho / (2 * math.pi * l) * (math.log(4 * l / d) - 1);
  if (r1 <= target) return (r1: r1, rods: 1, rn: r1);
  final a = rho / (2 * math.pi * r1 * s);
  for (final e in _fsq.entries) {
    final v = r1 * (1 + e.value * a) / e.key;
    if (v <= target) return (r1: r1, rods: e.key, rn: v);
  }
  return (r1: r1, rods: null, rn: r1);
}

String _a(double? v, [int d = 0]) => v == null ? 'Spec sheet' : '${fmt(v, d)} A';

CalcResult computeSubstation(CalcInputs x) {
  final sq3 = math.sqrt(3);
  final hv = x.n('hv'), lv = x.n('lv');
  final pf1 = x.n('pf1'), pf2 = x.n('pf2');
  final yes = x.s('pfc') == 'yes', red = x.s('red') == 'yes';
  final oh = x.s('hvt') == 'oh', laYes = x.s('la') == 'yes', spdYes = x.s('spd') == 'yes';
  final nIn = x.n('n'), n = x.i('n');
  final sf = x.n('sf'), ovr = x.n('ovr');

  // ── Load and transformer (sub) ──
  final base = x.n('kw');
  final p = base * x.n('lf') / 100 * (1 + x.n('fut') / 100);
  final pfu = yes ? pf2 : pf1;
  final s = p / pfu;
  final share = red && n > 1 ? n - 1 : n;
  final need = s / share / sf;
  final t = ovr > 0 ? ovr : (nextUp(_trs, need) ?? _trs.last);
  final big = ovr > 0 ? false : need > _trs.last;
  final load = s / (t * n) * 100;
  final loadN1 = n > 1 ? s / (t * (n - 1)) * 100 : load;
  final zp = x.n('zp') > 0 ? x.n('zp') : (t <= 630 ? 4.0 : 6.0);
  final ihvRated = t / (sq3 * hv);
  final ilv = t * 1000 / (sq3 * lv);
  final zs = t / (x.n('ssc') * 1000);
  final isc = ilv / (zp / 100 / n + zs) / 1000;
  final ip = x.n('kap') * math.sqrt2 * isc;
  final ihvFault = x.n('ssc') / (sq3 * hv);

  final hvd = x.s('hvd'), lvd = x.s('lvd');
  final dof = hvd == 'do' || (hvd == 'auto' && t <= x.n('dolim'));
  final lbs = dof || hvd == 'lbs' || (hvd == 'auto' && t <= x.n('hvlim'));
  final lvT = lvd == 'nh'
      ? 'NH fuse-switch'
      : lvd == 'mcb'
      ? 'MCB'
      : (lvd == 'mccb' || (lvd != 'acb' && ilv <= x.n('lvlim')))
      ? 'MCCB'
      : 'ACB';
  final acb = nextUp(lvT == 'ACB' ? ElecTables.acb : (lvT == 'NH fuse-switch' ? _nhl : ElecTables.breakers), ilv);
  final fuse = nextUp(_dropOut, ihvRated);
  final double? icu = lvT == 'NH fuse-switch'
      ? 120
      : lvT == 'MCB'
      ? nextUp(_mcbIcu, isc)
      : nextUp(ElecTables.lvIcu, isc);
  final icuText = icu != null ? '${num0(icu)} kA' : (lvT == 'MCB' ? '> 25 kA' : '> 100 kA');
  final vcbPick = nextUp(_hvb, 1.25 * ihvRated);
  final double? vcb = hv == 33 ? math.max(1250, vcbPick ?? 1250) : vcbPick;
  final hvi = nextUp(_hvi, ihvFault);
  final hviText = hvi == null ? '> 40' : num0(hvi);
  final smin = ihvFault * 1000 / 143;
  final hvCable = nextUp(ElecTables.cableSizes, smin);
  final q = p * (math.tan(math.acos(pf1)) - math.tan(math.acos(pf2)));
  final bank = math.max(0, (q / 25).ceil() * 25);
  final required = p > x.n('thr');

  // ── CT, relay, LV settings, earthing (sub2) ──
  final cts = x.n('cts');
  final ctp = x.n('ctr') > 0 ? x.n('ctr') : (nextUp(ElecTables.ctPrimaries, 1.2 * ihvRated) ?? ElecTables.ctPrimaries.last);
  final iset = x.n('pk') > 0 ? x.n('pk') : 1.25 * ihvRated;
  final sec = iset * cts / ctp;
  final ps = iset / ctp;
  final irefl = isc * 1000 * lv / (hv * 1000);
  final tclr = lvT == 'ACB' ? x.n('tacb') : 0.1;
  final tt = tclr + x.n('gm');
  final t1 = _idmt(irefl, iset, 1);
  final tms = t1.isFinite ? math.min(1.0, math.max(0.05, ((tt / t1 / 0.05) - 1e-9).ceil() * 0.05)) : 0.1;
  final inst = math.max(1.3 * irefl, 12 * ihvRated);
  final im = inst / ctp;
  final alf = nextUp(_alf, im);
  final ctl = nextUp(ElecTables.ctPrimaries, ilv) ?? ElecTables.ctPrimaries.last;
  final ab = acb ?? ilv;
  final ir = math.min(1.0, ((ilv / ab / 0.05) - 1e-9).ceil() * 0.05);
  final irA = ir * ab, isd = 6 * ir * ab;
  final etg = x.n('etg');
  final rodL = x.n('rodL');
  final rods = _rods(x.n('rho'), rodL, x.n('rodD'), x.n('rodS'), etg);
  final pits = 2 * n + 2 + (oh && laYes ? 1 : 0);
  final totalPits = math.max(pits, rods.rods ?? 0);
  final se = isc * 1000 * math.sqrt(x.n('et')) / x.n('ek');
  final tape = _tape.where((e) => e.$1 >= se).firstOrNull?.$2 ?? 'Use larger / duplicate tape';
  final spdType = (x.s('lps') == 'yes' || oh) ? 'Type 1+2 (Iimp ≥ 12.5 kA per pole)' : 'Type 2 (In ≥ 20 kA)';
  final laOk = !oh || laYes;

  // ── LV cable, transformer to panel (lvCab) ──
  final ca = interp(ElecTables.ambientXlpe, x.n('lvamb'));
  final cg = interp(ElecTables.grouping, x.n('lvg'));
  final lvl = x.n('lvl');
  double vd(double size, int runs) =>
      sq3 * ilv * lvl * (0.025 / (size * runs) * 0.9 + 0.00008 / runs * 0.436) / lv * 100;
  ({int runs, double size, double vd})? cab;
  for (var runs = 1; runs <= 8 && cab == null; runs++) {
    for (var i = 0; i < ElecTables.cableSizes.length; i++) {
      final size = ElecTables.cableSizes[i];
      if (ElecTables.ratingXlpe3[i] * ca * cg * runs >= ilv && vd(size, runs) <= x.n('lvvd')) {
        cab = (runs: runs, size: size, vd: vd(size, runs));
        break;
      }
    }
  }
  final String cabText, cabPe, cabVd;
  if (cab == null) {
    cabText = 'Use busduct (cable not practical)';
    cabPe = '-';
    cabVd = '-';
  } else {
    cabPe = '${num0(ElecTables.peFor(cab.size))} mm²';
    cabVd = '${fmt(cab.vd, 2)} %';
    cabText = cab.runs > 4
        ? 'Busduct ${_a(nextUp(ElecTables.acb, ilv))} recommended (cable: ${cab.runs} × ${num0(cab.size)} mm²)'
        : '${cab.runs} × [3 × 1C ${num0(cab.size)} mm² + N ${num0(cab.size)} mm²] Cu XLPE';
  }

  final hvKind = dof ? 'Drop-out fuse only' : (lbs ? 'LBS + drop-out fuse' : 'VCB');
  final busbar = acb == null ? 'Spec sheet' : ElecTables.busbarText(acb);

  // ── Issues (errsBN) ──
  final nx = _trs.where((v) => v > t).firstOrNull;
  final ln = nx != null ? s / (nx * n) * 100 : 0.0;
  final sm = _trs.reversed.where((v) => v < t && s / (v * n) * 100 <= 80).firstOrNull;
  final n2 = n + 1;
  final t2 = nextUp(_trs, s / (red ? n2 - 1 : n2) / sf) ?? _trs.last;
  final issues = <CalcIssue>[
    if (!(base > 0)) const CalcIssue('The load is zero or empty.', 'Enter the connected load in kW.'),
    if (!(pf1 > 0 && pf1 <= 1))
      const CalcIssue(
        'Present power factor must be between 0 and 1.',
        'Use a typical value instead.',
        suggestion: 'Power factor now = 0.85',
        patch: {'pf1': 0.85},
        patchLabel: 'Use 0.85',
      ),
    if (!(pf2 > 0 && pf2 <= 1))
      const CalcIssue(
        'Target power factor must be between 0 and 1.',
        'Use the usual target.',
        suggestion: 'Target power factor = 0.95',
        patch: {'pf2': 0.95},
        patchLabel: 'Use 0.95',
      )
    else if (pf2 <= pf1 && pf1 < 0.95)
      const CalcIssue(
        'Target power factor is not above the present one, so no capacitors are sized.',
        'Set the target above the present power factor.',
        suggestion: 'Target power factor = 0.95',
        patch: {'pf2': 0.95},
        patchLabel: 'Use 0.95',
      ),
    if (!(nIn >= 1) || nIn != nIn.roundToDouble())
      CalcIssue(
        'The number of transformers must be a whole number, at least 1.',
        'Enter a whole number.',
        suggestion: 'Transformers = ${math.max(1, nIn.round())}',
        patch: {'n': math.max(1, nIn.round())},
        patchLabel: 'Fix it',
      ),
    if (red && nIn < 2)
      const CalcIssue(
        'N-1 backup needs at least 2 transformers.',
        'Use 2 transformers, or set Backup to None.',
        suggestion: 'Transformers = 2',
        patch: {'n': 2},
        patchLabel: 'Use 2',
      ),
    if (lv < 380 || lv > 440)
      const CalcIssue(
        'LV voltage is usually 400 or 415 V.',
        'Use the usual value.',
        suggestion: 'LV voltage = 415 V',
        patch: {'lv': 415},
        patchLabel: 'Use 415 V',
      ),
    if (!(x.n('ssc') > 0))
      const CalcIssue(
        'The HV source fault level (MVA) is zero or empty.',
        'Get the real value from the utility; use an assumed value for now.',
        suggestion: 'HV source fault level = 250 MVA (assumed)',
        patch: {'ssc': 250},
        patchLabel: 'Use 250',
      ),
    if (x.n('kap') < 1 || x.n('kap') > 2)
      const CalcIssue(
        'Peak factor κ is normally between 1.02 and 2.0.',
        'Use the usual value.',
        suggestion: 'Peak factor κ = 1.7',
        patch: {'kap': 1.7},
        patchLabel: 'Use 1.7',
      ),
    if (!(sf > 0 && sf <= 1))
      const CalcIssue(
        'Derating factor must be between 0 and 1 (1 = no derating).',
        'Enter a valid value.',
        suggestion: 'Derating factor = 1',
        patch: {'sf': 1},
        patchLabel: 'Use 1',
      ),
    if (big || (nx == null && load > 85))
      CalcIssue(
        big
            ? 'The load is above the largest standard transformer (3150 kVA).'
            : 'Even the largest size would be loaded above 85 %.',
        'Split the load across more transformers.',
        suggestion: 'Use $n2 × ${num0(t2)} kVA',
        patch: {'n': n2, 'ovr': 0},
        patchLabel: 'Use $n2 transformers',
      )
    else if (load > 85)
      CalcIssue(
        load > 100
            ? 'The transformer is overloaded (loading ${fmt(load, 0)} %).'
            : 'Transformer loading is above 85 %, leaving little spare capacity.',
        'The next size up gives spare capacity.',
        suggestion: 'Next size: ${num0(nx!)} kVA (loading becomes ${fmt(ln, 0)} %)',
        patch: {'ovr': nx},
        patchLabel: 'Use ${num0(nx)} kVA',
      )
    else if (load < 40 && sm != null)
      CalcIssue(
        'Transformer loading is below 40 %: it is oversized.',
        'A smaller size costs less and has lower losses.',
        suggestion: 'Smaller size: ${num0(sm)} kVA (loading becomes ${fmt(s / (sm * n) * 100, 0)} %)',
        patch: {'ovr': sm},
        patchLabel: 'Use ${num0(sm)} kVA',
      ),
    if (red && n > 1 && loadN1 > 100)
      CalcIssue(
        'With one transformer out, the others are overloaded (${fmt(loadN1, 0)} %).',
        'Make each unit big enough to carry the whole load.',
        suggestion: 'Next size: ${num0(nx ?? t2)} kVA',
        patch: {'ovr': nx ?? t2},
        patchLabel: 'Use ${num0(nx ?? t2)} kVA',
      ),
    if (zp < 3 || zp > 8)
      CalcIssue(
        'Impedance Z ${num0(zp)} % is unusual.',
        'The typical value (4 % or 6 %) is used automatically.',
        suggestion: 'Impedance Z = auto (typical)',
        patch: const {'zp': 0},
        patchLabel: 'Use auto',
      ),
    if (lvT == 'MCB' && (ilv > 125 || isc > 25))
      CalcIssue(
        'An MCB (IEC 60898-1) can\'t be used above 125 A or 25 kA. Here the current is ${fmt(ilv, 0)} A and the '
            'fault ${fmt(isc, 1)} kA.',
        'Use an MCCB or ACB (IEC 60947-2) as the transformer LV incomer.',
        suggestion: 'LV incomer = MCCB / ACB (auto)',
        patch: const {'lvd': 'auto'},
        patchLabel: 'Use auto',
      ),
    if (dof && t > x.n('dolim'))
      CalcIssue(
        'Above ${num0(x.n('dolim'))} kVA HT switchgear (LBS or VCB) is needed; drop-out fuses alone are not enough.',
        'Use an LBS with drop-out fuses.',
        suggestion: 'HV protection = LBS + drop-out fuse',
        patch: const {'hvd': 'lbs'},
        patchLabel: 'Use LBS',
      ),
    if (lbs && t > x.n('hvlim'))
      CalcIssue(
        'Above ${num0(x.n('hvlim'))} kVA a VCB is required on the HV side; LBS + fuse is not enough.',
        'Set HV protection to VCB.',
        suggestion: 'HV protection = VCB + relay',
        patch: const {'hvd': 'vcb'},
        patchLabel: 'Use VCB',
      ),
    if (lvT != 'MCB' && icu == null)
      CalcIssue(
        'The LV fault current is above 100 kA; no ACB Icu covers it.',
        'Check the HV fault level, or choose a higher impedance.',
        suggestion: 'Impedance Z = ${num0(zp + 1)} % (reduces fault current)',
        patch: {'zp': zp + 1},
        patchLabel: 'Raise Z',
      ),
    if (!lbs && im > 30)
      CalcIssue(
        'The instantaneous setting is more than 30 × the CT primary; the CT may saturate.',
        'Use a larger CT primary.',
        suggestion: 'CT primary ≥ ${_ctText(nextUp(ElecTables.ctPrimaries, inst / 30))}',
      ),
    if (!lbs && inst > 0.8 * ihvFault * 1000)
      const CalcIssue(
        'The instantaneous setting is very close to the HV fault current.',
        'Check the source fault level and agree the settings with the relay engineer.',
        suggestion: 'Check the source fault level with the utility',
      ),
    if (!lbs && ps < 0.5)
      CalcIssue(
        'The plug setting is below 0.5 × In and may be outside the relay\'s range.',
        'Use a smaller CT primary.',
        suggestion: 'CT primary = ${num0(nextUp(ElecTables.ctPrimaries, iset) ?? ctp)} A',
      ),
    if (rods.rods == null) _rodIssue(x, etg),
    if (!laOk)
      CalcIssue(
        'The HV line is overhead but there is no lightning arrester.',
        'Fit one lightning arrester per phase at the HV incoming point.',
        suggestion: 'LA: ${hv == 11 ? 12 : 36} kV, 10 kA, one per phase',
        patch: const {'la': 'yes'},
        patchLabel: 'Mark LA fitted',
      ),
    if (!spdYes)
      CalcIssue(
        'There is no surge protector (SPD) in the LV main panel.',
        'Fit an SPD at the LV incomer.',
        suggestion: spdType,
        patch: const {'spd': 'yes'},
        patchLabel: 'Mark SPD fitted',
      ),
  ];

  final loadOk = load >= 40 && load <= 85;
  final relayRows = lbs
      ? [
          ResultRow('Transformer', 'Drop-out fuse ${_a(fuse)}'),
          const ResultRow('Relay 50/51', 'Not needed'),
        ]
      : [
          ResultRow('51 pickup', '${fmt(iset, 1)} A = ${fmt(sec, 2)} A on relay (${fmt(ps, 2)} × In)'),
          ResultRow('CT / rule', '${num0(ctp)}/${num0(cts)} : ${fmt(iset, 1)} × ${num0(cts)} ÷ ${num0(ctp)}'),
          ResultRow('Curve / TMS', 'Standard Inverse / ${fmt(tms, 2)}'),
          ResultRow('50 instantaneous', '${fmt(inst, 0)} A'),
          ResultRow('51N earth fault', '${fmt(0.2 * ctp, 1)} A'),
        ];
  final adjustable = lvT == 'ACB' || lvT == 'MCCB';

  return CalcResult(
    headline: CalcHeadline(
      'Transformer',
      '$n × ${num0(t)} kVA',
      caption: 'Loading ${fmt(load, 0)} % (good: 50-80 %) · ${fmt(s, 0)} kVA design load',
    ),
    metrics: [
      ResultRow('HV current', '${fmt(ihvRated, 1)} A'),
      ResultRow('LV current', '${fmt(ilv, 0)} A'),
      ResultRow('Earthing', '$totalPits electrodes'),
    ],
    sections: [
      ResultSection('Load', [
        ResultRow('Connected load', '${fmt(base, 1)} kW'),
        ResultRow('After load factor and expansion', '${fmt(p, 1)} kW'),
        ResultRow('Apparent power', '${fmt(s, 0)} kVA'),
        ResultRow(
          'Substation needed (above ${num0(x.n('thr'))} kW)',
          required ? 'Yes' : 'No',
          tone: required ? Tone.bad : Tone.ok,
        ),
      ]),
      ResultSection('Transformer', [
        ResultRow('Size', '$n × ${num0(t)} kVA'),
        ResultRow('Loading', '${fmt(load, 0)} %', tone: loadOk ? Tone.ok : Tone.bad),
        ResultRow('Needed per unit', '${fmt(need, 0)} kVA'),
        ResultRow('Vector group / Z', 'Dyn11 / ${num0(zp)} %'),
        if (n > 1) ResultRow('Loading (one out)', '${fmt(loadN1, 0)} %', tone: loadN1 > 100 ? Tone.bad : Tone.normal),
        ResultRow('Type', x.s('tt') == 'oil' ? 'Oil, ONAN' : 'Cast resin'),
      ]),
      ResultSection('HV switchgear (${num0(hv)} kV, $hvKind)', [
        if (lbs) ...[
          if (!dof) ResultRow('Load break switch', '630 A, $hviText kA / 1 s'),
          ResultRow('Drop-out fuse link (3 ×)', '${_a(fuse)}, T type'),
        ] else ...[
          ResultRow('Breaker rating', _a(vcb)),
          ResultRow('Breaking capacity ≥', '$hviText kA'),
        ],
        ResultRow('Cable min by fault', '${fmt(smin, 0)} mm² → ${hvCable == null ? 'Spec sheet' : '${num0(hvCable)} mm²'}'),
      ]),
      ResultSection('LV incomer ($lvT)', [
        ResultRow('$lvT rating', _a(acb)),
        ResultRow('Icu ≥', icuText),
        ResultRow('Busbar', busbar),
        ResultRow('LV cable (to panel)', cabText, tone: cab == null ? Tone.bad : Tone.normal),
        ResultRow('Cable earth (PE)', cabPe),
        ResultRow('Voltage drop', cabVd),
      ]),
      ResultSection('Short circuit', [
        ResultRow('LV fault', '${fmt(isc, 1)} kA'),
        ResultRow('Peak current', '${fmt(ip, 1)} kA'),
        ResultRow('HV fault', '${fmt(ihvFault, 1)} kA'),
      ]),
      ResultSection('CT and PT', [
        if (!lbs) ResultRow('HV protection CT', '${num0(ctp)}/${num0(cts)} A, 5P${alf == null ? '>30' : num0(alf)}, 15 VA'),
        ResultRow('HV metering CT', '${num0(ctp)}/${num0(cts)} A, Cl 0.5'),
        ResultRow('LV metering CT', '${num0(ctl)}/5 A, Cl 0.5'),
        ResultRow('HV PT', '${num0(hv * 1000)}/√3 : 110/√3 V'),
        const ResultRow('PT class / burden', '0.5 + 3P, 50 VA'),
        const ResultRow('LV', 'Direct, no PT'),
      ]),
      ResultSection(
        lbs ? 'HV protection' : 'HV relay 50/51, 51N',
        relayRows,
        note: lbs ? 'Add a relay and CT only if the utility asks for a VCB.' : null,
      ),
      ResultSection('LV $lvT settings', [
        if (adjustable) ...[
          ResultRow('Ir (long time)', '${fmt(irA, 0)} A'),
          ResultRow('Isd / tsd', '${fmt(isd, 0)} A / ${fmt(tclr, 1)} s'),
          if (lvT == 'ACB') ResultRow('Ig (ground fault)', '${fmt(0.2 * ab, 0)} A'),
        ] else ...[
          const ResultRow('Trip settings', 'Fixed, none to set'),
          const ResultRow('Clearing time', '< 0.1 s'),
        ],
      ]),
      ResultSection('Earthing', [
        ResultRow('Neutral (2 per transformer)', '${2 * n}'),
        const ResultRow('Body / equipment', '2'),
        ResultRow('Lightning arrester', '${oh && laYes ? 1 : 0}'),
        ResultRow('Minimum by practice', '$pits'),
        ResultRow(
          'Rods for ≤ ${num0(etg)} Ω',
          rods.rods == null ? '> 20' : '${rods.rods} rods (${fmt(rods.rn, 2)} Ω)',
          tone: rods.rods == null ? Tone.bad : Tone.ok,
        ),
        ResultRow('Install at least', '$totalPits electrodes'),
        ResultRow('Copper strap', '${fmt(se, 0)} mm² → $tape'),
      ]),
      ResultSection('Lightning protection', [
        ResultRow(
          'Lightning arrester',
          oh ? (laYes ? 'OK' : 'MISSING') : 'Not needed (cable)',
          tone: laOk ? Tone.ok : Tone.bad,
        ),
        if (oh) ResultRow('LA rating', '${hv == 11 ? '12' : '36'} kV, 10 kA'),
        ResultRow('LV surge protector', spdYes ? 'OK' : 'MISSING', tone: spdYes ? Tone.ok : Tone.bad),
        ResultRow('SPD type', spdType),
        ResultRow('Building protection', x.s('lps') == 'yes' ? 'Present, bond to earth' : 'Check IEC 62305-2'),
      ]),
      ResultSection('Power factor correction', [
        ResultRow('Capacitor needed', '${fmt(q, 0)} kVAR'),
        ResultRow('APFC bank', '$bank kVAR'),
      ]),
      ResultSection('Required components', [
        ResultRow(
          'Lightning arrester (3)',
          oh ? '${hv == 11 ? '12' : '36'} kV, 10 kA (IEC 60099-4)' : 'Optional (cable supply)',
        ),
        lbs
            ? ResultRow('Drop-out fuse (3)', '${_a(fuse)} link, T type, 12 kV (IEC 60282-2)')
            : const ResultRow('Drop-out fuse (0)', 'Not used with VCB'),
        dof
            ? ResultRow('HT switchgear (none)', 'Not used up to ${num0(x.n('dolim'))} kVA')
            : lbs
            ? ResultRow('HT switchgear (1)', 'LBS ${num0(hv)} kV, 630 A (IEC 62271-103), manual')
            : ResultRow('HT switchgear (1)', 'VCB ${_a(vcb)} + relay, CT, PT (IEC 62271-100)'),
        const ResultRow('Energy meter (1)', '3-phase, CT operated /5 A, Class 0.5S (IEC 62053-22)'),
      ]),
    ],
    issues: issues,
    steps: [
      CalcStep(
        'Design load',
        'P = Load × Load factor × (1 + Expansion)',
        '${fmt(base, 1)} × ${num0(x.n('lf'))} % × (1 + ${num0(x.n('fut'))} %)',
        '${fmt(p, 1)} kW',
      ),
      CalcStep('Apparent power', 'S = P / PF', '${fmt(p, 1)} / $pfu', '${fmt(s, 0)} kVA'),
      CalcStep(
        'Transformer size',
        'Per unit = S / units sharing / derating, next standard',
        '${fmt(s, 0)} / $share / ${num0(sf)} = ${fmt(need, 0)}',
        '$n × ${num0(t)} kVA, loading ${fmt(load, 0)} %',
      ),
      CalcStep('HV rated current', 'I = kVA / (√3 × kV)', '${num0(t)} / (√3 × ${num0(hv)})', '${fmt(ihvRated, 1)} A'),
      CalcStep('LV rated current', 'I = kVA / (√3 × kV)', '${num0(t)} / (√3 × ${num0(lv / 1000)})', '${fmt(ilv, 0)} A'),
      CalcStep(
        'LV fault current',
        'Ik = In / (Zt/n + Zs), Zs = kVA / source kVA',
        '${fmt(ilv, 0)} / (${fmt(zp / 100, 3)}/$n + ${fmt(zs, 4)})',
        '${fmt(isc, 1)} kA (peak ${fmt(ip, 1)} kA)',
      ),
      CalcStep(
        'HV protection',
        dof
            ? 'Drop-out fuse link = next standard ≥ HV current'
            : lbs
            ? 'LBS + drop-out fuse link ≥ HV current'
            : 'VCB rating ≥ 1.25 × HV current',
        lbs ? '${fmt(ihvRated, 1)} A' : '1.25 × ${fmt(ihvRated, 1)} = ${fmt(1.25 * ihvRated, 1)}',
        lbs ? '${_a(fuse)} link' : '${_a(vcb)} VCB',
      ),
      CalcStep(
        'LV incomer',
        'Rating ≥ LV rated current; Icu ≥ LV fault',
        '${fmt(ilv, 0)} A, ${fmt(isc, 1)} kA',
        '$lvT ${_a(acb)}, Icu $icuText',
      ),
      CalcStep(
        'LV cable (transformer to panel)',
        'n × S × Ca × Cg ≥ I, voltage drop ≤ ${num0(x.n('lvvd'))} %',
        'Ca ${fmt(ca, 2)}, Cg ${fmt(cg, 2)}, length ${num0(lvl)} m, I ${fmt(ilv, 0)} A',
        '$cabText, PE $cabPe, drop $cabVd',
      ),
      CalcStep(
        'LV busbar',
        'Area = rating / 1.6, then nearest standard bar',
        '${_a(acb)} / 1.6 = ${acb == null ? '-' : fmt(acb / 1.6, 0)} mm²',
        busbar,
      ),
      CalcStep(
        'CT ratio',
        'Primary ≥ 1.2 × HV current (market list)',
        '1.2 × ${fmt(ihvRated, 1)} = ${fmt(1.2 * ihvRated, 1)}',
        '${num0(ctp)}/${num0(cts)} A',
      ),
      CalcStep(
        'Relay pickup (secondary)',
        'Setting = Pickup × CT secondary / CT primary',
        '${fmt(iset, 1)} × ${num0(cts)} / ${num0(ctp)}',
        '${fmt(sec, 2)} A (${fmt(ps, 2)} × In)',
      ),
      CalcStep(
        'Earth resistance',
        'Rod R = ρ/(2πL) × [ln(4L/d) − 1]; rods for target',
        '${fmt(x.n('rho'), 0)} Ω·m, L ${num0(rodL)} m, target ${num0(etg)} Ω',
        '${rods.rods == null ? '> 20 rods' : '${rods.rods} rods (${fmt(rods.rn, 2)} Ω)'}, install $totalPits',
      ),
      CalcStep(
        'Earth strap',
        'S = Ik × √t / k',
        '${fmt(isc * 1000, 0)} × √${num0(x.n('et'))} / ${num0(x.n('ek'))}',
        '${fmt(se, 0)} mm² → $tape',
      ),
      CalcStep(
        'Power factor correction',
        'Qc = P × (tan(acos PF1) − tan(acos PF2))',
        '${fmt(p, 1)} × (${fmt(math.tan(math.acos(pf1)), 3)} − ${fmt(math.tan(math.acos(pf2)), 3)})',
        '${fmt(q, 0)} kVAR, bank $bank kVAR',
      ),
    ],
  );
}

String _ctText(double? c) => c == null ? '> 6000 A' : '${num0(c)} A';

/// The earth target can't be met with 20 rods: suggest a longer rod that reaches it, if one does.
CalcIssue _rodIssue(CalcInputs x, double etg) {
  final l = <double>[4, 5, 6, 9, 12]
      .where((l) => l > x.n('rodL') && _rods(x.n('rho'), l, x.n('rodD'), x.n('rodS'), etg).rods != null)
      .firstOrNull;
  final rods = l == null ? null : _rods(x.n('rho'), l, x.n('rodD'), x.n('rodS'), etg).rods;
  return CalcIssue(
    'The earth resistance target (${num0(etg)} Ω) is not reached even with 20 rods.',
    'Use longer rods or an earth grid, with bentonite.',
    suggestion: l == null ? 'Use bentonite and an earth grid' : 'Rod length ${num0(l)} m needs $rods rods',
    patch: l == null ? null : {'rodL': l},
    patchLabel: l == null ? null : 'Use ${num0(l)} m rods',
  );
}
