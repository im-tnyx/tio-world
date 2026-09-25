import 'package:tio_feature_profile/profile.dart';
import 'package:tio_shared/shared.dart';

/// Exercise media gender for a signed-in profile's gender.
///
/// `other` and an unknown profile map to null, so Exercise media falls back
/// to each Exercise's curated `defaultGender`. Workout cannot read Profile,
/// so this composition-root mapping feeds `exerciseViewerMediaGenderProvider`.
ExerciseMediaGender? exerciseMediaGenderForProfile(ProfileGender? gender) =>
    switch (gender) {
      ProfileGender.male => ExerciseMediaGender.male,
      ProfileGender.female => ExerciseMediaGender.female,
      ProfileGender.other || null => null,
    };
