import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/calc_inputs.dart';
import '../domain/calc_module.dart';
import '../domain/calc_result.dart';
import '../domain/electrical_tables.dart';

bool _notOffgrid(CalcInputs x) => x.s('type') != 'offgrid';
bool _gridSanction(CalcInputs x) => x.s('type') == 'netmeter' || x.s('type') == 'ongrid';
bool _netmeter(CalcInputs x) => x.s('type') == 'netmeter';
bool _battery(CalcInputs x) => x.s('type') == 'offgrid' || x.s('type') == 'hybrid';
bool _offgrid(CalcInputs x) => x.s('type') == 'offgrid';
bool _hybrid(CalcInputs x) => x.s('type') == 'hybrid';

/// Solar PV system design: array, strings, inverter, cables, protection and
/// battery (IEC 62548-1, IEC 60364-7-712, SREDA net metering).
final solarModule = CalcModule(
  id: 'solar',
  title: 'Solar PV system',
  shortTitle: 'Solar\nPV',
  subtitle: 'Array, strings, inverter, battery, cables',
  icon: Icons.solar_power_outlined,
  color: AppColors.tileAmber,
  defaults: const {
    'type': 'netmeter',
    'E': 30,
    'peak': 8,
    'sanc': 10,
    'trf': 0,
    'psh': 4.5,
    'pr': 0.78,
    'off': 100,
    'roof': 150,
    'lim': 0,
    'strs': 0,
    'mps': 0,
    'wp': 550,
    'voc': 49.8,
    'vmp': 41.8,
    'isc': 14,
    'gam': 0.27,
    'pgam': 0.34,
    'area': 2.58,
    'mfs': 25,
    'vdc': 1100,
    'mpmin': 200,
    'mpmax': 1000,
    'imppt': 40,
    'nmppt': 2,
    'tmin': 5,
    'tmax': 70,
    'ratio': 1.15,
    'ph': 'auto',
    'vac': 415,
    'lac': 20,
    'ldc': 30,
    'lmain': 15,
    'vd': 1,
    'vdac': 2,
    'rfa': 60,
    'lps': 'no',
    'chem': 'lfp',
    'dod': 0,
    'aut': 1,
    'bh': 4,
    'crit': 3,
  },
  groups: const [
    FieldGroup('System', [
      ChoiceField('type', 'System type', [
        CalcOption('ongrid', 'On-grid', detail: 'Grid-tied, no battery, self-consumption'),
        CalcOption('offgrid', 'Off-grid', detail: 'Stand-alone with battery, no grid'),
        CalcOption('hybrid', 'Hybrid', detail: 'Grid + PV + battery backup'),
        CalcOption('netmeter', 'Net metering', detail: 'Exports to the utility, bidirectional meter'),
      ]),
      NumberField('E', 'Daily energy use', unit: 'kWh/day'),
      NumberField('peak', 'Peak load', unit: 'kW'),
      NumberField('off', 'Offset target', unit: '%', visibleIf: _notOffgrid),
      NumberField('sanc', 'Sanctioned load', unit: 'kW', visibleIf: _gridSanction),
      NumberField('trf', 'Transformer', unit: 'kVA', help: '0 = LV supply', visibleIf: _netmeter),
    ]),
    FieldGroup('Site & module', [
      NumberField('psh', 'Peak sun hours', positive: true, unit: 'h'),
      NumberField('pr', 'Performance ratio', positive: true),
      NumberField('roof', 'Roof area', unit: 'm²'),
      NumberField('wp', 'Module power', positive: true, unit: 'Wp'),
      NumberField('voc', 'Module Voc', positive: true, unit: 'V'),
      NumberField('vmp', 'Module Vmp', positive: true, unit: 'V'),
      NumberField('isc', 'Module Isc', positive: true, unit: 'A'),
      NumberField('area', 'Module area', positive: true, unit: 'm²'),
      NumberField('gam', 'Voc/Vmp coefficient', unit: '%/°C'),
      NumberField('pgam', 'Pmax coefficient', unit: '%/°C'),
      NumberField('mfs', 'Max series fuse', unit: 'A'),
      NumberField('tmin', 'Lowest air temp', unit: '°C'),
      NumberField('tmax', 'Hottest cell temp', unit: '°C'),
    ]),
    FieldGroup('Inverter', advanced: true, [
      NumberField('lim', 'Limit array to', unit: 'kWp', help: '0 = none'),
      NumberField('mps', 'Modules per string', integer: true, help: '0 = auto'),
      NumberField('strs', 'Number of strings', integer: true, help: '0 = auto'),
      NumberField('vdc', 'Max DC voltage', positive: true, unit: 'V'),
      NumberField('mpmin', 'MPPT min', positive: true, unit: 'V'),
      NumberField('mpmax', 'MPPT max', positive: true, unit: 'V'),
      NumberField('imppt', 'Max Isc per MPPT', positive: true, unit: 'A'),
      NumberField('nmppt', 'MPPT inputs', positive: true, integer: true),
      NumberField('ratio', 'DC / AC ratio', positive: true),
      ChoiceField('ph', 'AC phase', [
        CalcOption('auto', 'Auto'),
        CalcOption('1', '1-phase 230 V'),
        CalcOption('3', '3-phase'),
      ]),
      NumberField('vac', 'AC voltage', positive: true, unit: 'V'),
    ]),
    FieldGroup('Cables & protection', advanced: true, [
      NumberField('ldc', 'DC string cable', unit: 'm'),
      NumberField('lmain', 'DC main cable', unit: 'm'),
      NumberField('lac', 'AC cable', unit: 'm'),
      NumberField('rfa', 'Roof cable ambient', unit: '°C'),
      NumberField('vd', 'DC drop limit', unit: '%'),
      NumberField('vdac', 'AC drop limit', unit: '%'),
      ChoiceField('lps', 'Lightning protection system', [CalcOption('no', 'No'), CalcOption('yes', 'Yes')]),
    ]),
    FieldGroup('Battery', visibleIf: _battery, [
      ChoiceField('chem', 'Battery type', [
        CalcOption('lfp', 'LFP (LiFePO4)'),
        CalcOption('vrla', 'VRLA AGM / GEL'),
        CalcOption('opzs', 'OPzS / OPzV tubular'),
      ]),
      NumberField('dod', 'Depth of discharge', unit: '%', help: '0 = default for the type'),
      NumberField('aut', 'Autonomy', unit: 'days', visibleIf: _offgrid),
      NumberField('bh', 'Backup time', unit: 'h', visibleIf: _hybrid),
      NumberField('crit', 'Critical load', unit: 'kW', visibleIf: _hybrid),
    ]),
  ],
  compute: computeSolar,
  basis:
      'PV array design IEC 62548-1:2023+AMD1:2025 (string voltage, cable 1.25 × Isc, fuses 1.5 to 2.4 × Isc). '
      'Installation IEC 60364-7-712; commissioning IEC 62446-1:2016+AMD1:2018; modules IEC 61215-1:2021, '
      'IEC 61730-1:2023; inverters IEC 62109-1/-2, anti-islanding IEC 62116:2014; PV cable IEC 62930; PV fuse '
      'IEC 60269-6; DC switch IEC 60947-3; SPD IEC 61643-31 / -11; batteries IEC 62619, IEC 63056, IEC 61427-1; '
      'transfer switch IEC 60947-6-1. String voltage is checked at the coldest temperature (Voc rises) and the '
      'hottest (Vmp falls). Net metering: Bangladesh Net Metering Guideline 2025 (SREDA), up to 100 % of the '
      'sanctioned load and 80 % of the transformer rating, as reported; confirm with SREDA and your utility.',
);

const _pvCables = <double>[4, 6, 10, 16, 25, 35, 50, 70, 95];
const _inverters = <double>[1, 2, 3, 3.6, 5, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50, 60, 80, 100, 125, 150, 200, 250];
const _pvFuses = <double>[10, 12, 15, 16, 20, 25, 30, 32, 40];
const _dcVolts = <double>[600, 800, 1000, 1100, 1200, 1500];
const _dcAmps = <double>[16, 25, 32, 40, 50, 63, 80, 100, 125];
const _chargers = <double>[20, 30, 40, 60, 80, 100, 150];
const _spdVolts = <double>[600, 800, 1000, 1200, 1500];

typedef _Chem = ({String name, double dod, double eta, double c, String life});
const _chem = <String, _Chem>{
  'lfp': (name: 'LFP (LiFePO4)', dod: 0.9, eta: 0.95, c: 0.5, life: '4000-6000 cycles at 80 % DoD'),
  'vrla': (name: 'VRLA AGM / GEL', dod: 0.5, eta: 0.85, c: 0.2, life: '500-1000 cycles at 50 % DoD'),
  'opzs': (name: 'OPzS / OPzV tubular', dod: 0.65, eta: 0.85, c: 0.2, life: '1500-3000 cycles at 65 % DoD'),
};
const _typeName = {'ongrid': 'On-grid', 'offgrid': 'Off-grid', 'hybrid': 'Hybrid', 'netmeter': 'Net metering'};

/// Rating of a PV cable size (single-core XLPE table).
double _pvRating(double s) => ElecTables.ratingXlpe1[ElecTables.cableSizes.indexOf(s)];

CalcResult computeSolar(CalcInputs x) {
  final sq3 = math.sqrt(3);
  final t = _typeName.containsKey(x.s('type')) ? x.s('type') : 'netmeter';
  final offgrid = t == 'offgrid', hybrid = t == 'hybrid', netmeter = t == 'netmeter';
  final bat = offgrid || hybrid;
  final cm = _chem[x.s('chem')] ?? _chem['lfp']!;
  final dod = x.n('dod') > 0 ? x.n('dod') / 100 : cm.dod;
  final e = x.n('E'), psh = x.n('psh'), pr = x.n('pr'), wp = x.n('wp');

  // Array size.
  final epv = offgrid
      ? e / cm.eta
      : hybrid
      ? e * x.n('off') / 100 * (1 + 0.4 * (1 / cm.eta - 1))
      : e * x.n('off') / 100;
  final wanted = epv / (psh * pr);
  var kWr = wanted;
  const none = 1e9;
  final cap = netmeter
      ? math.min(x.n('sanc') > 0 ? x.n('sanc') : none, x.n('trf') > 0 ? 0.8 * x.n('trf') : none)
      : none;
  if (x.n('lim') > 0) kWr = math.min(kWr, x.n('lim'));
  if (cap < none) kWr = math.min(kWr, cap);
  final limited = kWr < wanted - 1e-9;
  final nReq = math.max(1, limited ? (kWr * 1000 / wp + 1e-9).floor() : (kWr * 1000 / wp - 1e-9).ceil());
  final nRoof = (x.n('roof') / (x.n('area') * 1.4)).floor();
  final nm = math.max(1, math.min(nReq, nRoof));

  // Strings, corrected for temperature.
  final f1 = 1 + (-x.n('gam') / 100) * (x.n('tmin') - 25);
  final vocCold = x.n('voc') * f1, vmpCold = x.n('vmp') * f1;
  final vmpHot = x.n('vmp') * (1 - x.n('pgam') / 100 * (x.n('tmax') - 25));
  final nMax = math.min((x.n('vdc') / vocCold).floor(), (x.n('mpmax') / vmpCold).floor());
  final nMin = (x.n('mpmin') / vmpHot).ceil();
  final nsAuto = math.max(1, math.min(nMax, nm));
  final ns = x.n('mps') > 0 ? x.i('mps') : nsAuto;
  final ssAuto = math.max(1, (nm / ns).round());
  final ss = x.n('strs') > 0 ? x.i('strs') : ssAuto;
  final nt = ss * ns;
  final kWp = nt * wp / 1000;

  final isc = x.n('isc');
  final spm = math.max(1, (x.n('imppt') / isc).floor());
  final k = math.min(ss, spm);
  final mpptNeeded = (ss / spm).ceil();
  final invNeeded = math.max(1, (mpptNeeded / x.n('nmppt')).ceil());
  final vString = ns * vocCold;

  // Inverter.
  final pReq = offgrid
      ? x.n('peak') * 1.25
      : hybrid
      ? math.max(kWp / x.n('ratio'), x.n('crit') * 1.25)
      : kWp / x.n('ratio');
  var pac = nextUp(_inverters, pReq);
  var ni = 1;
  if (pac == null) {
    pac = _inverters.last;
    ni = (pReq / pac).ceil();
  }
  final ph = x.s('ph') == '1'
      ? 1
      : x.s('ph') == '3'
      ? 3
      : (pac * ni <= 5 ? 1 : 3);
  final iac = ph == 3 ? pac * 1000 / (sq3 * x.n('vac')) : pac * 1000 / 230;
  final vph = ph == 3 ? x.n('vac') : 230.0;

  // DC cables.
  final ca = interp(ElecTables.ambientXlpe, x.n('rfa'));
  const rho = 0.025;
  final iString = 1.25 * isc;
  double vdd(double s, double i, double l, double v) => 2 * i * l * rho / s / v * 100;
  final vmpString = ns * x.n('vmp');
  double? stringCable;
  for (final s in _pvCables) {
    if (_pvRating(s) * ca >= iString && vdd(s, isc * 0.95, x.n('ldc'), vmpString) <= x.n('vd')) {
      stringCable = s;
      break;
    }
  }
  final iMain = 1.25 * k * isc;
  double? mainCable;
  for (final s in _pvCables) {
    if (_pvRating(s) * ca >= iMain && vdd(s, k * isc * 0.95, x.n('lmain'), vmpString) <= x.n('vd')) {
      mainCable = s;
      break;
    }
  }

  // DC protection.
  final needFuse = k >= 3;
  final fuse = nextUp(_pvFuses, 1.5 * isc);
  final fuseOk = fuse != null && fuse <= x.n('mfs') && fuse <= 2.4 * isc * 1.05;
  final ue = nextUp(_dcVolts, vString) ?? 1500;
  final ie = nextUp(_dcAmps, iMain);
  final ucp = nextUp(_spdVolts, 1.1 * vString) ?? 1500;
  final lps = x.s('lps') == 'yes';
  final pe = lps ? 16.0 : 6.0;

  // AC side.
  final acBreaker = ElecTables.nextBreaker(1.25 * iac);
  final acTab = ph == 3 ? ElecTables.ratingPvc3 : ElecTables.ratingPvc1;
  final cp = interp(ElecTables.ambientPvc, 35);
  double? acCable;
  for (var i = 0; i < ElecTables.cableSizes.length; i++) {
    final s = ElecTables.cableSizes[i];
    if (s < 2.5 || acTab[i] * cp < acBreaker) continue;
    final drop = (ph == 3 ? sq3 : 2) * iac * x.n('lac') * (rho / s * 0.95 + 0.00008 * 0.31) / vph * 100;
    if (drop <= x.n('vdac')) {
      acCable = s;
      break;
    }
  }
  final annual = kWp * psh * 365 * pr;

  // Battery.
  ({
    double eu,
    double en,
    double vb,
    double ah,
    double id,
    double cr,
    double? cable,
    int mods,
    int par,
    double ser,
    double? fuse,
    double cc,
    int ncc,
    bool heavy,
  })?
  b;
  if (bat) {
    final eu = offgrid ? e * x.n('aut') : x.n('crit') * x.n('bh');
    final en = eu / (dod * 0.92);
    final pi = offgrid ? pac : math.min(pac, x.n('crit') * 1.25);
    final vb = pi <= 1
        ? 12.0
        : pi <= 3
        ? 24.0
        : pi <= 15
        ? 48.0
        : 384.0;
    final ah = en * 1000 / vb;
    final id = pi * 1000 / (vb * 0.92);
    final ib = 1.25 * id;
    final cb = interp(ElecTables.ambientXlpe, 40);
    double? cable;
    for (final s in _pvCables) {
      if (_pvRating(s) * cb >= ib && vdd(s, id, 3, vb) <= 1) {
        cable = s;
        break;
      }
    }
    final ich = kWp * 1000 / vb;
    final cc = nextUp(_chargers, ich) ?? 150;
    b = (
      eu: eu,
      en: en,
      vb: vb,
      ah: ah,
      id: id,
      cr: id / ah,
      cable: cable,
      mods: (en / 5.12).ceil(),
      par: (ah / 200).ceil(),
      ser: vb <= 48 ? vb / 12 : 0,
      fuse: nextUp(ElecTables.breakers, ib),
      cc: cc,
      ncc: (ich / cc).ceil(),
      heavy: id / ah > cm.c,
    );
  }

  String mm(double? s) => s == null ? '-' : '${num0(s)} mm²';
  final invText = '${ni > 1 ? '$ni × ' : ''}${num0(pac)} kW';

  final issues = <CalcIssue>[
    if (ns < nMin)
      CalcIssue(
        'Too few modules per string: in hot weather the voltage falls below the inverter\'s MPPT minimum.',
        'Use more modules per string, or an inverter with a lower MPPT minimum.',
        suggestion: 'Modules per string must be at least $nMin',
      ),
    if (netmeter && kWp > cap + 0.01)
      CalcIssue(
        'The array is above the net-metering limit (${fmt(cap, 1)} kW).',
        'Keep the array within the limit.',
        suggestion: 'Limit the array to ${fmt(cap, 1)} kWp',
        patch: {'lim': double.parse(cap.toStringAsFixed(2))},
        patchLabel: 'Set the limit',
      ),
    if (nRoof < nReq)
      CalcIssue(
        'The roof is too small: $nReq modules are needed but only $nRoof fit.',
        'Use higher-wattage modules or more roof area.',
        suggestion: 'Modules that fit: $nRoof (${fmt(nRoof * wp / 1000, 1)} kWp)',
      ),
    if (ns > nMax)
      CalcIssue(
        'Too many modules per string: in cold weather the voltage exceeds the inverter maximum (${num0(x.n('vdc'))} V).',
        'Use fewer modules per string.',
        suggestion: 'Modules per string ≤ $nMax',
        patch: {'mps': nMax},
        patchLabel: 'Use $nMax',
      ),
    if (nt > nRoof && nRoof >= nReq)
      CalcIssue(
        'The $nt modules placed do not fit on the roof (only $nRoof fit).',
        'Use fewer strings or fewer modules per string.',
        suggestion: 'Modules that fit: $nRoof',
      ),
    if (invNeeded > 1)
      CalcIssue(
        'The inverter has too few MPPT inputs: $invNeeded inverters are needed.',
        'Choose an inverter with more MPPT inputs.',
        suggestion: 'Inverters needed: $invNeeded',
      ),
    if (stringCable == null)
      const CalcIssue(
        'Even a 95 mm² string cable is over the voltage-drop limit.',
        'Shorten the DC cable run or raise the limit.',
      ),
    if (acCable == null)
      const CalcIssue('No AC cable meets the voltage-drop limit.', 'Shorten the AC cable run or raise the limit.'),
    if (needFuse && !fuseOk)
      CalcIssue(
        'The string fuse exceeds the module\'s maximum series fuse rating (${num0(x.n('mfs'))} A).',
        'Check the module datasheet, or use fewer parallel strings.',
        suggestion: 'gPV fuse ${fuse == null ? '-' : num0(fuse)} A vs module limit ${num0(x.n('mfs'))} A',
      ),
    if (b != null && b.heavy)
      CalcIssue(
        'The battery discharge rate (${fmt(b.cr, 2)} C) is too high for ${cm.name}.',
        'Increase the battery capacity or use a smaller inverter.',
        suggestion: 'Battery capacity ≥ ${fmt(b.id / cm.c / 1000 * b.vb, 1)} kWh',
      ),
  ];

  final steps = <CalcStep>[
    CalcStep(
      'PV energy needed',
      offgrid
          ? 'E / battery efficiency'
          : hybrid
          ? 'E × offset × battery loss on 40 % share'
          : 'E × offset',
      offgrid ? '${num0(e)} / ${cm.eta}' : '${num0(e)} × ${num0(x.n('off') / 100)}',
      '${fmt(epv, 1)} kWh/day',
    ),
    CalcStep('Array size', 'kWp = E / (PSH × PR)', '${fmt(epv, 1)} / (${num0(psh)} × ${num0(pr)})', '${fmt(kWr, 2)} kWp'),
    CalcStep(
      'Voc and Vmp at ${num0(x.n('tmin'))} °C',
      'Voc × (1 + coeff × (25 − Tmin))',
      '${num0(x.n('voc'))} × ${fmt(f1, 3)}',
      '${fmt(vocCold, 1)} V / ${fmt(vmpCold, 1)} V',
    ),
    CalcStep('Vmp at ${num0(x.n('tmax'))} °C', 'Vmp × (1 − coeff × (T − 25))', '${num0(x.n('vmp'))} × ${fmt(vmpHot / x.n('vmp'), 3)}', '${fmt(vmpHot, 1)} V'),
    CalcStep(
      'Modules per string',
      'Max = min(Vdc max / Voc cold, MPPT max / Vmp cold); min = MPPT min / Vmp hot',
      'max $nMax, min $nMin',
      '$ns per string',
    ),
    CalcStep('Strings', 'Modules needed $nm / $ns, $spm strings per MPPT input', '$ss × $ns', '$ss strings, $nt modules, ${fmt(kWp, 2)} kWp'),
    CalcStep(
      'String cable',
      'I = 1.25 × Isc (IEC 62548-1), derated for ${num0(x.n('rfa'))} °C, drop ≤ ${num0(x.n('vd'))} %',
      '1.25 × ${num0(isc)} = ${fmt(iString, 1)} A',
      mm(stringCable),
    ),
    CalcStep('Inverter', 'kWp / DC-AC ratio', '${fmt(kWp, 2)} / ${num0(x.n('ratio'))}', invText),
    CalcStep(
      'AC current',
      ph == 3 ? 'I = P / (√3 × V)' : 'I = P / 230 V',
      '${num0(pac)} kW',
      '${fmt(iac, 1)} A, breaker ${num0(acBreaker)} A, cable ${mm(acCable)}',
    ),
    if (b != null) ...[
      CalcStep(
        'Battery energy',
        'Usable / (DoD × 0.92)',
        '${fmt(b.eu, 1)} / (${fmt(dod, 2)} × 0.92)',
        '${fmt(b.en, 1)} kWh nominal',
      ),
      CalcStep('Battery bank', 'Ah = kWh × 1000 / V', '${fmt(b.en, 1)} × 1000 / ${num0(b.vb)}', '${fmt(b.ah, 0)} Ah'),
    ],
  ];

  final okMark = kWp <= cap + 0.01 ? '✔' : '✘';
  final invMark = ni * pac <= cap + 0.01 ? '✔' : '✘';

  return CalcResult(
    headline: CalcHeadline(
      '${_typeName[t]} PV array',
      '${fmt(kWp, 2)} kWp',
      caption: '$nt × ${num0(wp)} Wp · inverter $invText',
    ),
    metrics: [
      ResultRow('Inverter', invText),
      ResultRow('Yield', '${fmt(annual, 0)} kWh/yr'),
      if (b != null) ResultRow('Battery', '${fmt(b.en, 1)} kWh') else ResultRow('Strings', '$ss × $ns'),
    ],
    sections: [
      ResultSection('PV array', [
        ResultRow('Array', '${fmt(kWp, 2)} kWp'),
        ResultRow('Modules', '$nt × ${num0(wp)} Wp'),
        ResultRow('Strings', '$ss × $ns modules'),
        ResultRow('Yield', '${fmt(annual, 0)} kWh/year'),
      ]),
      ResultSection('Inverter', [
        ResultRow('Inverter', invText),
        ResultRow(
          'Type',
          offgrid
              ? 'Off-grid inverter-charger'
              : hybrid
              ? 'Hybrid inverter'
              : 'Grid-tied inverter',
        ),
        ResultRow('AC output', '${ph == 3 ? '3-phase' : '1-phase'} ${fmt(iac, 1)} A'),
        ResultRow('MPPT inputs needed', '$mpptNeeded'),
      ]),
      if (b != null)
        ResultSection('Battery', [
          ResultRow('Nominal energy', '${fmt(b.en, 1)} kWh'),
          ResultRow('Type', cm.name),
          ResultRow('Bank', '${num0(b.vb)} V, ${fmt(b.ah, 0)} Ah'),
          ResultRow('Discharge rate', '${fmt(b.cr, 2)} C', tone: b.heavy ? Tone.bad : Tone.ok),
        ]),
      if (netmeter)
        ResultSection('Net metering check', [
          ResultRow('Limit', cap < none ? '${fmt(cap, 1)} kW' : 'Not set'),
          ResultRow('Array', '${fmt(kWp, 2)} kWp $okMark', tone: okMark == '✔' ? Tone.ok : Tone.bad),
          ResultRow('Inverter', '${num0(ni * pac)} kW $invMark', tone: invMark == '✔' ? Tone.ok : Tone.bad),
        ], note: 'Guideline 2025: up to 100 % of the sanctioned load.'),
      ResultSection('String design', [
        ResultRow('Voc cold per module', '${fmt(vocCold, 1)} V'),
        ResultRow('String Voc cold', '${fmt(vString, 0)} V', tone: ns > nMax ? Tone.bad : Tone.normal),
        ResultRow('Vmp hot per module', '${fmt(vmpHot, 1)} V'),
        ResultRow('Modules per string', '$nMin to $nMax'),
        ResultRow('String Isc', '${fmt(isc, 1)} A'),
        ResultRow('Strings per MPPT', '$k'),
        ResultRow('Design current 1.25 × Isc', '${fmt(iString, 1)} A'),
      ]),
      ResultSection('Cables', [
        ResultRow('DC string cable', mm(stringCable), tone: stringCable == null ? Tone.bad : Tone.normal),
        ResultRow('DC main cable', mm(mainCable)),
        ResultRow('Earth / bonding (PE)', '${num0(pe)} mm² Cu'),
        ResultRow('AC cable (Cu)', mm(acCable), tone: acCable == null ? Tone.bad : Tone.normal),
        ResultRow('AC breaker', '${num0(acBreaker)} A'),
        ResultRow('RCD', offgrid ? 'Per load board' : 'Type B 300 mA (or A if the inverter isolates)'),
        if (b != null) ...[
          ResultRow('Battery discharge current', '${fmt(b.id, 0)} A'),
          ResultRow('Battery cable (3 m)', mm(b.cable)),
          ResultRow('Battery DC breaker / fuse', b.fuse == null ? 'Spec sheet' : '${num0(b.fuse!)} A'),
        ],
      ]),
      ResultSection('Protection', [
        ResultRow(
          'String fuse (gPV)',
          needFuse ? '${fuse == null ? '-' : num0(fuse)} A, ${num0(ue)} V' : 'Not needed (under 3 strings)',
          tone: needFuse && !fuseOk ? Tone.bad : Tone.normal,
        ),
        ResultRow('DC isolator', '${num0(ue)} V, ≥ ${ie == null ? '> 125' : num0(ie)} A'),
        ResultRow('DC SPD', '${lps ? 'Type 1+2' : 'Type 2'}, Ucpv ≥ ${num0(ucp)} V'),
        ResultRow('AC isolator', 'Lockable, ${num0(acBreaker)} A'),
        const ResultRow('AC SPD', 'Type 2'),
        ResultRow('Anti-islanding', offgrid ? 'Not applicable' : 'IEC 62116'),
        if (netmeter) const ResultRow('Meter', 'Bidirectional, utility approved'),
        if (b != null) ...[
          ResultRow('Battery life', cm.life),
          ResultRow(
            'Battery units',
            x.s('chem') == 'lfp'
                ? '${b.mods} × 5.12 kWh (51.2 V 100 Ah)'
                : '${b.ser > 0 ? '${num0(b.ser)} × ' : ''}${b.par} parallel of 12 V 200 Ah',
          ),
          if (offgrid)
            ResultRow('Solar charge controller', '${b.ncc} × ${num0(b.cc)} A MPPT')
          else
            const ResultRow('Backup transfer', 'IEC 60947-6-1 / EPS port'),
        ],
      ]),
    ],
    issues: issues,
    steps: steps,
  );
}
