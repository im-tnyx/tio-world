import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
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
  _FakeRoutineNotesRepository repository, {
  bool Function()? isSessionCurrent,
}) async {
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
            isSessionCurrent: isSessionCurrent ?? () => true,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpLazySection(
  WidgetTester tester,
  _FakeRoutineNotesRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: SizedBox(
        height: 300,
        child: ListView.builder(
          key: const ValueKey('routine-notes-lazy-list'),
          scrollCacheExtent: const ScrollCacheExtent.pixels(0),
          itemCount: 20,
          itemBuilder: (context, index) => index == 0
              ? RoutineNotesSection(
                  routineId: RoutineId(_routine),
                  repository: repository,
                  ownerId: _owner,
                  isSessionCurrent: () => true,
                )
              : const SizedBox(
                  height: 200,
                  child: SizedBox.shrink(),
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

  testWidgets('removes the composer when the opening session is revoked',
      (tester) async {
    var current = true;
    await _pumpSection(
      tester,
      _FakeRoutineNotesRepository(),
      isSessionCurrent: () => current,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('routine-note-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('routine-note-body')),
      'private draft',
    );

    current = false;
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('routine-note-composer-sheet')),
      findsNothing,
    );
  });

  testWidgets('shows unknown delete notice even when the list becomes empty',
      (tester) async {
    final repository = _FakeRoutineNotesRepository(
      notes: [_routineNote()],
      readResults: [
        [_routineNote()],
        const [],
      ],
      deleteError: const RoutineNoteOutcomeUnknown(mutationId: _note),
    );
    await _pumpSection(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('routine-note-delete-$_note')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Note'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('routine-notes-empty')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('routine-notes-notice-message')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('routine-notes-refresh')), findsOneWidget);
    expect(find.textContaining('could not be confirmed'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('routine-notes-refresh')));
    await tester.pumpAndSettle();
    expect(repository.readCalls, 3);
  });

  testWidgets('keeps pending-safe controller alive across lazy list scrolling',
      (tester) async {
    final repository = _FakeRoutineNotesRepository();
    await _pumpLazySection(tester, repository);
    await tester.pumpAndSettle();
    expect(repository.readCalls, 1);

    await tester.drag(
      find.byKey(const ValueKey('routine-notes-lazy-list')),
      const Offset(0, -1600),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('routine-notes-lazy-list')),
      const Offset(0, 1600),
    );
    await tester.pumpAndSettle();

    expect(repository.readCalls, 1);
  });
}

final class _FakeRoutineNotesRepository implements RoutineNotesRepository {
  _FakeRoutineNotesRepository({
    this.notes = const [],
    this.readCompleter,
    this.readError,
    this.readResults = const [],
    this.deleteError,
  });

  List<RoutineNote> notes;
  final Completer<List<RoutineNote>>? readCompleter;
  Object? readError;
  final List<List<RoutineNote>> readResults;
  final Object? deleteError;
  var readCalls = 0;

  @override
  Future<List<RoutineNote>> read(RoutineNoteScope scope) async {
    readCalls++;
    final error = readError;
    if (error != null) throw error;
    if (readResults.isNotEmpty) return [...readResults.removeAt(0)];
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
  Future<void> delete(RoutineNoteDelete command) async {
    if (deleteError != null) throw deleteError!;
  }
}
