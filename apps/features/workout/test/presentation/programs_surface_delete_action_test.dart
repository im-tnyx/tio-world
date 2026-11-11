import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

ProgramId _id(int value) => ProgramId(
      '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}',
    );

Program _program(
  int value,
  String name, {
  bool isDefault = false,
}) =>
    Program(
      id: _id(value),
      name: name,
      isDefault: isDefault,
    );

final class _FakeProgramRepository implements ProgramRepository {
  _FakeProgramRepository({List<Program>? programs})
      : programs = [...?programs];

  final List<Program> programs;
  int listCalls = 0;

  @override
  Future<List<Program>> list() async {
    listCalls++;
    return List.unmodifiable(programs);
  }

  @override
  Future<void> create(Program program) async {
    programs.add(program);
  }

  @override
  Future<void> rename({
    required ProgramId id,
    required String name,
  }) async {
    final index = programs.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final current = programs[index];
      programs[index] = Program(
        id: current.id,
        name: name,
        isDefault: current.isDefault,
      );
    }
  }
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required ProgramRepository repository,
  Future<bool> Function(Program)? onDeleteProgram,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: ProgramsSurface.library(
          repository: repository,
          onManagePressed: () async {},
          onDeleteProgram: onDeleteProgram,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ProgramsSurface Program Delete Action', () {
    testWidgets('non-default program displays Delete Program in action sheet',
        (tester) async {
      final nonDefault = _program(2, 'Hypertrophy', isDefault: false);
      final repo = _FakeProgramRepository(programs: [nonDefault]);

      await _pumpSurface(
        tester,
        repository: repo,
        onDeleteProgram: (p) async => true,
      );

      final overflowFinder =
          find.byKey(ValueKey('program-overflow-${nonDefault.id.value}'));
      expect(overflowFinder, findsOneWidget);

      await tester.tap(overflowFinder);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('program-actions-sheet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('program-action-delete')),
        findsOneWidget,
      );
      expect(find.text('Delete Program'), findsOneWidget);
    });

    testWidgets('default canonical program omits Delete Program action',
        (tester) async {
      final defaultProg = _program(1, 'My Program', isDefault: true);
      final repo = _FakeProgramRepository(programs: [defaultProg]);

      await _pumpSurface(
        tester,
        repository: repo,
        onDeleteProgram: (p) async => true,
      );

      final overflowFinder =
          find.byKey(ValueKey('program-overflow-${defaultProg.id.value}'));
      expect(overflowFinder, findsOneWidget);

      await tester.tap(overflowFinder);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('program-actions-sheet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('program-action-delete')),
        findsNothing,
      );
      expect(find.text('Delete Program'), findsNothing);
    });

    testWidgets('omits Delete Program action when onDeleteProgram is null',
        (tester) async {
      final nonDefault = _program(2, 'Hypertrophy', isDefault: false);
      final repo = _FakeProgramRepository(programs: [nonDefault]);

      await _pumpSurface(
        tester,
        repository: repo,
        onDeleteProgram: null,
      );

      final overflowFinder =
          find.byKey(ValueKey('program-overflow-${nonDefault.id.value}'));
      expect(overflowFinder, findsOneWidget);

      await tester.tap(overflowFinder);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('program-actions-sheet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('program-action-delete')),
        findsNothing,
      );
    });

    testWidgets(
        'tapping Delete Program invokes callback and refreshes programs on true',
        (tester) async {
      final nonDefault = _program(2, 'Hypertrophy', isDefault: false);
      final repo = _FakeProgramRepository(programs: [nonDefault]);
      Program? receivedProgram;

      await _pumpSurface(
        tester,
        repository: repo,
        onDeleteProgram: (p) async {
          receivedProgram = p;
          repo.programs.removeWhere((item) => item.id == p.id);
          return true;
        },
      );

      expect(repo.listCalls, 1);

      await tester.tap(
        find.byKey(ValueKey('program-overflow-${nonDefault.id.value}')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('program-action-delete')));
      await tester.pumpAndSettle();

      expect(receivedProgram?.id, nonDefault.id);
      expect(repo.listCalls, greaterThanOrEqualTo(2));
      expect(find.text('Hypertrophy'), findsNothing);
    });

    testWidgets(
        'tapping Delete Program does not remove program when callback returns false',
        (tester) async {
      final nonDefault = _program(2, 'Hypertrophy', isDefault: false);
      final repo = _FakeProgramRepository(programs: [nonDefault]);
      Program? receivedProgram;

      await _pumpSurface(
        tester,
        repository: repo,
        onDeleteProgram: (p) async {
          receivedProgram = p;
          return false;
        },
      );

      final initialCalls = repo.listCalls;

      await tester.tap(
        find.byKey(ValueKey('program-overflow-${nonDefault.id.value}')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('program-action-delete')));
      await tester.pumpAndSettle();

      expect(receivedProgram?.id, nonDefault.id);
      expect(repo.listCalls, initialCalls);
      expect(find.text('Hypertrophy'), findsOneWidget);
    });

    testWidgets('dismissing action sheet does not invoke onDeleteProgram',
        (tester) async {
      final nonDefault = _program(2, 'Hypertrophy', isDefault: false);
      final repo = _FakeProgramRepository(programs: [nonDefault]);
      var called = false;

      await _pumpSurface(
        tester,
        repository: repo,
        onDeleteProgram: (p) async {
          called = true;
          return true;
        },
      );

      await tester.tap(
        find.byKey(ValueKey('program-overflow-${nonDefault.id.value}')),
      );
      await tester.pumpAndSettle();

      // Tap outside the bottom sheet to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(
        find.byKey(const ValueKey('program-actions-sheet')),
        findsNothing,
      );
    });

    testWidgets('LibraryPage wires onDeleteProgram down to ProgramsSurface',
        (tester) async {
      final nonDefault = _program(2, 'Hypertrophy', isDefault: false);
      final repo = _FakeProgramRepository(programs: [nonDefault]);
      Program? deletedProgram;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: LibraryPage(
              programRepository: repo,
              onProgramsManagePressed: () async {},
              onExercisesPressed: () {},
              onCreateExercisePressed: () {},
              canCreateExercise: false,
              onSearchPressed: () {},
              onDeleteProgram: (p) async {
                deletedProgram = p;
                repo.programs.removeWhere((item) => item.id == p.id);
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProgramsSurface), findsOneWidget);
      expect(find.text('Hypertrophy'), findsOneWidget);
      final overflowFinder =
          find.byKey(ValueKey('program-overflow-${nonDefault.id.value}'));
      expect(overflowFinder, findsOneWidget);

      await tester.tap(overflowFinder);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('program-action-delete')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('program-action-delete')));
      await tester.pumpAndSettle();

      expect(deletedProgram?.id, nonDefault.id);
      expect(find.text('Hypertrophy'), findsNothing);
    });
  });
}
