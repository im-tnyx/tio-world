import 'package:flutter/foundation.dart';

/// Read-only, process-local invalidation of owner-scoped Program/Routine lists.
///
/// This is not a Move result, receipt, or another Routine source of truth.
/// In particular, a refresh after an UNKNOWN RPC must never be interpreted
/// as proof that the Move committed. No old-owner event can refresh another
/// login cycle's lists.
final class RoutineMoveRefreshSignal extends ChangeNotifier {
  String? _ownerId;
  String? _loginCycleId;
  bool _programsMayHaveChanged = false;
  int _version = 0;

  int get version => _version;
  bool get programsMayHaveChanged => _programsMayHaveChanged;

  bool matches({
    required String? ownerId,
    required String? loginCycleId,
  }) =>
      _version > 0 &&
      ownerId != null && ownerId.isNotEmpty &&
      loginCycleId != null && loginCycleId.isNotEmpty &&
      _ownerId == ownerId && _loginCycleId == loginCycleId;

  /// Call only after a Move write has been attempted and the *live* app
  /// session still matches the frozen owner and login cycle. The signal
  /// invalidates readers; the server-backed read determines what exists.
  void request({
    required String ownerId,
    required String loginCycleId,
    required bool programsMayHaveChanged,
  }) {
    if (ownerId.isEmpty || loginCycleId.isEmpty) return;
    _ownerId = ownerId;
    _loginCycleId = loginCycleId;
    _programsMayHaveChanged = programsMayHaveChanged;
    _version++;
    notifyListeners();
  }
}
