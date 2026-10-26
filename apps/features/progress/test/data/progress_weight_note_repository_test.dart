import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_progress/src/data/body_state_row_mapper.dart';

void main() {
  final instant = DateTime.utc(2026, 10, 26, 8);
  const id = '33f70133-1d22-4c8d-981d-3b83672d5111';

  BodyWeightRecord draft({String? note = 'After morning walk'}) =>
      BodyWeightRecord(
        weightKg: 73.4,
        measuredAt: instant,
        source: BodyWeightSources.manual,
        note: note,
        submissionId: id,
      );

  test('same stable manual submission cannot generate duplicate History', () async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(draft());
    await repository.recordCurrentWeight(draft());
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.id, id);
    expect(repository.weightEntries.single.note, 'After morning walk');
  });

  test('same UUID with modified payload is rejected, never silently overwritten',
      () async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(draft());
    await expectLater(
      () => repository.recordCurrentWeight(draft(note: 'Different')),
      throwsStateError,
    );
    expect(repository.weightEntries.single.note, 'After morning walk');
  });

  test('optional missing and blank note stays absent in History', () async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(draft(note: '  '));
    final page = await repository.getWeightHistory(BodyWeightHistoryQuery(
      fromInclusive: instant.subtract(const Duration(days: 1)),
      toExclusive: instant.add(const Duration(days: 1)),
    ));
    expect(page.entries.single.note, isNull);
  });

  test('History reads trimmed note and A1 exact update retains it', () async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(draft(note: '  Walked after lunch  '));
    var page = await repository.getWeightHistory(BodyWeightHistoryQuery(
      fromInclusive: instant.subtract(const Duration(days: 1)),
      toExclusive: instant.add(const Duration(days: 2)),
    ));
    expect(page.entries.single.note, 'Walked after lunch');
    await repository.updateWeightLog(BodyWeightLogEdit(
      id: id,
      weightKg: 73.6,
      measuredAt: instant.add(const Duration(hours: 1)),
    ));
    page = await repository.getWeightHistory(BodyWeightHistoryQuery(
      fromInclusive: instant.subtract(const Duration(days: 1)),
      toExclusive: instant.add(const Duration(days: 2)),
    ));
    expect(page.entries.single.id, id);
    expect(page.entries.single.note, 'Walked after lunch');
  });

  test('overlong note and malformed submission ID are rejected', () {
    expect(
      () => draft(note: 'x' * 501).validateNoteAndSubmission(),
      throwsArgumentError,
    );
    expect(
      () => BodyWeightRecord(
        weightKg: 70,
        measuredAt: instant,
        source: BodyWeightSources.manual,
        submissionId: 'not-a-uuid',
      ).validateNoteAndSubmission(),
      throwsArgumentError,
    );
  });

  test('legacy mapping tolerates missing metadata but validates note type', () {
    const mapper = BodyStateRowMapper();
    final old = <String, dynamic>{
      'id': id,
      'weight_kg': 70,
      'measured_at': instant.toIso8601String(),
      'source': 'onboarding_setup',
    };
    expect(mapper.mapHistoryWeight(old).note, isNull);
    expect(
      mapper.mapHistoryWeight({
        ...old,
        'metadata': <String, dynamic>{'note': '  Felt good  '},
      }).note,
      'Felt good',
    );
    expect(
      () => mapper.mapHistoryWeight({
        ...old,
        'metadata': <String, dynamic>{'note': 123},
      }),
      throwsFormatException,
    );
  });
}
