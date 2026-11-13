/// Presentation-only, one-shot eligibility gate for a naturally expired rest.
///
/// A positive remaining duration must first be observed while foregrounded.
/// A new rest snapshots the setting once its initial read is known; enabling
/// during an already resolved running rest only applies to a later rest. Disabling before expiry always suppresses feedback.
/// Neither a cancelled nor a restored already-expired rest can notify.
final class RestTimerCompletionGate {
  String? _currentRestId;
  bool _foreground = true;
  bool _enabledAtStart = false;
  bool _initialPreferenceResolved = false;
  bool _armed = false;
  bool _completed = false;

  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!foreground) _armed = false;
  }

  void observeRest({
    required String? restId,
    required bool remainingPositive,
    required bool vibrationEnabled,
    bool preferenceReady = true,
  }) {
    if (restId != _currentRestId) {
      _currentRestId = restId;
      _initialPreferenceResolved = preferenceReady;
      _enabledAtStart = preferenceReady && vibrationEnabled;
      _armed = false;
      _completed = false;
    }
    // A restored or newly started rest may be observed before the local
    // preference finishes its initial read. Resolve eligibility when known,
    // but only while that rest is still genuinely counting down.
    if (restId != null &&
        remainingPositive &&
        !_initialPreferenceResolved &&
        preferenceReady) {
      _initialPreferenceResolved = true;
      _enabledAtStart = vibrationEnabled;
    }
    if (restId != null &&
        remainingPositive &&
        _foreground &&
        _enabledAtStart &&
        !_completed) {
      _armed = true;
    }
  }

  /// Consumes the completion even if feedback is disabled or the app is hidden.
  bool complete(String restId, {required bool vibrationEnabled}) {
    if (restId != _currentRestId || _completed) return false;
    _completed = true;
    final shouldNotify =
        _armed && _foreground && _enabledAtStart && vibrationEnabled;
    _armed = false;
    return shouldNotify;
  }
}
