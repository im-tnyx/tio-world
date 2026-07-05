import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Workout',
      description: 'Track your exercises and follow workout plans.',
    );
  }
}
