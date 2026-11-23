import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/features/calc/domain/calc_inputs.dart';
import 'package:powerhub/features/calc/domain/calc_module.dart';
import 'package:powerhub/features/calc/domain/calc_result.dart';
import 'package:powerhub/features/calc/domain/electrical_tables.dart';
import 'package:powerhub/features/calc/modules/modules.dart';
import 'package:powerhub/features/calc/report/calc_report.dart';

/// Every value a field of [m] can take: each option of each choice field, plus zero for each number.
Iterable<Map<String, Object?>> _variants(CalcModule m) sync* {
  for (final g in m.groups) {
    for (final f in g.fields) {
      switch (f) {
        case ChoiceField(:final options):
          for (final o in options) {
            yield {f.key: o.value};
          }
        case NumberField():
          yield {f.key: 0};
          yield {f.key: -1};
      }
    }
  }
}

void main() {
  test('module ids are unique (they are stored with saved projects)', () {
    final ids = calcModules.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  for (final m in calcModules) {
    group(m.title, () {
      test('every field has a default, and every choice default is one of its options', () {
        for (final g in m.groups) {
          for (final f in g.fields) {
            expect(m.defaults.containsKey(f.key), isTrue, reason: '${m.id}.${f.key} has no default');
            if (f is ChoiceField) {
              final values = f.options.map((o) => o.value).toSet();
              // A key shared by two exclusive fields (earthing rod count) only needs to fit one of them.
              final shared = m.groups.expand((g) => g.fields).where((x) => x.key == f.key).length > 1;
              if (!shared) {
                expect(values, contains(m.defaults[f.key].toString()), reason: '${m.id}.${f.key}');
              }
            }
          }
        }
      });

      test('the typical values give a full result', () {
        final r = m.run(const {});
        expect(r.headline.value, isNot(anyOf('', '-')));
        expect(r.sections, isNotEmpty);
        expect(r.summary, r.headline.value);
      });

      test('never throws: every option, zero and negative numbers, empty and junk inputs', () {
        expect(() => m.run(const {}), returnsNormally);
        for (final v in _variants(m)) {
          expect(() => m.run(v), returnsNormally, reason: '${m.id} with $v');
        }
        // Junk from a damaged or hand-edited project.
        final junk = {for (final k in m.defaults.keys) k: 'abc'};
        expect(() => m.run(junk), returnsNormally, reason: '${m.id} with junk');
      });

      test('inputs describe themselves for the report', () {
        final lines = describeInputs(m, m.inputs(const {}));
        expect(lines, isNotEmpty);
        expect(lines.every((l) => l.$1.isNotEmpty && l.$2.isNotEmpty), isTrue);
      });
    });
  }

  group('CalcInputs', () {
    const x = CalcInputs({'a': '1,250.5', 'b': 'junk', 'c': true, 'l': [{'n': 2}, 'skip']}, {'b': 7, 'd': 'x'});
    test('parses text numbers and falls back to defaults', () {
      expect(x.n('a'), 1250.5);
      expect(x.n('b'), 7);
      expect(x.n('missing'), 0);
      expect(x.s('d'), 'x');
      expect(x.b('c'), isTrue);
      expect(x.list('l'), [
        {'n': 2},
      ]);
    });
    test('merged = defaults overwritten by values', () {
      expect(x.merged['d'], 'x');
      expect(x.merged['a'], '1,250.5');
    });
  });

  group('tables', () {
    test('next standard sizes', () {
      expect(ElecTables.nextBreaker(29.8), 32);
      expect(ElecTables.nextBreaker(99999), 6300);
      expect(nextUp(const [1.0, 2.0], 3), isNull);
    });
    test('busbar: smallest bar with area ≥ I / 1.6', () {
      final b = ElecTables.busbar(400)!; // needs 250 mm²
      expect(b.area, greaterThanOrEqualTo(250));
      // 50 × 5 and 25 × 10 are both 250 mm²; thinner first, as in the web version.
      expect(ElecTables.busbarText(400), '50 × 5 mm');
    });
    test('cables by breaker never go below the 6 mm² sub-main minimum', () {
      expect(ElecTables.cablesFor(16).cable, '6 mm²');
      expect(ElecTables.cablesFor(100).cable, '35 mm²');
      expect(ElecTables.cablesFor(630).cable, 'Spec sheet');
    });
    test('interp clamps and interpolates', () {
      expect(interp(ElecTables.ambientPvc, 0), 1.22);
      expect(interp(ElecTables.ambientPvc, 32.5), closeTo(0.97, 1e-9));
      expect(interp(ElecTables.ambientPvc, 99), 0.5);
    });
  });
}
