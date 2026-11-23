import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/features/calc/modules/pf_module.dart';
import 'package:powerhub/features/calc/modules/solar_module.dart';

void main() {
  test('a zero voltage uses the typical value and says so, instead of dividing by zero', () {
    final typical = pfModule.run(const {});
    final r = pfModule.run(const {'v': 0});
    expect(r.issues.first.message, contains('must be above zero'));
    expect(r.issues.first.fix, contains('415'));
    expect(r.headline.value, typical.headline.value);
  });

  test('half-typed module data still gives a result (Voc 0 is flagged; an empty Isc means typical)', () {
    final r = solarModule.run(const {'voc': 0, 'isc': ''});
    expect(r.issues.where((i) => i.message.contains('must be above zero')).length, 1);
    expect(r.headline.value, isNot('-'));
  });

  test('valid inputs add no extra issues', () {
    final r = pfModule.run(const {'v': 400});
    expect(r.issues.where((i) => i.message.contains('must be above zero')), isEmpty);
  });
}
