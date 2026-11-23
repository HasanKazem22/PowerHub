import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/features/calc/domain/calc_result.dart';
import 'package:powerhub/features/calc/modules/solar_module.dart';

String row(CalcResult r, String section, String label) =>
    r.sections.firstWhere((s) => s.title == section).rows.firstWhere((x) => x.label == label).value;

void main() {
  // Defaults: net metering, 30 kWh/day, PSH 4.5, PR 0.78 → 8.55 kWp wanted (limit 10 kW);
  // 16 × 550 Wp; Voc cold = 49.8 × 1.054 = 52.49 V → max 20 per string, Vmp hot 35.4 V → min 6;
  // one string of 16 = 8.8 kWp; inverter 8.8 / 1.15 = 7.65 → 8 kW, 3-phase 11.1 A;
  // yield 8.8 × 4.5 × 365 × 0.78 = 11 274 kWh/year.
  final r = computeSolar(solarModule.inputs(const {}));

  test('array and strings for the defaults', () {
    expect(r.headline.value, '8.80 kWp');
    expect(row(r, 'PV array', 'Modules'), '16 × 550 Wp');
    expect(row(r, 'PV array', 'Strings'), '1 × 16 modules');
    expect(row(r, 'String design', 'Modules per string'), '6 to 20');
  });

  test('inverter and yield', () {
    expect(row(r, 'Inverter', 'Inverter'), '8 kW');
    expect(row(r, 'Inverter', 'AC output'), '3-phase 11.1 A');
    expect(row(r, 'PV array', 'Yield'), '11274 kWh/year');
    expect(row(r, 'Cables', 'AC breaker'), '16 A');
  });

  test('off-grid adds a battery bank', () {
    // 8 kW peak × 1.25 = 10 kW inverter → 48 V bank; 30 kWh × 1 day / (0.9 × 0.92) = 36.2 kWh.
    final o = computeSolar(solarModule.inputs(const {'type': 'offgrid'}));
    expect(row(o, 'Battery', 'Nominal energy'), '36.2 kWh');
    expect(row(o, 'Battery', 'Bank'), startsWith('48 V'));
  });

  test('too many modules per string is flagged with a fix', () {
    final bad = computeSolar(solarModule.inputs(const {'mps': 25}));
    final issue = bad.issues.firstWhere((i) => i.message.startsWith('Too many modules per string'));
    expect(issue.patch, {'mps': 20});
  });
}
