import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';

import '../../domain/domain.dart';

/// 1:1 Pixel-perfect Implementation of Tnyx-Hub Auth Landing Screen (`AuthScreen.kt`).
///
/// Features:
/// - Reusable [TioSocialButton] components from `tio_core`
/// - "Let's get you in" display title
/// - "Sign up or log in to sync your progress" subtitle
/// - Truecaller / Phone action button
/// - Google Sign-In button with branded icon
/// - Email button ("Continue with Email") -> routes to Sign Up
/// - Legal terms & privacy policy interactive footer
class AuthLandingPage extends StatefulWidget {
  const AuthLandingPage({
    this.signInWithGoogleUseCase,
    this.googleAuthUseCase,
    this.onAuthSuccess,
    this.onTruecallerClick,
    this.onEmailClick,
    super.key,
  });

  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final GoogleAuthUseCase? googleAuthUseCase;
  final ValueChanged<GoogleAuthComplete>? onAuthSuccess;
  final VoidCallback? onTruecallerClick;
  final VoidCallback? onEmailClick;

  @override
  State<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends State<AuthLandingPage> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _navigateOnAuthSuccess([String? userId]) async {
    final effectiveUserId = userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        final row = await client
            .from('users')
            .select('is_onboarded, name')
            .eq('id', effectiveUserId)
            .maybeSingle();

        if (row != null && row['is_onboarded'] == true) {
          if (!mounted) return;
          final name = row['name'] as String? ?? '';
          context.go(
            AppRoutes.congratulations.path,
            extra: {
              'userName': name,
              'isWelcomeBack': true,
            },
          );
          return;
        }
      } catch (_) {
        // Non-blocking fallback
      }
    }

    if (!mounted) return;
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AppRoutes.onboarding.path);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.signInWithGoogleUseCase == null && widget.googleAuthUseCase == null) {
      await _navigateOnAuthSuccess();
      return;
    }

    try {
      if (widget.signInWithGoogleUseCase != null) {
        final result = await widget.signInWithGoogleUseCase!();
        if (!mounted) return;
        if (result is SignInSuccess) {
          await _navigateOnAuthSuccess(result.session.userId);
          return;
        } else if (result is SignInFailure) {
          setState(() {
            _errorMessage = result.message;
          });
        }
      } else if (widget.googleAuthUseCase != null) {
        final result = await widget.googleAuthUseCase!();
        if (!mounted) return;
        if (result is GoogleAuthComplete) {
          widget.onAuthSuccess?.call(result);
          await _navigateOnAuthSuccess(result.session.userId);
          return;
        } else if (result is GoogleAuthFailed) {
          setState(() {
            _errorMessage = result.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEmailClick() async {
    if (widget.onEmailClick != null) {
      widget.onEmailClick!();
    } else {
      final result = await context.push<bool>(AppRoutes.emailSignup.path);
      if (result == true && mounted) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(AppRoutes.onboarding.path);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Background vertical gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.75, 1.0],
                  colors: [
                    colors.background.withAlpha(50),
                    colors.background.withAlpha(120),
                    colors.background.withAlpha(220),
                    colors.background,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar (100% Identical alignment with OnboardingTopBar & Auth pages)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TioSpacing.small,
                    0,
                    TioSpacing.large,
                    0,
                  ),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        if (context.canPop())
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                            onPressed: () => context.pop(false),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TioSpacing.large,
                      16,
                      TioSpacing.large,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),

                        // Error banner if any
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.danger.withAlpha(25),
                              borderRadius: BorderRadius.circular(TioRadius.large),
                              border: Border.all(
                                color: colors.danger.withAlpha(80),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: colors.danger, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Brand Wordmark
                        Text(
                          'T I O',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colors.primary,
                            letterSpacing: 4.0,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Header (Title + Subtitle)
                        Text(
                          "Let's get you in",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign up or log in to sync your personalized plan',
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Action Buttons using Reusable TioSocialButton ──

                        // 1. Truecaller / Phone Button
                        TioSocialButton.truecaller(
                          label: 'Continue with Truecaller',
                          onPressed: widget.onTruecallerClick ?? () {},
                        ),

                        const SizedBox(height: 12),

                        // 2. Google Sign In Button
                        TioSocialButton.google(
                          label: 'Continue with Google',
                          loading: _isLoading,
                          onPressed: _handleGoogleSignIn,
                        ),

                        const SizedBox(height: 12),

                        // 3. Continue with Email Button (Routes to Sign Up)
                        TioSocialButton.email(
                          label: 'Continue with Email',
                          onPressed: _handleEmailClick,
                        ),

                        const SizedBox(height: 16),

                        // Legal terms & privacy policy disclaimer
                        const TioTermsDisclaimer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
