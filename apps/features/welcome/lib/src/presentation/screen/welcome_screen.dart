import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../action/welcome_action.dart';
import '../state/welcome_ui_state.dart';
import '../theme/welcome_visual_tokens.dart';
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
        backgroundColor: WelcomeColorTokens.mediaBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height *
                  WelcomeLayoutTokens.heroImageHeightFactor,
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
                  horizontal: TioSpacing.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: TioSpacing.small),
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
                          WelcomeMotionTokens.contentRevealStart,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                WelcomeMotionTokens.contentRevealOffsetY *
                                    (1.0 - value),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(flex: WelcomeLayoutTokens.heroTopFlex),
                            RichText(
                              text: TextSpan(
                                style: WelcomeTypographyTokens.hero.copyWith(
                                  color: WelcomeColorTokens.onMediaPrimary,
                                ),
                                children: const [
                                  TextSpan(text: 'TRAIN.\n'),
                                  TextSpan(text: 'EAT.\n'),
                                  TextSpan(text: 'EVOLVE.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: TioSpacing.medium),
                            const SizedBox(
                              width: WelcomeLayoutTokens.heroDividerWidth,
                              height: WelcomeLayoutTokens.heroDividerHeight,
                              child: ColoredBox(
                                color: WelcomeColorTokens.onMediaPrimary,
                              ),
                            ),
                            const SizedBox(height: TioSpacing.medium),
                            Text(
                              'AI guidance.\nPersonalized for you.\nResults that last.',
                              style: WelcomeTypographyTokens.supporting.copyWith(
                                color: WelcomeColorTokens.onMediaSecondary,
                              ),
                            ),
                            const Spacer(
                              flex: WelcomeLayoutTokens.heroBottomFlex,
                            ),
                            DecoratedBox(
                              key: const ValueKey('welcome-feature-panel'),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(
                                  alpha: WelcomeLayoutTokens
                                      .featurePanelSurfaceOpacity,
                                ),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(
                                  WelcomeLayoutTokens.featurePanelRadius,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TioSpacing.small,
                                  vertical: TioSpacing.medium,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int i = 0;
                                        i < state.featureLines.length;
                                        i++) ...[
                                      if (i > 0)
                                        Container(
                                          width: WelcomeLayoutTokens
                                              .featureDividerWidth,
                                          height: WelcomeLayoutTokens
                                              .featureDividerHeight,
                                          color: colorScheme.outlineVariant,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: WelcomeLayoutTokens
                                                .featureDividerHorizontalMargin,
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
                                                  width: WelcomeLayoutTokens
                                                      .featureAssetWidth,
                                                  height: WelcomeLayoutTokens
                                                      .featureGlyphSize,
                                                  color: colorScheme.primary,
                                                  colorBlendMode: BlendMode.srcIn,
                                                )
                                              : i == 1
                                                  ? Icon(
                                                      Icons.restaurant,
                                                      size: WelcomeLayoutTokens
                                                          .featureGlyphSize,
                                                      color:
                                                          colorScheme.primary,
                                                    )
                                                  : SvgPicture.asset(
                                                      'assets/ic_chat.svg',
                                                      package:
                                                          'tio_feature_welcome',
                                                      width: WelcomeLayoutTokens
                                                          .featureAssetWidth,
                                                      height: WelcomeLayoutTokens
                                                          .featureGlyphSize,
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
                            const SizedBox(height: TioSpacing.extraLarge),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: TioButton.primary(
                                    label: state.ctaText,
                                    trailing: const Icon(
                                      Icons.arrow_forward,
                                      size: WelcomeLayoutTokens.ctaIconSize,
                                    ),
                                    onPressed: () => onAction(
                                      const WelcomeGetStartedClicked(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: TioSpacing.extraLarge),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: WelcomeTypographyTokens.accountPrompt
                                          .copyWith(
                                        color: WelcomeColorTokens.onMediaSecondary,
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
                                        style: WelcomeTypographyTokens.loginAction
                                            .copyWith(
                                          color:
                                              WelcomeColorTokens.onMediaPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: TioSpacing.small),
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
