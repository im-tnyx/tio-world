import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _entry = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const _set = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
const _mutation = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
final _routine = RoutineId('11111111-1111-1111-1111-111111111111');

void main() {
  test(
      'identified envelopes project canonical values without losing repeated refs',
      () {
    final prescription = SetPrescription(reps: 8, loadKg: 0, restSeconds: 0);
    final first = RoutineCompositionEntry(
      id: _entry.toUpperCase(),
      exercise: ExerciseRef.catalog('ex_future_catalog_entry'),
      sets: [
        RoutineCompositionSet(
            id: _set.toUpperCase(), prescription: prescription)
      ],
    );
    final second = RoutineCompositionEntry(
      id: _mutation,
      exercise: first.exercise,
      sets: [
        RoutineCompositionSet(id: _routine.value, prescription: prescription)
      ],
    );
    final snapshot = RoutineCompositionSnapshot(
      routineId: _routine,
      revision: 1,
      entries: [first, second],
    );
    expect(first.id, _entry);
    expect(first.sets.single.id, _set);
    expect(
        snapshot.composition.exercises[0], snapshot.composition.exercises[1]);
    expect(snapshot.entries[0], isNot(snapshot.entries[1]));
    expect(snapshot.composition.exercises.first.sets.single, prescription);
  });

  test('save command copies lists and retains IDs on reorder/replay', () {
    final sets = [
      RoutineCompositionSet(id: _set, prescription: SetPrescription(reps: 3))
    ];
    final entry = RoutineCompositionEntry(
        id: _entry, exercise: ExerciseRef.catalog('ex_squat'), sets: sets);
    final entries = [entry];
    final command = RoutineCompositionSave(
      routineId: _routine,
      expectedRevision: 0,
      mutationId: _mutation.toUpperCase(),
      entries: entries,
    );
    sets.clear();
    entries.clear();
    expect(command.entries.single.sets.single.id, _set);
    expect(command.mutationId, _mutation);
    expect(() => command.entries.clear(), throwsUnsupportedError);
    expect(() => entry.sets.clear(), throwsUnsupportedError);
    final reordered = RoutineCompositionSave(
      routineId: _routine,
      expectedRevision: 1,
      mutationId: _set,
      entries: command.entries.reversed.toList(),
    );
    expect(reordered.entries.single.id, _entry);
  });

  test('empty snapshot and save command are valid', () {
    final snapshot =
        RoutineCompositionSnapshot(routineId: _routine, revision: 0);
    final command = RoutineCompositionSave(
        routineId: _routine, expectedRevision: 0, mutationId: _mutation);
    expect(snapshot.composition.exercises, isEmpty);
    expect(snapshot.lastMutationId, isNull);
    expect(snapshot.hasSameContent(command), isTrue);
  });

  test('duplicate entry or globally duplicate set UUIDs are rejected', () {
    final set =
        RoutineCompositionSet(id: _set, prescription: SetPrescription(reps: 1));
    final first = RoutineCompositionEntry(
        id: _entry, exercise: ExerciseRef.catalog('ex_squat'), sets: [set]);
    final second = RoutineCompositionEntry(
        id: _mutation, exercise: first.exercise, sets: [set]);
    for (final entries in [
      [first, first],
      [first, second]
    ]) {
      expect(
          () => RoutineCompositionSave(
              routineId: _routine,
              expectedRevision: 0,
              mutationId: _mutation,
              entries: entries),
          throwsArgumentError);
    }
    expect(
        () => RoutineCompositionEntry(
            id: _entry, exercise: first.exercise, sets: [set, set]),
        throwsArgumentError);
  });

  test('Superset composition requires two or three contiguous known members',
      () {
    const groupId = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
    final group = RoutineSupersetGroup(
      id: groupId,
      restPreset: const RoutineRestTimerPreset(
        normalRestSeconds: 60,
        warmUpRestSeconds: 15,
      ),
    );
    RoutineCompositionEntry member(String id, {String? groupRef}) =>
        RoutineCompositionEntry(
          id: id,
          exercise: ExerciseRef.catalog('ex_squat'),
          supersetId: groupRef,
          sets: [
            RoutineCompositionSet(
              id: 'eeeeeeee-eeee-eeee-eeee-${id.substring(24)}',
              prescription: SetPrescription(reps: 8),
            ),
          ],
        );
    final first = member('10000000-0000-4000-8000-000000000001',
        groupRef: groupId);
    final second = member('10000000-0000-4000-8000-000000000002',
        groupRef: groupId);
    final third = member('10000000-0000-4000-8000-000000000003',
        groupRef: groupId);

    expect(
      RoutineCompositionSnapshot(
        routineId: _routine,
        revision: 1,
        entries: [first, second],
        supersets: [group],
      ).supersets.single.restPreset.normalRestSeconds,
      60,
    );
    expect(
      RoutineCompositionSnapshot(
        routineId: _routine,
        revision: 1,
        entries: [first, second, third],
        supersets: [group],
      ).entries,
      hasLength(3),
    );
    for (final invalidEntries in [
      [first],
      [first, second, third, member(
        '10000000-0000-4000-8000-000000000004', groupRef: groupId)],
      [first, member('10000000-0000-4000-8000-000000000005'), second],
    ]) {
      expect(
        () => RoutineCompositionSnapshot(
          routineId: _routine,
          revision: 1,
          entries: invalidEntries,
          supersets: [group],
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => RoutineCompositionSnapshot(
        routineId: _routine,
        revision: 1,
        entries: [first, second],
      ),
      throwsArgumentError,
    );
  });

  test('Superset labels follow ordered Routine blocks', () {
    const firstGroup = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
    const secondGroup = 'ffffffff-ffff-ffff-ffff-ffffffffffff';
    RoutineCompositionEntry entry(String id, String? groupId) =>
        RoutineCompositionEntry(
          id: id,
          exercise: ExerciseRef.catalog('ex_squat'),
          supersetId: groupId,
          sets: [
            RoutineCompositionSet(
              id: 'eeeeeeee-eeee-eeee-eeee-${id.substring(24)}',
              prescription: SetPrescription(reps: 8),
            ),
          ],
        );
    final entries = [
      entry('10000000-0000-4000-8000-000000000001', firstGroup),
      entry('10000000-0000-4000-8000-000000000002', firstGroup),
      entry('10000000-0000-4000-8000-000000000003', null),
      entry('10000000-0000-4000-8000-000000000004', secondGroup),
      entry('10000000-0000-4000-8000-000000000005', secondGroup),
    ];
    expect(routineSupersetMemberLabel(entries, entries[0].id), 'A1');
    expect(routineSupersetMemberLabel(entries, entries[1].id), 'A2');
    expect(routineSupersetMemberLabel(entries, entries[3].id), 'B1');
    expect(routineSupersetMemberLabel(entries, entries[4].id), 'B2');
    expect(routineSupersetMemberLabel(entries, entries[2].id), isNull);
  });

  test('UUID grammar accepts canonical non-v4 and rejects invalid identities',
      () {
    expect(
        RoutineCompositionSet(
                id: _entry, prescription: SetPrescription(reps: 1))
            .id,
        _entry);
    for (final id in [
      '',
      'not-a-uuid',
      ' $_entry',
      _entry.replaceAll('-', '')
    ]) {
      expect(
          () => RoutineCompositionSet(
              id: id, prescription: SetPrescription(reps: 1)),
          throwsArgumentError);
      expect(
          () => RoutineCompositionSave(
              routineId: _routine, expectedRevision: 0, mutationId: id),
          throwsArgumentError);
    }
  });

  test(
      'negative revisions and PostgreSQL int32 prescription overflow are rejected',
      () {
    expect(
        () => RoutineCompositionSave(
            routineId: _routine, expectedRevision: -1, mutationId: _mutation),
        throwsArgumentError);
    expect(() => RoutineCompositionSnapshot(routineId: _routine, revision: -1),
        throwsArgumentError);
    // Invalid Reps fail at value-object construction; other int32 bounds
    // are enforced by the identified persistence envelope.
    expect(() => SetPrescription(reps: 2147483648), throwsArgumentError);
    expect(
        () => RoutineCompositionSet(
            id: _set,
            prescription: SetPrescription(reps: 1, restSeconds: 2147483648)),
        throwsArgumentError);
    expect(
        RoutineCompositionSet(
                id: _set,
                prescription:
                    SetPrescription(reps: 2147483647, restSeconds: 2147483647))
            .prescription
            .reps,
        2147483647);
  });

  test('null differs from explicit zero and equality includes persisted IDs',
      () {
    final nullable =
        RoutineCompositionSet(id: _set, prescription: SetPrescription(reps: 1));
    final zero = RoutineCompositionSet(
        id: _set,
        prescription: SetPrescription(reps: 1, loadKg: 0, restSeconds: 0));
    final differentId =
        RoutineCompositionSet(id: _entry, prescription: nullable.prescription);
    expect(nullable, isNot(zero));
    expect(nullable, isNot(differentId));
    expect(nullable,
        RoutineCompositionSet(id: _set, prescription: nullable.prescription));
    expect(
        nullable.hashCode,
        RoutineCompositionSet(id: _set, prescription: nullable.prescription)
            .hashCode);
  });
}
