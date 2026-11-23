import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/core/theme/app_theme.dart';
import 'package:powerhub/data/database.dart';
import 'package:powerhub/data/providers.dart';
import 'package:powerhub/features/calc/modules/modules.dart';
import 'package:powerhub/features/calc/presentation/calc_screen.dart';
import 'package:powerhub/features/calc/report/calc_report.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final m in calcModules) {
    testWidgets('${m.title}: opens, shows its result, and opens its advanced inputs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(theme: AppTheme.light(), home: CalcScreen(moduleId: m.id)),
        ),
      );
      // The database answers in real time, outside the test's fake clock: let it, until the spinner is gone.
      final loading = find.byType(CircularProgressIndicator);
      for (var i = 0; i < 100 && loading.evaluate().isNotEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(loading, findsNothing, reason: 'the calculator should finish loading');
      await tester.pumpAndSettle();

      final result = m.run(const {});
      expect(find.text(m.title), findsOneWidget);
      expect(find.text(result.headline.value), findsOneWidget);

      // Unfold every advanced group, scrolling through the whole page: nothing may overflow or throw.
      final folded = find.text('Typical values used · tap to change');
      for (var i = 0; i < 10 && folded.evaluate().isNotEmpty; i++) {
        // Centred, not at the top: the page scrolls under the frosted app bar, which would take the tap.
        await tester.runAsync(() => Scrollable.ensureVisible(tester.element(folded.first), alignment: 0.5));
        await tester.pumpAndSettle();
        await tester.tap(folded.first);
        await tester.pumpAndSettle();
      }
      expect(folded, findsNothing, reason: 'every advanced group opens');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -20000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  test('reports build for every calculator, for both readers', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final m in calcModules) {
      final inputs = m.inputs(const {});
      for (final audience in ReportAudience.values) {
        final pdf = await buildCalcReport(
          module: m,
          inputs: inputs,
          result: m.run(const {}),
          audience: audience,
          projectName: 'রহমান টাওয়ার · Test',
          preparedBy: 'Engr. Hasan',
          company: 'Bear Tech',
        );
        expect(String.fromCharCodes(pdf.take(4)), '%PDF', reason: '${m.id} ${audience.name}');
      }
    }
  });
}
