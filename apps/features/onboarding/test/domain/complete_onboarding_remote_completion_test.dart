import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('CompleteOnboardingUseCase remote completion publication', () {
    test('persists canonical preferences before local mode and completion',
        () async {
      final operations = <String>[];
      final modePreference = _FakeAppModePreference(operations);
      final statusRepository = _FakeOnboardingStatusRepository(operations);
      final remoteRepository = _FakeRemoteCompletionAndPreferences(operations);
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: modePreference,
        statusRepository: statusRepository,
        completionRepository: remoteRepository,
        validator: _validator,
      );

      await useCase(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
        flowPlan: _workoutFlowPlan,
      );

      expect(
        operations,
        [
          'status.ensureInitialized',
          'preferences.upsert.workout.home,workout,progress',
          'mode.write.workout',
          'remote.markCompleted',
          'status.write.completed',
        ],
      );
      expect(statusRepository.status, OnboardingStatus.completed);
      expect(modePreference.storedMode, AppMode.workout);
      expect(remoteRepository.preferencesState.appMode, AppMode.workout);
      expect(
        remoteRepository.preferencesState.activeTabs,
        AppMode.workout.guidedDestinations,
      );
    });

    test('canonical preference failure keeps onboarding incomplete and retryable',
        () async {
      final operations = <String>[];
      final modePreference = _FakeAppModePreference(operations);
      final statusRepository = _FakeOnboardingStatusRepository(operations);
      final remoteRepository = _FakeRemoteCompletionAndPreferences(
        operations,
        preferencesWriteError: StateError('preferences write failed'),
      );
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: modePreference,
        statusRepository: statusRepository,
        completionRepository: remoteRepository,
        validator: _validator,
      );

      await expectLater(
        () => useCase(
          draft: OnboardingDraft(selectedMode: AppMode.workout),
          flowPlan: _workoutFlowPlan,
        ),
        throwsStateError,
      );

      expect(
        operations,
        [
          'status.ensureInitialized',
          'preferences.upsert.workout.home,workout,progress',
        ],
      );
      expect(statusRepository.status, isNull);
      expect(modePreference.storedMode, isNull);
      expect(remoteRepository.completionState,
          RemoteOnboardingCompletionState.incomplete);
    });

    test('backend completion failure never publishes local completed cache',
        () async {
      final operations = <String>[];
      final modePreference = _FakeAppModePreference(operations);
      final statusRepository = _FakeOnboardingStatusRepository(operations);
      final remoteRepository = _FakeRemoteCompletionAndPreferences(
        operations,
        completionWriteError: StateError('remote completion failed'),
      );
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: modePreference,
        statusRepository: statusRepository,
        completionRepository: remoteRepository,
        validator: _validator,
      );

      await expectLater(
        () => useCase(
          draft: OnboardingDraft(selectedMode: AppMode.workout),
          flowPlan: _workoutFlowPlan,
        ),
        throwsStateError,
      );

      expect(
        operations,
        [
          'status.ensureInitialized',
          'preferences.upsert.workout.home,workout,progress',
          'mode.write.workout',
          'remote.markCompleted',
        ],
      );
      expect(statusRepository.status, isNull);
      expect(modePreference.storedMode, AppMode.workout);
      expect(remoteRepository.preferencesState.appMode, AppMode.workout);
    });

    test('completed retry repairs a missing canonical preference before return',
        () async {
      final operations = <String>[];
      final modePreference = _FakeAppModePreference(
        operations,
        initialMode: AppMode.workout,
      );
      final statusRepository = _FakeOnboardingStatusRepository(
        operations,
        initialStatus: OnboardingStatus.completed,
      );
      final remoteRepository = _FakeRemoteCompletionAndPreferences(
        operations,
        initialCompletionState: RemoteOnboardingCompletionState.completed,
        initialPreferencesState: const AppPreferencesState.missing(),
      );
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: modePreference,
        statusRepository: statusRepository,
        completionRepository: remoteRepository,
        validator: _validator,
      );

      await useCase(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
        flowPlan: _workoutFlowPlan,
      );

      expect(
        operations,
        [
          'preferences.read',
          'status.ensureInitialized',
          'preferences.upsert.workout.home,workout,progress',
          'mode.write.workout',
          'remote.markCompleted',
          'status.write.completed',
        ],
      );
      expect(remoteRepository.preferencesState.isPresent, isTrue);
      expect(remoteRepository.preferencesState.appMode, AppMode.workout);
    });

    test('fully completed canonical retry is idempotent', () async {
      final operations = <String>[];
      final modePreference = _FakeAppModePreference(
        operations,
        initialMode: AppMode.workout,
      );
      final statusRepository = _FakeOnboardingStatusRepository(
        operations,
        initialStatus: OnboardingStatus.completed,
      );
      final remoteRepository = _FakeRemoteCompletionAndPreferences(
        operations,
        initialCompletionState: RemoteOnboardingCompletionState.completed,
        initialPreferencesState: AppPreferencesState.present(
          appMode: AppMode.workout,
          activeTabs: AppMode.workout.guidedDestinations,
        ),
      );
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: modePreference,
        statusRepository: statusRepository,
        completionRepository: remoteRepository,
        validator: _validator,
      );

      await useCase(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
        flowPlan: _workoutFlowPlan,
      );

      expect(operations, ['preferences.read', 'remote.read']);
    });
  });
}

const _validator = OnboardingCompletionValidator(
  hasDurableOwnerPersistence: true,
  backendUserReady: true,
);

final _workoutFlowPlan = const BuildOnboardingFlowUseCase()(
  entryPath: OnboardingEntryPath.firstRun,
  mode: AppMode.workout,
  workoutIntroChoice: null,
);

class _FakeRemoteCompletionAndPreferences
    implements OnboardingCompletionRepository, AppPreferencesRepository {
  _FakeRemoteCompletionAndPreferences(
    this.operations, {
    this.preferencesWriteError,
    this.completionWriteError,
    RemoteOnboardingCompletionState initialCompletionState =
        RemoteOnboardingCompletionState.incomplete,
    AppPreferencesState initialPreferencesState =
        const AppPreferencesState.missing(),
  })  : completionState = initialCompletionState,
        preferencesState = initialPreferencesState;

  final List<String> operations;
  final Object? preferencesWriteError;
  final Object? completionWriteError;
  RemoteOnboardingCompletionState completionState;
  AppPreferencesState preferencesState;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async {
    operations.add('remote.read');
    return completionState;
  }

  @override
  Future<void> markCurrentCompleted() async {
    operations.add('remote.markCompleted');
    if (completionWriteError case final error?) {
      throw error;
    }
    completionState = RemoteOnboardingCompletionState.completed;
  }

  @override
  Future<AppPreferencesState> read() async {
    operations.add('preferences.read');
    return preferencesState;
  }

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    operations.add(
      'preferences.upsert.${preferences.appMode.name}.'
      '${preferences.activeTabs.map((tab) => tab.storageValue).join(',')}',
    );
    if (preferencesWriteError case final error?) {
      throw error;
    }
    preferencesState = AppPreferencesState.present(
      appMode: preferences.appMode,
      activeTabs: preferences.activeTabs,
    );
  }
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference(
    this.operations, {
    this.initialMode,
  }) : storedMode = initialMode;

  final List<String> operations;
  final AppMode? initialMode;
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
  _FakeOnboardingStatusRepository(
    this.operations, {
    OnboardingStatus? initialStatus,
  })  : status = initialStatus,
        hasStoredContractVersion = initialStatus != null;

  final List<String> operations;
  OnboardingStatus? status;
  bool hasStoredContractVersion;

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
