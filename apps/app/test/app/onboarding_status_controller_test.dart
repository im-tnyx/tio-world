import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('OnboardingStatusController', () {
    test('fresh install stays notStarted and enters firstRun', () async {
      final repository = _FakeOnboardingStatusRepository();
      final appModeController =
          await _loadAppModeController(_FakeAppModePreference());
      final controller = OnboardingStatusController(
        repository: repository,
        appModeController: appModeController,
      );

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.status, OnboardingStatus.notStarted);
      expect(controller.entryPath, OnboardingEntryPath.firstRun);
      expect(controller.lastError, isNull);
      expect(repository.writeCalls, 0);
    });

    test('legacy confirmed mode migrates once to explicit completed status',
        () async {
      final repository = _FakeOnboardingStatusRepository(
        status: null,
        hasStoredContractVersion: false,
      );
      final appModeController = await _loadAppModeController(
        _FakeAppModePreference(initialMode: AppMode.hybrid),
      );
      final controller = OnboardingStatusController(
        repository: repository,
        appModeController: appModeController,
      );

      await controller.load();

      expect(controller.status, OnboardingStatus.completed);
      expect(controller.entryPath, OnboardingEntryPath.legacyModeOnly);
      expect(repository.status, OnboardingStatus.completed);
      expect(repository.hasStoredContractVersion, isTrue);
      expect(repository.writeCalls, 1);

      await controller.load();
      expect(repository.writeCalls, 1);
    });

    test('invalid completed state without confirmed mode fails safe', () async {
      final repository = _FakeOnboardingStatusRepository(
        status: OnboardingStatus.completed,
        hasStoredContractVersion: true,
      );
      final appModeController =
          await _loadAppModeController(_FakeAppModePreference());
      final controller = OnboardingStatusController(
        repository: repository,
        appModeController: appModeController,
      );

      await controller.load();

      expect(controller.status, OnboardingStatus.notStarted);
      expect(controller.entryPath, OnboardingEntryPath.firstRun);
      expect(repository.status, OnboardingStatus.notStarted);
      expect(repository.writeCalls, 1);
    });

    test('existing inProgress state preserves onboarding gate', () async {
      final repository = _FakeOnboardingStatusRepository(
        status: OnboardingStatus.inProgress,
        hasStoredContractVersion: true,
      );
      final appModeController =
          await _loadAppModeController(_FakeAppModePreference());
      final controller = OnboardingStatusController(
        repository: repository,
        appModeController: appModeController,
      );

      await controller.load();

      expect(controller.status, OnboardingStatus.inProgress);
      expect(controller.entryPath, OnboardingEntryPath.firstRun);
      expect(repository.writeCalls, 0);
    });

    test('repository failure falls back safely and keeps the error visible',
        () async {
      final repository = _ThrowingOnboardingStatusRepository();
      final appModeController =
          await _loadAppModeController(_FakeAppModePreference());
      final controller = OnboardingStatusController(
        repository: repository,
        appModeController: appModeController,
      );

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.status, OnboardingStatus.notStarted);
      expect(controller.entryPath, OnboardingEntryPath.firstRun);
      expect(controller.lastError, isA<StateError>());
    });

    test('markCompleted updates in-memory completion state', () async {
      final repository = _FakeOnboardingStatusRepository();
      final appModeController = await _loadAppModeController(
        _FakeAppModePreference(initialMode: AppMode.workout),
      );
      final controller = OnboardingStatusController(
        repository: repository,
        appModeController: appModeController,
      );

      await controller.load();
      controller.markCompleted();

      expect(controller.status, OnboardingStatus.completed);
      expect(controller.entryPath, OnboardingEntryPath.firstRun);
      expect(controller.lastError, isNull);
    });
  });
}

Future<AppModeController> _loadAppModeController(
  AppModePreference preference,
) async {
  final controller = AppModeController(preference);
  await controller.load();
  return controller;
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference({this.initialMode});

  final AppMode? initialMode;
  AppMode? _mode;

  @override
  Future<void> clear() async {
    _mode = null;
  }

  @override
  Future<AppMode?> read() async => _mode ?? initialMode;

  @override
  Future<void> write(AppMode mode) async {
    _mode = mode;
  }
}

class _FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  _FakeOnboardingStatusRepository({
    this.status,
    this.hasStoredContractVersion = false,
  });

  OnboardingStatus? status;
  bool hasStoredContractVersion;
  int writeCalls = 0;

  @override
  Future<void> clear() async {
    status = null;
    hasStoredContractVersion = false;
  }

  @override
  Future<void> ensureInitialized() async {
    hasStoredContractVersion = true;
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
    writeCalls++;
    await ensureInitialized();
    this.status = status;
  }
}

class _ThrowingOnboardingStatusRepository
    implements OnboardingStatusRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<OnboardingStatusSnapshot> read() async {
    throw StateError('read failed');
  }

  @override
  Future<void> write(OnboardingStatus status) async {}
}
