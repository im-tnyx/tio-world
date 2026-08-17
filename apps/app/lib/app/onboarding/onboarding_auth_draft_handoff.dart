import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

import '../network_providers.dart';

/// One-shot, in-memory handoff for the onboarding draft that exists immediately
/// before the signup authentication checkpoint.
///
/// The draft starts unbound while the user is unauthenticated. The next
/// authenticated Supabase identity binds it, and only that same identity may
/// consume it. This keeps an auth-state redirect from losing App Mode/Profile
/// progress without persisting unauthenticated data under the wrong account.
class OnboardingAuthDraftHandoff {
  OnboardingAuthDraftHandoff({SupabaseClient? client}) : _client = client {
    _authSubscription = client?.auth.onAuthStateChange.listen((authState) {
      final userId = authState.session?.user.id;
      if (userId != null && userId.isNotEmpty) {
        bindAuthenticatedUser(userId);
        return;
      }

      if (_boundUserId != null && client?.auth.currentUser == null) {
        clear();
      }
    });
  }

  final SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;

  OnboardingDraft? _pendingDraft;
  String? _boundUserId;

  bool get hasPendingDraft => _pendingDraft != null;

  String? get _currentUserId {
    final userId = _client?.auth.currentUser?.id;
    return userId == null || userId.isEmpty ? null : userId;
  }

  /// Stages a draft only while no Supabase user is authenticated.
  void stage(OnboardingDraft draft) {
    if (_currentUserId != null) return;
    _pendingDraft = draft;
    _boundUserId = null;
  }

  /// Binds an unbound staged draft to the identity selected at the checkpoint.
  ///
  /// A conflicting identity invalidates the handoff rather than leaking the
  /// previous draft across accounts.
  void bindAuthenticatedUser(String userId) {
    if (_pendingDraft == null || userId.isEmpty) return;

    final boundUserId = _boundUserId;
    if (boundUserId == null) {
      _boundUserId = userId;
      return;
    }

    if (boundUserId != userId) {
      clear();
    }
  }

  /// Consumes the staged draft exactly once for the matching authenticated user.
  ///
  /// A null user never consumes an unbound draft. This prevents a later logged
  /// out onboarding attempt from inheriting a prior authenticated handoff.
  OnboardingDraft? takeForUser(String? userId) {
    final pendingDraft = _pendingDraft;
    if (pendingDraft == null) return null;

    if (userId == null || userId.isEmpty) {
      if (_boundUserId != null) clear();
      return null;
    }

    bindAuthenticatedUser(userId);
    if (_boundUserId != userId) return null;

    final result = _pendingDraft;
    clear();
    return result;
  }

  /// Clears a cancelled/failed pre-auth attempt, but preserves a handoff if a
  /// Supabase session was actually established and navigation raced the result.
  void clearIfUnauthenticated() {
    if (_currentUserId == null) clear();
  }

  void clear() {
    _pendingDraft = null;
    _boundUserId = null;
  }

  void dispose() {
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    clear();
  }
}

final onboardingAuthDraftHandoffProvider =
    Provider<OnboardingAuthDraftHandoff>((ref) {
  final handoff = OnboardingAuthDraftHandoff(
    client: ref.watch(supabaseClientProvider),
  );
  ref.onDispose(handoff.dispose);
  return handoff;
});

/// App-owned controller wrapper that stages the exact post-profile resume draft
/// before the signup auth route is opened.
class AppOnboardingController extends OnboardingController {
  AppOnboardingController({
    required OnboardingEntryPath entryPath,
    required OnboardingAuthDraftHandoff authDraftHandoff,
    OnboardingDraft? initialDraft,
    bool includeMobile = false,
    OnboardingStatusRepository statusRepository =
        const NoOpOnboardingStatusRepository(),
    OnboardingDraftRepository? draftRepository,
    OnboardingCompletionValidator completionValidator =
        const OnboardingCompletionValidator(),
  })  : _authDraftHandoff = authDraftHandoff,
        super(
          entryPath: entryPath,
          initialDraft: initialDraft,
          includeMobile: includeMobile,
          statusRepository: statusRepository,
          draftRepository: draftRepository,
          completionValidator: completionValidator,
        );

  final OnboardingAuthDraftHandoff _authDraftHandoff;

  @override
  Future<void> next({
    required Future<void> Function(OnboardingDraft draft) onFinish,
    Future<bool> Function()? onAuthRequired,
  }) {
    final originalOnAuthRequired = onAuthRequired;
    return super.next(
      onFinish: onFinish,
      onAuthRequired: originalOnAuthRequired == null
          ? null
          : () async {
              _authDraftHandoff.stage(_buildResumeAfterAuthDraft());
              try {
                final authenticated = await originalOnAuthRequired();
                if (!authenticated) {
                  _authDraftHandoff.clearIfUnauthenticated();
                }
                return authenticated;
              } catch (_) {
                _authDraftHandoff.clearIfUnauthenticated();
                rethrow;
              }
            },
    );
  }

  OnboardingDraft _buildResumeAfterAuthDraft() {
    final currentState = state;
    if (currentState.currentIndex >= currentState.flowPlan.stepCount - 1) {
      return currentState.draft;
    }

    final nextStepId =
        currentState.flowPlan.steps[currentState.currentIndex + 1].id;
    return currentState.draft.copyWith(
      currentStepId: nextStepId,
      completedStepIds: {
        ...currentState.completedStepIds,
        currentState.stepId,
      },
    );
  }
}
