import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../action/welcome_action.dart';
import '../state/welcome_ui_state.dart';
import '../widgets/welcome_backdrop.dart';
import '../widgets/welcome_feature_tile.dart';
import '../widgets/welcome_top_bar.dart';

const _featurePanelRadius = 20.0;
const _featureDividerHorizontalMargin = 4.0;

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
                          0.4,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
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
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: TioSpacing.medium),
                            Container(
                              width: 60,
                              height: 2,
                              color: Colors.white,
                            ),
                            const SizedBox(height: TioSpacing.medium),
                            const Text(
                              'AI guidance.\nPersonalized for you.\nResults that last.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const Spacer(flex: 3),
                            DecoratedBox(
                              key: const ValueKey('welcome-feature-panel'),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(alpha: 0.94),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(
                                  _featurePanelRadius,
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
                                          width: 1,
                                          height: 64,
                                          color: colorScheme.outlineVariant,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal:
                                                _featureDividerHorizontalMargin,
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
                                                  width: 32,
                                                  height: 28,
                                                  color: colorScheme.primary,
                                                  colorBlendMode: BlendMode.srcIn,
                                                )
                                              : i == 1
                                                  ? Icon(
                                                      Icons.restaurant,
                                                      size: 28,
                                                      color: colorScheme.primary,
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
                                      size: 20,
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
                                    const Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    GestureDetector(
                                      key: const ValueKey(
                                        'welcome-signin-button',
                                      ),
                                      onTap: () => onAction(
                                        const WelcomeSignInClicked(),
                                      ),
                                      child: const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
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
