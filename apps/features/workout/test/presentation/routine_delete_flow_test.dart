import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final _program = Program(
  id: ProgramId('10000000-0000-4000-8000-000000000001'), name: 'Strength',
);
final _routine = Routine(
  id: RoutineId('20000000-0000-4000-8000-000000000041'),
  programId: _program.id, name: 'Push',
);

final class _DeleteRepo implements RoutineDeleteRepository {
  int reads = 0;
  int writes = 0;
  bool absent = false;
  String targetName = 'Push';
  Future<RoutineDeleteTarget?> Function()? onInspect;
  RoutineDeleteOutcomeUnknown? uncertainty;
  @override
  Future<RoutineDeleteTarget?> inspect({
    required ProgramId programId, required RoutineId routineId,
  }) async {
    reads++;
    if (onInspect != null) return onInspect!();
    if (absent) return null;
    return RoutineDeleteTarget(
      routineId: routineId, programId: programId, name: targetName,
      expectedRevision: 2, ownerId: 'owner-a', loginCycleId: 'cycle-a',
    );
  }

  @override
  Future<RoutineDeleteResult> delete(RoutineDeleteTarget target) async {
    writes++;
    if (uncertainty case final outcome?) throw outcome;
    return RoutineDeleteResult.confirmed;
  }
}

void main() {
  Future<void> pumpFlow(WidgetTester tester, _DeleteRepo repository,
      RoutineDeleteFlow flow, bool Function() canWrite,
      void Function(bool) onResult, {
        TioThemeMode mode = TioThemeMode.light,
        double textScale = 1,
        Widget Function(BuildContext, Widget)? confirmationGuard,
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
          onPressed: () async => onResult(await flow.run(
            context: context, program: _program, routine: _routine,
            repository: repository, canWrite: canWrite,
            confirmationGuard: confirmationGuard,
          )),
          child: const Text('Open Delete'),
        ),
      ))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('concurrent Delete taps cannot issue a second inspection',
      (tester) async {
    final pendingRead = Completer<RoutineDeleteTarget?>();
    final repository = _DeleteRepo()
      ..onInspect = () => pendingRead.future;
    final flow = RoutineDeleteFlow();
    await pumpFlow(tester, repository, flow, () => true, (_) {});
    await tester.tap(find.text('Open Delete'));
    await tester.pump();
    await tester.tap(find.text('Open Delete'));
    await tester.pump();
    expect(repository.reads, 1);
    expect(repository.writes, 0);
    pendingRead.complete(null);
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
  });
  testWidgets('cancel after fresh inspection never dispatches Delete',
      (tester) async {
    final repository = _DeleteRepo();
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => true,
        (result) => returned = result);
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Routine?'), findsOneWidget);
    expect(find.textContaining('Push'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    final dialog = find.byKey(ValueKey('confirm-delete-routine-${_routine.id.value}'));
    expect(dialog, findsOneWidget);
    // Flutter's Dialog route may fill the viewport for barrier/insets.
    // Measure the actual TioCard, not the outer Dialog render bounds.
    final card = find.descendant(of: dialog, matching: find.byType(TioCard));
    expect(card, findsOneWidget);
    expect(tester.getSize(card).width, lessThanOrEqualTo(TioSize.dp320));
    final cardCenter = tester.getCenter(card);
    final logicalScreen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect((cardCenter.dx - logicalScreen.width / 2).abs(), lessThan(1));
    expect((cardCenter.dy - logicalScreen.height / 2).abs(), lessThan(1));
    final buttonTheme = Theme.of(tester.element(find.text('Cancel')));
    expect(
      buttonTheme.filledButtonTheme.style?.minimumSize?.resolve({})?.height,
      TioSize.dp38,
    );
    expect(
      buttonTheme.outlinedButtonTheme.style?.minimumSize?.resolve({})?.height,
      TioSize.dp38,
    );
    expect(repository.reads, 1);
    expect(repository.writes, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(returned, false);
    expect(repository.writes, 0);
  });

  testWidgets('only explicit confirmation dispatches once and refreshes',
      (tester) async {
    final repository = _DeleteRepo();
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => true,
        (result) => returned = result);
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repository.reads, 1);
    expect(repository.writes, 1);
    expect(returned, true);
    expect(find.text('Routine deleted.'), findsOneWidget);
    final feedback = tester.widget<SnackBar>(
      find.byKey(const ValueKey('routine-delete-confirmed-feedback')),
    );
    expect(feedback.duration, const Duration(seconds: 5));
    expect(feedback.behavior, SnackBarBehavior.floating);
    expect(feedback.shape, isA<StadiumBorder>());
    expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
  });

  testWidgets('unknown result asks for refresh without claiming deletion',
      (tester) async {
    final repository = _DeleteRepo()
      ..uncertainty = const RoutineDeleteOutcomeUnknown(
        reason: RoutineDeleteUncertainty.stillPresent,
      );
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => true,
        (result) => returned = result);
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repository.writes, 1);
    expect(returned, true);
    expect(find.textContaining('unconfirmed'), findsOneWidget);
    expect(find.text('Routine deleted.'), findsNothing);
    expect(find.byKey(const ValueKey('routine-delete-confirmed-feedback')),
        findsNothing);
  });

  testWidgets('centered dialog stays usable on narrow dark large-text screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _DeleteRepo()
      ..targetName = 'Very long full-body strength training routine';
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => true,
      (result) => returned = result,
      mode: TioThemeMode.dark, textScale: 1.6,
    );
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    final card = find.descendant(
      of: find.byType(Dialog), matching: find.byType(TioCard),
    );
    expect(tester.getSize(card).width, lessThanOrEqualTo(TioSize.dp320));
    expect(find.textContaining(repository.targetName), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    expect(returned, false);
  });
  testWidgets('revoked owner dismisses open Delete dialog without exposing name or RPC',
      (tester) async {
    final live = ValueNotifier<bool>(true);
    addTearDown(live.dispose);
    final repository = _DeleteRepo();
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => live.value,
      (result) => returned = result,
      confirmationGuard: (dialogContext, content) => ValueListenableBuilder<bool>(
        valueListenable: live,
        builder: (context, authorized, _) {
          if (authorized) return content;
          final route = ModalRoute.of(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && route != null && route.isActive) {
              Navigator.of(context).removeRoute(route);
            }
          });
          return const SizedBox.shrink();
        },
      ),
    );
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Push'), findsOneWidget);
    live.value = false;
    await tester.pumpAndSettle();
    expect(find.textContaining('Push'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(repository.writes, 0);
    expect(returned, false);
  });
  testWidgets('login-cycle revocation before confirm sends zero RPCs',
      (tester) async {
    final repository = _DeleteRepo();
    var valid = true;
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => valid,
        (result) => returned = result);
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    valid = false;
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    expect(returned, false);
  });
}
