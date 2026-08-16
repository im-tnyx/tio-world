import 'package:flutter/foundation.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

import '../app_mode/app_mode_controller.dart';

class OnboardingStatusController extends ChangeNotifier {
  OnboardingStatusController({
    required OnboardingStatusRepository repository,
    required AppModeController appModeController,
  })  : _repository = repository,
        _appModeController = appModeController;

  final OnboardingStatusRepository _repository;
  final AppModeController _appModeController;

  OnboardingStatus _status = OnboardingStatus.notStarted;
  OnboardingEntryPath _entryPath = OnboardingEntryPath.firstRun;
  bool _isLoaded = false;
  Object? _lastError;

  OnboardingStatus get status => _status;
  OnboardingEntryPath get entryPath => _entryPath;
  bool get isLoaded => _isLoaded;
  Object? get lastError => _lastError;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final snapshot = await _repository.read();
      final confirmedMode = _appModeController.selectedMode;

      if (snapshot.status != null) {
        _status = snapshot.status!;
        _entryPath = _status == OnboardingStatus.completed &&
                confirmedMode != null &&
                !snapshot.hasStoredContractVersion
            ? OnboardingEntryPath.legacyModeOnly
            : OnboardingEntryPath.firstRun;
      } else if (!snapshot.hasStoredContractVersion && confirmedMode != null) {
        // Compatibility bridge for pre-status installs only. AppMode is not used
        // to downgrade or invalidate an explicitly persisted completion state.
        await _repository.write(OnboardingStatus.completed);
        _status = OnboardingStatus.completed;
        _entryPath = OnboardingEntryPath.legacyModeOnly;
      } else {
        _status = OnboardingStatus.notStarted;
        _entryPath = OnboardingEntryPath.firstRun;
      }
      _lastError = null;
    } catch (error) {
      _status = OnboardingStatus.notStarted;
      _entryPath = OnboardingEntryPath.firstRun;
      _lastError = error;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  void markCompleted() {
    _status = OnboardingStatus.completed;
    _entryPath = OnboardingEntryPath.firstRun;
    _lastError = null;
    notifyListeners();
  }
}
