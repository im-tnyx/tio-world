import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'nutrition_profile_screen_components.dart';

class AllergiesRestrictionsScreen extends StatelessWidget {
  const AllergiesRestrictionsScreen({
    required this.selectedRestrictions,
    required this.otherText,
    required this.onToggled,
    required this.onOtherTextChanged,
    super.key,
    this.errorText,
  });

  final Set<NutritionAllergyRestriction>? selectedRestrictions;
  final String otherText;
  final ValueChanged<NutritionAllergyRestriction> onToggled;
  final ValueChanged<String> onOtherTextChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final selected =
        selectedRestrictions ?? const <NutritionAllergyRestriction>{};
    return NutritionProfileScreenScaffold(
      stepId: NutritionProfileStepId.allergiesRestrictions,
      title: 'Any food allergies or restrictions?',
      description: 'Select all that apply, or choose None.',
      errorText: errorText,
      child: Column(
        children: [
          for (final restriction in NutritionAllergyRestriction.values) ...[
            if (restriction == NutritionAllergyRestriction.other)
              NutritionProfileOtherChoiceCard(
                id: 'nutrition-allergy-other',
                selected: selected.contains(NutritionAllergyRestriction.other),
                value: otherText,
                hintText: 'e.g. Soy, Sesame, specific foods...',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggled(NutritionAllergyRestriction.other);
                },
                onTextChanged: onOtherTextChanged,
              )
            else
              NutritionProfileChoiceCard(
                id: 'nutrition-allergy-${restriction.name}',
                title: _restrictionLabel(restriction),
                selected: selected.contains(restriction),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggled(restriction);
                },
              ),
            const SizedBox(height: TioSpacing.md),
          ],
        ],
      ),
    );
  }
}

String _restrictionLabel(NutritionAllergyRestriction restriction) =>
    switch (restriction) {
      NutritionAllergyRestriction.none => 'None',
      NutritionAllergyRestriction.lactose => 'Lactose',
      NutritionAllergyRestriction.gluten => 'Gluten',
      NutritionAllergyRestriction.nuts => 'Nuts',
      NutritionAllergyRestriction.seafood => 'Seafood',
      NutritionAllergyRestriction.other => 'Other',
    };
