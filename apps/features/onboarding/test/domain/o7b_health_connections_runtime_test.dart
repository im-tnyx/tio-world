import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O7B Health Connections runtime', () {
    test('default gateway fails safe as unavailable and never fabricates connected',
        () async {
      const gateway = UnavailableHealthConnectionGateway();

      expect(await gateway.readStatus(), HealthConnectionStatus.unavailable);
      expect(
        await gateway.requestConnection(),
        HealthConnectionStatus.unavailable,
      );
    });

    test('controller only reports connected when gateway returns connected',
        () async {
      final gateway = _RecordingHealthConnectionGateway(
        initial: HealthConnectionStatus.notRequested,
        requestResult: HealthConnectionStatus.connected,
      );
      final controller = HealthConnectionsController(gateway: gateway);

      await controller.refresh();
      expect(controller.status, HealthConnectionStatus.notRequested);
      expect(gateway.requestCount, 0);

      await controller.requestConnection();
      expect(gateway.requestCount, 1);
      expect(controller.status, HealthConnectionStatus.connected);
    });

    test('all active modes place optional Health Connections before Review', () {
      const buildFlow = BuildOnboardingFlowUseCase();

      for (final mode in AppMode.values) {
        final plan = buildFlow(
          entryPath: OnboardingEntryPath.firstRun,
          mode: mode,
          workoutIntroChoice:
              mode == AppMode.hybrid ? WorkoutIntroChoice.later : null,
        );
        final healthIndex = plan.stepIds.indexOf(OnboardingStepId.healthConnections);
        final reviewIndex = plan.stepIds.indexOf(OnboardingStepId.review);
        final nutritionTargetsIndex =
            plan.stepIds.indexOf(OnboardingStepId.nutritionGoals);

        expect(healthIndex, nutritionTargetsIndex + 1, reason: '$mode placement');
        expect(reviewIndex, healthIndex + 1, reason: '$mode review placement');
        expect(
          plan.definitionFor(OnboardingStepId.healthConnections).isRequired,
          isFalse,
        );
      }
    });

    testWidgets('approved screen distinguishes unavailable and connected states',
        (tester) async {
      Future<void> pump(HealthConnectionStatus status) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                TioTheme(child: child ?? const SizedBox.shrink()),
            home: Scaffold(
              body: HealthConnectionsScreen(
                status: status,
                isBusy: false,
              ),
            ),
          ),
        );
      }

      await pump(HealthConnectionStatus.unavailable);
      expect(find.text('Connect health data'), findsOneWidget);
      expect(find.text('Health connection is not available yet'), findsOneWidget);
      expect(find.textContaining('never requests permission'), findsOneWidget);

      await pump(HealthConnectionStatus.connected);
      expect(find.text('Health data connected'), findsOneWidget);
    });

    testWidgets('pre-O7B unfinished Review draft routes through Health Connections',
        (tester) async {
      final draft = OnboardingDraft(
        status: OnboardingStatus.inProgress,
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.review,
        completedStepIds: const {
          OnboardingStepId.profileBasics,
          OnboardingStepId.bodyGoal,
          OnboardingStepId.wellnessGoals,
          OnboardingStepId.nutritionProfile,
          OnboardingStepId.nutritionGoals,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) =>
                TioTheme(child: child ?? const SizedBox.shrink()),
            home: OnboardingFlowPage(
              seed: OnboardingControllerSeed(
                entryPath: OnboardingEntryPath.resumeDraft,
                draft: draft,
              ),
              onFinishRequested: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HealthConnectionsScreen), findsOneWidget);
      expect(find.text('Connect health data'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Finish'), findsNothing);
    });
  });
}

class _RecordingHealthConnectionGateway implements HealthConnectionGateway {
  _RecordingHealthConnectionGateway({
    required this.initial,
    required this.requestResult,
  });

  final HealthConnectionStatus initial;
  final HealthConnectionStatus requestResult;
  int requestCount = 0;

  @override
  Future<HealthConnectionStatus> readStatus() async => initial;

  @override
  Future<HealthConnectionStatus> requestConnection() async {
    requestCount++;
    return requestResult;
  }
}
