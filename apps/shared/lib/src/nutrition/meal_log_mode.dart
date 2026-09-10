/// Whether a durable meal log stores manual/coarse nutrition or detailed items.
///
/// This is an explicit domain identity. It must not be inferred from whether
/// detailed items happen to be present, because item presence and the durable
/// logging mode are separate facts.
enum MealLogMode {
  manual('manual'),
  detailed('detailed');

  const MealLogMode(this.storageValue);

  /// Stable storage identity. This value is never coupled to presentation.
  final String storageValue;

  /// Decodes a currently supported storage identity.
  ///
  /// Unknown future identities intentionally remain unknown: callers must not
  /// remap them to an existing mode, and there is deliberately no fallback.
  static MealLogMode? fromStorageValue(String? value) {
    for (final mode in values) {
      if (mode.storageValue == value) return mode;
    }

    return null;
  }
}
