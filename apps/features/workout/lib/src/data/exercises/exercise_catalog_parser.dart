import 'package:tio_shared/shared.dart';

import '../../domain/exercises/exercise_catalog.dart';
import '../../domain/exercises/invalid_exercise_catalog_exception.dart';
import 'exercise_catalog_row_dto.dart';

/// Validates decoded built-in catalog rows and maps them to canonical
/// [Exercise] values.
///
/// Accepts already-decoded rows; the bundled catalog document and version
/// envelope are owned by `ExerciseCatalogDocumentDecoder`. Every row is
/// checked so the failure lists all issues, and any invalid or duplicate row
/// fails the whole catalog with [InvalidExerciseCatalogException].
final class ExerciseCatalogParser {
  const ExerciseCatalogParser();

  ExerciseCatalog parse(List<Object?> rows) {
    final issues = <ExerciseCatalogIssue>[];
    final exercises = <Exercise>[];
    final firstRowByRef = <ExerciseRef, int>{};

    for (var index = 0; index < rows.length; index++) {
      final exercise =
          ExerciseCatalogRowDto.read(rows[index], index, issues)?.toExercise(
        issues,
      );
      if (exercise == null) continue;

      final firstRow = firstRowByRef[exercise.ref];
      if (firstRow != null) {
        issues.add(ExerciseCatalogIssue(
          rowIndex: index,
          exerciseId: exercise.ref.value,
          path: 'id',
          problem: 'duplicates the ExerciseRef of row $firstRow',
        ));
        continue;
      }
      firstRowByRef[exercise.ref] = index;
      exercises.add(exercise);
    }

    if (issues.isNotEmpty) throw InvalidExerciseCatalogException(issues);
    return ExerciseCatalog(exercises);
  }
}
