import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import '../../theme/auth_form_tokens.dart';
import '../../theme/auth_visual_tokens.dart';

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

enum _LoginAuthAction { email, google }

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  _LoginAuthAction? _activeAction;
  String? _errorMessage;

  bool get _isBusy => _activeAction != null;
  bool get _isEmailLoading => _activeAction == _LoginAuthAction.email;
  bool get _isGoogleLoading => _activeAction == _LoginAuthAction.google;

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

  Future<void> _handleEmailSignIn() async {
    if (!_isFormValid || _isBusy) return;

    setState(() {
      _activeAction = _LoginAuthAction.email;
      _errorMessage = null;
    });

    if (widget.signInWithEmailUseCase == null) {
      if (mounted) setState(() => _activeAction = null);
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
        case SignInCancelled():
          break;
        case SignInFailure(:final message):
          setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted && _activeAction == _LoginAuthAction.email) {
        setState(() => _activeAction = null);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isBusy) return;

    setState(() {
      _activeAction = _LoginAuthAction.google;
      _errorMessage = null;
    });

    try {
      if (widget.signInWithGoogleUseCase != null) {
        final result = await widget.signInWithGoogleUseCase!();
        if (!mounted) return;

        switch (result) {
          case SignInSuccess():
            widget.onSignInSuccess?.call(result);
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
          case GoogleAuthCancelled():
            break;
          case GoogleAuthFailed(:final message):
            setState(() => _errorMessage = message);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Google sign in error: $e');
    } finally {
      if (mounted && _activeAction == _LoginAuthAction.google) {
        setState(() => _activeAction = null);
      }
    }
  }

  void _handleTruecallerSignIn() {
    if (_isBusy) return;
    setState(() {
      _errorMessage = 'Truecaller sign-in is not available yet.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
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
                    height: AuthFormTokens.topBarHeight,
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
                            if (!_isBusy) {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/auth');
                              }
                            }
                          },
                        ),
                        const SizedBox(width: TioSpacing.small),
                        Text('Login', style: textTheme.titleLarge),
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
                                size: AuthFormTokens.passwordVisibilityIconSize,
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
                            if (!_isBusy) {
                              context.push('/login/forgot-password');
                            }
                          },
                          child: Text(
                            'Forgot Password?',
                            style: textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(height: TioSpacing.extraLarge),
                        // Login Action Button (Reusable TioButton Component)
                        TioButton.primary(
                          key: const ValueKey('login-submit-button'),
                          label: 'Login',
                          expand: true,
                          loading: _isEmailLoading,
                          enabled: _isFormValid && !_isGoogleLoading,
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
                          loading: _isGoogleLoading,
                          enabled: !_isEmailLoading,
                          onPressed: _handleGoogleSignIn,
                        ),

                        const SizedBox(height: AuthFormTokens.socialProviderGap),

                        // Continue with Truecaller Button
                        TioSocialButton.truecaller(
                          key: const ValueKey('login-truecaller-button'),
                          loading: false,
                          enabled: !_isBusy,
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
                        style: textTheme.bodyMedium,
                      ),
                      TextButton(
                        key: const ValueKey('login-signup-link'),
                        onPressed: () {
                          if (!_isBusy) {
                            context.pushReplacement(AppRoutes.emailSignup.path);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AuthFormTokens.footerLinkHorizontalPadding,
                            vertical: AuthFormTokens.footerLinkVerticalPadding,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Sign Up', style: textTheme.labelLarge),
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
    final colors = context.tioColors;
    return Material(
      color: Colors.transparent,
      elevation: AuthVisualTokens.floatingErrorElevation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuthVisualTokens.floatingErrorHorizontalPadding,
          vertical: AuthVisualTokens.floatingErrorVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: colors.danger,
          borderRadius: BorderRadius.circular(AuthVisualTokens.floatingErrorRadius),
          boxShadow: [
            BoxShadow(
              color: AuthVisualTokens.floatingErrorShadowBaseColor.withValues(
                alpha: AuthVisualTokens.floatingErrorShadowOpacity,
              ),
              blurRadius: AuthVisualTokens.floatingErrorShadowBlurRadius,
              offset: AuthVisualTokens.floatingErrorShadowOffset,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AuthVisualTokens.floatingErrorContentColor,
              size: AuthVisualTokens.floatingErrorIconSize,
            ),
            const SizedBox(width: AuthVisualTokens.floatingErrorContentGap),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AuthVisualTokens.floatingErrorContentColor,
                  fontSize: AuthVisualTokens.floatingErrorMessageFontSize,
                  fontWeight: AuthVisualTokens.floatingErrorLoginMessageFontWeight,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                color: AuthVisualTokens.floatingErrorDismissColor,
                size: AuthVisualTokens.floatingErrorDismissIconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
