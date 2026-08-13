import 'package:flutter/material.dart';

import 'tio_theme_config.dart';
import 'tokens/effects/tio_motion.dart';
import 'tokens/effects/tio_motion_scheme.dart';
import 'tokens/effects/tio_shadows.dart';
import 'tokens/foundation/tio_radius.dart';
import 'tokens/foundation/tio_spacing.dart';
import 'tokens/semantic/tio_colors.dart';
import 'tokens/components/tio_button_tokens.dart';
import 'tokens/components/tio_navigation_tokens.dart';
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
    final mediaQuery = MediaQuery.maybeOf(context);
    final highContrast =
        config.highContrast || (mediaQuery?.highContrast ?? false);
    final reducedMotion =
        config.reducedMotion || (mediaQuery?.disableAnimations ?? false);
    final colors = _resolveColors(systemBrightness, highContrast: highContrast);
    final motion = reducedMotion
        ? const TioMotionScheme.reduced()
        : const TioMotionScheme.standard();

    Widget themedChild = child;
    if (config.reducedMotion &&
        mediaQuery != null &&
        !mediaQuery.disableAnimations) {
      themedChild = MediaQuery(
        data: mediaQuery.copyWith(disableAnimations: true),
        child: themedChild,
      );
    }

    return Theme(
      data: ThemeData(
        useMaterial3: config.useMaterial3,
        colorScheme: colors.toColorScheme(),
        scaffoldBackgroundColor: colors.background,
        textTheme: TioTypography.textTheme(colors),
        pageTransitionsTheme: reducedMotion
            ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: _NoTransitionsBuilder(),
                  TargetPlatform.fuchsia: _NoTransitionsBuilder(),
                  TargetPlatform.iOS: _NoTransitionsBuilder(),
                  TargetPlatform.linux: _NoTransitionsBuilder(),
                  TargetPlatform.macOS: _NoTransitionsBuilder(),
                  TargetPlatform.windows: _NoTransitionsBuilder(),
                },
              )
            : const PageTransitionsTheme(),
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
            borderSide: BorderSide(color: colors.outlineStrong),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.outlineStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(
              TioButtonTokens.minimumWidth,
              TioButtonTokens.height,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TioButtonTokens.horizontalPadding,
            ),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            disabledBackgroundColor: colors.primary.withValues(
              alpha: TioButtonTokens.disabledContainerOpacity,
            ),
            disabledForegroundColor: colors.textPrimary.withValues(
              alpha: TioButtonTokens.disabledContentOpacity,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TioButtonTokens.radius),
            ),
          ).copyWith(overlayColor: _buttonStateLayer(colors.onPrimary)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(
              TioButtonTokens.minimumWidth,
              TioButtonTokens.height,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TioButtonTokens.horizontalPadding,
            ),
            foregroundColor: colors.primary,
            disabledForegroundColor: colors.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TioButtonTokens.radius),
            ),
          ).copyWith(
            overlayColor: _buttonStateLayer(colors.primary),
            side: _outlinedButtonSide(colors),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(
              TioButtonTokens.minimumWidth,
              TioButtonTokens.height,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TioButtonTokens.horizontalPadding,
            ),
            foregroundColor: colors.primary,
            disabledForegroundColor: colors.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TioButtonTokens.radius),
            ),
          ).copyWith(overlayColor: _buttonStateLayer(colors.primary)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: TioNavigationTokens.bottomBarHeight,
          elevation: TioNavigationTokens.elevation,
          backgroundColor: colors.surface,
          indicatorColor: colors.primary.withValues(
            alpha: TioNavigationTokens.indicatorOpacity,
          ),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              TioNavigationTokens.itemRadius,
            ),
          ),
        ),
        extensions: <ThemeExtension<dynamic>>[
          colors,
          TioShadows.standard,
          motion,
        ],
      ),
      child: themedChild,
    );
  }

  TioColors _resolveColors(
    Brightness systemBrightness, {
    required bool highContrast,
  }) {
    final colors = switch (config.mode) {
      TioThemeMode.light => TioColors.light,
      TioThemeMode.dark => TioColors.dark,
      TioThemeMode.oled => TioColors.oled,
      TioThemeMode.system =>
        systemBrightness == Brightness.dark ? TioColors.dark : TioColors.light,
    };
    return highContrast ? colors.highContrast : colors;
  }
}

WidgetStateProperty<Color?> _buttonStateLayer(Color color) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return Colors.transparent;
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: TioButtonTokens.pressedStateOpacity);
    }
    if (states.contains(WidgetState.focused)) {
      return color.withValues(alpha: TioButtonTokens.focusedStateOpacity);
    }
    if (states.contains(WidgetState.hovered)) {
      return color.withValues(alpha: TioButtonTokens.hoveredStateOpacity);
    }
    return Colors.transparent;
  });
}

WidgetStateProperty<BorderSide?> _outlinedButtonSide(TioColors colors) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return BorderSide(
        color: colors.textMuted,
        width: TioButtonTokens.outlineWidth,
      );
    }
    return BorderSide(
      color: colors.primary,
      width: states.contains(WidgetState.focused)
          ? TioButtonTokens.focusedOutlineWidth
          : TioButtonTokens.outlineWidth,
    );
  });
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
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
  int get fadeThroughEnterMs => TioMotion.fadeThroughEnterMs;
  int get fadeThroughExitMs => TioMotion.fadeThroughExitMs;
  int get progressMs => TioMotion.progressMs;
}
