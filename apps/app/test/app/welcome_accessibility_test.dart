import 'package:flutter/material.dart';
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
}
