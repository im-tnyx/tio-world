import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Nutrition',
      description: 'Log your meals and monitor your macros.',
    );
  }
}
