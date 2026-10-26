import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  final now = DateTime.utc(2026, 10, 26, 12);

  Future<void> pumpProgress(
    WidgetTester tester,
    InMemoryBodySetupRepository repository, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.dark),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: Scaffold(
          body: ProgressWeightPage(
            repository: repository,
            unit: WeightUnit.kg,
            sessionKey: 'owner-cycle-one',
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Progress 56dp Log Weight action stays fixed during Timeline scroll',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = InMemoryBodySetupRepository();
    for (var day = 0; day < 32; day++) {
      await repo.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 71 + day / 10,
          measuredAt: now.subtract(Duration(days: day + 1)),
          source: BodyWeightSources.manual,
        ),
      );
    }
    await pumpProgress(tester, repo);
    const actionKey = ValueKey('progress-weight-log-action');
    final action = find.byKey(actionKey);
    final list = find.byKey(const ValueKey('progress-weight-scroll'));
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('History'), findsNothing);
    expect(action, findsOneWidget);
    expect(tester.widget<TioButton>(action).variant, TioButtonVariant.primary);
    final before = tester.getRect(action);
    expect(before.height, TioSize.dp56);
    expect(before.right, closeTo(360 - TioSpacing.xl, 1));

    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(action), before,
        reason: 'the action must not scroll with Timeline');

    final listState = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    listState.position.jumpTo(listState.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.getRect(action), before);
    final loadMore = find.byKey(const ValueKey('progress-weight-load-more'));
    expect(loadMore, findsOneWidget);
    expect(tester.getRect(loadMore).bottom, lessThan(before.top),
        reason: 'bottom clearance must keep Load more above the fixed action');
  });

  testWidgets('short Timeline keeps action fixed and opens the canonical sheet',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = InMemoryBodySetupRepository();
    await pumpProgress(tester, repo, scale: 1.5);
    final action = find.byKey(const ValueKey('progress-weight-log-action'));
    expect(action, findsOneWidget);
    expect(tester.getRect(action).height, TioSize.dp56);
    expect(tester.takeException(), isNull);

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-log-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
  });
}
