import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _routine = '22222222-2222-4222-8222-222222222222';
const _note = '33333333-3333-4333-8333-333333333333';

RoutineNote _routineNote({String body = 'Keep shoulders down'}) {
  final date = DateTime.utc(2026, 11, 1);
  return RoutineNote(
    id: _note,
    userId: _owner,
    scope: RoutineNoteScope.routine(RoutineId(_routine)),
    body: body,
    createdAt: date,
    updatedAt: date,
    revision: 1,
  );
}

Future<void> _pumpSection(
  WidgetTester tester,
  _FakeRoutineNotesRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: RoutineNotesSection(
            routineId: RoutineId(_routine),
            repository: repository,
            ownerId: _owner,
            isSessionCurrent: () => true,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows loading then empty state', (tester) async {
    final pending = Completer<List<RoutineNote>>();
    final repository = _FakeRoutineNotesRepository(readCompleter: pending);
    await _pumpSection(tester, repository);

    expect(find.byKey(const ValueKey('routine-notes-loading')), findsOneWidget);
    pending.complete(const []);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('routine-notes-empty')), findsOneWidget);
    expect(find.text('No notes for this Routine yet.'), findsOneWidget);
  });

  testWidgets('shows populated note and delete affordance', (tester) async {
    final repository = _FakeRoutineNotesRepository(
      notes: [_routineNote()],
    );
    await _pumpSection(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Keep shoulders down'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('routine-note-delete-$_note')),
      findsOneWidget,
    );
  });

  testWidgets('shows retry state and reloads after failure', (tester) async {
    final repository = _FakeRoutineNotesRepository(
      readError: const RoutineNoteException(RoutineNoteFailureKind.unavailable),
    );
    await _pumpSection(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('routine-notes-failed')), findsOneWidget);
    repository.readError = null;
    await tester.tap(find.byKey(const ValueKey('routine-notes-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('routine-notes-empty')), findsOneWidget);
  });
}

final class _FakeRoutineNotesRepository implements RoutineNotesRepository {
  _FakeRoutineNotesRepository({
    this.notes = const [],
    this.readCompleter,
    this.readError,
  });

  List<RoutineNote> notes;
  final Completer<List<RoutineNote>>? readCompleter;
  Object? readError;

  @override
  Future<List<RoutineNote>> read(RoutineNoteScope scope) async {
    final error = readError;
    if (error != null) throw error;
    final pending = readCompleter;
    if (pending != null) return pending.future;
    return [...notes];
  }

  @override
  Future<RoutineNote> create(RoutineNoteCreate command) async => _routineNote();

  @override
  Future<RoutineNote> update(RoutineNoteUpdate command) async =>
      throw UnimplementedError();

  @override
  Future<RoutineNote> transfer(RoutineNoteTransfer command) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(RoutineNoteDelete command) async {}
}
