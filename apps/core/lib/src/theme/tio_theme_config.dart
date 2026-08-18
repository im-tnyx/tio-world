import 'tokens/typography/tio_font_family_option.dart';

enum TioThemeMode {
  system,
  light,
  dark,
  oled,
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
