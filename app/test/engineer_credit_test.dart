import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powerhub/core/theme/app_theme.dart';
import 'package:powerhub/features/settings/presentation/widgets/engineer_credit.dart';

void main() {
  testWidgets('the engineer row opens the profile sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: EngineerTile()),
      ),
    );
    expect(find.text(Engineer.name), findsOneWidget);
    await tester.tap(find.byType(EngineerTile));
    await tester.pumpAndSettle();
    expect(find.text('Engineer profile'), findsOneWidget);
    expect(find.text(Engineer.email), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
