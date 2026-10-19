import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-1111-1111-111111111111';
const _otherOwner = '22222222-2222-2222-2222-222222222222';
const _mutation = '33333333-3333-3333-3333-333333333333';
const _otherMutation = '44444444-4444-4444-4444-444444444444';
final _routine = RoutineId('55555555-5555-5555-5555-555555555555');
String _id(int value) =>
    '${value.toRadixString(16).padLeft(8, '0')}-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

Map<String, dynamic> _header([int revision = 0, String? token]) => {
      'id': _routine.value,
      'user_id': _owner,
      'composition_revision': revision,
      'last_composition_mutation_id': token,
      'name': 'Old Name',
    };
Map<String, dynamic> _entry(int id, int position, {String? custom}) => {
      'id': _id(id),
      'user_id': _owner,
      'routine_id': _routine.value,
      'position': position,
      'catalog_exercise_id': custom == null ? 'ex_squat' : null,
      'user_exercise_id': custom,
    };
Map<String, dynamic> _set(int id, int entry, int position) => {
      'id': _id(id),
      'user_id': _owner,
      'routine_exercise_id': _id(entry),
      'position': position,
      'reps': 8,
      'reps_max': null,
      'set_type': 'normal',
      'load_kg': null,
      'distance_meters': null,
      'duration_seconds': null,
      'rest_seconds': null,
      'entry': {
        'id': _id(entry),
        'user_id': _owner,
        'routine_id': _routine.value
      },
    };
RoutineCompositionSave _command(
        {int revision = 0, List<RoutineCompositionEntry> entries = const []}) =>
    RoutineCompositionSave(
        routineId: _routine,
        expectedRevision: revision,
        mutationId: _mutation,
        entries: entries);
Matcher _failure(RoutineCompositionFailureKind kind) =>
    isA<RoutineCompositionException>().having((e) => e.kind, 'kind', kind);

void main() {
  test('type hint is carried only on Custom entries, with explicit null', () {
    final customId = _id(61);
    final catalogId = _id(62);
    final custom = RoutineCompositionEntry(
      id: customId, exercise: ExerciseRef.userCreated(_id(31)),
      sets: [RoutineCompositionSet(
        id: _id(71), prescription: SetPrescription(reps: 12),
      )],
    );
    final catalog = RoutineCompositionEntry(
      id: catalogId, exercise: ExerciseRef.catalog('ex_bench_press'),
      sets: [RoutineCompositionSet(
        id: _id(72), prescription: SetPrescription(reps: 8),
      )],
    );
    final command = RoutineCompositionSave(
      routineId: _routine, expectedRevision: 0, mutationId: _mutation,
      entries: [custom, catalog],
      expectedCustomTypes: {customId: ExerciseType.weightReps},
    );
    final payload = SupabaseRoutineCompositionRepository.payload(command);
    expect(payload[0]['expected_exercise_type'], 'weight_reps');
    expect(payload[1].containsKey('expected_exercise_type'), isFalse);
    final none = SupabaseRoutineCompositionRepository.payload(
      RoutineCompositionSave(
        routineId: _routine, expectedRevision: 0, mutationId: _mutation,
        entries: [custom], expectedCustomTypes: {customId: null},
      ),
    );
    expect(none.single.containsKey('expected_exercise_type'), isTrue);
    expect(none.single['expected_exercise_type'], isNull);
    expect(SupabaseRoutineCompositionRepository.payload(
      RoutineCompositionSave(
        routineId: _routine, expectedRevision: 0, mutationId: _mutation,
        entries: [custom],
      ),
    ).single.containsKey('expected_exercise_type'), isFalse,
      reason: 'older clients can omit the optional type hint');
  });

  test(
      'reads owner-scoped rows in position order with independent repeated refs and nullable sets',
      () async {
    final gateway = _Gateway()
      ..entries = [_entry(1, 1), _entry(2, 0)]
      ..sets = [_set(10, 1, 1), _set(11, 1, 0), _set(12, 2, 0)];
    gateway.sets[0]['load_kg'] = 0;
    gateway.sets[0]['rest_seconds'] = 0;
    final snapshot = (await gateway.repository.read(_routine))!;
    expect(snapshot.entries.map((e) => e.id), [_id(2), _id(1)]);
    expect(snapshot.entries[0].exercise, snapshot.entries[1].exercise);
    expect(snapshot.entries[1].sets.map((s) => s.id), [_id(11), _id(10)]);
    expect(snapshot.entries[1].sets[0].prescription.loadKg, isNull);
    expect(snapshot.entries[1].sets[1].prescription.loadKg, 0);
    expect(snapshot.entries[1].sets[1].prescription.restSeconds, 0);
    expect(snapshot.composition.exercises[1].sets.length, 2);
    expect(
        gateway.scopes.every((scope) => scope == '$_owner/${_routine.value}'),
        isTrue);
  });

  test('empty existing composition is distinct from missing Routine', () async {
    final gateway = _Gateway();
    expect((await gateway.repository.read(_routine))!.entries, isEmpty);
    gateway.header = null;
    expect(await gateway.repository.read(_routine), isNull);
  });

  test(
      'unknown well-formed catalog and archived Custom identity need no metadata lookup',
      () async {
    final gateway = _Gateway()
      ..entries = [_entry(1, 0), _entry(2, 1, custom: _otherOwner)];
    gateway.entries[0]['catalog_exercise_id'] = 'ex_future_catalog_entry';
    final snapshot = (await gateway.repository.read(_routine))!;
    expect(snapshot.entries[0].exercise.value, 'ex_future_catalog_entry');
    expect(snapshot.entries[1].exercise, ExerciseRef.userCreated(_otherOwner));
  });

  test(
      'complete pages exceed 1000 entries/sets and continue after a lower server cap',
      () async {
    final gateway = _Gateway()
      ..cap = 137
      ..entries = [for (var i = 0; i < 1007; i++) _entry(i + 1, 1006 - i)]
      ..sets = [for (var i = 0; i < 1007; i++) _set(i + 10000, 1, i)];
    final snapshot = (await gateway.repository.read(_routine))!;
    expect(snapshot.entries.length, 1007);
    expect(snapshot.entries.first.id, _id(1007));
    expect(snapshot.entries.last.sets.length, 1007);
    expect(gateway.entryEmptyPages, 1);
    expect(gateway.setEmptyPages, 1);
    expect(gateway.entryCalls, 9);
    expect(gateway.setCalls, 9);
  });

  test('exact page boundary still requests a final empty page', () async {
    final gateway = _Gateway()..entries = [_entry(1, 0), _entry(2, 1)];
    await gateway.repo(pageSize: 2).read(_routine);
    expect(gateway.entryCalls, 2);
    expect(gateway.entryEmptyPages, 1);
  });

  test(
      'mid-read changed revision discards even malformed intermediate rows and restarts',
      () async {
    final gateway = _Gateway()..entries = [_entry(1, 9)];
    gateway.onHeader = (call) {
      if (call == 2) {
        gateway.header = _header(1, _mutation);
        gateway.entries = [_entry(2, 0)];
      }
    };
    final snapshot = (await gateway.repository.read(_routine))!;
    expect(snapshot.revision, 1);
    expect(snapshot.entries.single.id, _id(2));
    expect(gateway.headerCalls, 4);
  });

  test('provisional duplicate cursor can retry if ending revision changed',
      () async {
    final gateway = _Gateway()..entries = [_entry(1, 0), _entry(1, 1)];
    gateway.onHeader = (call) {
      if (call == 2) {
        gateway.header = _header(1, _mutation);
        gateway.entries = [_entry(2, 0)];
      }
    };
    expect(
        (await gateway.repository.read(_routine))!.entries.single.id, _id(2));
  });

  test('contention is bounded and parent disappearance returns missing',
      () async {
    final gateway = _Gateway();
    gateway.onHeader = (call) => gateway.header = _header(call, _mutation);
    await expectLater(gateway.repository.read(_routine),
        throwsA(_failure(RoutineCompositionFailureKind.readConflict)));
    expect(gateway.headerCalls, 6);
    gateway.onHeader = (call) {
      if (call == 8) gateway.header = null;
    };
    expect(await gateway.repository.read(_routine), isNull);
  });

  final invalidEntries = <String, void Function(Map<String, dynamic>)>{
    'missing id': (row) => row.remove('id'),
    'invalid UUID': (row) => row['id'] = 'bad',
    'wrong Routine': (row) => row['routine_id'] = _otherOwner,
    'gapped position': (row) => row['position'] = 1,
    'fractional position': (row) => row['position'] = 0.0,
    'missing reference key': (row) => row.remove('user_exercise_id'),
    'neither reference': (row) => row['catalog_exercise_id'] = null,
    'both references': (row) => row['user_exercise_id'] = _otherOwner,
    'catalog slug': (row) => row['catalog_exercise_id'] = 'Squat',
    'malformed Custom': (row) {
      row['catalog_exercise_id'] = null;
      row['user_exercise_id'] = 'bad';
    },
  };
  for (final invalid in invalidEntries.entries) {
    test('stable malformed entry: ${invalid.key}', () async {
      final row = _entry(1, 0);
      invalid.value(row);
      final gateway = _Gateway()..entries = [row];
      await expectLater(gateway.repository.read(_routine),
          throwsA(_failure(RoutineCompositionFailureKind.malformedData)));
    });
  }
  final invalidSets = <String, void Function(Map<String, dynamic>)>{
    'missing nullable key': (row) => row.remove('load_kg'),
    'missing type': (row) => row.remove('set_type'),
    'missing range key': (row) => row.remove('reps_max'),
    'missing distance key': (row) => row.remove('distance_meters'),
    'missing duration key': (row) => row.remove('duration_seconds'),
    'nonfinite distance': (row) => row['distance_meters'] = double.nan,
    'negative distance': (row) => row['distance_meters'] = -1,
    'fractional duration': (row) => row['duration_seconds'] = 2.5,
    'negative duration': (row) => row['duration_seconds'] = -1,
    'duration exceeds int32': (row) => row['duration_seconds'] = 2147483648,
    'range with unspecified reps': (row) { row['reps'] = null; row['reps_max'] = 10; },
    'unknown type': (row) => row['set_type'] = 'random',
    'wrong type kind': (row) => row['set_type'] = 12,
    'range max below minimum': (row) => row['reps_max'] = 7,
    'range max not integer': (row) => row['reps_max'] = 12.5,
    'orphan': (row) => row['routine_exercise_id'] = _id(99),
    'bad join': (row) => row['entry'] = null,
    'wrong joined Routine': (row) =>
        (row['entry'] as Map<String, dynamic>)['routine_id'] = _otherOwner,
    'zero reps': (row) => row['reps'] = 0,
    'fractional reps': (row) => row['reps'] = 8.0,
    'int32 reps overflow': (row) => row['reps'] = 2147483648,
    'negative rest': (row) => row['rest_seconds'] = -1,
    'int32 rest overflow': (row) => row['rest_seconds'] = 2147483648,
    'string load': (row) => row['load_kg'] = '1',
    'infinite load': (row) => row['load_kg'] = double.infinity,
    'NaN load': (row) => row['load_kg'] = double.nan,
    'negative load': (row) => row['load_kg'] = -1,
    'position gap': (row) => row['position'] = 1,
  };
  for (final invalid in invalidSets.entries) {
    test('stable malformed set: ${invalid.key}', () async {
      final row = _set(10, 1, 0);
      invalid.value(row);
      final gateway = _Gateway()
        ..entries = [_entry(1, 0)]
        ..sets = [row];
      await expectLater(gateway.repository.read(_routine),
          throwsA(_failure(RoutineCompositionFailureKind.malformedData)));
    });
  }

  test('nullable Reps and exact meters/seconds roundtrip through payload',
      () async {
    final gateway = _Gateway()
      ..entries = [_entry(1, 0)]
      ..sets = [_set(10, 1, 0)];
    gateway.sets[0]
      ..['reps'] = null
      ..['load_kg'] = null
      ..['distance_meters'] = 2500.5
      ..['duration_seconds'] = 905;
    final snapshot = (await gateway.repository.read(_routine))!;
    final prescription = snapshot.entries.single.sets.single.prescription;
    expect(prescription.reps, isNull);
    expect(prescription.loadKg, isNull);
    expect(prescription.distanceMeters, 2500.5);
    expect(prescription.durationSeconds, 905);
    final encoded = SupabaseRoutineCompositionRepository.payload(
      RoutineCompositionSave(
        routineId: _routine,
        expectedRevision: snapshot.revision,
        mutationId: _mutation,
        entries: snapshot.entries,
      ),
    ).single['sets'] as List<Map<String, dynamic>>;
    expect(encoded.single['reps'], isNull);
    expect(encoded.single['distance_meters'], 2500.5);
    expect(encoded.single['duration_seconds'], 905);
  });

  test('rich Set type and Rep Range read/write preserve stable UUIDs',
      () async {
    final row = _set(10, 1, 0)
      ..['set_type'] = 'drop'
      ..['reps'] = 8
      ..['reps_max'] = 12;
    final gw = _Gateway()..entries = [_entry(1, 0)]..sets = [row];
    final snapshot = (await gw.repository.read(_routine))!;
    final set = snapshot.entries.single.sets.single;
    expect(set.id, _id(10));
    expect(set.prescription.setType, RoutineSetType.drop);
    expect(set.prescription.reps, 8);
    expect(set.prescription.repsMax, 12);
    final command = RoutineCompositionSave(
      routineId: _routine, expectedRevision: snapshot.revision,
      mutationId: _mutation, entries: snapshot.entries,
    );
    expect(await gw.repository.save(command), 1);
    final payload = (gw.saved!['exercises'] as List).single;
    final serialized = (payload['sets'] as List).single;
    expect(serialized['set_type'], 'drop');
    expect(serialized['reps_max'], 12);
    expect(serialized['id'], _id(10));
  });

  test(
      'duplicate positions, nonadvancing cursor and duplicate global set IDs fail',
      () async {
    for (final entries in [
      [_entry(1, 0), _entry(2, 0)],
      [_entry(2, 0), _entry(1, 1)]
    ]) {
      final gateway = _Gateway()..entries = entries;
      await expectLater(gateway.repository.read(_routine),
          throwsA(_failure(RoutineCompositionFailureKind.malformedData)));
    }
    final gateway = _Gateway()
      ..entries = [_entry(1, 0), _entry(2, 1)]
      ..sets = [_set(10, 1, 0), _set(10, 2, 0)];
    await expectLater(gateway.repository.read(_routine),
        throwsA(_failure(RoutineCompositionFailureKind.malformedData)));
  });

  test('bad headers are rejected without coercion', () async {
    for (final revision in <Object?>[null, -1, 1.0, '1']) {
      final gateway = _Gateway();
      gateway.header!['composition_revision'] = revision;
      await expectLater(gateway.repository.read(_routine),
          throwsA(_failure(RoutineCompositionFailureKind.malformedData)));
    }
    final gateway = _Gateway();
    gateway.header!.remove('last_composition_mutation_id');
    await expectLater(gateway.repository.read(_routine),
        throwsA(_failure(RoutineCompositionFailureKind.malformedData)));
  });

  test('signed-out read/save perform no gateway calls', () async {
    final gateway = _Gateway()..owner = null;
    await expectLater(gateway.repository.read(_routine),
        throwsA(_failure(RoutineCompositionFailureKind.unauthorized)));
    await expectLater(gateway.repository.save(_command()),
        throwsA(_failure(RoutineCompositionFailureKind.unauthorized)));
    expect(gateway.headerCalls + gateway.saveCalls, 0);
  });

  test('foreign owner header/entry/set/join is rejected', () async {
    for (var target = 0; target < 4; target++) {
      final gateway = _Gateway()
        ..entries = [_entry(1, 0)]
        ..sets = [_set(10, 1, 0)];
      final row = switch (target) {
        0 => gateway.header!,
        1 => gateway.entries[0],
        2 => gateway.sets[0],
        _ => gateway.sets[0]['entry'] as Map<String, dynamic>
      };
      row['user_id'] = _otherOwner;
      await expectLater(gateway.repository.read(_routine),
          throwsA(_failure(RoutineCompositionFailureKind.forbidden)));
    }
  });

  test('auth change during read discards the old owner result', () async {
    final gateway = _Gateway();
    gateway.onHeader = (_) => gateway.owner = _otherOwner;
    await expectLater(gateway.repository.read(_routine),
        throwsA(_failure(RoutineCompositionFailureKind.unauthorized)));
    expect(gateway.entryCalls, 0);
  });

  test(
      'save sends ordered stable IDs, refs and explicit nulls through RPC once',
      () async {
    final gateway = _Gateway();
    final command = _command(entries: [
      RoutineCompositionEntry(
          id: _id(1),
          exercise: ExerciseRef.catalog('ex_squat'),
          sets: [
            RoutineCompositionSet(
                id: _id(10), prescription: SetPrescription(reps: 8))
          ])
    ]);
    expect(await gateway.repository.save(command), 1);
    expect(gateway.saved, {
      'routineId': _routine.value,
      'expectedRevision': 0,
      'mutationId': _mutation,
      'exercises': [
        {
          'id': _id(1),
          'exercise_ref': 'ex_squat',
          'sets': [
            {'id': _id(10), 'reps': 8, 'reps_max': null,
             'set_type': 'normal', 'load_kg': null, 'distance_meters': null,
              'duration_seconds': null, 'rest_seconds': null}
          ]
        }
      ],
    });
    expect(gateway.saveCalls, 1);
    expect(gateway.headerCalls, 0);
  });

  test(
      'explicit same-mutation replay reuses the command and accepts authoritative revision',
      () async {
    final gateway = _Gateway()..saveResult = 4;
    final command = _command(revision: 4);
    expect(await gateway.repository.save(command), 4);
    final firstPayload = gateway.saved;
    expect(await gateway.repository.save(command), 4);
    expect(gateway.saved, firstPayload);
    expect(gateway.saveCalls, 2);
  });

  final errors = <(String, String, RoutineCompositionFailureKind)>[
    (
      'P0001',
      'routine_composition_revision_conflict',
      RoutineCompositionFailureKind.revisionConflict
    ),
    (
      'P0001',
      'routine_composition_mutation_conflict',
      RoutineCompositionFailureKind.mutationConflict
    ),
    (
      'P0002',
      'routine_composition_not_found',
      RoutineCompositionFailureKind.notFound
    ),
    (
      'P0002',
      'routine_composition_exercise_not_found',
      RoutineCompositionFailureKind.exerciseUnavailable
    ),
    ('28000', 'private details', RoutineCompositionFailureKind.unauthorized),
    ('42501', 'private details', RoutineCompositionFailureKind.forbidden),
    (
      '22023',
      'routine_composition_archived_exercise_modified',
      RoutineCompositionFailureKind.exerciseUnavailable
    ),
    (
      '22023',
      'routine_composition_payload_too_large',
      RoutineCompositionFailureKind.invalidRequest
    ),
    ('22P02', 'private details', RoutineCompositionFailureKind.invalidRequest),
    ('22003', 'private details', RoutineCompositionFailureKind.invalidRequest),
    (
      '23503',
      'private details',
      RoutineCompositionFailureKind.integrityConflict
    ),
    (
      '23505',
      'private details',
      RoutineCompositionFailureKind.integrityConflict
    ),
    ('PGRST202', 'private details', RoutineCompositionFailureKind.unavailable),
  ];
  for (final error in errors) {
    test('definitive RPC ${error.$1}/${error.$2} maps and never retries',
        () async {
      final gateway = _Gateway()
        ..onSave = () async =>
            throw PostgrestException(code: error.$1, message: error.$2);
      await expectLater(
          gateway.repository.save(_command()), throwsA(_failure(error.$3)));
      expect(gateway.saveCalls, 1);
      expect(gateway.headerCalls, 0);
      expect(RoutineCompositionException(error.$3).toString(),
          isNot(contains('private details')));
    });
  }

  test(
      'lost committed response reconciles exact token, revision and identified content',
      () async {
    final gateway = _Gateway();
    final command = _command(entries: [
      RoutineCompositionEntry(
          id: _id(1),
          exercise: ExerciseRef.catalog('ex_squat'),
          sets: [
            RoutineCompositionSet(
                id: _id(10), prescription: SetPrescription(reps: 8))
          ])
    ]);
    gateway.onSave = () async {
      gateway.header = _header(1, _mutation);
      gateway.entries = [_entry(1, 0)];
      gateway.sets = [_set(10, 1, 0)];
      throw TimeoutException('not retained');
    };
    expect(await gateway.repository.save(command), 1);
    expect(gateway.saveCalls, 1);
  });

  test('unconfirmed or superseded write stays unknown without another write',
      () async {
    for (final header in [
      _header(),
      _header(2, _otherMutation),
      _header(1, _otherMutation)
    ]) {
      final gateway = _Gateway()
        ..header = header
        ..onSave = () async => throw TimeoutException('lost');
      await expectLater(
          gateway.repository.save(_command()),
          throwsA(isA<RoutineCompositionSaveOutcomeUnknown>().having(
              (e) => e.reason,
              'reason',
              header['composition_revision'] == 0
                  ? RoutineCompositionSaveUncertainty.unconfirmed
                  : RoutineCompositionSaveUncertainty.superseded)));
      expect(gateway.saveCalls, 1);
    }
  });

  test('same token but changed IDs or prescriptions is mutation conflict',
      () async {
    final gateway = _Gateway()
      ..header = _header(1, _mutation)
      ..entries = [_entry(1, 0)]
      ..onSave = () async => throw TimeoutException('lost');
    await expectLater(gateway.repository.save(_command()),
        throwsA(_failure(RoutineCompositionFailureKind.mutationConflict)));
    expect(gateway.saveCalls, 1);
  });

  test(
      'same token/content with unexpected revision cannot falsely confirm uncertain write',
      () async {
    final gateway = _Gateway()
      ..header = _header(3, _mutation)
      ..onSave = () async => throw TimeoutException('lost');
    await expectLater(gateway.repository.save(_command()),
        throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()));
  });

  test(
      'malformed successful response and ambiguous 503 use read-only reconciliation',
      () async {
    for (final response in <Object?>[null, '1', 1.0, [], -1, 0]) {
      final gateway = _Gateway()
        ..header = _header(1, _mutation)
        ..saveResult = response;
      expect(await gateway.repository.save(_command()), 1);
      expect(gateway.saveCalls, 1);
    }
    final gateway = _Gateway()
      ..header = _header(1, _mutation)
      ..onSave = () async => throw const PostgrestException(
          message: 'proxy unavailable', code: '503');
    expect(await gateway.repository.save(_command()), 1);
  });

  test('failed reconciliation remains unknown and failed reads are not empty',
      () async {
    final gateway = _Gateway()..headerError = TimeoutException('offline');
    gateway.onSave = () async => throw TimeoutException('lost');
    await expectLater(gateway.repository.save(_command()),
        throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()));
    await expectLater(gateway.repository.read(_routine),
        throwsA(_failure(RoutineCompositionFailureKind.unavailable)));
    expect(gateway.saveCalls, 1);
  });

  test(
      'auth change after save dispatch or during reconciliation leaves outcome unknown',
      () async {
    for (final duringRead in [false, true]) {
      final gateway = _Gateway();
      gateway.onSave = () async {
        if (!duringRead) gateway.owner = _otherOwner;
        if (duringRead) throw TimeoutException('lost');
        return 1;
      };
      if (duringRead) gateway.onHeader = (_) => gateway.owner = _otherOwner;
      await expectLater(
          gateway.repository.save(_command()),
          throwsA(isA<RoutineCompositionSaveOutcomeUnknown>().having(
              (e) => e.reason,
              'reason',
              RoutineCompositionSaveUncertainty.authChanged)));
      expect(gateway.saveCalls, 1);
    }
  });

  test('atomic Name-only lost response confirms only matched Name/token/revision', () async {
    final gw = _Gateway()..header = _header(1);
    gw.onAggregate = () async {
      gw.header = _header(2, _mutation)..['name'] = 'New Name';
      throw TimeoutException('lost response');
    };
    final command = RoutineAggregateUpdate(
      routineId: _routine,
      programId: ProgramId('66666666-6666-6666-6666-666666666666'),
      expectedRevision: 1,
      expectedName: 'Old Name',
      mutationId: _mutation,
      name: 'New Name',
    );
    expect(await gw.repository.updateAggregate(command), 2);
    expect(gw.aggregateCalls, 1);
    expect(gw.saveCalls, 0);
    expect(gw.aggregateArgs!['name'], 'New Name');
    expect(gw.aggregateArgs!['exercises'], isNull);
  });

  test('atomic same token but differing committed Name cannot confirm', () async {
    final gw = _Gateway()..header = _header(1);
    gw.onAggregate = () async {
      gw.header = _header(2, _mutation)..['name'] = 'Different';
      throw TimeoutException('lost response');
    };
    await expectLater(
      gw.repository.updateAggregate(RoutineAggregateUpdate(
        routineId: _routine,
        programId: ProgramId('66666666-6666-6666-6666-666666666666'),
        expectedRevision: 1,
        expectedName: 'Old Name',
        mutationId: _mutation,
        name: 'New Name',
      )),
      throwsA(_failure(RoutineCompositionFailureKind.mutationConflict)),
    );
    expect(gw.aggregateCalls, 1);
  });

  test('atomic login switch after dispatch fails closed and never retries', () async {
    final gw = _Gateway()..header = _header(1);
    gw.onAggregate = () async {
      gw.owner = _otherOwner;
      return 2;
    };
    await expectLater(
      gw.repository.updateAggregate(RoutineAggregateUpdate(
        routineId: _routine,
        programId: ProgramId('66666666-6666-6666-6666-666666666666'),
        expectedRevision: 1,
        expectedName: 'Old Name',
        mutationId: _mutation,
        name: 'New Name',
      )),
      throwsA(isA<RoutineCompositionSaveOutcomeUnknown>().having(
          (e) => e.reason, 'reason', RoutineCompositionSaveUncertainty.authChanged)),
    );
    expect(gw.aggregateCalls, 1);
  });

  test('in-flight composition Edit reserves same owner Routine across adapters',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final waiting = Completer<Object?>();
    final first = _Gateway()..onSave = () => waiting.future;
    final second = _Gateway();
    final saving = first.repo(crossOperationGate: gate).save(_command());

    expect(gate.inFlight(_owner, _routine), isTrue);
    expect(gate.tryStart(_owner, _routine), isFalse,
        reason: 'Move/Delete dispatch cannot overlap a saved Routine Edit');
    await expectLater(second.repo(crossOperationGate: gate).save(_command()),
        throwsA(_failure(RoutineCompositionFailureKind.readConflict)));
    expect(second.saveCalls, 0, reason: 'No second Edit RPC is sent');
    expect(gate.tryStart(_otherOwner, _routine), isTrue,
        reason: 'Another owner must not be blocked');
    gate.finish(_otherOwner, _routine);

    waiting.complete(1);
    expect(await saving, 1);
    expect(gate.inFlight(_owner, _routine), isFalse);
    expect(gate.tryStart(_owner, _routine), isTrue);
    gate.finish(_owner, _routine);
  });

  test('in-flight Move/Delete prevents atomic Name plus composition Update',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final gw = _Gateway();
    final update = RoutineAggregateUpdate(
      routineId: _routine,
      programId: ProgramId('66666666-6666-6666-6666-666666666666'),
      expectedRevision: 0,
      expectedName: 'Old Name',
      mutationId: _mutation,
      name: 'Renamed',
    );
    expect(gate.tryStart(_owner, _routine), isTrue);
    await expectLater(gw.repo(crossOperationGate: gate).updateAggregate(update),
        throwsA(_failure(RoutineCompositionFailureKind.readConflict)));
    expect(gw.aggregateCalls, 0);
    gate.finish(_owner, _routine);
    expect(await gw.repo(crossOperationGate: gate).updateAggregate(update), 2);
    expect(gw.aggregateCalls, 1);
  });

  test('atomic Name Update also blocks Move until definitive response',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final waiting = Completer<Object?>();
    final gw = _Gateway()..onAggregate = () => waiting.future;
    final update = RoutineAggregateUpdate(
      routineId: _routine,
      programId: ProgramId('66666666-6666-6666-6666-666666666666'),
      expectedRevision: 0,
      expectedName: 'Old Name',
      mutationId: _mutation,
      name: 'Renamed',
    );
    final saving = gw.repo(crossOperationGate: gate).updateAggregate(update);
    expect(gate.tryStart(_owner, _routine), isFalse);
    waiting.complete(2);
    expect(await saving, 2);
    expect(gate.inFlight(_owner, _routine), isFalse);
    expect(gw.aggregateCalls, 1);
  });

  test('unknown Edit CAS stays reserved until later owner-confirmed revision',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final gw = _Gateway()
      ..onSave = () async => throw TimeoutException('lost ACK');
    final repo = gw.repo(crossOperationGate: gate);
    await expectLater(repo.save(_command()),
        throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()));
    expect(gw.saveCalls, 1);
    expect(gate.uncertain(_owner, _routine), isTrue);
    expect(gate.tryStart(_owner, _routine), isFalse);

    // An absent or same-revision owner read never proves the timed-out
    // server transaction cannot still commit at the original revision.
    await repo.read(_routine);
    expect(gate.uncertain(_owner, _routine), isTrue);
    gw.header = _header(1, _otherMutation);
    expect((await repo.read(_routine))?.revision, 1);
    expect(gate.uncertain(_owner, _routine), isFalse);
    expect(gate.tryStart(_owner, _routine), isTrue);
    gate.finish(_owner, _routine);
  });

  test('uncertain atomic Name Update persists across adapter recreation',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final gw = _Gateway()
      ..onAggregate = () async => throw TimeoutException('timeout');
    final update = RoutineAggregateUpdate(
      routineId: _routine,
      programId: ProgramId('66666666-6666-6666-6666-666666666666'),
      expectedRevision: 0,
      expectedName: 'Old Name',
      mutationId: _mutation,
      name: 'Renamed',
    );
    await expectLater(gw.repo(crossOperationGate: gate).updateAggregate(update),
        throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()));
    final rebuilt = gw.repo(crossOperationGate: gate);
    await expectLater(rebuilt.save(_command()),
        throwsA(_failure(RoutineCompositionFailureKind.readConflict)));
    expect(gw.saveCalls, 0);
    gw.header = _header(1, _otherMutation);
    await rebuilt.read(_routine);
    expect(gate.uncertain(_owner, _routine), isFalse);
  });

  test('superseded composition Save retires old CAS without another read',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final gw = _Gateway();
    gw.onSave = () async {
      // Emulate the authorized, bracketed reconcile read seeing another
      // committed mutation at the strictly greater revision.
      gw.header = _header(1, _otherMutation);
      throw TimeoutException('lost Save ACK');
    };
    await expectLater(
      gw.repo(crossOperationGate: gate).save(_command()),
      throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()
          .having((e) => e.reason, 'reason',
              RoutineCompositionSaveUncertainty.superseded)
          .having((e) => e.observedRevision, 'observedRevision', 1)),
    );
    expect(gw.saveCalls, 1);
    expect(gate.uncertain(_owner, _routine), isFalse,
        reason: 'A verified later revision makes the old CAS impossible');
    expect(gate.tryStart(_owner, _routine), isTrue);
    gate.finish(_owner, _routine);
  });

  test('superseded atomic Name Update also retires old CAS on reconcile',
      () async {
    final gate = RoutineMoveDeleteAttemptGate();
    final gw = _Gateway();
    gw.onAggregate = () async {
      gw.header = _header(1, _otherMutation);
      throw TimeoutException('lost aggregate ACK');
    };
    final update = RoutineAggregateUpdate(
      routineId: _routine,
      programId: ProgramId('66666666-6666-6666-6666-666666666666'),
      expectedRevision: 0,
      expectedName: 'Old Name',
      mutationId: _mutation,
      name: 'Renamed',
    );
    await expectLater(
      gw.repo(crossOperationGate: gate).updateAggregate(update),
      throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()
          .having((e) => e.reason, 'reason',
              RoutineCompositionSaveUncertainty.superseded)
          .having((e) => e.observedRevision, 'observedRevision', 1)),
    );
    expect(gw.aggregateCalls, 1);
    expect(gate.uncertain(_owner, _routine), isFalse);
    expect(gate.tryStart(_owner, _routine), isTrue);
    gate.finish(_owner, _routine);
  });

  test('real deadline is bounded and does not send a second mutation',
      () async {
    final gateway = _Gateway()..onSave = () => Completer<Object?>().future;
    await expectLater(
        gateway.repo(timeout: const Duration(milliseconds: 5)).save(_command()),
        throwsA(isA<RoutineCompositionSaveOutcomeUnknown>()));
    expect(gateway.saveCalls, 1);
  });
}

final class _Gateway implements RoutineCompositionGateway, RoutineAggregateUpdateGateway {
  String? owner = _owner;
  Map<String, dynamic>? header = _header();
  List<Map<String, dynamic>> entries = [];
  List<Map<String, dynamic>> sets = [];
  int cap = 500;
  int headerCalls = 0, entryCalls = 0, setCalls = 0, saveCalls = 0;
  int aggregateCalls = 0;
  Map<String, dynamic>? aggregateArgs;
  Future<Object?> Function()? onAggregate;
  int entryEmptyPages = 0, setEmptyPages = 0;
  final scopes = <String>[];
  void Function(int)? onHeader;
  Future<Object?> Function()? onSave;
  Object? headerError;
  Object? saveResult = 1;
  Map<String, dynamic>? saved;
  SupabaseRoutineCompositionRepository get repository => repo();
  SupabaseRoutineCompositionRepository repo(
          {int pageSize = 500,
          Duration timeout = const Duration(seconds: 15),
          RoutineMoveDeleteAttemptGate? crossOperationGate}) =>
      SupabaseRoutineCompositionRepository(
          gateway: this,
          currentUserId: () => owner,
          crossOperationGate: crossOperationGate,
          pageSize: pageSize,
          requestTimeout: timeout);

  @override
  Future<Map<String, dynamic>?> readHeader(
      {required String userId, required String routineId}) async {
    headerCalls++;
    scopes.add('$userId/$routineId');
    onHeader?.call(headerCalls);
    if (headerError != null) throw headerError!;
    return header == null ? null : Map.of(header!);
  }

  List<Map<String, dynamic>> _page(
          List<Map<String, dynamic>> rows, String? afterId, int limit) =>
      rows
          .where((row) =>
              afterId == null ||
              row['id'] is! String ||
              (row['id'] as String).compareTo(afterId) > 0)
          .take(min(cap, limit))
          .map((row) => Map<String, dynamic>.of(row))
          .toList();

  @override
  Future<List<Map<String, dynamic>>> readEntries(
      {required String userId,
      required String routineId,
      required int limit,
      String? afterId}) async {
    entryCalls++;
    scopes.add('$userId/$routineId');
    final page = _page(entries, afterId, limit);
    if (page.isEmpty) entryEmptyPages++;
    return page;
  }

  @override
  Future<List<Map<String, dynamic>>> readSets(
      {required String userId,
      required String routineId,
      required int limit,
      String? afterId}) async {
    setCalls++;
    scopes.add('$userId/$routineId');
    final page = _page(sets, afterId, limit);
    if (page.isEmpty) setEmptyPages++;
    return page;
  }

  @override
  Future<Object?> save(
      {required String routineId,
      required int expectedRevision,
      required String mutationId,
      required List<Map<String, dynamic>> exercises}) async {
    saveCalls++;
    saved = {
      'routineId': routineId,
      'expectedRevision': expectedRevision,
      'mutationId': mutationId,
      'exercises': exercises
    };
    return onSave == null ? saveResult : await onSave!();
  }
  @override
  Future<Object?> updateAggregate({
    required String routineId,
    required String programId,
    required int expectedRevision,
    required String expectedName,
    required String mutationId,
    String? name,
    List<Map<String, dynamic>>? exercises,
  }) async {
    aggregateCalls++;
    aggregateArgs = {
      'routineId': routineId,
      'programId': programId,
      'expectedRevision': expectedRevision,
      'expectedName': expectedName,
      'mutationId': mutationId,
      'name': name,
      'exercises': exercises,
    };
    return onAggregate == null ? 2 : await onAggregate!();
  }

}
