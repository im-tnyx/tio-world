import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    this.signInWithGoogleUseCase,
    this.googleAuthUseCase,
    this.onAuthSuccess,
    this.onSignInSuccess,
    super.key,
  });

  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final GoogleAuthUseCase? googleAuthUseCase;
  final ValueChanged<GoogleAuthComplete>? onAuthSuccess;
  final ValueChanged<SignInSuccess>? onSignInSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    if (widget.signInWithGoogleUseCase == null && widget.googleAuthUseCase == null) {
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/onboarding');
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.signInWithGoogleUseCase != null) {
        final result = await widget.signInWithGoogleUseCase!();
        if (!mounted) return;

        switch (result) {
          case SignInSuccess():
            widget.onSignInSuccess?.call(result);
            if (context.canPop()) {
              context.pop(true);
            } else {
              context.go('/onboarding');
            }
          case SignInCancelled():
            break;
          case SignInFailure(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
        }
        return;
      }

      final result = await widget.googleAuthUseCase!();
      if (!mounted) return;

      switch (result) {
        case GoogleAuthComplete():
          widget.onAuthSuccess?.call(result);
          if (context.canPop()) {
            context.pop(true);
          } else {
            if (result.backendUserState is BackendUserReady &&
                (result.backendUserState as BackendUserReady).isOnboarded) {
              context.go('/');
            } else {
              context.go('/onboarding');
            }
          }
        case GoogleAuthCancelled():
          break;
        case GoogleAuthFailed(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your fitness journey.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Truecaller Login Placeholder
              _SocialLoginButton(
                icon: Icons.phone_android_outlined,
                label: 'Continue with Truecaller',
                color: const Color(0xFF25D366),
                onTap: () {
                  if (context.canPop()) {
                    context.pop(true);
                  } else {
                    context.go('/');
                  }
                },
              ),
              const SizedBox(height: 16),

              // Google Login
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _SocialLoginButton(
                  icon: Icons.g_mobiledata,
                  label: 'Continue with Google',
                  color: Colors.white,
                  textColor: Colors.black,
                  onTap: _handleGoogleSignIn,
                ),
              const SizedBox(height: 16),

              // Phone/Email Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 24),

              // Phone Login
              TioButton.secondary(
                label: 'Continue with Phone Number',
                expand: true,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop(true);
                  } else {
                    context.go('/');
                  }
                },
              ),
              const SizedBox(height: 16),

              // Email Login
              TioButton.ghost(
                label: 'Continue with Email Address',
                expand: true,
                onPressed: () => context.push('/login/email'),
              ),
              const SizedBox(height: 20),

              // Create account link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to Tio?',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => context.push('/login/email-signup'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Legal text disclaimer
              Align(
                alignment: Alignment.center,
                child: Text(
                  'By signing in, you agree to our Terms & Privacy Policy.',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
