import '../../domain/models/models.dart';
import 'onboarding_draft_snapshot_dto_mapper.dart';

/// Additive O5B draft codec layered over the legacy snapshot mapper.
///
/// Older schema payloads remain readable. Nutrition Profile answers are draft
/// orchestration data only and do not become durable Nutrition owner writes.
class NutritionAwareOnboardingDraftSnapshotDtoMapper
    extends OnboardingDraftSnapshotDtoMapper {
  const NutritionAwareOnboardingDraftSnapshotDtoMapper();

  @override
  Map<String, dynamic> toJson(OnboardingDraftSnapshot snapshot) {
    final json = super.toJson(snapshot);
    json['nutrition'] = _nutritionToJson(snapshot.draft.nutrition);
    return json;
  }

  @override
  OnboardingDraftSnapshot fromJson(Map<String, dynamic> json) {
    final base = super.fromJson(json);
    final nutrition = json['nutrition'] is Map<String, dynamic>
        ? _nutritionFromJson(json['nutrition'] as Map<String, dynamic>)
        : const NutritionOnboardingDraft();
    return OnboardingDraftSnapshot(
      schemaVersion: base.schemaVersion,
      draft: base.draft.copyWith(nutrition: nutrition),
      updatedAt: base.updatedAt,
    );
  }

  Map<String, dynamic> _nutritionToJson(NutritionOnboardingDraft draft) => {
        'current_step_id': draft.currentStepId.name,
        'diet_type': draft.dietType?.storageValue,
        'other_diet_type': draft.otherDietType,
        'allergy_restrictions': draft.allergyRestrictions
            ?.map((restriction) => restriction.storageValue)
            .toList(growable: false),
        'other_allergy_restriction': draft.otherAllergyRestriction,
      };

  NutritionOnboardingDraft _nutritionFromJson(Map<String, dynamic> json) {
    final currentStep = _nutritionStepFromStorage(json['current_step_id']);
    final rawRestrictions = json['allergy_restrictions'];
    final Set<NutritionAllergyRestriction>? restrictions;
    if (rawRestrictions is List<dynamic>) {
      restrictions = rawRestrictions
          .map(NutritionAllergyRestriction.tryFromStorage)
          .whereType<NutritionAllergyRestriction>()
          .toSet();
    } else {
      restrictions = null;
    }

    return NutritionOnboardingDraft(
      currentStepId: currentStep,
      dietType: NutritionDietType.tryFromStorage(json['diet_type']),
      otherDietType: _stringOrEmpty(json['other_diet_type']),
      allergyRestrictions: restrictions,
      otherAllergyRestriction:
          _stringOrEmpty(json['other_allergy_restriction']),
    );
  }

  NutritionProfileStepId _nutritionStepFromStorage(Object? value) {
    if (value is String) {
      for (final step in NutritionProfileStepId.values) {
        if (step.name == value) return step;
      }
    }
    return NutritionProfileStepId.dietType;
  }

  String _stringOrEmpty(Object? value) => value is String ? value : '';
}
