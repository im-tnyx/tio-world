import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/composition/secure_active_workout_draft_store.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final class _Values implements WorkoutDraftSecureValues {
  final data = <String, String>{};
  String? failWriteSuffix;
  String? failDeleteSuffix;
  bool failRead = false;

  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('secure key unavailable');
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (key.endsWith(failWriteSuffix ?? '\u0000')) {
      throw StateError('secure write failed');
    }
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (key.endsWith(failDeleteSuffix ?? '\u0000')) {
      throw StateError('secure delete failed');
    }
    data.remove(key);
  }
}

const ownerA = '00000000-0000-4000-8000-000000000001';
const ownerB = '00000000-0000-4000-8000-000000000002';
const requestId = '00000000-0000-4000-8000-000000000003';
const draftId = '00000000-0000-4000-8000-000000000004';

ActiveWorkoutDraft _draft(int revision) => ActiveWorkoutDraft(
      id: draftId,
      ownerId: ownerA,
      saveRequestId: requestId,
      revision: revision,
      time: WorkoutTime.start(startedAtUtc: DateTime.utc(2026, 11, 9)),
      exercises: [
        ActiveWorkoutDraftExercise(
          id: '00000000-0000-4000-8000-000000000005',
          exerciseRef: ExerciseRef.catalog('ex_test'),
          displayName: 'Test',
          sets: [
            ActiveWorkoutDraftSet(
              id: '00000000-0000-4000-8000-000000000006',
              prescription: SetPrescription(),
            ),
          ],
        ),
      ],
    );

void main() {
  test('500 performed set payload survives encrypted-slot adapter round trip',
      () async {
    final values = _Values();
    final store = SecureActiveWorkoutDraftStore(
      currentUserId: () => ownerA,
      values: values,
    );
    String id(int n) =>
        '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';
    final draft = ActiveWorkoutDraft(
      id: draftId,
      ownerId: ownerA,
      saveRequestId: requestId,
      time: WorkoutTime.start(startedAtUtc: DateTime.utc(2026, 11, 9)),
      exercises: [
        for (var exercise = 0; exercise < 100; exercise++)
          ActiveWorkoutDraftExercise(
            id: id(1000 + exercise),
            exerciseRef: ExerciseRef.catalog('ex_test'),
            displayName: 'Exercise $exercise',
            sets: [
              for (var set = 0; set < 5; set++)
                ActiveWorkoutDraftSet(
                  id: id(2000 + exercise * 5 + set),
                  prescription: SetPrescription(),
                  reps: 10,
                  loggedAtUtc: DateTime.utc(2026, 11, 9),
                ),
            ],
          ),
      ],
    );
    await store.save(draft);
    final reopened = SecureActiveWorkoutDraftStore(
      currentUserId: () => ownerA,
      values: values,
    );
    expect(
        (await reopened.load())!.exercises.expand((e) => e.sets).length, 500);
    expect(values.data.values.map((v) => v.length).reduce((a, b) => a + b),
        greaterThan(100000));
  });

  test(
      'restarts, account switch and same-account login retain only owner draft',
      () async {
    final values = _Values();
    String? owner = ownerA;
    final store = SecureActiveWorkoutDraftStore(
      currentUserId: () => owner,
      values: values,
    );
    await store.save(_draft(0));
    expect((await store.load())?.saveRequestId, requestId);
    owner = ownerB;
    expect(await store.load(), isNull);
    await expectLater(store.save(_draft(1)), throwsStateError);
    owner = null;
    await expectLater(store.load(), throwsStateError);
    owner = ownerA;
    final restarted = SecureActiveWorkoutDraftStore(
      currentUserId: () => owner,
      values: values,
    );
    expect((await restarted.load())?.exercises.single.sets.single.id,
        '00000000-0000-4000-8000-000000000006');
  });

  test(
      'failed next-slot write preserves committed revision; retry uses same key',
      () async {
    final values = _Values();
    final store = SecureActiveWorkoutDraftStore(
      currentUserId: () => ownerA,
      values: values,
    );
    await store.save(_draft(0));
    values.failWriteSuffix = '.b';
    await expectLater(store.save(_draft(1)), throwsStateError);
    expect((await store.load())?.revision, 0);
    values.failWriteSuffix = null;
    await store.save(_draft(1));
    await store
        .save(_draft(1)); // identical retry after uncertain acknowledgment
    expect((await store.load())?.revision, 1);
    await expectLater(store.save(_draft(0)), throwsStateError);
  });

  test('pointer write failure is visible and identical first write can retry',
      () async {
    final values = _Values()..failWriteSuffix = '.pointer';
    final store = SecureActiveWorkoutDraftStore(
      currentUserId: () => ownerA,
      values: values,
    );
    await expectLater(store.save(_draft(0)), throwsStateError);
    await expectLater(store.load(), throwsFormatException);
    values.failWriteSuffix = null;
    await store.save(_draft(0));
    expect((await store.load())?.id, draftId);
  });

  test('corruption and key loss surface errors without deleting encrypted data',
      () async {
    final values = _Values();
    final store = SecureActiveWorkoutDraftStore(
      currentUserId: () => ownerA,
      values: values,
    );
    await store.save(_draft(0));
    values.failRead = true;
    await expectLater(store.load(), throwsStateError);
    values.failRead = false;
    final slotKey = values.data.keys.singleWhere((key) => key.endsWith('.a'));
    final old = values.data[slotKey]!;
    values.data[slotKey] = '{broken';
    await expectLater(store.load(), throwsFormatException);
    expect(values.data[slotKey], '{broken');
    values.data[slotKey] = old;
    await store.delete();
    expect(await store.load(), isNull);
    expect(
        values.data.keys
            .where((key) => key.endsWith('.a') || key.endsWith('.b')),
        isEmpty);
  });

  for (final slot in ['a', 'b']) {
    test('verified discard remains successful if slot $slot cleanup fails',
        () async {
      final values = _Values();
      final store = SecureActiveWorkoutDraftStore(
        currentUserId: () => ownerA,
        values: values,
      );
      await store.save(_draft(0));
      await store.save(_draft(1));
      values.failDeleteSuffix = '.$slot';
      await store.delete();
      expect(values.data['active_workout_draft_v1.$ownerA.pointer'], 'deleted');
      expect(await store.load(), isNull);
      expect(values.data.containsKey('active_workout_draft_v1.$ownerA.$slot'),
          isTrue);

      values.failDeleteSuffix = null;
      await store.save(_draft(0));
      await store.save(_draft(1));
      expect((await store.load())?.revision, 1);
      await store.delete();
      expect(await store.load(), isNull);
      expect(
          values.data.keys
              .where((key) => key.endsWith('.a') || key.endsWith('.b')),
          isEmpty);
    });
  }

  test('tombstone write failure keeps the committed workout draft', () async {
    final values = _Values();
    final store = SecureActiveWorkoutDraftStore(
      currentUserId: () => ownerA,
      values: values,
    );
    await store.save(_draft(0));
    values.failWriteSuffix = '.pointer';
    await expectLater(store.delete(), throwsStateError);
    expect((await store.load())?.id, draftId);
  });
}
