import 'exercise_media.dart';
import 'exercise_ref.dart';
import 'exercise_status.dart';
import 'exercise_type.dart';

/// Canonical pure-Dart read model for one Exercise.
///
/// [ref] carries catalog or user-created identity. [media] carries optional
/// per-gender media URLs. Bundled catalog localization is represented as
/// immutable locale-keyed content; persistence, ownership and standards remain
/// outside this domain contract.
final class Exercise {
  Exercise({
    required this.ref,
    required String displayName,
    String? description,
    Map<String, String> localizedTitles = const {},
    Map<String, List<String>> localizedInstructions = const {},
    this.exerciseType,
    String? muscleGroup,
    List<String> primaryMuscles = const [],
    List<String> secondaryMuscles = const [],
    String? primaryEquipment,
    String? category,
    List<String> levels = const [],
    required this.status,
    this.media,
  })  : displayName = _requireNonBlankText(displayName, 'displayName'),
        description = _normalizeOptionalText(description),
        localizedTitles = _validateLocalizedTitles(localizedTitles),
        localizedInstructions =
            _validateLocalizedInstructions(localizedInstructions),
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

  /// Optional user-authored description/instructions.
  final String? description;

  /// Locale-keyed display titles supplied by the bundled catalog.
  final Map<String, String> localizedTitles;

  /// Locale-keyed, ordered instruction steps supplied by the bundled catalog.
  final Map<String, List<String>> localizedInstructions;

  /// Optional stable Exercise measurement-profile identity.
  final ExerciseType? exerciseType;

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

  static String? _normalizeOptionalText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Map<String, String> _validateLocalizedTitles(
    Map<String, String> values,
  ) {
    final normalized = <String, String>{};
    for (final entry in values.entries) {
      final locale = _requireNonBlankText(entry.key, 'localizedTitles locale');
      normalized[locale] = _requireNonBlankText(
        entry.value,
        'localizedTitles.$locale',
      );
    }
    return Map<String, String>.unmodifiable(normalized);
  }

  static Map<String, List<String>> _validateLocalizedInstructions(
    Map<String, List<String>> values,
  ) {
    final normalized = <String, List<String>>{};
    for (final entry in values.entries) {
      final locale = _requireNonBlankText(
        entry.key,
        'localizedInstructions locale',
      );
      if (entry.value.isEmpty) {
        throw ArgumentError.value(
          entry.value,
          'localizedInstructions.$locale',
          'must contain at least one instruction step',
        );
      }
      normalized[locale] = List<String>.unmodifiable([
        for (final step in entry.value)
          _requireNonBlankText(step, 'localizedInstructions.$locale'),
      ]);
    }
    return Map<String, List<String>>.unmodifiable(normalized);
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

  static int _localizedTitlesHash(Map<String, String> values) =>
      Object.hashAll(
        values.keys.toList()..sort(),
      ).hashCode ^
      Object.hashAll(
        values.entries
            .map((entry) => Object.hash(entry.key, entry.value))
            .toList()
          ..sort(),
      ).hashCode;

  static int _localizedInstructionsHash(Map<String, List<String>> values) =>
      Object.hashAll(
        values.entries
            .map((entry) => Object.hash(
                  entry.key,
                  Object.hashAll(entry.value),
                ))
            .toList()
          ..sort(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          other.ref == ref &&
          other.displayName == displayName &&
          other.description == description &&
          other.localizedTitles.length == localizedTitles.length &&
          other.localizedTitles.entries.every(
            (entry) => other.localizedTitles[entry.key] == entry.value,
          ) &&
          other.localizedInstructions.length == localizedInstructions.length &&
          other.localizedInstructions.entries.every(
            (entry) =>
                other.localizedInstructions.containsKey(entry.key) &&
                _listsEqual(
                    other.localizedInstructions[entry.key]!, entry.value),
          ) &&
          other.exerciseType == exerciseType &&
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
        description,
        _localizedTitlesHash(localizedTitles),
        _localizedInstructionsHash(localizedInstructions),
        exerciseType,
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
