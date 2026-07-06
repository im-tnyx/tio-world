import 'package:flutter/material.dart';

import 'tio_theme_config.dart';
import 'tokens/effects/tio_motion.dart';
import 'tokens/effects/tio_shadows.dart';
import 'tokens/foundation/tio_radius.dart';
import 'tokens/foundation/tio_spacing.dart';
import 'tokens/semantic/tio_colors.dart';
import 'tokens/typography/tio_typography.dart';

class TioTheme extends StatelessWidget {
  const TioTheme({
    super.key,
    this.config = const TioThemeConfig(),
    required this.child,
  });

  final TioThemeConfig config;
  final Widget child;

  static TioColors colors(BuildContext context) {
    return Theme.of(context).extension<TioColors>() ?? TioColors.light;
  }

  static TioShadows shadows(BuildContext context) {
    return Theme.of(context).extension<TioShadows>() ?? TioShadows.standard;
  }

  static TextTheme typography(BuildContext context) {
    return Theme.of(context).textTheme;
  }

  static const spacing = TioThemeSpacingTokens();
  static const radius = TioThemeRadiusTokens();
  static const motion = TioThemeMotionTokens();

  @override
  Widget build(BuildContext context) {
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final colors = _resolveColors(systemBrightness);

    return Theme(
      data: ThemeData(
        useMaterial3: config.useMaterial3,
        colorScheme: colors.toColorScheme(),
        scaffoldBackgroundColor: colors.background,
        textTheme: TioTypography.textTheme(colors),
        cardTheme: CardThemeData(
          color: colors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.surfaceVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.surfaceVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
        extensions: <ThemeExtension<dynamic>>[
          colors,
          TioShadows.standard,
        ],
      ),
      child: child,
    );
  }

  TioColors _resolveColors(Brightness systemBrightness) {
    if (config.mode == TioThemeMode.light) return TioColors.light;
    if (config.mode == TioThemeMode.dark) return TioColors.dark;
    if (config.mode == TioThemeMode.oled) return TioColors.oled;
    return systemBrightness == Brightness.dark ? TioColors.dark : TioColors.light;
  }
}

class TioThemeSpacingTokens {
  const TioThemeSpacingTokens();

  double get small => TioSpacing.small;
  double get medium => TioSpacing.medium;
  double get large => TioSpacing.large;
  double get extraLarge => TioSpacing.extraLarge;
}

class TioThemeRadiusTokens {
  const TioThemeRadiusTokens();

  double get small => TioRadius.small;
  double get medium => TioRadius.medium;
  double get large => TioRadius.large;
  double get extraLarge => TioRadius.extraLarge;
}

class TioThemeMotionTokens {
  const TioThemeMotionTokens();

  int get fastMs => TioMotion.fastMs;
  int get normalMs => TioMotion.normalMs;
  int get slowMs => TioMotion.slowMs;
}
