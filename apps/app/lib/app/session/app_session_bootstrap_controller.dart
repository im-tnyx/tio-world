import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

import '../onboarding/onboarding_status_controller.dart';
import 'app_session_bootstrap_state.dart';

class AppSessionBootstrapController extends ChangeNotifier {
  AppSessionBootstrapController({
    required AuthSessionRepository authSessionRepository,
    required OnboardingCompletionRepository? onboardingCompletionRepository,
    required OnboardingStatusController onboardingStatusController,
  })  : _authSessionRepository = authSessionRepository,
        _onboardingCompletionRepository = onboardingCompletionRepository,
        _onboardingStatusController = onboardingStatusController;

  final AuthSessionRepository _authSessionRepository;
  final OnboardingCompletionRepository? _onboardingCompletionRepository;
  final OnboardingStatusController _onboardingStatusController;

  AppSessionBootstrapState _state = const AppSessionBootstrapLoading();
  StreamSubscription<AuthSessionState>? _authSubscription;
  int _resolutionGeneration = 0;
  bool _started = false;

  AppSessionBootstrapState get state => _state;

  void start() {
    if (_started) return;
    _started = true;
    _authSubscription = _authSessionRepository.sessionState.listen(
      (authState) => unawaited(_resolve(authState)),
      onError: (Object error, StackTrace _) {
        _resolutionGeneration++;
        _setState(AppSessionBootstrapFailure(error));
      },
    );
  }

  Future<void> refresh({bool emitLoading = true}) async {
    final authState = await _authSessionRepository.currentSessionState;
    await _resolve(authState, emitLoading: emitLoading);
  }

  /// Accepts the already-verified result of a successful onboarding completion.
  ///
  /// The completion use case has already persisted owner data and published the
  /// durable backend completion marker before this is called. Advancing the
  /// bootstrap state locally avoids a redundant backend read and lets the fresh
  /// completion flow show Congratulations before entering Home.
  void markReadyAfterOnboardingCompletion(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
    _resolutionGeneration++;
    _setState(AppSessionBootstrapReady(userId: userId));
  }

  Future<void> _resolve(
    AuthSessionState authState, {
    bool emitLoading = true,
  }) async {
    final generation = ++_resolutionGeneration;

    switch (authState) {
      case AuthSessionUnknown():
        _setState(const AppSessionBootstrapLoading());
        break;
      case AuthSessionUnauthenticated():
        _setState(const AppSessionBootstrapUnauthenticated());
        break;
      case AuthSessionAuthenticated(:final session):
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
          final remoteState = await completionRepository.readCurrent();
          if (generation != _resolutionGeneration) return;

          await _onboardingStatusController.reconcileRemote(remoteState);
          if (generation != _resolutionGeneration) return;

          switch (remoteState) {
            case RemoteOnboardingCompletionState.completed:
              _setState(AppSessionBootstrapReady(userId: session.userId));
              break;
            case RemoteOnboardingCompletionState.uninitialized:
            case RemoteOnboardingCompletionState.incomplete:
              _setState(
                AppSessionBootstrapRequiresOnboarding(userId: session.userId),
              );
              break;
          }
        } catch (error) {
          if (generation != _resolutionGeneration) return;
          _setState(AppSessionBootstrapFailure(error));
        }
        break;
    }
  }

  void _setState(AppSessionBootstrapState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
