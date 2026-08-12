import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final shouldHandleInternalBack = state.canGoBack;
    final shouldHandleRouteExit = onExitRequested != null;

    return PopScope(
      canPop: !shouldHandleInternalBack && !shouldHandleRouteExit,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.state.canGoBack) {
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
              OnboardingTopBar(
                state: state,
                onExitRequested: onExitRequested == null
                    ? null
                    : () => unawaited(onExitRequested!()),
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
          onBack: controller.previous,
          onContinue: () => controller.next(onFinish: onFinishRequested),
        ),
      ),
    );
  }
}
