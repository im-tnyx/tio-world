import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../widgets/widgets.dart';

class OnboardingFlowPage extends ConsumerWidget {
  const OnboardingFlowPage({
    required this.seed,
    required this.stepBuilder,
    required this.onFinishRequested,
    super.key,
    this.onExitRequested,
  });

  final OnboardingControllerSeed seed;
  final OnboardingStepBuilder stepBuilder;
  final Future<void> Function() onFinishRequested;
  final Future<void> Function()? onExitRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider(seed));
    final state = controller.state;
    final shouldHandleRouteExit = onExitRequested != null;
    final visibleBack = state.hasPreviousStep
        ? controller.previous
        : onExitRequested == null
            ? null
            : () => unawaited(onExitRequested!());

    return PopScope(
      canPop: !state.isBusy && !state.hasPreviousStep && !shouldHandleRouteExit,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.state.isBusy) return;
        if (controller.state.hasPreviousStep) {
          controller.previous();
          return;
        }
        final exit = onExitRequested;
        if (exit != null) unawaited(exit());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (state.stepId != OnboardingStepId.mode)
                OnboardingTopBar(
                  state: state,
                  onBack: visibleBack,
                ),
              Expanded(
                child: OnboardingContentHost(
                  state: state,
                  controller: controller,
                  stepBuilder: stepBuilder,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: OnboardingBottomBar(
          state: state,
          onContinue: () => controller.next(onFinish: onFinishRequested),
        ),
      ),
    );
  }
}
