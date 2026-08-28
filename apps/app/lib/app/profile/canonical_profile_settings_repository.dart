import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';

/// App-level Profile Settings adapter that respects the final canonical owner
/// boundaries without introducing a cross-feature dependency into Profile.
///
/// Common Profile fields are persisted through [UserProfileRepository] while
/// Current Weight is recorded through [BodyRepository]. Account-owned username
/// remains coordinated separately by [SaveProfileSettingsUseCase].
final class CanonicalProfileSettingsRepository
    implements ProfileSettingsRepository {
  CanonicalProfileSettingsRepository({
    required UserProfileRepository profileRepository,
    required BodyRepository bodyRepository,
    DateTime Function()? now,
  })  : _profileRepository = profileRepository,
        _bodyRepository = bodyRepository,
        _now = now ?? DateTime.now;

  final UserProfileRepository _profileRepository;
  final BodyRepository _bodyRepository;
  final DateTime Function() _now;

  @override
  Future<void> updateProfileSettings(ProfileSettingsUpdate update) async {
    final current = await _profileRepository.read();
    if (current == null) {
      throw StateError(
        'Canonical Profile is not initialized for the current account.',
      );
    }

    await _profileRepository.upsert(
      UserProfileData(
        name: update.name,
        gender: update.gender,
        dateOfBirth: update.dateOfBirth,
        unitPreferences: current.unitPreferences,
        heightCm: update.heightCm,
        activityLevel: current.activityLevel,
        healthConditions: current.healthConditions,
        otherHealthCondition: current.otherHealthCondition,
      ),
    );

    await _bodyRepository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: update.currentWeightKg,
        measuredAt: _now().toUtc(),
        source: BodyWeightSources.profileSettings,
      ),
    );
  }
}
