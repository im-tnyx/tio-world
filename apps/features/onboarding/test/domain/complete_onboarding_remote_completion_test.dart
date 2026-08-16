import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('CompleteOnboardingUseCase remote completion publication', () {
    test('publishes backend completion before local completed cache', () async {
      final operations = <String>[];
      final modePreference = _FakeAppModePreference(operations);
      final statusRepository = _FakeOnboardingStatusRepository(operations);
      final completionRepository = _FakeOnboardingCompletionRepository(
        operations,
      );
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: modePreference,
        statusRepository: statusRepository,
        completionRepository: completionRepository,
        validator: const OnboardingCompletionValidator(
          hasDurableOwnerPersistence: true,
          backendUserReady: true,
        ),
      );

      await useCase(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
        flowPlan: const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: AppMode.workout,
          workoutIntroChoice: null,
        ),
      );

      expect(
        operations,
        [
          'status.ensureInitialized',
          'mode.write.workout',
          'remote.markCompleted',
          'status.write.completed',
        ],
      );
      expect(statusRepository.status, OnboardingStatus.completed);
    });

    test('backend completion failure never publishes local completed cache',
        () async {
      final operations = <String>[];
      final modePreference = _FakeAppModePreference(operations);
      final statusRepository = _FakeOnboardingStatusRepository(operations);
      final completionRepository = _FakeOnboardingCompletionRepository(
        operations,
        error: StateError('remote completion failed'),
      );
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: modePreference,
        statusRepository: statusRepository,
        completionRepository: completionRepository,
        validator: const OnboardingCompletionValidator(
          hasDurableOwnerPersistence: true,
          backendUserReady: true,
        ),
      );

      await expectLater(
        () => useCase(
          draft: OnboardingDraft(selectedMode: AppMode.workout),
          flowPlan: const BuildOnboardingFlowUseCase()(
            entryPath: OnboardingEntryPath.firstRun,
            mode: AppMode.workout,
            workoutIntroChoice: null,
          ),
        ),
        throwsStateError,
      );

      expect(
        operations,
        [
          'status.ensureInitialized',
          'mode.write.workout',
          'remote.markCompleted',
        ],
      );
      expect(statusRepository.status, isNull);
      expect(modePreference.storedMode, AppMode.workout);
    });
  });
}

class _FakeOnboardingCompletionRepository
    implements OnboardingCompletionRepository {
  _FakeOnboardingCompletionRepository(
    this.operations, {
    this.error,
  });

  final List<String> operations;
  final Object? error;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async {
    return RemoteOnboardingCompletionState.incomplete;
  }

  @override
  Future<void> markCurrentCompleted() async {
    operations.add('remote.markCompleted');
    if (error case final error?) {
      throw error;
    }
  }
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference(this.operations);

  final List<String> operations;
  AppMode? storedMode;

  @override
  Future<void> clear() async {
    storedMode = null;
  }

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
    storedMode = mode;
    operations.add('mode.write.${mode.name}');
  }
}

class _FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  _FakeOnboardingStatusRepository(this.operations);

  final List<String> operations;
  OnboardingStatus? status;
  bool hasStoredContractVersion = false;

  @override
  Future<void> clear() async {
    status = null;
    hasStoredContractVersion = false;
  }

  @override
  Future<void> ensureInitialized() async {
    hasStoredContractVersion = true;
    operations.add('status.ensureInitialized');
  }

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return OnboardingStatusSnapshot(
      status: status,
      hasStoredContractVersion: hasStoredContractVersion,
    );
  }

  @override
  Future<void> write(OnboardingStatus status) async {
    this.status = status;
    hasStoredContractVersion = true;
    operations.add('status.write.${status.name}');
  }
}
