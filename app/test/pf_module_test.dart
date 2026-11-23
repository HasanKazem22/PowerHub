import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/features/calc/domain/calc_result.dart';
import 'package:powerhub/features/calc/modules/pf_module.dart';

String row(CalcResult r, String section, String label) =>
    r.sections.firstWhere((s) => s.title == section).rows.firstWhere((x) => x.label == label).value;

void main() {
  // Defaults: 300 kW, PF 0.80 → 0.95, 415 V, 10 % non-linear (plain capacitors, 440 V).
  // Q = 300 × (0.75 − 0.32868) = 126.4 kVAR; Qr = 126.4 / (415/440)² = 142.1 kVAR at 440 V;
  // step = 12.5 (≥ 142.1 / 12), n = 12, Qrt = 150, Qe = 133.4 kVAR; Ib = 185.6 A; 1.43 × Ib = 265.4 → 300 A;
  // line current 521.7 A × 1.2 = 626 → 750/5 CT.
  final r = computePf(pfModule.inputs(const {}));

  test('reactive power and bank steps for the defaults', () {
    expect(r.headline.value, '126 kVAR');
    expect(row(r, 'Capacitor bank', 'Steps'), '12 × 12.5 kVAR');
    expect(row(r, 'Capacitor bank', 'Total rated'), '150 kVAR');
    expect(row(r, 'Capacitor bank', 'Rated voltage'), '440 V');
  });

  test('main incomer and line CT', () {
    expect(row(r, 'Main incomer', 'Bank current'), '186 A');
    expect(row(r, 'Main incomer', 'MCCB / ACB'), startsWith('300 A'));
    expect(row(r, 'Main incomer', 'Line CT'), '750/5 A');
  });

  test('a detuned bank above 15 % non-linear load', () {
    final d = computePf(pfModule.inputs(const {'nl': 30}));
    expect(row(d, 'Capacitor bank', 'Rated voltage'), '525 V');
    expect(row(d, 'Compensation', 'Capacitor type'), 'Detuned 7 %');
  });

  test('a target PF below the present PF is flagged with a fix', () {
    final bad = computePf(pfModule.inputs(const {'pf2': 0.7}));
    final issue = bad.issues.firstWhere((i) => i.message.startsWith('Target PF must be above'));
    expect(issue.patch, {'pf2': 0.95});
  });
}
