import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

/// Pixel-perfect implementation of the Tnyx-Hub Email/Social Login Screen.
///
/// Follows AGENTS.md and Material 3 Expressive design tokens:
/// - Semantic colors from [TioColors] (Light, Dark, OLED, High-Contrast ready).
/// - Dimensions, spacing, and radii from [TioSpacing], [TioRadius], and [TioInputTokens].
/// - Outlined Email input field with floating label.
/// - Outlined Password input field with visibility toggle.
/// - "Forgot Password?" action link.
/// - Full-width "Login" submit button with loading and validation states.
/// - "OR" divider with subtle semantic outline.
/// - "Continue with Google" branded button with official 4-color Google logo.
/// - "Continue with Truecaller" branded action button.
/// - "Don't have an account? Sign Up" footer navigation.
/// - Floating error banner for accessible feedback.
class LoginPage extends StatefulWidget {
  const LoginPage({
    this.signInWithGoogleUseCase,
    this.signInWithEmailUseCase,
    this.googleAuthUseCase,
    this.onAuthSuccess,
    this.onSignInSuccess,
    super.key,
  });

  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final SignInWithEmailUseCase? signInWithEmailUseCase;
  final GoogleAuthUseCase? googleAuthUseCase;
  final ValueChanged<GoogleAuthComplete>? onAuthSuccess;
  final ValueChanged<SignInSuccess>? onSignInSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[\w.+\-]+@[\w\-]+\.\w{2,}$').hasMatch(email);
  }

  bool get _isPasswordValid {
    return _passwordController.text.isNotEmpty;
  }

  bool get _isFormValid => _isEmailValid && _isPasswordValid;

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

  Future<void> _handleEmailSignIn() async {
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.signInWithEmailUseCase == null) {
      await _navigateOnAuthSuccess();
      return;
    }

    try {
      final result = await widget.signInWithEmailUseCase!(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      switch (result) {
        case SignInSuccess():
          widget.onSignInSuccess?.call(result);
          await _navigateOnAuthSuccess(result.session.userId);
        case SignInCancelled():
          break;
        case SignInFailure(:final message):
          setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.signInWithGoogleUseCase != null) {
        final result = await widget.signInWithGoogleUseCase!();
        if (!mounted) return;

        switch (result) {
          case SignInSuccess():
            widget.onSignInSuccess?.call(result);
            await _navigateOnAuthSuccess(result.session.userId);
          case SignInCancelled():
            break;
          case SignInFailure(:final message):
            setState(() => _errorMessage = message);
        }
        return;
      }

      if (widget.googleAuthUseCase != null) {
        final result = await widget.googleAuthUseCase!();
        if (!mounted) return;

        switch (result) {
          case GoogleAuthComplete():
            widget.onAuthSuccess?.call(result);
            await _navigateOnAuthSuccess(result.session.userId);
          case GoogleAuthCancelled():
            break;
          case GoogleAuthFailed(:final message):
            setState(() => _errorMessage = message);
        }
        return;
      }

      await _navigateOnAuthSuccess();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Google sign in error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleTruecallerSignIn() {
    if (_isLoading) return;
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final isDark = colors.isDark;

    final inputBorderRadius = BorderRadius.circular(TioRadius.large);
    final inputBorderColor = colors.outlineStrong.withValues(alpha: isDark ? 0.35 : 0.45);
    final inputFocusedBorderColor = colors.textPrimary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.background,
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Stack(
          children: [
            Column(
              children: [
                // Top App Bar (100% Identical alignment with OnboardingTopBar & SignUp)
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
                        IconButton(
                          key: const ValueKey('login-back-button'),
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textPrimary,
                            size: 24,
                          ),
                          onPressed: () {
                            if (!_isLoading) {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/auth');
                              }
                            }
                          },
                        ),
                        const SizedBox(width: TioSpacing.small),
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: TioSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: TioSpacing.large),

                        // Email Input Field (Outlined)
                        TextFormField(
                          key: const ValueKey('login-email-input'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: colors.textPrimary, fontSize: 16),
                          cursorColor: colors.primary,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioSpacing.large,
                              vertical: TioSpacing.large,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: inputBorderRadius,
                              borderSide: BorderSide(color: inputBorderColor, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: inputBorderRadius,
                              borderSide: BorderSide(color: inputFocusedBorderColor, width: 1.8),
                            ),
                            filled: false,
                          ),
                        ),

                        const SizedBox(height: TioSpacing.large),

                        // Password Input Field (Outlined with Visibility Toggle)
                        TextFormField(
                          key: const ValueKey('login-password-input'),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleEmailSignIn(),
                          style: TextStyle(color: colors.textPrimary, fontSize: 16),
                          cursorColor: colors.primary,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: colors.textMuted, fontSize: 16),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioSpacing.large,
                              vertical: TioSpacing.large,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: inputBorderRadius,
                              borderSide: BorderSide(color: inputBorderColor, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: inputBorderRadius,
                              borderSide: BorderSide(color: inputFocusedBorderColor, width: 1.8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: colors.textMuted,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() => _isPasswordVisible = !_isPasswordVisible);
                              },
                            ),
                            filled: false,
                          ),
                        ),

                        const SizedBox(height: TioSpacing.medium),

                        // Forgot Password Link
                        GestureDetector(
                          key: const ValueKey('login-forgot-password-link'),
                          onTap: () {
                            if (!_isLoading) {
                              context.push('/login/forgot-password');
                            }
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Login Action Button (Reusable TioButton Component)
                        TioButton.primary(
                          key: const ValueKey('login-submit-button'),
                          label: 'Login',
                          expand: true,
                          loading: _isLoading,
                          enabled: _isFormValid,
                          onPressed: _handleEmailSignIn,
                        ),

                        const SizedBox(height: TioSpacing.extraLarge),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: colors.outlineStrong.withValues(alpha: 0.3),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.large),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: colors.outlineStrong.withValues(alpha: 0.3),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: TioSpacing.extraLarge),

                        // Continue with Google Button
                        TioSocialButton.google(
                          key: const ValueKey('login-google-button'),
                          loading: _isLoading,
                          onPressed: _handleGoogleSignIn,
                        ),

                        const SizedBox(height: 12),

                        // Continue with Truecaller Button
                        TioSocialButton.truecaller(
                          key: const ValueKey('login-truecaller-button'),
                          loading: _isLoading,
                          onPressed: _handleTruecallerSignIn,
                        ),

                        const SizedBox(height: TioSpacing.extraLarge + TioSpacing.small),
                      ],
                    ),
                  ),
                ),

                // Footer: Don't have an account? Sign Up
                Padding(
                  padding: const EdgeInsets.only(bottom: 0, top: TioSpacing.small),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('login-signup-link'),
                        onPressed: () {
                          if (!_isLoading) {
                            context.pushReplacement(AppRoutes.emailSignup.path);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Floating Error Banner at Top
            if (_errorMessage != null)
              Positioned(
                top: TioSpacing.medium,
                left: TioSpacing.large,
                right: TioSpacing.large,
                child: _FloatingErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Floating error banner matching Tnyx-Hub error state
class _FloatingErrorBanner extends StatelessWidget {
  const _FloatingErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    return Material(
      color: Colors.transparent,
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: TioSpacing.large, vertical: TioSpacing.medium),
        decoration: BoxDecoration(
          color: colors.danger,
          borderRadius: BorderRadius.circular(TioRadius.large),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: TioSpacing.medium),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
