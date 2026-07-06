enum TioThemeMode {
  system,
  light,
  dark,
  oled,
}

class TioThemeConfig {
  const TioThemeConfig({
    this.mode = TioThemeMode.system,
    this.highContrast = false,
    this.reducedMotion = false,
    this.useMaterial3 = true,
  });

  final TioThemeMode mode;
  final bool highContrast;
  final bool reducedMotion;
  final bool useMaterial3;
}
