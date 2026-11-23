import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/features/calc/modules/earthing_module.dart';

void main() {
  test('square of 4 rods in clay (defaults)', () {
    // R = 30 / (2π × 3) × [ln(960) − 1] = 9.34 Ω; a = 0.1704; Rn = 9.34 × (1 + 5.46a) / 4 = 4.51 Ω.
    final r = computeEarthing(earthingModule.inputs(const {}));
    expect(r.headline.value, 'R = 4.51 Ω');
    expect(r.headline.caption, startsWith('ACCEPTED'));
    expect(r.issues, isEmpty);
  });

  test('a target that is missed suggests more rods', () {
    // ρ 40: 4 rods 6.01 Ω, 5 rods 5.10 Ω, 6 rods 4.42 Ω ≤ 5.
    final r = computeEarthing(earthingModule.inputs(const {'soil': 'custom', 'rho': 40}));
    expect(r.headline.caption, contains('ADD MORE RODS'));
    expect(r.issues.single.patch, {'n': '6'});
  });

  test('earth conductor from fault level', () {
    // Isc = 10 000 / (1.73 × 11) / 0.06 = 8758 A; S = 8758 × √1 / 115 = 76.2 mm².
    final r = computeEarthing(earthingModule.inputs(const {'tool': 'conductor'}));
    expect(r.headline.value, '76.2 mm²');
    expect(r.headline.caption, startsWith('Use 95 mm²'));
  });

  test('busbar for 100 A at 5 mm', () {
    // 100 / 1.6 = 62.5 mm², / 5 = 12.5 mm → 15 mm.
    final r = computeEarthing(earthingModule.inputs(const {'tool': 'busbar'}));
    expect(r.headline.value, '15 × 5 mm');
  });
}
