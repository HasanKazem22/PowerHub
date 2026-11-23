import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/features/calc/modules/substation_module.dart';

void main() {
  Map<String, String> rows(Map<String, Object?> values) {
    final r = computeSubstation(substationModule.inputs(values));
    return {for (final s in r.sections) for (final row in s.rows) '${s.title}/${row.label}': row.value};
  }

  test('300 kW: 288 kW design load, 303 kVA → 1 × 315 kVA, 438 A on LV', () {
    final r = computeSubstation(substationModule.inputs(const {}));
    expect(r.headline.value, '1 × 315 kVA');
    final m = rows(const {});
    expect(m['Load/After load factor and expansion'], '288.0 kW');
    expect(m['Load/Apparent power'], '303 kVA');
    expect(r.metrics[1].value, '438 A');
    expect(r.metrics[0].value, '16.5 A'); // 315 / (√3 × 11)
    // 96 % loading: suggests the next size up.
    expect(r.issues.any((i) => i.patch?['ovr'] == 400), isTrue);
  });

  test('a load above 3150 kVA asks to split across transformers', () {
    final r = computeSubstation(substationModule.inputs(const {'kw': 10000}));
    final split = r.issues.where((i) => i.message.contains('largest standard transformer'));
    expect(split, hasLength(1));
    expect(split.single.patch, {'n': 2, 'ovr': 0});
  });

  test('N-1 backup with one transformer is flagged', () {
    final r = computeSubstation(substationModule.inputs(const {'red': 'yes', 'n': 1}));
    expect(r.issues.any((i) => i.message.contains('N-1') && i.patch?['n'] == 2), isTrue);
  });

  test('small transformer uses a drop-out fuse, large one a VCB', () {
    expect(rows(const {'kw': 150})['Required components/HT switchgear (none)'], isNotNull);
    final big = rows(const {'kw': 1500});
    expect(big.keys.any((k) => k.startsWith('HV relay 50/51')), isTrue);
    expect(big['Required components/HT switchgear (1)'], startsWith('VCB'));
  });
}
