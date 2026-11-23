import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/features/calc/modules/load_module.dart';

Map<String, Object?> _unit(String id, {String fdb = '', double custW = 0, String ph = 'auto'}) => {
  ...newLoadUnit(1, residential: true, fdb: fdb),
  'id': id,
  'name': 'U$id',
  'custW': custW,
  'ph': ph,
};

void main() {
  test('a typical flat: three stages, 1-phase, × 5.68 × safety factor', () {
    final r = unitLoad(newLoadUnit(1, residential: true));
    // Lighting (10 × 20 + 4 × 75) × 80 % = 400 W; 6 sockets × 390 = 2340 W; 2 × 2000 × 70 % = 2800 W.
    expect(r.lighting, 400);
    expect(r.sockets, 2340);
    expect(r.power, 2800);
    expect(r.kw, closeTo(5.54, 1e-9));
    expect(r.phases, 1);
    expect(r.amps, closeTo(5.54 * 5.68 * 1.25, 1e-9)); // 39.3 A
    expect(r.breaker, 40);
  });

  test('above 7.5 kW a unit goes 3-phase (× 1.68)', () {
    final r = unitLoad(_unit('1', custW: 4000)); // 5.54 + 2.8 = 8.34 kW
    expect(r.phases, 3);
    expect(r.amps, closeTo(8.34 * 1.68 * 1.25, 1e-9));
  });

  test('forcing 1-phase above 7.5 kW is flagged', () {
    final r = computeLoad(
      loadModule.inputs({
        'units': [_unit('1', custW: 4000, ph: '1')],
      }),
    );
    expect(r.issues.map((i) => i.message), contains(contains('on one phase')));
  });

  test('residential: every unit feeds the MDB, divided by its diversity', () {
    final r = computeLoad(
      loadModule.inputs({
        'units': [_unit('1'), _unit('2')],
        'mdbDiv': 2,
      }),
    );
    final mdb = r.sections.firstWhere((s) => s.title == 'Main panel (MDB)');
    expect(mdb.rows.firstWhere((x) => x.label == 'Max demand').value, '5.54 kW'); // 11.08 ÷ 2
    expect(r.headline.value, startsWith('10 A')); // 5.54 × 1.68 = 9.3 A
  });

  test('commercial: an FDB passes on its demand, not its connected load', () {
    final r = computeLoad(
      loadModule.inputs({
        'bt': 'com',
        'fdbs': [
          {'id': 'f1', 'name': 'FDB-1', 'div': 2},
        ],
        'units': [_unit('1', fdb: 'f1'), _unit('2', fdb: 'f1'), _unit('3')],
        'mdbDiv': 1,
      }),
    );
    final mdb = r.sections.firstWhere((s) => s.title == 'Main panel (MDB)');
    // 2 × 5.54 ÷ 2 = 5.54 from the FDB, + 5.54 direct.
    expect(mdb.rows.first.value, '11.08 kW');
    expect(r.sections.any((s) => s.title == 'FDB-1 (FDB)'), isTrue);
  });

  test('a unit pointing at a removed FDB is fed from the MDB', () {
    final r = computeLoad(
      loadModule.inputs({
        'bt': 'com',
        'fdbs': const <Object>[],
        'units': [_unit('1', fdb: 'gone')],
      }),
    );
    final mdb = r.sections.firstWhere((s) => s.title == 'Main panel (MDB)');
    expect(mdb.rows.first.value, '5.54 kW');
  });

  test('generator: the larger of running load and motor starting, next standard size', () {
    final r = computeLoad(
      loadModule.inputs({
        'units': [for (var i = 0; i < 20; i++) _unit('$i')], // 110.8 kW
        'mdbDiv': 1,
        'genMotor': 0,
      }),
    );
    // 110.8 × 1.1 = 121.9 kW ÷ 0.85 = 143.4 kVA ÷ 0.85 loading = 168.7 → 200 kVA.
    final gen = r.sections.firstWhere((s) => s.title.startsWith('Standby generator'));
    expect(gen.rows.firstWhere((x) => x.label == 'Suggested generator').value, startsWith('200 kVA'));
  });
}
