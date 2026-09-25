import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

String document({
  Object? schemaVersion = 1,
  Object? catalogVersion = 1,
  Object? exercises = const <Object?>[],
  Map<String, Object?> extra = const {},
}) =>
    jsonEncode({
      'schemaVersion': schemaVersion,
      'catalogVersion': catalogVersion,
      'exercises': exercises,
      ...extra,
    });

InvalidExerciseCatalogDocumentException invalidDocument(String source) {
  try {
    const ExerciseCatalogDocumentDecoder().decode(source);
  } on InvalidExerciseCatalogDocumentException catch (error) {
    return error;
  }
  fail('Expected InvalidExerciseCatalogDocumentException');
}

void main() {
  const decoder = ExerciseCatalogDocumentDecoder();

  test('decodes a valid versioned document', () {
    final decoded = decoder.decode(document(exercises: [
      {'id': 'ex_synthetic_alpha'},
    ]));

    expect(decoded.schemaVersion, 1);
    expect(decoded.catalogVersion, 1);
    expect(decoded.exercises, hasLength(1));
  });

  test('rejects a missing schemaVersion', () {
    final error = invalidDocument(jsonEncode({
      'catalogVersion': 1,
      'exercises': <Object?>[],
    }));

    expect(error.path, 'schemaVersion');
    expect(error.problem, 'is required');
  });

  test('rejects a non-integer schemaVersion', () {
    final error = invalidDocument(document(schemaVersion: '1'));

    expect(error.path, 'schemaVersion');
    expect(error.problem, 'must be an integer');
  });

  test('rejects an unsupported schemaVersion distinctly', () {
    expect(
      () => decoder.decode(document(schemaVersion: 2)),
      throwsA(
        isA<UnsupportedExerciseCatalogSchemaVersionException>()
            .having((error) => error.actual, 'actual', 2)
            .having((error) => error.supported, 'supported', 1),
      ),
    );
  });

  test('rejects an invalid catalogVersion', () {
    final wrongType = invalidDocument(document(catalogVersion: 1.5));
    final nonPositive = invalidDocument(document(catalogVersion: 0));

    expect(wrongType.path, 'catalogVersion');
    expect(wrongType.problem, 'must be an integer');
    expect(nonPositive.path, 'catalogVersion');
    expect(nonPositive.problem, 'must be positive');
  });

  test('rejects missing exercises', () {
    final error = invalidDocument(jsonEncode({
      'schemaVersion': 1,
      'catalogVersion': 1,
    }));

    expect(error.path, 'exercises');
    expect(error.problem, 'is required');
  });

  test('rejects non-array exercises', () {
    final error = invalidDocument(document(exercises: {'id': 'ex_bad'}));

    expect(error.path, 'exercises');
    expect(error.problem, 'must be an array');
  });

  test('ignores unknown top-level fields', () {
    final decoded = decoder.decode(document(extra: {
      'futureEnvelopeField': {'enabled': true},
    }));

    expect(decoded.schemaVersion, 1);
    expect(decoded.catalogVersion, 1);
  });

  test('rejects malformed JSON', () {
    final error = invalidDocument('{"schemaVersion":');

    expect(error.path, r'$');
    expect(error.problem, 'must be valid JSON');
    expect(error.cause, isA<FormatException>());
  });

  test('rejects a non-object JSON root', () {
    final error = invalidDocument('[]');

    expect(error.path, r'$');
    expect(error.problem, 'must be an object');
  });
}
