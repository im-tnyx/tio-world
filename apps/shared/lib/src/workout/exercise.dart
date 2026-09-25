import 'exercise_media.dart';
import 'exercise_ref.dart';
import 'exercise_status.dart';

/// Canonical pure-Dart read model for one Exercise.
///
/// [ref] carries catalog or user-created identity. [media] carries optional
/// per-gender media URLs. Catalog parsing, persistence, ownership, localized
/// instructions and standards remain outside this domain contract.
final class Exercise {
  Exercise({
    required this.ref,
    required String displayName,
    String? muscleGroup,
    List<String> primaryMuscles = const [],
    List<String> secondaryMuscles = const [],
    String? primaryEquipment,
    String? category,
    List<String> levels = const [],
    required this.status,
    this.media,
  })  : displayName = _requireNonBlankText(displayName, 'displayName'),
        muscleGroup = _validateOptionalTaxonomy(muscleGroup, 'muscleGroup'),
        primaryMuscles = _validateTaxonomyList(
          primaryMuscles,
          'primaryMuscles',
        ),
        secondaryMuscles = _validateTaxonomyList(
          secondaryMuscles,
          'secondaryMuscles',
        ),
        primaryEquipment = _validateOptionalTaxonomy(
          primaryEquipment,
          'primaryEquipment',
        ),
        category = _validateOptionalTaxonomy(category, 'category'),
        levels = _validateTaxonomyList(levels, 'levels');

  /// Stable catalog or user-created identity.
  final ExerciseRef ref;

  /// Human-readable name supplied by the owning source.
  final String displayName;

  /// Optional broad muscle-group taxonomy token.
  final String? muscleGroup;

  /// Ordered primary-muscle taxonomy tokens.
  final List<String> primaryMuscles;

  /// Ordered secondary-muscle taxonomy tokens.
  final List<String> secondaryMuscles;

  /// Optional broad primary-equipment taxonomy token.
  final String? primaryEquipment;

  /// Optional broad Exercise category taxonomy token.
  final String? category;

  /// Ordered applicability/level taxonomy tokens.
  final List<String> levels;

  /// Canonical active/archive lifecycle state.
  final ExerciseStatus status;

  /// Optional per-gender media; null when the source provides none.
  final ExerciseMedia? media;

  static String _requireNonBlankText(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        name,
        'must contain at least one non-whitespace character',
      );
    }
    return value;
  }

  static String? _validateOptionalTaxonomy(String? value, String name) {
    if (value == null) return null;
    return _requireNonBlankText(value, name);
  }

  static List<String> _validateTaxonomyList(
    List<String> values,
    String name,
  ) {
    final copy = List<String>.of(values);
    final seen = <String>{};

    for (final value in copy) {
      _requireNonBlankText(value, name);
      if (!seen.add(value)) {
        throw ArgumentError.value(
          values,
          name,
          'must not contain duplicate taxonomy values',
        );
      }
    }

    return List<String>.unmodifiable(copy);
  }

  static bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          other.ref == ref &&
          other.displayName == displayName &&
          other.muscleGroup == muscleGroup &&
          _listsEqual(other.primaryMuscles, primaryMuscles) &&
          _listsEqual(other.secondaryMuscles, secondaryMuscles) &&
          other.primaryEquipment == primaryEquipment &&
          other.category == category &&
          _listsEqual(other.levels, levels) &&
          other.status == status &&
          other.media == media;

  @override
  int get hashCode => Object.hash(
        ref,
        displayName,
        muscleGroup,
        Object.hashAll(primaryMuscles),
        Object.hashAll(secondaryMuscles),
        primaryEquipment,
        category,
        Object.hashAll(levels),
        status,
        media,
      );
}
