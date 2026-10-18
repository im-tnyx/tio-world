import 'package:tio_shared/shared.dart';

/// Process-local arbitration between Routine Move (both variants) and Delete.
///
/// This gate is shared across adapter recreations, routes and login cycles.
/// It does not replace server-side owner/RLS and revision-CAS checks. UNKNOWN
/// writes stay blocked until an authenticated owner read proves the old CAS
/// revision cannot still commit. An absent or same-revision read is not proof.
final class RoutineMoveDeleteAttemptGate {
  final Set<String> _inFlight = {};
  final Map<String, int> _unknownRevisions = {};
  final Map<String, int> _generations = {};

  static String _key(String owner, RoutineId routineId) =>
      '$owner/${routineId.value}';

  int generation(String owner, RoutineId routineId) =>
      _generations[_key(owner, routineId)] ?? 0;

  bool inFlight(String owner, RoutineId routineId) =>
      _inFlight.contains(_key(owner, routineId));

  bool uncertain(String owner, RoutineId routineId) =>
      _unknownRevisions.containsKey(_key(owner, routineId));

  /// Only a verified owner read of a later revision retires the old CAS.
  void observeRevision(String owner, RoutineId routineId, int revision) {
    final key = _key(owner, routineId);
    final blocked = _unknownRevisions[key];
    if (blocked != null && revision > blocked) {
      _unknownRevisions.remove(key);
      _generations[key] = (_generations[key] ?? 0) + 1;
    }
  }

  /// Reserve synchronously before an RPC; prevents cross-adapter overlap.
  bool tryStart(String owner, RoutineId routineId) {
    final key = _key(owner, routineId);
    if (_inFlight.contains(key) || _unknownRevisions.containsKey(key)) {
      return false;
    }
    _inFlight.add(key);
    _generations[key] = (_generations[key] ?? 0) + 1;
    return true;
  }

  void markUncertain(String owner, RoutineId routineId, int revision) {
    final key = _key(owner, routineId);
    if (_inFlight.contains(key)) _unknownRevisions[key] = revision;
  }

  void finish(String owner, RoutineId routineId) {
    _inFlight.remove(_key(owner, routineId));
  }
}
