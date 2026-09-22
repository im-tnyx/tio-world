import 'tokens/typography/tio_font_family_option.dart';

/// The four user-facing appearance modes.
///
/// Mode names are product semantics; the `TioColors`/`TioShadows` constants
/// they resolve to are internal palette identities (see the theme README).
enum TioThemeMode {
  /// Follows the OS: light resolves [light], dark resolves [dark].
  system,

  /// The Light palette (`TioColors.light`).
  light,

  /// The standard pure-black dark palette (`TioColors.oled`).
  dark,

  /// Tio's navy/slate dark palette (`TioColors.dark`).
  tioDark,
}

class TioThemeConfig {
  const TioThemeConfig({
    this.mode = TioThemeMode.system,
    this.fontFamilyOption = TioFontFamilyOption.system,
    this.highContrast = false,
    this.reducedMotion = false,
    this.useMaterial3 = true,
  });

  final TioThemeMode mode;
  final TioFontFamilyOption fontFamilyOption;
  final bool highContrast;
  final bool reducedMotion;
  final bool useMaterial3;

  String? get resolvedFontFamily => fontFamilyOption.family;
}
