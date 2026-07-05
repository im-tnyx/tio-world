import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';

void main() {
  testWidgets('App shell renders with navigation tabs', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TioApp()));

    // Verify that the app title 'Tio' is present in the AppBar.
    expect(find.text('Tio'), findsOneWidget);

    // Verify that the bottom navigation bar labels are present.
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('Nutrition'), findsWidgets);
    expect(find.text('Coach'), findsWidgets);
    expect(find.text('Progress'), findsWidgets);

    // Verify that we start on the Dashboard page.
    expect(find.text('Your daily health and fitness overview.'), findsOneWidget);
  });

  testWidgets('Navigation tabs switch content', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TioApp()));

    // Tap on Workout tab.
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();

    // Verify Workout page content.
    expect(find.text('Track your exercises and follow workout plans.'), findsOneWidget);

    // Tap on Nutrition tab.
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();

    // Verify Nutrition page content.
    expect(find.text('Log your meals and monitor your macros.'), findsOneWidget);
  });
}
