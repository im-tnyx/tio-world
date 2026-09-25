/// The bundled Exercise catalog asset could not be loaded.
final class MissingExerciseCatalogAssetException implements Exception {
  const MissingExerciseCatalogAssetException({
    required this.assetKey,
    required this.cause,
  });

  final String assetKey;
  final Object cause;

  @override
  String toString() =>
      'MissingExerciseCatalogAssetException: could not load $assetKey: $cause';
}

/// The bundled Exercise catalog document is malformed or violates its
/// envelope contract.
final class InvalidExerciseCatalogDocumentException implements Exception {
  const InvalidExerciseCatalogDocumentException({
    required this.path,
    required this.problem,
    this.cause,
  });

  final String path;
  final String problem;
  final Object? cause;

  @override
  String toString() {
    final causeSuffix = cause == null ? '' : ': $cause';
    return 'InvalidExerciseCatalogDocumentException at $path: '
        '$problem$causeSuffix';
  }
}

/// The document uses a schema version this application cannot safely decode.
final class UnsupportedExerciseCatalogSchemaVersionException
    implements Exception {
  const UnsupportedExerciseCatalogSchemaVersionException({
    required this.actual,
    required this.supported,
  });

  final int actual;
  final int supported;

  @override
  String toString() =>
      'UnsupportedExerciseCatalogSchemaVersionException: schemaVersion '
      '$actual is unsupported; expected $supported';
}
