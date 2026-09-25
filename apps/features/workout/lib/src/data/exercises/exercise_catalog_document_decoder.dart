import 'dart:convert';

import 'exercise_catalog_source_exceptions.dart';

/// Validated version envelope for the bundled Exercise catalog.
final class ExerciseCatalogDocument {
  ExerciseCatalogDocument({
    required this.schemaVersion,
    required this.catalogVersion,
    required Iterable<Object?> exercises,
  }) : exercises = List<Object?>.unmodifiable(exercises);

  final int schemaVersion;
  final int catalogVersion;
  final List<Object?> exercises;
}

/// Decodes and validates the catalog document envelope.
///
/// Row validation intentionally remains in `ExerciseCatalogParser`; this
/// decoder owns only JSON/root/version/list boundaries. Unknown top-level
/// fields are ignored for forward compatibility.
final class ExerciseCatalogDocumentDecoder {
  const ExerciseCatalogDocumentDecoder();

  static const supportedSchemaVersion = 1;

  ExerciseCatalogDocument decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw InvalidExerciseCatalogDocumentException(
        path: r'$',
        problem: 'must be valid JSON',
        cause: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const InvalidExerciseCatalogDocumentException(
        path: r'$',
        problem: 'must be an object',
      );
    }

    final schemaVersion = _positiveInteger(
      decoded,
      'schemaVersion',
    );
    if (schemaVersion != supportedSchemaVersion) {
      throw UnsupportedExerciseCatalogSchemaVersionException(
        actual: schemaVersion,
        supported: supportedSchemaVersion,
      );
    }

    final catalogVersion = _positiveInteger(
      decoded,
      'catalogVersion',
    );
    final exercises = _required(decoded, 'exercises');
    if (exercises is! List<dynamic>) {
      throw const InvalidExerciseCatalogDocumentException(
        path: 'exercises',
        problem: 'must be an array',
      );
    }

    return ExerciseCatalogDocument(
      schemaVersion: schemaVersion,
      catalogVersion: catalogVersion,
      exercises: exercises,
    );
  }

  static int _positiveInteger(Map<String, dynamic> document, String key) {
    final value = _required(document, key);
    if (value is! int) {
      throw InvalidExerciseCatalogDocumentException(
        path: key,
        problem: 'must be an integer',
      );
    }
    if (value <= 0) {
      throw InvalidExerciseCatalogDocumentException(
        path: key,
        problem: 'must be positive',
      );
    }
    return value;
  }

  static Object? _required(Map<String, dynamic> document, String key) {
    if (!document.containsKey(key)) {
      throw InvalidExerciseCatalogDocumentException(
        path: key,
        problem: 'is required',
      );
    }
    return document[key];
  }
}
