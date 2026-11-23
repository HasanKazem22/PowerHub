import 'package:powerhub/core/theme/app_theme.dart';
import 'package:powerhub/shared/widgets/dialogs/app_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A layout overflow fails a widget test, so these catch the "BOTTOM OVERFLOWED" stripe.
  Future<void> openSheet(WidgetTester tester, Size screen, int count) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showAppActionSheet(
                  context,
                  title: 'Backup settings',
                  actions: [
                    for (var i = 0; i < count; i++)
                      AppSheetAction(
                        icon: Icons.settings_outlined,
                        label: 'Option $i',
                        subtitle: 'What option $i does',
                        onTap: () {},
                      ),
                  ],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('five options fit on a small phone without overflowing', (tester) async {
    await openSheet(tester, const Size(360, 640), 5);
    expect(find.text('Option 4'), findsOneWidget);
  });

  testWidgets('more options than the screen can hold scroll instead of overflowing', (tester) async {
    await openSheet(tester, const Size(360, 420), 12);
    expect(find.text('Backup settings'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Option 11'), 100, scrollable: find.byType(Scrollable).last);
    expect(find.text('Option 11'), findsOneWidget);
  });
}
