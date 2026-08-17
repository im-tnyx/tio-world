import 'package:tio_shared/shared.dart';

import '../../domain/models/onboarding_draft.dart';
import '../../domain/models/onboarding_draft_snapshot.dart';
import '../../domain/models/onboarding_status.dart';
import '../../domain/models/onboarding_step_id.dart';
import '../../domain/models/profile_onboarding_draft.dart';
import '../../domain/models/profile_step_id.dart';
import '../../domain/models/target_step_id.dart';
import '../../domain/models/targets_onboarding_draft.dart';
import '../../domain/models/workout_duration.dart';
import '../../domain/models/workout_equipment.dart';
import '../../domain/models/workout_experience_level.dart';
import '../../domain/models/workout_focus_area.dart';
import '../../domain/models/workout_gym_access.dart';
import '../../domain/models/workout_intro_choice.dart';
import '../../domain/models/workout_onboarding_draft.dart';
import '../../domain/models/workout_split.dart';
import '../../domain/models/workout_step_id.dart';
import '../../domain/models/workout_training_day.dart';

/// Versioned serialization mapper for [OnboardingDraftSnapshot].
///
/// Encodes and decodes canonical draft payloads to/from JSON maps using
/// stable string identifiers for forward compatibility.
class OnboardingDraftSnapshotDtoMapper {
  const OnboardingDraftSnapshotDtoMapper();

  static const int supportedSchemaVersion = 1;

  Map<String, dynamic> toJson(OnboardingDraftSnapshot snapshot) {
    final draft = snapshot.draft;

    return {
      'schema_version': snapshot.schemaVersion,
      'status': draft.status.name,
      'selected_mode': draft.selectedMode?.name,
      'workout_intro_choice': draft.workoutIntroChoice?.name,
      'current_step_id': draft.currentStepId.name,
      'completed_step_ids': draft.completedStepIds.map((s) => s.name).toList(),
      'profile': _profileToJson(draft.profile),
      'workout': _workoutToJson(draft.workout),
      'targets': _targetsToJson(draft.targets),
      'updated_at': (snapshot.updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    };
  }

  OnboardingDraftSnapshot fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schema_version'] as int? ?? supportedSchemaVersion;
    if (schemaVersion > supportedSchemaVersion) {
      throw UnsupportedError(
        'Onboarding draft schema version $schemaVersion is newer than supported version $supportedSchemaVersion.',
      );
    }

    final statusStr = json['status'] as String?;
    final status = OnboardingStatus.values.where((s) => s.name == statusStr).firstOrNull ??
        OnboardingStatus.inProgress;

    final modeStr = json['selected_mode'] as String?;
    final selectedMode =
        AppMode.values.where((m) => m.name == modeStr).firstOrNull;

    final introStr = json['workout_intro_choice'] as String?;
    final workoutIntroChoice =
        WorkoutIntroChoice.values.where((c) => c.name == introStr).firstOrNull;

    final stepStr = json['current_step_id'] as String?;
    final currentStepId =
        OnboardingStepId.values.where((s) => s.name == stepStr).firstOrNull ??
            OnboardingStepId.mode;

    final completedList = (json['completed_step_ids'] as List<dynamic>?) ?? [];
    final completedStepIds = completedList
        .map((s) => OnboardingStepId.values.where((step) => step.name == s).firstOrNull)
        .whereType<OnboardingStepId>()
        .toSet();

    final profile = json['profile'] is Map<String, dynamic>
        ? _profileFromJson(json['profile'] as Map<String, dynamic>)
        : ProfileOnboardingDraft();

    final workout = json['workout'] is Map<String, dynamic>
        ? _workoutFromJson(json['workout'] as Map<String, dynamic>)
        : const WorkoutOnboardingDraft();

    final targets = json['targets'] is Map<String, dynamic>
        ? _targetsFromJson(json['targets'] as Map<String, dynamic>)
        : const TargetsOnboardingDraft();

    final updatedAtStr = json['updated_at'] as String?;
    final updatedAt = updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null;

    final draft = OnboardingDraft(
      status: status,
      selectedMode: selectedMode,
      workoutIntroChoice: workoutIntroChoice,
      currentStepId: currentStepId,
      completedStepIds: completedStepIds,
      profile: profile,
      workout: workout,
      targets: targets,
    );

    return OnboardingDraftSnapshot(
      schemaVersion: schemaVersion,
      draft: draft,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> _profileToJson(ProfileOnboardingDraft p) => {
        'current_step_id': p.currentStepId.name,
        'name': p.name,
        'gender': p.gender?.name,
        'goals': p.goals.map((g) => g.name).toList(),
        'date_of_birth': p.dateOfBirth?.toIso8601String().split('T').first,
        'height_cm': p.heightCm,
        'current_weight_kg': p.currentWeightKg,
        'target_weight_kg': p.targetWeightKg,
        'activity_level': p.activityLevel?.name,
        'health_conditions': p.healthConditions.map((c) => c.name).toList(),
        'other_health_condition': p.otherHealthCondition,
        'mobile': p.mobile,
        'is_mobile_verified': p.isMobileVerified,
      };

  ProfileOnboardingDraft _profileFromJson(Map<String, dynamic> j) {
    final stepStr = j['current_step_id'] as String?;
    final currentStep = ProfileStepId.values.where((s) => s.name == stepStr).firstOrNull ??
        ProfileStepId.name;

    final genderStr = j['gender'] as String?;
    final gender = ProfileGender.values.where((g) => g.name == genderStr).firstOrNull;

    final goalsList = (j['goals'] as List<dynamic>?) ?? [];
    final goals = goalsList
        .map((g) => ProfileGoal.values.where((pg) => pg.name == g).firstOrNull)
        .whereType<ProfileGoal>()
        .toSet();

    final dobStr = j['date_of_birth'] as String?;
    final dob = dobStr != null ? DateTime.tryParse(dobStr) : null;

    final activityStr = j['activity_level'] as String?;
    final activity =
        ProfileActivityLevel.values.where((a) => a.name == activityStr).firstOrNull;

    final conditionsList = (j['health_conditions'] as List<dynamic>?) ?? [];
    final healthConditions = conditionsList
        .map((c) => ProfileHealthCondition.values.where((hc) => hc.name == c).firstOrNull)
        .whereType<ProfileHealthCondition>()
        .toSet();

    return ProfileOnboardingDraft(
      currentStepId: currentStep,
      name: j['name'] as String? ?? '',
      gender: gender,
      goals: goals,
      dateOfBirth: dob,
      heightCm: (j['height_cm'] as num?)?.toDouble(),
      currentWeightKg: (j['current_weight_kg'] as num?)?.toDouble(),
      targetWeightKg: (j['target_weight_kg'] as num?)?.toDouble(),
      activityLevel: activity,
      healthConditions: healthConditions,
      otherHealthCondition: j['other_health_condition'] as String? ?? '',
      mobile: j['mobile'] as String? ?? '',
      isMobileVerified: j['is_mobile_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _workoutToJson(WorkoutOnboardingDraft w) => {
        'current_step_id': w.currentStepId.name,
        'gym_access': w.gymAccess?.name,
        'equipment': w.equipment.map((e) => e.name).toList(),
        'experience_level': w.experienceLevel?.name,
        'focus_areas': w.focusAreas.map((f) => f.name).toList(),
        'training_days': w.trainingDays.map((d) => d.name).toList(),
        'workout_duration': w.workoutDuration?.name,
        'workout_split': w.workoutSplit?.name,
        'health_concerns': w.healthConcerns,
        'special_event': w.specialEvent,
      };

  WorkoutOnboardingDraft _workoutFromJson(Map<String, dynamic> j) {
    final stepStr = j['current_step_id'] as String?;
    final currentStep = WorkoutStepId.values.where((s) => s.name == stepStr).firstOrNull ??
        WorkoutStepId.gymAccess;

    final gymStr = j['gym_access'] as String?;
    final gym = WorkoutGymAccess.values.where((g) => g.name == gymStr).firstOrNull;

    final equipList = (j['equipment'] as List<dynamic>?) ?? [];
    final equipment = equipList
        .map((e) => WorkoutEquipment.values.where((we) => we.name == e).firstOrNull)
        .whereType<WorkoutEquipment>()
        .toSet();

    final expStr = j['experience_level'] as String?;
    final exp = WorkoutExperienceLevel.values.where((e) => e.name == expStr).firstOrNull;

    final focusList = (j['focus_areas'] as List<dynamic>?) ?? [];
    final focus = focusList
        .map((f) => WorkoutFocusArea.values.where((wf) => wf.name == f).firstOrNull)
        .whereType<WorkoutFocusArea>()
        .toSet();

    final daysList = (j['training_days'] as List<dynamic>?) ?? [];
    final days = daysList
        .map((d) => WorkoutTrainingDay.values.where((wd) => wd.name == d).firstOrNull)
        .whereType<WorkoutTrainingDay>()
        .toSet();

    final durStr = j['workout_duration'] as String?;
    final dur = WorkoutDuration.values.where((d) => d.name == durStr).firstOrNull;

    final splitStr = j['workout_split'] as String?;
    final split = WorkoutSplit.values.where((s) => s.name == splitStr).firstOrNull;

    return WorkoutOnboardingDraft(
      currentStepId: currentStep,
      gymAccess: gym,
      equipment: equipment,
      experienceLevel: exp,
      focusAreas: focus,
      trainingDays: days,
      workoutDuration: dur,
      workoutSplit: split,
      healthConcerns: j['health_concerns'] as String? ?? '',
      specialEvent: j['special_event'] as String? ?? '',
    );
  }

  Map<String, dynamic> _targetsToJson(TargetsOnboardingDraft t) => {
        'current_step_id': t.currentStepId.name,
        'daily_steps': t.dailySteps,
        'sleep_target_minutes': t.sleepTargetMinutes,
        'sleep_time_minutes': t.sleepTimeMinutes,
        'wake_time_minutes': t.wakeTimeMinutes,
        'water_ml': t.waterMl,
        'goal_pace_kg_per_week': t.goalPaceKgPerWeek,
      };

  TargetsOnboardingDraft _targetsFromJson(Map<String, dynamic> j) {
    final stepStr = j['current_step_id'] as String?;
    final currentStep = TargetStepId.values.where((s) => s.name == stepStr).firstOrNull ??
        TargetStepId.bridge;

    return TargetsOnboardingDraft(
      currentStepId: currentStep,
      dailySteps: j['daily_steps'] as int? ?? 10000,
      sleepTargetMinutes: j['sleep_target_minutes'] as int? ?? 480,
      sleepTimeMinutes: j['sleep_time_minutes'] as int? ?? 1320,
      wakeTimeMinutes: j['wake_time_minutes'] as int? ?? 360,
      waterMl: j['water_ml'] as int? ?? 2500,
      goalPaceKgPerWeek: (j['goal_pace_kg_per_week'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
