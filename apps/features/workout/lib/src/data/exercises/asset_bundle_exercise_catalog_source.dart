import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/exercises/exercise_catalog.dart';
import '../../domain/exercises/exercise_catalog_repository.dart';
import 'decoded_rows_exercise_catalog_repository.dart';
import 'exercise_catalog_document_decoder.dart';
import 'exercise_catalog_parser.dart';
import 'exercise_catalog_source_exceptions.dart';

/// Flutter package asset key for the Workout-owned production catalog.
const exerciseCatalogAssetKey =
    'packages/tio_feature_workout/assets/exercises/exercise_catalog.json';

/// Production [ExerciseCatalogRepository] backed by an injected [AssetBundle].
///
/// Loading and document decoding are owned here. Row validation and canonical
/// mapping are delegated to the existing W3A1 repository/parser boundary.
final class AssetBundleExerciseCatalogSource
    implements ExerciseCatalogRepository {
  const AssetBundleExerciseCatalogSource(
    this._assetBundle, {
    this.assetKey = exerciseCatalogAssetKey,
    ExerciseCatalogDocumentDecoder decoder =
        const ExerciseCatalogDocumentDecoder(),
    ExerciseCatalogParser parser = const ExerciseCatalogParser(),
  })  : _decoder = decoder,
        _parser = parser;

  final AssetBundle _assetBundle;
  final String assetKey;
  final ExerciseCatalogDocumentDecoder _decoder;
  final ExerciseCatalogParser _parser;

  @override
  Future<ExerciseCatalog> load() => DecodedRowsExerciseCatalogRepository(
        _loadRows,
        parser: _parser,
      ).load();

  Future<List<Object?>> _loadRows() async {
    final String source;
    try {
      source = await _assetBundle.loadString(assetKey);
    } on FlutterError catch (error, stackTrace) {
      throw MissingExerciseCatalogAssetException(
        assetKey: assetKey,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return _decoder.decode(source).exercises;
  }
}
