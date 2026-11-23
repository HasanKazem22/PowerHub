import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/features/calc/domain/calc_result.dart';
import 'package:powerhub/features/calc/modules/rewind_module.dart';

String row(CalcResult r, String section, String label) =>
    r.sections.firstWhere((s) => s.title == section).rows.firstWhere((x) => x.label == label).value;

void main() {
  // Defaults: 7.5 kW, 415 V star, 4 poles, 36 slots, bore 125 mm, core 130 mm.
  final r = computeRewind(rewindModule.inputs(const {}));

  test('speed, span and winding factor match the hand calculation', () {
    expect(row(r, 'Motor data', 'Synchronous speed'), '1500 rpm');
    expect(row(r, 'Winding layout', 'Coil span'), '1 - 9 (8 slots)'); // round(5/6 × 9) = 8
    expect(row(r, 'Winding factors', 'Winding factor kw'), '0.945'); // sin 80° × 0.5 / (3 sin 10°)
  });

  test('turns and wire', () {
    // Tph = 230.0 / (4.44 × 50 × 6.381 mWb × 0.9452) = 171.8 → 14.3 turns/coil → 14.
    expect(r.headline.value, '14 turns/coil');
    // 13.64 A / 5 A/mm² = 2.73 mm² over 2 strands → 1.318 mm → 1.32 mm (IEC 60317).
    expect(r.headline.caption, 'Wire 2 × 1.32 mm');
  });

  test('phase start slots are 2q apart', () {
    expect(row(r, 'Phase start slots', 'Phase V (V1) starts at slot'), '7');
    expect(row(r, 'Phase start slots', 'Phase W (W1) starts at slot'), '13');
    expect(row(r, 'Phase start slots', 'U group start slots'), '1, 10, 19, 28');
  });

  test('odd poles raise an issue and still compute a layout', () {
    final bad = computeRewind(rewindModule.inputs(const {'poles': 3}));
    expect(bad.issues.any((i) => i.message.contains('Poles')), isTrue);
    expect(bad.headline.value, '14 turns/coil');
  });
}
