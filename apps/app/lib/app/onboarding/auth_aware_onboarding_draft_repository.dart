import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

/// Device-local onboarding state kept before an account owns the draft.
///
/// [draft] is the signed-out screen state. [resumeAfterAuth] is a separate
/// checkpoint used only after successful authentication, so an app restart or
/// cancelled sign-in never skips the auth boundary.
class LocalOnboardingDraftRecord {
  const LocalOnboardingDraftRecord({
    required this.draft,
    this.resumeAfterAuth,
    this.boundUserId,
  });

  final OnboardingDraftSnapshot draft;
  final OnboardingDraftSnapshot? resumeAfterAuth;
  final String? boundUserId;

  LocalOnboardingDraftRecord copyWith({
    OnboardingDraftSnapshot? draft,
    OnboardingDraftSnapshot? resumeAfterAuth,
    String? boundUserId,
    bool clearResumeAfterAuth = false,
    bool clearBoundUserId = false,
  }) {
    return LocalOnboardingDraftRecord(
      draft: draft ?? this.draft,
      resumeAfterAuth: clearResumeAfterAuth
          ? null
          : (resumeAfterAuth ?? this.resumeAfterAuth),
      boundUserId:
          clearBoundUserId ? null : (boundUserId ?? this.boundUserId),
    );
  }
}

abstract interface class LocalOnboardingDraftStore {
  Future<LocalOnboardingDraftRecord?> load();

  Future<void> save(LocalOnboardingDraftRecord record);

  Future<void> clear();
}

/// Encrypted device-local storage for the pre-auth onboarding draft.
///
/// The in-memory copy is a safe fallback for tests or a platform storage
/// failure; production persistence still prefers platform secure storage.
class SecureLocalOnboardingDraftStore implements LocalOnboardingDraftStore {
  SecureLocalOnboardingDraftStore({
    FlutterSecureStorage? storage,
    OnboardingDraftSnapshotDtoMapper? mapper,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _mapper = mapper ?? const OnboardingDraftSnapshotDtoMapper();

  static const _storageKey = 'tio.onboarding.pre_auth_draft.v1';

  final FlutterSecureStorage _storage;
  final OnboardingDraftSnapshotDtoMapper _mapper;
  LocalOnboardingDraftRecord? _memoryFallback;

  @override
  Future<LocalOnboardingDraftRecord?> load() async {
    try {
      final encoded = await _storage.read(key: _storageKey);
      if (encoded == null || encoded.isEmpty) return _memoryFallback;

      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        await clear();
        return null;
      }

      final draftJson = decoded['draft'];
      if (draftJson is! Map<String, dynamic>) {
        await clear();
        return null;
      }

      final resumeJson = decoded['resume_after_auth'];
      final boundUserId = decoded['bound_user_id'] as String?;
      final record = LocalOnboardingDraftRecord(
        draft: _mapper.fromJson(draftJson),
        resumeAfterAuth: resumeJson is Map<String, dynamic>
            ? _mapper.fromJson(resumeJson)
            : null,
        boundUserId:
            boundUserId == null || boundUserId.isEmpty ? null : boundUserId,
      );
      _memoryFallback = record;
      return record;
    } catch (_) {
      return _memoryFallback;
    }
  }

  @override
  Future<void> save(LocalOnboardingDraftRecord record) async {
    _memoryFallback = record;
    final encoded = jsonEncode({
      'bound_user_id': record.boundUserId,
      'draft': _mapper.toJson(record.draft),
      'resume_after_auth': record.resumeAfterAuth == null
          ? null
          : _mapper.toJson(record.resumeAfterAuth!),
    });

    try {
      await _storage.write(key: _storageKey, value: encoded);
    } catch (_) {
      // Keep the in-memory copy for the current process if secure storage is
      // temporarily unavailable.
    }
  }

  @override
  Future<void> clear() async {
    _memoryFallback = null;
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {
      // Best effort. The process-local copy is already cleared.
    }
  }
}

/// Routes onboarding draft persistence according to authentication ownership.
///
/// Signed out: local encrypted draft only.
/// Authenticated: durable onboarding completion is checked before any draft is
/// loaded or saved. Completed accounts reject transient onboarding handoff data;
/// incomplete accounts may migrate an eligible local draft once and then clear
/// the local copy.
class AuthAwareOnboardingDraftRepository implements OnboardingDraftRepository {
  AuthAwareOnboardingDraftRepository({
    required LocalOnboardingDraftStore localStore,
    required String? Function() currentUserId,
    OnboardingDraftRepository? remoteRepository,
    OnboardingCompletionRepository? completionRepository,
    Stream<String?>? userIdChanges,
  })  : _localStore = localStore,
        _currentUserId = currentUserId,
        _remoteRepository = remoteRepository,
        _completionRepository = completionRepository {
    _userSubscription = userIdChanges?.listen((userId) {
      if (_completionStateUserId != userId) {
        _invalidateCompletionState();
      }
      if (userId == null || userId.isEmpty) {
        unawaited(_clearBoundDraftAfterSignOut());
      } else {
        unawaited(_bindLocalDraft(userId));
      }
    });
  }

  final LocalOnboardingDraftStore _localStore;
  final String? Function() _currentUserId;
  final OnboardingDraftRepository? _remoteRepository;
  final OnboardingCompletionRepository? _completionRepository;
  StreamSubscription<String?>? _userSubscription;
  String? _completionStateUserId;
  RemoteOnboardingCompletionState? _completionState;

  String? get _authenticatedUserId {
    final userId = _currentUserId();
    return userId == null || userId.isEmpty ? null : userId;
  }

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    final userId = _authenticatedUserId;
    final local = await _localStore.load();

    if (userId == null) {
      if (local?.boundUserId != null) {
        await _localStore.clear();
        return null;
      }
      return local?.draft;
    }

    final completionState = await _readCompletionState(userId);
    if (completionState == RemoteOnboardingCompletionState.completed) {
      await _remoteRepository?.clearDraft();
      await _localStore.clear();
      return null;
    }

    if (local != null) {
      final boundUserId = local.boundUserId;
      if (boundUserId != null && boundUserId != userId) {
        await _localStore.clear();
        return _remoteRepository?.loadDraft();
      }
    }

    final remote = _remoteRepository;
    if (remote != null) {
      final remoteSnapshot = await remote.loadDraft();
      if (remoteSnapshot != null) {
        await _localStore.clear();
        return remoteSnapshot;
      }
    }

    if (local == null) return null;

    final candidate = local.resumeAfterAuth ?? local.draft;
    if (remote != null) {
      await remote.saveDraft(candidate);
      await _localStore.clear();
    } else if (local.boundUserId == null) {
      await _localStore.save(local.copyWith(boundUserId: userId));
    }
    return candidate;
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) async {
    final userId = _authenticatedUserId;
    if (userId == null) {
      final existing = await _localStore.load();
      final unbound = existing?.boundUserId == null ? existing : null;
      await _localStore.save(
        LocalOnboardingDraftRecord(
          draft: snapshot,
          resumeAfterAuth: unbound?.resumeAfterAuth,
        ),
      );
      return;
    }

    final completionState = await _readCompletionState(userId);
    if (completionState == RemoteOnboardingCompletionState.completed) {
      await _remoteRepository?.clearDraft();
      await _localStore.clear();
      return;
    }

    final local = await _localStore.load();
    final canUseLocalResume = local != null &&
        (local.boundUserId == null || local.boundUserId == userId);
    final resume = canUseLocalResume ? local.resumeAfterAuth : null;
    if (resume != null && _wouldRegress(snapshot, resume)) {
      await _bindLocalDraft(userId);
      return;
    }

    final remote = _remoteRepository;
    if (remote != null) {
      await remote.saveDraft(snapshot);
    }
    await _localStore.clear();
  }

  @override
  Future<void> clearDraft() async {
    final userId = _authenticatedUserId;
    if (userId != null) {
      await _remoteRepository?.clearDraft();
    }
    await _localStore.clear();
    _invalidateCompletionState();
  }

  Future<RemoteOnboardingCompletionState?> _readCompletionState(
    String userId,
  ) async {
    final completionRepository = _completionRepository;
    if (completionRepository == null) return null;
    if (_completionStateUserId == userId && _completionState != null) {
      return _completionState;
    }

    final state = await completionRepository.readCurrent();
    _completionStateUserId = userId;
    _completionState = state;
    return state;
  }

  void _invalidateCompletionState() {
    _completionStateUserId = null;
    _completionState = null;
  }

  Future<void> _bindLocalDraft(String userId) async {
    final local = await _localStore.load();
    if (local == null) return;

    final boundUserId = local.boundUserId;
    if (boundUserId == null) {
      await _localStore.save(local.copyWith(boundUserId: userId));
      return;
    }

    if (boundUserId != userId) {
      await _localStore.clear();
    }
  }

  Future<void> _clearBoundDraftAfterSignOut() async {
    final local = await _localStore.load();
    if (local?.boundUserId != null) {
      await _localStore.clear();
    }
  }

  bool _wouldRegress(
    OnboardingDraftSnapshot incoming,
    OnboardingDraftSnapshot resume,
  ) {
    final incomingCompleted = incoming.draft.completedStepIds;
    final resumeCompleted = resume.draft.completedStepIds;
    return resumeCompleted.length > incomingCompleted.length &&
        resumeCompleted.containsAll(incomingCompleted);
  }

  void dispose() {
    unawaited(_userSubscription?.cancel());
    _userSubscription = null;
  }
}
