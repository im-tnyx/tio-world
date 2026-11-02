import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _note = '33333333-3333-4333-8333-333333333333';
const _mutation = '44444444-4444-4444-8444-444444444444';
const _exercise = 'ex_barbell_bench_press';

ExerciseNoteDraftSnapshot _draft({
  String draftId = 'entry-1:0',
  RoutineNoteType type = RoutineNoteType.pinnedExercise,
  String body = 'Keep shoulders down',
}) =>
    ExerciseNoteDraftSnapshot(
      draftId: draftId,
      exerciseRef: ExerciseRef.catalog(_exercise),
      type: type,
      body: body,
    );

RoutineNote _savedNote(RoutineNoteCreate command) {
  final now = DateTime.utc(2026, 11, 2);
  return RoutineNote(
    id: command.id,
    userId: _owner,
    scope: command.scope,
    body: command.body,
    createdAt: now,
    updatedAt: now,
    revision: 1,
    lastMutationId: command.mutationId,
  );
}

void main() {
  test('uses canonical Exercise scope and stable command IDs on retry',
      () async {
    final repository = _FakeRoutineNotesRepository(
      createErrors: [
        const RoutineNoteException(RoutineNoteFailureKind.unavailable),
      ],
    );
    final uuids = [_note, _mutation];
    final bridge = RoutineNotesSaveBridge(
      repository: repository,
      ownerId: _owner,
      isSessionCurrent: () => true,
      newUuid: () => uuids.removeAt(0),
    );

    final first = await bridge.save(drafts: [_draft()], routineId: null);
    final second = await bridge.save(drafts: [_draft()], routineId: null);

    expect(first.status, RoutineNotesSaveStatus.unavailable);
    expect(second.status, RoutineNotesSaveStatus.saved);
    expect(repository.createCalls, 2);
    expect(repository.commands[0].id, _note);
    expect(repository.commands[1].id, _note);
    expect(repository.commands[0].mutationId, _mutation);
    expect(repository.commands[1].mutationId, _mutation);
    expect(
      repository.commands[0].scope,
      RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise)),
    );
  });

  test('does not save a Routine-scoped draft before durable Routine identity',
      () async {
    final repository = _FakeRoutineNotesRepository();
    final bridge = RoutineNotesSaveBridge(
      repository: repository,
      ownerId: _owner,
      isSessionCurrent: () => true,
      newUuid: () => _note,
    );

    final result = await bridge.save(
      drafts: [
        _draft(type: RoutineNoteType.pinnedRoutine),
      ],
      routineId: null,
    );

    expect(result.status, RoutineNotesSaveStatus.invalid);
    expect(repository.createCalls, 0);
  });

  test('reconciles unknown save without issuing a duplicate create', () async {
    final repository = _FakeRoutineNotesRepository(unknownCreate: true);
    final uuids = [_note, _mutation];
    final bridge = RoutineNotesSaveBridge(
      repository: repository,
      ownerId: _owner,
      isSessionCurrent: () => true,
      newUuid: () => uuids.removeAt(0),
    );

    final first = await bridge.save(drafts: [_draft()], routineId: null);
    expect(first.status, RoutineNotesSaveStatus.unknown);
    expect(repository.createCalls, 1);

    repository.notes = [_savedNote(repository.commands.single)];
    final second = await bridge.save(drafts: [_draft()], routineId: null);
    expect(second.status, RoutineNotesSaveStatus.saved);
    expect(repository.createCalls, 1);
    expect(repository.readCalls, greaterThanOrEqualTo(3));
  });

  test('enforces the five-note scope quota before create', () async {
    final scope = RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise));
    final repository = _FakeRoutineNotesRepository(
      notes: List.generate(
        routineNotesMaximumCount,
        (index) => _existingNote(scope, index),
      ),
    );
    final bridge = RoutineNotesSaveBridge(
      repository: repository,
      ownerId: _owner,
      isSessionCurrent: () => true,
      newUuid: () => _note,
    );

    final result = await bridge.save(drafts: [_draft()], routineId: null);

    expect(result.status, RoutineNotesSaveStatus.quota);
    expect(repository.createCalls, 0);
  });

  test('removed quota-rejected draft can be discarded before retry', () async {
    final scope = RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise));
    final repository = _FakeRoutineNotesRepository(
      notes: List.generate(
        routineNotesMaximumCount,
        (index) => _existingNote(scope, index),
      ),
    );
    final bridge = RoutineNotesSaveBridge(
      repository: repository,
      ownerId: _owner,
      isSessionCurrent: () => true,
      newUuid: () => _note,
    );

    final rejected = await bridge.save(drafts: [_draft()], routineId: null);
    final discarded = await bridge.save(drafts: const [], routineId: null);

    expect(rejected.status, RoutineNotesSaveStatus.quota);
    expect(discarded.status, RoutineNotesSaveStatus.saved);
    expect(repository.createCalls, 0);
  });

  test('undispatched quota rejection permits a corrected draft retry',
      () async {
    final scope = RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise));
    final repository = _FakeRoutineNotesRepository(
      notes: List.generate(
        routineNotesMaximumCount,
        (index) => _existingNote(scope, index),
      ),
    );
    final bridge = RoutineNotesSaveBridge(
      repository: repository,
      ownerId: _owner,
      isSessionCurrent: () => true,
      newUuid: () => _note,
    );

    final rejected = await bridge.save(
      drafts: [_draft(body: 'Original draft')],
      routineId: null,
    );
    repository.notes = repository.notes.sublist(1);
    final retried = await bridge.save(
      drafts: [_draft(body: 'Corrected draft')],
      routineId: null,
    );

    expect(rejected.status, RoutineNotesSaveStatus.quota);
    expect(retried.status, RoutineNotesSaveStatus.saved);
    expect(repository.commands.single.body, 'Corrected draft');
  });

  test('confirmed draft cannot be edited into an unpersisted Note', () async {
    final repository = _FakeRoutineNotesRepository();
    final bridge = RoutineNotesSaveBridge(
      repository: repository,
      ownerId: _owner,
      isSessionCurrent: () => true,
      newUuid: () => _note,
    );

    expect(
      (await bridge.save(drafts: [_draft()], routineId: null)).status,
      RoutineNotesSaveStatus.saved,
    );
    final changed = await bridge.save(
      drafts: [_draft(body: 'Changed after save')],
      routineId: null,
    );

    expect(changed.status, RoutineNotesSaveStatus.invalid);
    expect(repository.createCalls, 1);
  });

  test('rejects blank and over-limit drafts before persistence', () async {
    final repository = _FakeRoutineNotesRepository();
    final bridge = RoutineNotesSaveBridge(
      repository: repository,
      ownerId: _owner,
      isSessionCurrent: () => true,
      newUuid: () => _note,
    );

    expect(
      (await bridge.save(drafts: [_draft(body: '   ')], routineId: null))
          .status,
      RoutineNotesSaveStatus.saved,
    );
    expect(
      (await bridge.save(
        drafts: [_draft(body: 'x' * 501)],
        routineId: null,
      ))
          .status,
      RoutineNotesSaveStatus.invalid,
    );
    expect(repository.createCalls, 0);
  });
}

RoutineNote _existingNote(RoutineNoteScope scope, int index) {
  final now = DateTime.utc(2026, 11, 1).add(Duration(minutes: index));
  return RoutineNote(
    id: '55555555-5555-4555-8555-55555555555$index',
    userId: _owner,
    scope: scope,
    body: 'Existing $index',
    createdAt: now,
    updatedAt: now,
    revision: 1,
  );
}

final class _FakeRoutineNotesRepository implements RoutineNotesRepository {
  _FakeRoutineNotesRepository({
    this.notes = const [],
    this.createErrors = const [],
    this.unknownCreate = false,
  });

  List<RoutineNote> notes;
  final List<Object> createErrors;
  final bool unknownCreate;
  final commands = <RoutineNoteCreate>[];
  var readCalls = 0;
  var createCalls = 0;

  @override
  Future<List<RoutineNote>> read(RoutineNoteScope scope) async {
    readCalls++;
    return notes.where((note) => note.scope == scope).toList();
  }

  @override
  Future<RoutineNote> create(RoutineNoteCreate command) async {
    createCalls++;
    commands.add(command);
    if (createErrors.isNotEmpty) throw createErrors.removeAt(0);
    if (unknownCreate) {
      throw RoutineNoteOutcomeUnknown(mutationId: command.mutationId);
    }
    final saved = _savedNote(command);
    notes = [...notes, saved];
    return saved;
  }

  @override
  Future<RoutineNote> update(RoutineNoteUpdate command) async =>
      throw UnimplementedError();

  @override
  Future<RoutineNote> transfer(RoutineNoteTransfer command) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(RoutineNoteDelete command) async =>
      throw UnimplementedError();
}
