import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _routine = '22222222-2222-4222-8222-222222222222';
const _note1 = '33333333-3333-4333-8333-333333333333';
const _note2 = '44444444-4444-4444-8444-444444444444';
const _mutation1 = '55555555-5555-4555-8555-555555555555';
const _mutation2 = '66666666-6666-4666-8666-666666666666';
const _exercise = 'ex_barbell_bench_press';

RoutineNote _note({
  String id = _note1,
  String body = 'Existing note',
  DateTime? createdAt,
  int revision = 1,
}) {
  final created = createdAt ?? DateTime.utc(2026, 11, 1);
  return RoutineNote(
    id: id,
    userId: _owner,
    scope: RoutineNoteScope.routine(RoutineId(_routine)),
    body: body,
    createdAt: created,
    updatedAt: created,
    revision: revision,
  );
}

RoutineNote _exerciseNote({String body = 'Exercise cue'}) {
  final created = DateTime.utc(2026, 11, 1);
  return RoutineNote(
    id: _note1,
    userId: _owner,
    scope: RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise)),
    body: body,
    createdAt: created,
    updatedAt: created,
    revision: 2,
  );
}

void main() {
  test('loads ordered Routine notes and enforces owner/scope', () async {
    final repository = _FakeRoutineNotesRepository(
      notes: [
        _note(id: _note2, createdAt: DateTime.utc(2026, 11, 2)),
        _note(id: _note1, createdAt: DateTime.utc(2026, 11, 1)),
      ],
    );
    final controller = _controller(repository);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state.status, RoutineNotesStatus.ready);
    expect(controller.state.notes.map((note) => note.id), [_note1, _note2]);
    expect(repository.readScope, RoutineNoteScope.routine(RoutineId(_routine)));
  });

  test('create uses normalized body and stable note/mutation UUIDs', () async {
    final repository = _FakeRoutineNotesRepository(
      createResult: _note(id: _note2, body: 'saved'),
    );
    final controller = _controller(
      repository,
      uuids: [_note2, _mutation1],
    );
    addTearDown(controller.dispose);
    await controller.load();

    final created = await controller.create('  saved  ');

    expect(created, isTrue);
    expect(repository.createCommand?.id, _note2);
    expect(repository.createCommand?.mutationId, _mutation1);
    expect(repository.createCommand?.scope,
        RoutineNoteScope.routine(RoutineId(_routine)));
    expect(repository.createCommand?.body, 'saved');
    expect(controller.state.notes.single.id, _note2);
  });

  test('Exercise scope uses canonical identity and transfers atomically',
      () async {
    final repository = _FakeRoutineNotesRepository(
      notes: [_exerciseNote()],
      transferResult: _note(),
    );
    final controller = _controller(
      repository,
      scope: RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise)),
      uuids: [_mutation2],
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(repository.readScope,
        RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise)));

    expect(
      await controller.transfer(
        controller.state.notes.single,
        RoutineNoteScope.routine(RoutineId(_routine)),
      ),
      isTrue,
    );
    expect(repository.transferCommand?.id, _note1);
    expect(repository.transferCommand?.expectedRevision, 2);
    expect(repository.transferCommand?.destination,
        RoutineNoteScope.routine(RoutineId(_routine)));
    expect(controller.state.notes, isEmpty);
  });

  test('keeps the source note when transfer destination quota is rejected',
      () async {
    final repository = _FakeRoutineNotesRepository(
      notes: [_exerciseNote()],
      transferError:
          const RoutineNoteException(RoutineNoteFailureKind.quotaExceeded),
    );
    final controller = _controller(
      repository,
      scope: RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise)),
      uuids: [_mutation2],
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(
      await controller.transfer(
        controller.state.notes.single,
        RoutineNoteScope.routine(RoutineId(_routine)),
      ),
      isFalse,
    );
    expect(repository.notes.single.scope,
        RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise)));
    expect(controller.state.failure, RoutineNoteFailureKind.quotaExceeded);
  });

  test('rejects a sixth note without calling the repository', () async {
    final repository = _FakeRoutineNotesRepository(
      notes: List.generate(
        routineNotesMaximumCount,
        (index) => _note(
          id: '77777777-7777-4777-8777-77777777777${index + 1}',
        ),
      ),
    );
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('sixth'), isFalse);
    expect(controller.state.failure, RoutineNoteFailureKind.quotaExceeded);
    expect(repository.createCalls, 0);
  });

  test('rejects blank and over-limit bodies before persistence', () async {
    final repository = _FakeRoutineNotesRepository();
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('   '), isFalse);
    expect(controller.state.failure, RoutineNoteFailureKind.invalidRequest);
    expect(await controller.create('x' * 501), isFalse);
    expect(controller.state.failure, RoutineNoteFailureKind.invalidRequest);
    expect(repository.createCalls, 0);
  });

  test('retryable create failure keeps the composer-ready state', () async {
    final repository = _FakeRoutineNotesRepository(
      createErrors: [
        const RoutineNoteException(RoutineNoteFailureKind.unavailable),
      ],
      createResult: _note(id: _note2, body: 'retry me'),
    );
    final controller = _controller(repository, uuids: [
      _note2,
      _mutation1,
      _note2,
      _mutation2,
    ]);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('retry me'), isFalse);
    expect(controller.state.isReady, isTrue);
    expect(controller.state.failure, RoutineNoteFailureKind.unavailable);
    expect(await controller.create('retry me'), isTrue);
    expect(repository.createCalls, 2);
  });

  test('does not publish a read result after the session changes', () async {
    final read = Completer<List<RoutineNote>>();
    final repository = _FakeRoutineNotesRepository(readCompleter: read);
    var current = true;
    final controller = _controller(repository, isCurrent: () => current);
    addTearDown(controller.dispose);

    final loading = controller.load();
    await pumpEventQueue();
    current = false;
    read.complete([_note()]);
    await loading;

    expect(controller.state.status, RoutineNotesStatus.loading);
    expect(controller.state.notes, isEmpty);
  });

  test('delete sends expected revision and removes only the owned note',
      () async {
    final repository = _FakeRoutineNotesRepository(notes: [_note()]);
    final controller = _controller(repository, uuids: [_mutation2]);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.delete(controller.state.notes.single), isTrue);

    expect(repository.deleteCommand?.id, _note1);
    expect(repository.deleteCommand?.expectedRevision, 1);
    expect(repository.deleteCommand?.mutationId, _mutation2);
    expect(controller.state.notes, isEmpty);
  });

  test('unknown create outcome reloads and exposes confirmation notice',
      () async {
    final repository = _FakeRoutineNotesRepository(
      createError: const RoutineNoteOutcomeUnknown(mutationId: _mutation1),
      notesAfterUnknown: [_note(body: 'server saved')],
    );
    final controller = _controller(repository, uuids: [_note2, _mutation1]);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('server saved'), isFalse);

    expect(controller.state.notes.single.body, 'server saved');
    expect(controller.state.actionNotice, contains('could not be confirmed'));
    expect(controller.hasPendingMutation, isTrue);
    expect(await controller.create('server saved'), isFalse);
    expect(repository.createCalls, 1);
    expect(repository.readCalls, 2);
  });

  test('unknown create becomes success when the original note ID is read back',
      () async {
    final repository = _FakeRoutineNotesRepository(
      createError: const RoutineNoteOutcomeUnknown(mutationId: _mutation1),
      notesAfterUnknown: [_note(id: _note2, body: 'confirmed')],
    );
    final controller = _controller(repository, uuids: [_note2, _mutation1]);
    addTearDown(controller.dispose);
    await controller.load();

    expect(await controller.create('confirmed'), isTrue);
    expect(controller.hasPendingMutation, isFalse);
    expect(controller.state.actionNotice, 'Note save confirmed.');
  });

  test('preserves pending create recovery after deleting an older note',
      () async {
    final repository = _FakeRoutineNotesRepository(
      notes: [_note()],
      createError: const RoutineNoteOutcomeUnknown(mutationId: _mutation1),
      readResults: [
        [_note()],
        [_note()],
        [_note(id: _note2, body: 'pending save')],
      ],
    );
    final controller = _controller(
      repository,
      uuids: [_note2, _mutation1, _mutation2],
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(await controller.create('pending save'), isFalse);
    expect(controller.hasPendingMutation, isTrue);
    expect(controller.state.actionNotice, contains('Refresh'));

    expect(await controller.delete(controller.state.notes.single), isTrue);
    expect(controller.hasPendingMutation, isTrue);
    expect(controller.canCreate, isFalse);
    expect(controller.state.actionNotice, contains('Refresh'));

    expect(await controller.create('duplicate attempt'), isFalse);
    expect(repository.createCalls, 1);
    expect(repository.createCommand?.id, _note2);
    expect(repository.createCommand?.mutationId, _mutation1);

    await controller.load();
    expect(controller.hasPendingMutation, isFalse);
    expect(controller.state.actionNotice, 'Note save confirmed.');
    expect(controller.state.notes.single.id, _note2);
    expect(repository.createCalls, 1);
  });
}

RoutineNotesController _controller(
  _FakeRoutineNotesRepository repository, {
  List<String> uuids = const [_note2, _mutation1],
  bool Function()? isCurrent,
  RoutineNoteScope? scope,
}) {
  final values = [...uuids];
  return scope == null
      ? RoutineNotesController(
          routineId: RoutineId(_routine),
          repository: repository,
          ownerId: _owner,
          isSessionCurrent: isCurrent ?? () => true,
          newUuid: () => values.removeAt(0),
        )
      : RoutineNotesController.forScope(
          scope: scope,
          repository: repository,
          ownerId: _owner,
          isSessionCurrent: isCurrent ?? () => true,
          newUuid: () => values.removeAt(0),
        );
}

final class _FakeRoutineNotesRepository implements RoutineNotesRepository {
  _FakeRoutineNotesRepository({
    this.notes = const [],
    this.createResult,
    this.createError,
    this.createErrors = const [],
    this.notesAfterUnknown,
    this.readCompleter,
    this.readResults = const [],
    this.transferResult,
    this.transferError,
  });

  List<RoutineNote> notes;
  final RoutineNote? createResult;
  final Object? createError;
  final List<Object> createErrors;
  final List<RoutineNote>? notesAfterUnknown;
  final Completer<List<RoutineNote>>? readCompleter;
  final List<List<RoutineNote>> readResults;
  final RoutineNote? transferResult;
  final Object? transferError;
  RoutineNoteScope? readScope;
  RoutineNoteCreate? createCommand;
  RoutineNoteDelete? deleteCommand;
  RoutineNoteTransfer? transferCommand;
  var readCalls = 0;
  var createCalls = 0;
  var transferCalls = 0;

  @override
  Future<List<RoutineNote>> read(RoutineNoteScope scope) async {
    readCalls++;
    readScope = scope;
    final pending = readCompleter;
    if (pending != null) return pending.future;
    if (readResults.isNotEmpty) return [...readResults.removeAt(0)];
    if (readCalls > 1 && notesAfterUnknown != null) {
      notes = notesAfterUnknown!;
    }
    return [...notes];
  }

  @override
  Future<RoutineNote> create(RoutineNoteCreate command) async {
    createCalls++;
    createCommand = command;
    if (createErrors.isNotEmpty) throw createErrors.removeAt(0);
    final error = createError;
    if (error != null) throw error;
    return createResult!;
  }

  @override
  Future<RoutineNote> update(RoutineNoteUpdate command) async =>
      throw UnimplementedError();

  @override
  Future<RoutineNote> transfer(RoutineNoteTransfer command) async {
    transferCalls++;
    transferCommand = command;
    final error = transferError;
    if (error != null) throw error;
    return transferResult!;
  }

  @override
  Future<void> delete(RoutineNoteDelete command) async {
    deleteCommand = command;
    notes = notes.where((note) => note.id != command.id).toList();
  }
}
