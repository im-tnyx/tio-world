import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_shared/shared.dart';

import '../app_mode/app_mode_controller.dart';
import '../onboarding/onboarding_status_controller.dart';
import 'app_session_bootstrap_state.dart';

class AppSessionBootstrapController extends ChangeNotifier {
  AppSessionBootstrapController({
    required AuthSessionRepository authSessionRepository,
    required OnboardingCompletionRepository? onboardingCompletionRepository,
    required OnboardingStatusController onboardingStatusController,
    AccountSetupRepository? accountSetupRepository,
    ProfileAccountRepository? profileAccountRepository,
    OnboardingDraftRepository? onboardingDraftRepository,
    AppPreferencesRepository? appPreferencesRepository,
    AppModeController? appModeController,
    Duration completionLookupTimeout = const Duration(seconds: 8),
  })  : _authSessionRepository = authSessionRepository,
        _onboardingCompletionRepository = onboardingCompletionRepository,
        _onboardingStatusController = onboardingStatusController,
        _accountSetupRepository = accountSetupRepository,
        _profileAccountRepository = profileAccountRepository,
        _onboardingDraftRepository = onboardingDraftRepository,
        _appPreferencesRepository = appPreferencesRepository,
        _appModeController = appModeController,
        _completionLookupTimeout = completionLookupTimeout;

  final AuthSessionRepository _authSessionRepository;
  final OnboardingCompletionRepository? _onboardingCompletionRepository;
  final OnboardingStatusController _onboardingStatusController;
  final AccountSetupRepository? _accountSetupRepository;
  final ProfileAccountRepository? _profileAccountRepository;
  final OnboardingDraftRepository? _onboardingDraftRepository;
  final AppPreferencesRepository? _appPreferencesRepository;
  final AppModeController? _appModeController;
  final Duration _completionLookupTimeout;

  AppSessionBootstrapState _state = const AppSessionBootstrapLoading();
  StreamSubscription<AuthSessionState>? _authSubscription;
  int _resolutionGeneration = 0;
  bool _started = false;
  bool _disposed = false;
  String? _activeAuthenticatedUserId;

  AppSessionBootstrapState get state => _state;

  void start() {
    if (_disposed || _started) return;
    _started = true;
    _debug('start');
    _authSubscription = _authSessionRepository.sessionState.listen(
      (authState) {
        _debug('auth event: ${authState.runtimeType}');
        unawaited(_resolve(authState));
      },
      onError: (Object error, StackTrace _) {
        if (_disposed) return;
        _resolutionGeneration++;
        _debug('auth stream error: ${error.runtimeType}');
        _setState(AppSessionBootstrapFailure(error));
      },
    );
  }

  Future<void> refresh({bool emitLoading = true}) async {
    if (_disposed) return;
    _debug('refresh requested');
    final authState = await _authSessionRepository.currentSessionState;
    if (_disposed) return;
    _debug('refresh auth state: ${authState.runtimeType}');
    await _resolve(authState, emitLoading: emitLoading, force: true);
  }

  /// Accepts the already-verified result of a successful onboarding completion.
  void markReadyAfterOnboardingCompletion(String userId) {
    if (_disposed) return;
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
    _activeAuthenticatedUserId = userId;
    _resolutionGeneration++;
    _debug('mark ready after onboarding completion');
    _setState(AppSessionBootstrapReady(userId: userId));
  }

  Future<void> _resolve(
    AuthSessionState authState, {
    bool emitLoading = true,
    bool force = false,
  }) async {
    if (_disposed) return;

    if (!force &&
        authState is AuthSessionAuthenticated &&
        _activeAuthenticatedUserId == authState.session.userId &&
        (_state is AppSessionBootstrapLoading ||
            _state is AppSessionBootstrapReady ||
            _state is AppSessionBootstrapRequiresAccountSetup ||
            _state is AppSessionBootstrapRequiresOnboarding)) {
      _debug('duplicate authenticated event ignored for active user');
      return;
    }

    final generation = ++_resolutionGeneration;
    _debug('resolve generation=$generation state=${authState.runtimeType}');

    switch (authState) {
      case AuthSessionUnknown():
        _setState(const AppSessionBootstrapLoading());
        break;
      case AuthSessionUnauthenticated():
        _activeAuthenticatedUserId = null;
        _setState(const AppSessionBootstrapUnauthenticated());
        break;
      case AuthSessionAuthenticated(:final session):
        _activeAuthenticatedUserId = session.userId;
        if (emitLoading) {
          _setState(const AppSessionBootstrapLoading());
        }
        final completionRepository = _onboardingCompletionRepository;
        if (completionRepository == null) {
          _setState(
            AppSessionBootstrapFailure(
              StateError('Durable onboarding completion repository unavailable.'),
            ),
          );
          break;
        }

        try {
          _debug('completion lookup started generation=$generation');
          final remoteState = await completionRepository
              .readCurrent()
              .timeout(_completionLookupTimeout);
          if (_disposed || generation != _resolutionGeneration) return;

          await _onboardingStatusController.reconcileRemote(remoteState);
          if (_disposed || generation != _resolutionGeneration) return;

          switch (remoteState) {
            case RemoteOnboardingCompletionState.completed:
              await _restoreAuthenticatedAppPreferences(generation);
              if (_disposed || generation != _resolutionGeneration) return;

              // Legacy completed accounts remain ready even if their historical
              // profile predates the Account Setup completion marker.
              _setState(AppSessionBootstrapReady(userId: session.userId));
              unawaited(_clearObsoleteDraft());
              break;
            case RemoteOnboardingCompletionState.uninitialized:
            case RemoteOnboardingCompletionState.incomplete:
              final accountSetupRepository = _accountSetupRepository;
              if (accountSetupRepository != null) {
                final accountState = await accountSetupRepository
                    .readAccountSetupState()
                    .timeout(_completionLookupTimeout);
                if (_disposed || generation != _resolutionGeneration) return;

                if (!accountState.hasUsername || !accountState.isCompleted) {
                  _setState(
                    AppSessionBootstrapRequiresAccountSetup(
                      userId: session.userId,
                    ),
                  );
                  break;
                }

                _setState(
                  AppSessionBootstrapRequiresOnboarding(
                    userId: session.userId,
                  ),
                );
                break;
              }

              // Compatibility fallback for non-Supabase/test environments that
              // do not yet expose the narrow AccountSetupRepository capability.
              final accountRepository = _profileAccountRepository;
              if (accountRepository != null) {
                final username = await accountRepository
                    .currentUsername()
                    .timeout(_completionLookupTimeout);
                if (_disposed || generation != _resolutionGeneration) return;
                if (username == null || username.trim().isEmpty) {
                  _setState(
                    AppSessionBootstrapRequiresAccountSetup(
                      userId: session.userId,
                    ),
                  );
                  break;
                }
              }
              _setState(
                AppSessionBootstrapRequiresOnboarding(userId: session.userId),
              );
              break;
          }
        } catch (error) {
          if (_disposed || generation != _resolutionGeneration) return;
          _debug('bootstrap lookup failed: ${error.runtimeType}');
          _setState(AppSessionBootstrapFailure(error));
        }
        break;
    }
  }

  Future<void> _restoreAuthenticatedAppPreferences(int generation) async {
    final repository = _appPreferencesRepository;
    final modeController = _appModeController;

    // Non-Supabase/test compositions may intentionally omit this capability.
    // Production injects both dependencies. Do not invent remote semantics when
    // the backend-neutral owner is unavailable.
    if (repository == null || modeController == null) {
      _debug('canonical app preferences restore unavailable in composition');
      return;
    }

    _debug('app preferences lookup started generation=$generation');
    final preferences =
        await repository.read().timeout(_completionLookupTimeout);
    if (_disposed || generation != _resolutionGeneration) return;

    if (preferences.isMissing) {
      _debug('canonical app preferences missing; using compatibility state');
      await modeController.restoreMissingCanonical();
      return;
    }

    await modeController.restoreCanonical(preferences);
  }

  Future<void> _clearObsoleteDraft() async {
    final repository = _onboardingDraftRepository;
    if (repository == null) return;
    try {
      await repository.clearDraft();
      _debug('cleared obsolete completed-account draft');
    } catch (error) {
      _debug('obsolete draft cleanup failed: ${error.runtimeType}');
    }
  }

  void _setState(AppSessionBootstrapState next) {
    if (_disposed || _state == next) return;
    _debug('state: ${_state.runtimeType} -> ${next.runtimeType}');
    _state = next;
    notifyListeners();
  }

  void _debug(String message) {
    assert(() {
      debugPrint('[SessionBootstrap] $message');
      return true;
    }());
  }

  @override
  void dispose() {
    if (_disposed) return;
    _debug('dispose');
    _disposed = true;
    _resolutionGeneration++;
    _authSubscription?.cancel();
    super.dispose();
  }
}
