import 'dart:async';

import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

// Synthetic fixtures only; media hosts are reserved example domains.

ExerciseMedia syntheticMedia(
  String slug, {
  ExerciseMediaGender defaultGender = ExerciseMediaGender.male,
  bool femaleImage = true,
  bool maleImage = true,
  bool thumbnailOnly = false,
}) {
  Uri? image(String gender, bool present) => present && !thumbnailOnly
      ? Uri.parse('https://media.example/$slug-$gender.png')
      : null;
  Uri? thumbnail(String gender) => thumbnailOnly
      ? Uri.parse('https://media.example/$slug-$gender-thumb.jpg')
      : null;

  return ExerciseMedia(
    type: ExerciseMediaType.image,
    defaultGender: defaultGender,
    male: ExerciseMediaVariant(
      imageUrl: image('male', maleImage),
      thumbnailUrl: thumbnail('male'),
    ),
    female: ExerciseMediaVariant(
      imageUrl: image('female', femaleImage),
      thumbnailUrl: thumbnail('female'),
    ),
  );
}

Exercise syntheticExercise(
  String id,
  String displayName, {
  String? muscleGroup,
  String? primaryEquipment,
  String? category,
  ExerciseStatus status = ExerciseStatus.active,
  ExerciseMedia? media,
}) =>
    Exercise(
      ref: ExerciseRef.catalog(id),
      displayName: displayName,
      muscleGroup: muscleGroup,
      primaryEquipment: primaryEquipment,
      category: category,
      status: status,
      media: media,
    );

/// Three active Exercises across two muscle groups, equipment and
/// categories, plus one archived Exercise that must never surface.
ExerciseCatalog syntheticCatalog() => ExerciseCatalog([
      syntheticExercise(
        'ex_synthetic_curl',
        'Synthetic Curl',
        muscleGroup: 'upper_arms',
        primaryEquipment: 'dumbbell',
        category: 'strength',
        media: syntheticMedia('curl'),
      ),
      syntheticExercise(
        'ex_synthetic_press',
        'Synthetic Press',
        muscleGroup: 'chest',
        primaryEquipment: 'ez_bar',
        category: 'strength',
        media: syntheticMedia('press', thumbnailOnly: true),
      ),
      syntheticExercise(
        'ex_synthetic_stretch',
        'Synthetic Stretch',
        muscleGroup: 'upper_arms',
        category: 'stretch',
      ),
      syntheticExercise(
        'ex_synthetic_archived',
        'Synthetic Archived Curl',
        muscleGroup: 'waist',
        primaryEquipment: 'cable',
        category: 'cardio',
        status: ExerciseStatus.archived,
      ),
    ]);

/// Repository that completes with [catalog], or fails with [error].
///
/// With [hold] set, [load] waits until [release] is called.
final class FakeExerciseCatalogRepository implements ExerciseCatalogRepository {
  FakeExerciseCatalogRepository({
    this.catalog,
    this.error,
    bool hold = false,
  }) : _gate = hold ? Completer<void>() : null;

  final ExerciseCatalog? catalog;
  final Object? error;
  final Completer<void>? _gate;
  int loads = 0;

  void release() => _gate?.complete();

  @override
  Future<ExerciseCatalog> load() async {
    loads++;
    if (_gate != null) await _gate.future;
    if (error case final error?) throw error;
    return catalog ?? ExerciseCatalog(const []);
  }
}
