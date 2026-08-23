import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O7E integrated Health Connections acceptance', () {
    test('all App Mode variants keep Health optional immediately before Review', () {
      const buildFlow = BuildOnboardingFlowUseCase();
      const validator = OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      );
      final variants = <({AppMode mode, WorkoutIntroChoice? intro})>[
        (mode: AppMode.workout, intro: null),
        (mode: AppMode.nutrition, intro: null),
        (mode: AppMode.hybrid, intro: WorkoutIntroChoice.setupNow),
        (mode: AppMode.hybrid, intro: WorkoutIntroChoice.later),
      ];

      for (final variant in variants) {
        final plan = buildFlow(
          entryPath: OnboardingEntryPath.firstRun,
          mode: variant.mode,
          workoutIntroChoice: variant.intro,
        );
        final healthIndex =
            plan.stepIds.indexOf(OnboardingStepId.healthConnections);
        final reviewIndex = plan.stepIds.indexOf(OnboardingStepId.review);

        expect(healthIndex, greaterThanOrEqualTo(0), reason: '${variant.mode}');
        expect(reviewIndex, healthIndex + 1, reason: '${variant.mode}');
        expect(
          plan.definitionFor(OnboardingStepId.healthConnections).isRequired,
          isFalse,
          reason: '${variant.mode}',
        );
        expect(
          validator
              .evaluate(
                draft: OnboardingDraft(
                  selectedMode: variant.mode,
                  workoutIntroChoice: variant.intro,
                ),
                flowPlan: plan,
              )
              .isEligible,
          isTrue,
          reason: 'Health must not become a completion blocker for ${variant.mode}',
        );
      }
    });

    test('current-release gateway cannot fabricate authorization', () async {
      const gateway = UnavailableHealthConnectionGateway();

      expect(await gateway.readStatus(), HealthConnectionStatus.unavailable);
      expect(
        await gateway.requestConnection(),
        HealthConnectionStatus.unavailable,
      );
    });

    test('serialized draft ignores stale or injected platform Health status', () {
      const mapper = OnboardingDraftSnapshotDtoMapper();
      final restored = mapper.fromJson({
        'schema_version': OnboardingDraftSnapshot.currentSchemaVersion,
        'status': 'inProgress',
        'selected_mode': 'nutrition',
        'current_step_id': 'review',
        'completed_step_ids': ['healthConnections'],
        'health_connection_status': 'connected',
        'health_connect_status': 'connected',
      });

      expect(
        restored.draft.completedStepIds,
        contains(OnboardingStepId.healthConnections),
      );

      final encoded = mapper.toJson(restored);
      expect(encoded.containsKey('health_connection_status'), isFalse);
      expect(encoded.containsKey('health_connect_status'), isFalse);
      expect(encoded.containsKey('health_connection'), isFalse);
      expect(encoded.containsKey('health_connections'), isFalse);
    });

    test('canonical owner persistence has no Health authorization owner target', () {
      final ownerNames = OwnerPersistenceTarget.values.map((owner) => owner.name);

      expect(ownerNames, isNot(contains('health')));
      expect(ownerNames, isNot(contains('healthConnection')));
      expect(ownerNames, isNot(contains('healthConnections')));
    });

    testWidgets('unfinished pre-O7B Review checkpoint must pass through Health',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) =>
                TioTheme(child: child ?? const SizedBox.shrink()),
            home: OnboardingFlowPage(
              seed: OnboardingControllerSeed(
                entryPath: OnboardingEntryPath.resumeDraft,
                draft: _nutritionReviewDraft(includeHealthCheckpoint: false),
              ),
              onFinishRequested: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HealthConnectionsScreen), findsOneWidget);
      expect(find.text('Connect health data'), findsOneWidget);
      expect(find.text('Review your plan'), findsNothing);
    });

    testWidgets('completed Health checkpoint resumes Review without connection claim',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) =>
                TioTheme(child: child ?? const SizedBox.shrink()),
            home: OnboardingFlowPage(
              seed: OnboardingControllerSeed(
                entryPath: OnboardingEntryPath.resumeDraft,
                draft: _nutritionReviewDraft(includeHealthCheckpoint: true),
              ),
              onFinishRequested: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review your plan'), findsOneWidget);
      expect(find.byType(HealthConnectionsScreen), findsNothing);
      expect(find.text('Health data connected'), findsNothing);
      expect(find.text('Connected'), findsNothing);
    });
  });
}

OnboardingDraft _nutritionReviewDraft({required bool includeHealthCheckpoint}) {
  return OnboardingDraft(
    status: OnboardingStatus.inProgress,
    selectedMode: AppMode.nutrition,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.maintainWeight,
    ),
    currentStepId: OnboardingStepId.review,
    completedStepIds: {
      OnboardingStepId.profileBasics,
      OnboardingStepId.bodyGoal,
      OnboardingStepId.wellnessGoals,
      OnboardingStepId.nutritionProfile,
      OnboardingStepId.nutritionGoals,
      if (includeHealthCheckpoint) OnboardingStepId.healthConnections,
    },
  );
}
