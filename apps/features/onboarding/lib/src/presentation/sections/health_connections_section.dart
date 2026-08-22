import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/health/health_connections_screen.dart';
import '../state/state.dart';

class HealthConnectionsSection extends ConsumerWidget {
  const HealthConnectionsSection({
    required this.state,
    super.key,
  });

  final OnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.stepId != OnboardingStepId.healthConnections ||
        state.currentSection != OnboardingSectionId.healthConnections) {
      throw StateError(
        'HealthConnectionsSection can only render the healthConnections step.',
      );
    }

    final controller = ref.watch(healthConnectionsControllerProvider);
    return HealthConnectionsScreen(
      status: controller.status,
      isBusy: controller.isBusy,
      error: controller.error,
    );
  }
}
