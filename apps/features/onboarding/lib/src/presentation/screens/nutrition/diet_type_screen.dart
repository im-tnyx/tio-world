import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'nutrition_profile_screen_components.dart';

class DietTypeScreen extends StatelessWidget {
  const DietTypeScreen({
    required this.selectedDietType,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final NutritionDietType? selectedDietType;
  final ValueChanged<NutritionDietType> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return NutritionProfileScreenScaffold(
      stepId: NutritionProfileStepId.dietType,
      title: 'What type of diet do you follow?',
      description: 'Choose the option that best matches your usual diet.',
      errorText: errorText,
      child: Column(
        children: [
          for (final dietType in NutritionDietType.values) ...[
            NutritionProfileChoiceCard(
              id: 'nutrition-diet-${dietType.name}',
              title: _dietLabel(dietType),
              selected: selectedDietType == dietType,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(dietType);
              },
            ),
            const SizedBox(height: TioSpacing.md),
          ],
        ],
      ),
    );
  }
}

String _dietLabel(NutritionDietType dietType) => switch (dietType) {
      NutritionDietType.vegetarian => 'Vegetarian',
      NutritionDietType.nonVegetarian => 'Non-Vegetarian',
      NutritionDietType.vegan => 'Vegan',
      NutritionDietType.eggitarian => 'Eggitarian',
      NutritionDietType.other => 'Other',
    };
