import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_shared/shared.dart';

void main() {
  Widget app({
    AppMode? initialMode,
    VoidCallback? onBack,
    Future<void> Function(AppMode mode)? onConfirmed,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: AppModeSetupPage(
        initialMode: initialMode,
        onBack: onBack ?? () {},
        onModeConfirmed: onConfirmed ?? (_) async {},
      ),
    );
  }

  testWidgets('preserves App Mode content with Back-only top chrome',
      (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('How will you use Tio?'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-mode-workout')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-mode-nutrition')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-mode-hybrid')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-mode-setup-back')), findsOneWidget);
    expect(find.textContaining('Step '), findsNothing);
    expect(find.textContaining('/'), findsNothing);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('selection enables Continue and confirms selected mode',
      (tester) async {
    AppMode? confirmed;
    await tester.pumpWidget(
      app(onConfirmed: (mode) async => confirmed = mode),
    );

    await tester.tap(find.byKey(const ValueKey('app-mode-nutrition')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'After signup, Tio will focus setup on nutrition targets and meal preferences.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(confirmed, AppMode.nutrition);
  });

  testWidgets('visible and system Back share the same exit behavior',
      (tester) async {
    var exits = 0;
    await tester.pumpWidget(app(onBack: () => exits++));

    await tester.tap(find.byKey(const ValueKey('app-mode-setup-back')));
    await tester.pump();
    expect(exits, 1);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 2);
  });

  testWidgets('compact width and large text keep Continue reachable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: app(initialMode: AppMode.workout),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Continue'), findsOneWidget);
  });
}
