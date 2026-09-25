import '../../domain/exercises/exercise_catalog.dart';
import '../../domain/exercises/exercise_catalog_repository.dart';
import 'exercise_catalog_parser.dart';

/// [ExerciseCatalogRepository] over already-decoded catalog rows.
///
/// Production-neutral: `AssetBundleExerciseCatalogSource` supplies rows
/// decoded from the bundled catalog document. Each [load] reads and validates
/// the rows again.
final class DecodedRowsExerciseCatalogRepository
    implements ExerciseCatalogRepository {
  const DecodedRowsExerciseCatalogRepository(
    this._readRows, {
    ExerciseCatalogParser parser = const ExerciseCatalogParser(),
  }) : _parser = parser;

  final Future<List<Object?>> Function() _readRows;
  final ExerciseCatalogParser _parser;

  @override
  Future<ExerciseCatalog> load() async => _parser.parse(await _readRows());
}
