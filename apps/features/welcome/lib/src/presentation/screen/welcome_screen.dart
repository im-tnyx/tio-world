import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../action/welcome_action.dart';
import '../state/welcome_ui_state.dart';
import '../widgets/welcome_backdrop.dart';
import '../widgets/welcome_feature_tile.dart';
import '../widgets/welcome_top_bar.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.state,
    required this.onAction,
    super.key,
  });

  final WelcomeUiState state;
  final ValueChanged<WelcomeAction> onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.tioColors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Transparent system bars are intentional for the edge-to-edge hero.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: colors.mediaBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: Image.asset(
                'assets/landing_screen.png',
                package: 'tio_feature_welcome',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            const WelcomeBackdrop(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: TioSpacing.sm),
                    WelcomeTopBar(
                      localeCode: state.localeCode,
                      skipText: state.skipText,
                      onSkip: () => onAction(const WelcomeSkipForNowClicked()),
                    ),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: context.tioMotion.slow,
                        curve: const Interval(
                          0.40,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                TioSize.dp30 * (1.0 - value),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(flex: 1),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: TioFontSize.size42,
                                  height: TioLineHeight.height110,
                                  fontWeight: TioFontWeight.w900,
                                  fontFamily: TioFontFamily.roboto,
                                ).copyWith(
                                  color: colors.onMediaPrimary,
                                ),
                                children: const [
                                  TextSpan(text: 'TRAIN.\n'),
                                  TextSpan(text: 'EAT.\n'),
                                  TextSpan(text: 'EVOLVE.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: TioSpacing.md),
                            SizedBox(
                              width: TioSize.dp60,
                              height: TioSize.dp2,
                              child: ColoredBox(
                                color: colors.onMediaPrimary,
                              ),
                            ),
                            const SizedBox(height: TioSpacing.md),
                            Text(
                              'AI guidance.\nPersonalized for you.\nResults that last.',
                              style: const TextStyle(
                                fontSize: TioFontSize.size16,
                                height: TioLineHeight.height140,
                              ).copyWith(
                                color: colors.onMediaSecondary,
                              ),
                            ),
                            const Spacer(flex: 3),
                            DecoratedBox(
                              key: const ValueKey('welcome-feature-panel'),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(
                                  alpha: TioOpacity.opacity94,
                                ),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(
                                  TioSize.dp20,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TioSpacing.sm,
                                  vertical: TioSpacing.md,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int i = 0;
                                        i < state.featureLines.length;
                                        i++) ...[
                                      if (i > 0)
                                        Container(
                                          width: TioSize.dp1,
                                          height: TioSize.dp64,
                                          color: colorScheme.outlineVariant,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: TioSpacing.xs,
                                          ),
                                        ),
                                      Expanded(
                                        child: WelcomeFeatureTile(
                                          title: state.featureLines[i],
                                          description: i == 0
                                              ? 'Smart workout\nplans for you'
                                              : i == 1
                                                  ? 'Personalized diet\n& meal tracking'
                                                  : 'Smart suggestions\n& real support',
                                          iconWidget: i == 0
                                              ? Image.asset(
                                                  'assets/dumbell-blue.png',
                                                  package: 'tio_feature_welcome',
                                                  width: TioSize.dp32,
                                                  height: TioSize.dp28,
                                                  color: colorScheme.primary,
                                                  colorBlendMode: BlendMode.srcIn,
                                                )
                                              : i == 1
                                                  ? Icon(
                                                      Icons.restaurant,
                                                      size: TioSize.dp28,
                                                      color:
                                                          colorScheme.primary,
                                                    )
                                                  : SvgPicture.asset(
                                                      'assets/ic_chat.svg',
                                                      package:
                                                          'tio_feature_welcome',
                                                      width: TioSize.dp32,
                                                      height: TioSize.dp28,
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                        colorScheme.primary,
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: TioSpacing.xl),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: TioButton.primary(
                                    label: state.ctaText,
                                    trailing: const Icon(
                                      Icons.arrow_forward,
                                      size: TioSize.dp20,
                                    ),
                                    onPressed: () => onAction(
                                      const WelcomeGetStartedClicked(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: TioSpacing.xl),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: const TextStyle(
                                        fontSize: TioFontSize.size14,
                                        fontWeight: TioFontWeight.w400,
                                      ).copyWith(
                                        color: colors.onMediaSecondary,
                                      ),
                                    ),
                                    GestureDetector(
                                      key: const ValueKey(
                                        'welcome-signin-button',
                                      ),
                                      onTap: () => onAction(
                                        const WelcomeSignInClicked(),
                                      ),
                                      child: Text(
                                        'Log In',
                                        style: const TextStyle(
                                          fontSize: TioFontSize.size14,
                                          fontWeight: TioFontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ).copyWith(
                                          color: colors.onMediaPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: TioSpacing.sm),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
