import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required ValueNotifier<bool> active,
    required ValueChanged<bool?> onResult,
    TioThemeMode mode = TioThemeMode.dark,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(body: Builder(builder: (context) => Center(
        child: TextButton(
          onPressed: () async => onResult(await showTioConfirmationDialog(
            context: context,
            dialogKey: const ValueKey('test-centered-dialog'),
            cardKey: const ValueKey('test-centered-card'),
            title: 'Delete measurement?',
            message: 'Delete only this saved record? This cannot be undone.',
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
            icon: const Icon(Icons.delete_outline_rounded),
            intent: TioConfirmationIntent.destructive,
            activeWhileOpen: active,
          )),
          child: const Text('Open confirmation'),
        ),
      ))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('centered dialog uses Routine compact width and action minima',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    bool? result;
    await pumpHost(tester, active: active, onResult: (v) => result = v);
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const ValueKey('test-centered-dialog'));
    final card = find.byKey(const ValueKey('test-centered-card'));
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(dialog, findsOneWidget);
    expect(card, findsOneWidget);
    expect(tester.getSize(card).width, lessThanOrEqualTo(TioSize.dp320));
    expect(tester.getCenter(card).dx, closeTo(195, 1));
    expect(tester.getCenter(card).dy, closeTo(425, 1));
    expect(find.text('Delete measurement?'), findsOneWidget);
    final themedActions = Theme.of(tester.element(find.text('Cancel')));
    expect(
      themedActions.filledButtonTheme.style?.minimumSize?.resolve({})?.height,
      TioSize.dp38,
    );
    expect(
      themedActions.outlinedButtonTheme.style?.minimumSize?.resolve({})?.height,
      TioSize.dp38,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow light large-text dialog keeps both actions accessible',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    bool? result;
    await pumpHost(
      tester,
      active: active,
      onResult: (v) => result = v,
      mode: TioThemeMode.light,
      textScale: 1.6,
    );
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('test-centered-card'));
    expect(tester.getSize(card).width, lessThanOrEqualTo(TioSize.dp320));
    expect(find.text('Delete measurement?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('barrier dismissal is null, not an explicit confirmation',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    final results = <bool?>[];
    await pumpHost(tester, active: active, onResult: results.add);
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(results, <bool?>[null]);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner revocation dismisses exact dialog without stale barrier',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    final results = <bool?>[];
    await pumpHost(tester, active: active, onResult: results.add);
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    expect(find.text('Delete measurement?'), findsOneWidget);
    active.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Delete measurement?'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse);
    expect(find.text('Open confirmation'), findsOneWidget);
    expect(results, <bool?>[null]);
    expect(tester.takeException(), isNull);
  });
}
