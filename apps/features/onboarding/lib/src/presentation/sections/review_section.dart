import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../screens/review/review_screen.dart';
import '../state/state.dart';

class ReviewSection extends StatelessWidget {
  const ReviewSection({
    required this.state,
    super.key,
  });

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.review) {
      throw StateError('ReviewSection can only render the review step.');
    }

    return ReviewScreen(
      draft: state.draft,
      flowPlan: state.flowPlan,
      completionEligibility: state.completionEligibility,
    );
  }
}
