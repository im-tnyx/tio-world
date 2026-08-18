abstract final class TioFontFamily {
  /// Leaves family resolution to Flutter/platform defaults.
  static const String? system = null;

  /// Explicit named family already evidenced by production UI.
  ///
  /// This is not bundled by `tio_core`; consumers that require a bundled
  /// custom family must register that family in the owning package pubspec and
  /// add its exact family name here before migration.
  static const String roboto = 'Roboto';
}
