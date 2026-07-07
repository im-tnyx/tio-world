import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../controllers/welcome_controller.dart';
import '../widgets/welcome_backdrop.dart';
import '../widgets/welcome_disclaimer.dart';
import '../widgets/welcome_feature_tile.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(welcomeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Animated Backdrop
          const WelcomeBackdrop(),

          // 2. Animated Content
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0.0, 30.0 * (1.0 - value)),
                  child: child,
                ),
              );
            },
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Language Selection / Logo Space
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Language text button
                        TextButton(
                          onPressed: () {
                            // Can show language selector dialog
                          },
                          child: const Text(
                            'EN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 3),

                    // Title Section
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
                              color: Color(0xFFD4AF37), // Gold
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle / Tagline
                    Container(
                      width: 60,
                      height: 2,
                      color: const Color(0xFFD4AF37),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Feature Grid Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < state.features.length; i++) ...[
                          if (i > 0)
                            Container(
                              width: 1,
                              height: 64,
                              color: Colors.white12,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          Expanded(
                            child: WelcomeFeatureTile(
                              title: state.features[i].title,
                              description: state.features[i].description,
                              icon: state.features[i].icon,
                              color: state.features[i].color,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Styled Buttons block matching the white/outlined mockup style
                    Theme(
                      data: Theme.of(context).copyWith(
                        filledButtonTheme: FilledButtonThemeData(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        outlinedButtonTheme: OutlinedButtonThemeData(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Get Started Button
                          TioButton.primary(
                            label: state.ctaText,
                            expand: true,
                            trailing: const Icon(Icons.arrow_forward, size: 20),
                            onPressed: () {
                              context.push(AppRoutes.onboarding.path);
                            },
                          ),

                          const SizedBox(height: 12),

                          // Sign In Button
                          TioButton.secondary(
                            label: state.signInText,
                            expand: true,
                            trailing: const Icon(Icons.arrow_forward, size: 20),
                            onPressed: () {
                              context.push(AppRoutes.login.path);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Disclaimer Text
                    Align(
                      alignment: Alignment.center,
                      child: WelcomeDisclaimer(
                        onTermsTap: () {
                          // Handle terms click
                        },
                        onPrivacyTap: () {
                          // Handle privacy click
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
