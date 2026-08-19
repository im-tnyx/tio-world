import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_welcome/welcome.dart';

void main() {
  testWidgets('welcome hero preserves readable image and feature contrast',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const WelcomeRoute(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    final topBarText = tester.widget<Text>(find.text('EN'));
    expect(topBarText.style?.color, Colors.white);

    final skipFinder = find.byKey(const ValueKey('welcome-skip-action'));
    final skipRect = tester.getRect(skipFinder);
    final skipInkWell = tester.widget<InkWell>(skipFinder);
    final localeRect = tester.getRect(find.text('EN'));
    expect(skipRect.center.dx, greaterThan(393 / 2));
    expect(skipRect.center.dx, greaterThan(localeRect.center.dx));
    expect(skipRect.right, greaterThan(350));
    expect(skipInkWell.borderRadius, BorderRadius.circular(TioRadius.lg));

    final featureTitle = tester.widget<Text>(find.text('AI WORKOUT'));
    final featureContext = tester.element(find.text('AI WORKOUT'));
    expect(
      featureTitle.style?.color,
      Theme.of(featureContext).colorScheme.onSurface,
    );

    final panel = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('welcome-feature-panel')),
    );
    final decoration = panel.decoration as BoxDecoration;
    expect(decoration.color?.a, greaterThan(0.9));
    expect(decoration.borderRadius, BorderRadius.circular(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome hero honors reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(reducedMotion: true),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const WelcomeRoute(),
      ),
    );

    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(animation.duration, Duration.zero);
  });

  testWidgets(
      'placeholder language is not announced as actions and legal copy is omitted',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const WelcomeRoute(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final languageNode = tester.getSemantics(find.text('EN'));
      expect(languageNode.flagsCollection.isButton, isFalse);
      expect(
        languageNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );

      expect(
        find.textContaining('By continuing', findRichText: true),
        findsNothing,
      );
    } finally {
      semantics.dispose();
    }
  });
}
