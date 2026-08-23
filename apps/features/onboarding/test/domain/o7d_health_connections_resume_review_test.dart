import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O7D Health Connections resume and Review', () {
    const mapper = OnboardingDraftSnapshotDtoMapper();

    test('snapshot persists Health step progress without platform health state', () {
      final snapshot = OnboardingDraftSnapshot(
        draft: _nutritionHealthDraft(
          currentStepId: OnboardingStepId.review,
          completedStepIds: const {
            OnboardingStepId.healthConnections,
          },
        ),
        updatedAt: DateTime.utc(2026, 8, 23, 2),
      );

      final json = mapper.toJson(snapshot);

      expect(json['current_step_id'], 'review');
      expect(
        json['completed_step_ids'],
        contains('healthConnections'),
      );
      expect(json.containsKey('health_connection_status'), isFalse);
      expect(json.containsKey('health_connect_status'), isFalse);
      expect(json.containsKey('health_connection'), isFalse);
      expect(json.containsKey('health_connections'), isFalse);

      final restored = mapper.fromJson(json);
      expect(restored.draft.currentStepId, OnboardingStepId.review);
      expect(
        restored.draft.completedStepIds,
        contains(OnboardingStepId.healthConnections),
      );
    });

    test('completed Health step resumes at Review without platform state', () async {
      final repository = InMemoryOnboardingDraftRepository(
        initialSnapshot: OnboardingDraftSnapshot(
          draft: _nutritionHealthDraft(
            currentStepId: OnboardingStepId.healthConnections,
          ),
        ),
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        draftRepository: repository,
      );

      await controller.hydrateDraft();
      expect(controller.state.stepId, OnboardingStepId.healthConnections);

      await controller.next(onFinish: (_) async {});
      expect(controller.state.stepId, OnboardingStepId.review);
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.healthConnections),
      );

      // Immediate autosave is intentionally fire-and-forget in the controller.
      // Yield once so the in-memory repository observes that checkpoint.
      await Future<void>.delayed(Duration.zero);
      final saved = await repository.loadDraft();
      expect(saved, isNotNull);
      expect(saved!.draft.currentStepId, OnboardingStepId.review);
      expect(
        saved.draft.completedStepIds,
        contains(OnboardingStepId.healthConnections),
      );

      final resumed = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        draftRepository: repository,
      );
      await resumed.hydrateDraft();

      expect(resumed.state.stepId, OnboardingStepId.review);
      expect(
        resumed.state.completedStepIds,
        contains(OnboardingStepId.healthConnections),
      );
    });

    testWidgets('Review never fabricates a connected Health state', (tester) async {
      final draft = _nutritionHealthDraft(
        currentStepId: OnboardingStepId.review,
        completedStepIds: const {
          OnboardingStepId.healthConnections,
        },
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TioTheme(
            child: Scaffold(
              body: SingleChildScrollView(
                child: ReviewScreen(
                  draft: draft,
                  flowPlan: flowPlan,
                  completionEligibility:
                      OnboardingCompletionEligibility.eligible,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review your plan'), findsOneWidget);
      expect(find.text('Health data connected'), findsNothing);
      expect(find.text('Connected'), findsNothing);
    });
  });
}

OnboardingDraft _nutritionHealthDraft({
  required OnboardingStepId currentStepId,
  Set<OnboardingStepId> completedStepIds = const {},
}) {
  return OnboardingDraft(
    status: OnboardingStatus.inProgress,
    selectedMode: AppMode.nutrition,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.maintainWeight,
    ),
    currentStepId: currentStepId,
    completedStepIds: completedStepIds,
  );
}
