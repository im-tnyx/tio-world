import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tio_feature_workout/workout.dart';

/// Narrow encrypted key/value seam for deterministic failure and recovery tests.
abstract interface class WorkoutDraftSecureValues {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

final class FlutterWorkoutDraftSecureValues
    implements WorkoutDraftSecureValues {
  FlutterWorkoutDraftSecureValues({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Two encrypted slots and a commit pointer retain the last complete draft if
/// a write is interrupted. A missing key, corrupt payload or failed write is
/// surfaced; none is silently converted into an empty workout.
final class SecureActiveWorkoutDraftStore implements ActiveWorkoutDraftStore {
  SecureActiveWorkoutDraftStore({
    required String? Function() currentUserId,
    WorkoutDraftSecureValues? values,
  })  : _currentUserId = currentUserId,
        _values = values ?? FlutterWorkoutDraftSecureValues();

  final String? Function() _currentUserId;
  final WorkoutDraftSecureValues _values;
  Future<void> _tail = Future<void>.value();

  String _owner() {
    final id = _currentUserId();
    if (id == null || id.isEmpty) {
      throw StateError('Workout draft requires an authenticated owner.');
    }
    return id;
  }

  void _assertOwner(String owner) {
    if (_currentUserId() != owner) {
      throw StateError('Workout draft owner changed during operation.');
    }
  }

  String _key(String owner, String suffix) =>
      'active_workout_draft_v1.$owner.$suffix';

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  @override
  Future<ActiveWorkoutDraft?> load() => _serial(() async {
        final owner = _owner();
        final pointer = await _values.read(_key(owner, 'pointer'));
        if (pointer == 'deleted') {
          _assertOwner(owner);
          return null;
        }
        if (pointer == null) {
          // An interrupted first save may have written exactly one encrypted
          // slot before the commit pointer landed. Promote that sole slot so
          // restart/retry can continue the same owner-bound draft.
          final a = await _values.read(_key(owner, 'a'));
          final b = await _values.read(_key(owner, 'b'));
          if (a != null && b != null) {
            throw const FormatException('Ambiguous uncommitted workout draft.');
          }
          final raw = a ?? b;
          if (raw == null) {
            _assertOwner(owner);
            return null;
          }
          final Object? decoded;
          try {
            decoded = jsonDecode(raw);
          } catch (_) {
            throw const FormatException('Uncommitted workout draft is corrupt.');
          }
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('Uncommitted workout draft is corrupt.');
          }
          final draft = ActiveWorkoutDraft.fromJson(decoded);
          if (draft.ownerId != owner) {
            throw const FormatException('Workout draft owner mismatch.');
          }
          final slot = a != null ? 'a' : 'b';
          final pointerKey = _key(owner, 'pointer');
          _assertOwner(owner);
          await _values.write(pointerKey, slot);
          if (await _values.read(pointerKey) != slot) {
            throw StateError('Workout draft commit recovery failed.');
          }
          _assertOwner(owner);
          return draft;
        }
        if (pointer != 'a' && pointer != 'b') {
          throw const FormatException('Invalid workout draft commit pointer.');
        }
        final raw = await _values.read(_key(owner, pointer));
        if (raw == null) {
          throw const FormatException(
              'Committed workout draft is unavailable.');
        }
        final Object? decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (_) {
          throw const FormatException('Committed workout draft is corrupt.');
        }
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Committed workout draft is corrupt.');
        }
        final draft = ActiveWorkoutDraft.fromJson(decoded);
        if (draft.ownerId != owner) {
          throw const FormatException('Workout draft owner mismatch.');
        }
        _assertOwner(owner);
        return draft;
      });

  @override
  Future<void> save(ActiveWorkoutDraft draft) => _serial(() async {
        final owner = _owner();
        if (draft.ownerId != owner) {
          throw StateError('Workout draft owner mismatch.');
        }
        final pointerKey = _key(owner, 'pointer');
        final pointer = await _values.read(pointerKey);
        final encoded = jsonEncode(draft.toJson());
        if (pointer != null &&
            pointer != 'a' &&
            pointer != 'b' &&
            pointer != 'deleted') {
          throw const FormatException('Invalid workout draft commit pointer.');
        }
        if (pointer == null) {
          final a = await _values.read(_key(owner, 'a'));
          final b = await _values.read(_key(owner, 'b'));
          if (b != null || (a != null && a != encoded)) {
            throw const FormatException('Uncommitted workout draft exists.');
          }
        }
        if (pointer == 'a' || pointer == 'b') {
          final currentRaw = await _values.read(_key(owner, pointer!));
          if (currentRaw == null) {
            throw const FormatException(
                'Committed workout draft is unavailable.');
          }
          final current = ActiveWorkoutDraft.fromJson(
            Map<String, dynamic>.from(jsonDecode(currentRaw) as Map),
          );
          if (current.ownerId != owner ||
              current.id != draft.id ||
              current.saveRequestId != draft.saveRequestId) {
            throw StateError('Workout draft identity or revision conflict.');
          }
          if (draft.revision == current.revision && currentRaw == encoded) {
            _assertOwner(owner);
            return;
          }
          if (draft.revision <= current.revision) {
            throw StateError('Workout draft revision conflict.');
          }
        }
        _assertOwner(owner);
        final target = pointer == 'a' ? 'b' : 'a';
        await _values.write(_key(owner, target), encoded);
        if (await _values.read(_key(owner, target)) != encoded) {
          throw StateError('Workout draft write verification failed.');
        }
        _assertOwner(owner);
        await _values.write(pointerKey, target);
        if (await _values.read(pointerKey) != target) {
          throw StateError('Workout draft commit verification failed.');
        }
      });

  @override
  Future<void> delete() => _serial(() async {
        final owner = _owner();
        final pointerKey = _key(owner, 'pointer');
        _assertOwner(owner);
        await _values.write(pointerKey, 'deleted');
        if (await _values.read(pointerKey) != 'deleted') {
          throw StateError('Workout draft discard verification failed.');
        }
        // The verified tombstone is the logical discard commit. A secure
        // storage slot cleanup failure must not report discard failure after
        // the draft is already hidden across restarts. Residual slots remain
        // encrypted and owner-scoped, and later saves overwrite them.
        for (final slot in ['a', 'b']) {
          try {
            await _values.delete(_key(owner, slot));
          } catch (_) {
            // Best-effort physical cleanup after the logical commit.
          }
        }
      });
}
