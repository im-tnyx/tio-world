import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tio_core/core.dart';
import '../theme/welcome_tokens.dart';
import '../state/welcome_ui_state.dart';
import '../action/welcome_action.dart';
import '../widgets/welcome_backdrop.dart';
import '../widgets/welcome_disclaimer.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Existing Background Image (Instant rendering at the bottom layer aligned from the top)
            Align(
              alignment: const Alignment(0, -1.0),
              child: FractionallySizedBox(
                widthFactor: 1.2,
                heightFactor: 0.82,
                child: Image.asset(
                  'assets/landing_screen.png',
                  package: 'tio_feature_welcome',
                  fit: BoxFit.fill,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),

            // 2. Backdrop (Loaded instantly with the image)
            const WelcomeBackdrop(),

            // 3. Main Content Container (SafeArea renders top bar instantly, content animations are inside)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: WelcomeDimens.paddingScreen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: WelcomeDimens.spaceXS),
                    WelcomeTopBar(
                      localeCode: state.localeCode,
                      skipText: state.skipText,
                      onSkip: () => onAction(const WelcomeSkipForNowClicked()),
                    ),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: context.tioMotion.slow,
                        curve: const Interval(0.4, 1.0,
                            curve: Curves.easeOutCubic),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 30.0 * (1.0 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(flex: 1),

                            // Existing Title Text with Gold Accents
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 42,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(text: 'TRAIN.\n'),
                                  TextSpan(text: 'EAT.\n'),
                                  TextSpan(
                                    text: 'EVOLVE.',
                                    style: TextStyle(
                                      color: Colors.white, // Gold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: WelcomeDimens.spaceS),

                            // Existing Subtitle/Tagline separator and lines
                            Container(
                              width: 60,
                              height: 2,
                              color: Colors.white,
                            ),
                            const SizedBox(height: WelcomeDimens.spaceS),
                            const Text(
                              'AI guidance.\nPersonalized for you.\nResults that last.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),

                            const Spacer(flex: 3),

                            // Feature Grid Row matching the horizontal columns design
                            DecoratedBox(
                              key: const ValueKey('welcome-feature-panel'),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(
                                  alpha: 0.94,
                                ),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(
                                  WelcomeDimens.radiusXL,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: WelcomeDimens.spaceXS,
                                  vertical: WelcomeDimens.spaceS,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int i = 0;
                                        i < state.featureLines.length;
                                        i++) ...[
                                      if (i > 0)
                                        Container(
                                          width: 1,
                                          height: 64,
                                          color: colorScheme.outlineVariant,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: WelcomeDimens.spaceXXS,
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
                                                  package:
                                                      'tio_feature_welcome',
                                                  width: 32,
                                                  height: 28,
                                                  color: colorScheme.primary,
                                                  colorBlendMode:
                                                      BlendMode.srcIn,
                                                )
                                              : i == 1
                                                  ? Icon(
                                                      Icons.restaurant,
                                                      size: 28,
                                                      color:
                                                          colorScheme.primary,
                                                    )
                                                  : SvgPicture.asset(
                                                      'assets/ic_chat.svg',
                                                      package:
                                                          'tio_feature_welcome',
                                                      width: 32,
                                                      height: 28,
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

                            const SizedBox(height: 36),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TioButton.primary(
                                  label: state.ctaText,
                                  expand: true,
                                  trailing:
                                      const Icon(Icons.arrow_forward, size: 20),
                                  onPressed: () => onAction(
                                      const WelcomeGetStartedClicked()),
                                ),
                                const SizedBox(height: 12),
                                TioButton.secondary(
                                  label: state.signInText,
                                  expand: true,
                                  trailing:
                                      const Icon(Icons.arrow_forward, size: 20),
                                  onPressed: () =>
                                      onAction(const WelcomeSignInClicked()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            WelcomeDisclaimer(state: state),
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
