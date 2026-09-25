import 'package:tio_shared/shared.dart';

import '../../domain/exercises/invalid_exercise_catalog_exception.dart';

/// Typed view of the built-in catalog row fields W3A consumes.
///
/// Data-boundary only: presentation and other consumers see canonical
/// [Exercise] values. Unknown row keys are ignored. Presence and type are
/// checked here; value rules such as blank or duplicate taxonomy and https
/// media URLs come from the canonical [Exercise] and [ExerciseMedia]
/// contracts. `media` is optional.
final class ExerciseCatalogRowDto {
  const ExerciseCatalogRowDto._({
    required this.rowIndex,
    required this.id,
    required this.title,
    required this.muscleGroup,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.primaryEquipment,
    required this.category,
    required this.levels,
    required this.isArchived,
    required _MediaFields? media,
  }) : _media = media;

  final int rowIndex;
  final String id;
  final String title;
  final String muscleGroup;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String primaryEquipment;
  final String category;
  final List<String> levels;
  final bool isArchived;
  final _MediaFields? _media;

  /// JSON paths for canonical [Exercise] argument names that differ.
  static const _pathByArgument = {
    'displayName': 'title',
    'primaryEquipment': 'equipment.primary',
  };

  /// Reads one decoded row, or appends issues to [issues] and returns null.
  static ExerciseCatalogRowDto? read(
    Object? row,
    int rowIndex,
    List<ExerciseCatalogIssue> issues,
  ) {
    if (row is! Map) {
      issues.add(ExerciseCatalogIssue(
        rowIndex: rowIndex,
        path: r'$',
        problem: 'must be an object',
      ));
      return null;
    }

    final rawId = row['id'];
    final exerciseId = rawId is String ? rawId : null;
    final issueCount = issues.length;

    void problem(String path, String description) {
      issues.add(ExerciseCatalogIssue(
        rowIndex: rowIndex,
        exerciseId: exerciseId,
        path: path,
        problem: description,
      ));
    }

    T? field<T>(Map<dynamic, dynamic> map, String key, String path) {
      if (!map.containsKey(key)) {
        problem(path, 'is required');
        return null;
      }
      final value = map[key];
      if (value is T) return value;
      problem(path, 'must be ${_describe<T>()}');
      return null;
    }

    List<String>? stringList(String key) {
      final value = field<List<dynamic>>(row, key, key);
      if (value == null) return null;
      if (value.any((item) => item is! String)) {
        problem(key, 'must be a list of strings');
        return null;
      }
      return List<String>.from(value);
    }

    final id = field<String>(row, 'id', 'id');
    final title = field<String>(row, 'title', 'title');
    final muscleGroup = field<String>(row, 'muscleGroup', 'muscleGroup');
    final primaryMuscles = stringList('primaryMuscles');
    final secondaryMuscles = stringList('secondaryMuscles');
    final equipment =
        field<Map<dynamic, dynamic>>(row, 'equipment', 'equipment');
    final primaryEquipment = equipment == null
        ? null
        : field<String>(equipment, 'primary', 'equipment.primary');
    final category = field<String>(row, 'category', 'category');
    final levels = stringList('levels');
    final isArchived = field<bool>(row, 'isArchived', 'isArchived');
    final isCustom = field<bool>(row, 'isCustom', 'isCustom');
    if (isCustom == true) {
      problem('isCustom', 'must be false for a built-in catalog row');
    }
    final media = row.containsKey('media')
        ? _MediaFields.read(row['media'], problem)
        : null;

    if (issues.length != issueCount) return null;
    return ExerciseCatalogRowDto._(
      rowIndex: rowIndex,
      id: id!,
      title: title!,
      muscleGroup: muscleGroup!,
      primaryMuscles: primaryMuscles!,
      secondaryMuscles: secondaryMuscles!,
      primaryEquipment: primaryEquipment!,
      category: category!,
      levels: levels!,
      isArchived: isArchived!,
      media: media,
    );
  }

  /// Maps to canonical [Exercise], or appends an issue and returns null.
  Exercise? toExercise(List<ExerciseCatalogIssue> issues) {
    void problem(String path, String description) {
      issues.add(ExerciseCatalogIssue(
        rowIndex: rowIndex,
        exerciseId: id,
        path: path,
        problem: description,
      ));
    }

    final ExerciseRef ref;
    try {
      ref = ExerciseRef.catalog(id);
    } on ArgumentError {
      problem('id', 'must be a built-in catalog ex_* identifier');
      return null;
    }

    final ExerciseMedia? exerciseMedia;
    try {
      exerciseMedia = _media?.toMedia();
    } on _MediaUrlError catch (error) {
      problem(error.path, error.message);
      return null;
    }

    try {
      return Exercise(
        ref: ref,
        displayName: title,
        muscleGroup: muscleGroup,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        primaryEquipment: primaryEquipment,
        category: category,
        levels: levels,
        status: isArchived ? ExerciseStatus.archived : ExerciseStatus.active,
        media: exerciseMedia,
      );
    } on ArgumentError catch (error) {
      final argument = error.name ?? 'row';
      problem(
        _pathByArgument[argument] ?? argument,
        '${error.message}',
      );
      return null;
    }
  }

  static String _describe<T>() => switch (T) {
        const (String) => 'a string',
        const (bool) => 'a boolean',
        const (List<dynamic>) => 'a list',
        _ => 'an object',
      };
}

/// Presence/type-checked `media` object of one catalog row.
final class _MediaFields {
  const _MediaFields({
    required this.type,
    required this.defaultGender,
    required this.videoFallbackGender,
    required this.urls,
  });

  final ExerciseMediaType type;
  final ExerciseMediaGender defaultGender;
  final ExerciseMediaGender? videoFallbackGender;
  final Map<ExerciseMediaGender, Map<String, Uri?>> urls;

  static const _urlKeys = ['imageUrl', 'thumbnailUrl', 'videoUrl'];

  static _MediaFields? read(
    Object? value,
    void Function(String path, String problem) problem,
  ) {
    if (value is! Map) {
      problem('media', 'must be an object');
      return null;
    }
    var valid = true;

    T? enumValue<T extends Enum>(List<T> values, String key, bool required) {
      if (!value.containsKey(key) || value[key] == null) {
        if (required) {
          problem('media.$key', 'is required');
          valid = false;
        }
        return null;
      }
      final raw = value[key];
      for (final candidate in values) {
        if (candidate.name == raw) return candidate;
      }
      problem(
        'media.$key',
        'must be one of ${values.map((v) => v.name).join(', ')}',
      );
      valid = false;
      return null;
    }

    final type = enumValue(ExerciseMediaType.values, 'type', true);
    final defaultGender =
        enumValue(ExerciseMediaGender.values, 'defaultGender', true);
    final videoFallbackGender =
        enumValue(ExerciseMediaGender.values, 'videoFallbackGender', false);

    final urls = <ExerciseMediaGender, Map<String, Uri?>>{};
    for (final gender in ExerciseMediaGender.values) {
      final variant = value[gender.name];
      if (variant is! Map) {
        problem('media.${gender.name}', 'must be an object');
        valid = false;
        continue;
      }
      final variantUrls = <String, Uri?>{};
      for (final key in _urlKeys) {
        final raw = variant[key];
        final path = 'media.${gender.name}.$key';
        if (raw == null) {
          variantUrls[key] = null;
        } else if (raw is! String) {
          problem(path, 'must be a string or null');
          valid = false;
        } else {
          final uri = Uri.tryParse(raw);
          if (uri == null) {
            problem(path, 'must be a valid URL');
            valid = false;
          } else {
            variantUrls[key] = uri;
          }
        }
      }
      urls[gender] = variantUrls;
    }

    if (!valid) return null;
    return _MediaFields(
      type: type!,
      defaultGender: defaultGender!,
      videoFallbackGender: videoFallbackGender,
      urls: urls,
    );
  }

  /// Builds canonical media, or throws [_MediaUrlError] with its JSON path.
  ExerciseMedia toMedia() {
    ExerciseMediaVariant variant(ExerciseMediaGender gender) {
      final values = urls[gender]!;
      try {
        return ExerciseMediaVariant(
          imageUrl: values['imageUrl'],
          thumbnailUrl: values['thumbnailUrl'],
          videoUrl: values['videoUrl'],
        );
      } on ArgumentError catch (error) {
        throw _MediaUrlError(
          'media.${gender.name}.${error.name}',
          '${error.message}',
        );
      }
    }

    return ExerciseMedia(
      type: type,
      defaultGender: defaultGender,
      videoFallbackGender: videoFallbackGender,
      male: variant(ExerciseMediaGender.male),
      female: variant(ExerciseMediaGender.female),
    );
  }
}

final class _MediaUrlError {
  const _MediaUrlError(this.path, this.message);

  final String path;
  final String message;
}
