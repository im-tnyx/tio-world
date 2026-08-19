import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

    final inputBorderRadius = BorderRadius.circular(TioRadius.lg);
    final inputBorderColor = colors.outlineStrong.withValues(
      alpha: isDark
          ? TioInputTokens.darkUnfocusedOutlineOpacity
          : TioInputTokens.lightUnfocusedOutlineOpacity,
    );
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
                    TioSpacing.sm,
                    0,
                    TioSpacing.lg,
                    0,
                  ),
                  child: SizedBox(
                    height: TioSize.dp48,
                    child: Row(
                      children: [
                        IconButton(
                          key: const ValueKey('login-back-button'),
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textPrimary,
                            size: TioSize.dp24,
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
                        const SizedBox(width: TioSpacing.sm),
                        Text('Login', style: textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TioSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: TioSpacing.lg),

                        // Email Input Field (Outlined)
                        TextFormField(
                          key: const ValueKey('login-email-input'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: textTheme.bodyLarge,
                          cursorColor: colors.primary,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: textTheme.bodyMedium,
                            floatingLabelStyle: textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: TioFontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioInputTokens.horizontalPadding,
                              vertical:
                                  TioInputTokens.standardContentVerticalPadding,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: inputBorderRadius,
                              borderSide: BorderSide(
                                color: inputBorderColor,
                                width: TioStroke.width12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: inputBorderRadius,
                              borderSide: BorderSide(
                                color: inputFocusedBorderColor,
                                width: TioStroke.width18,
                              ),
                            ),
                            filled: false,
                          ),
                        ),

                        const SizedBox(height: TioSpacing.lg),

                        // Password Input Field (Outlined with Visibility Toggle)
                        TextFormField(
                          key: const ValueKey('login-password-input'),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleEmailSignIn(),
                          style: textTheme.bodyLarge,
                          cursorColor: colors.primary,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: textTheme.bodyLarge?.copyWith(
                              color: colors.textMuted,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioInputTokens.horizontalPadding,
                              vertical:
                                  TioInputTokens.standardContentVerticalPadding,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: inputBorderRadius,
                              borderSide: BorderSide(
                                color: inputBorderColor,
                                width: TioStroke.width12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: inputBorderRadius,
                              borderSide: BorderSide(
                                color: inputFocusedBorderColor,
                                width: TioStroke.width18,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: colors.textMuted,
                                size: TioSize.dp22,
                              ),
                              onPressed: () {
                                setState(
                                  () => _isPasswordVisible = !_isPasswordVisible,
                                );
                              },
                            ),
                            filled: false,
                          ),
                        ),

                        const SizedBox(height: TioSpacing.md),

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
                        const SizedBox(height: TioSpacing.xl),
                        // Login Action Button (Reusable TioButton Component)
                        TioButton.primary(
                          key: const ValueKey('login-submit-button'),
                          label: 'Login',
                          expand: true,
                          loading: _isEmailLoading,
                          enabled: _isFormValid && !_isGoogleLoading,
                          onPressed: _handleEmailSignIn,
                        ),

                        const SizedBox(height: TioSpacing.xl),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: colors.outlineStrong.withValues(
                                  alpha: TioOpacity.opacity30,
                                ),
                                thickness: TioStroke.width1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: TioSpacing.lg,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: TioFontSize.size11,
                                  fontWeight: TioFontWeight.w600,
                                  color: colors.textMuted,
                                  letterSpacing: TioLetterSpacing.positive05,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: colors.outlineStrong.withValues(
                                  alpha: TioOpacity.opacity30,
                                ),
                                thickness: TioStroke.width1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: TioSpacing.xl),

                        // Continue with Google Button
                        TioSocialButton.google(
                          key: const ValueKey('login-google-button'),
                          loading: _isGoogleLoading,
                          enabled: !_isEmailLoading,
                          onPressed: _handleGoogleSignIn,
                        ),

                        const SizedBox(height: TioSpacing.md),

                        // Continue with Truecaller Button
                        TioSocialButton.truecaller(
                          key: const ValueKey('login-truecaller-button'),
                          loading: false,
                          enabled: !_isBusy,
                          onPressed: _handleTruecallerSignIn,
                        ),

                        const SizedBox(
                          height: TioSpacing.xl + TioSpacing.sm,
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer: Don't have an account? Sign Up
                Padding(
                  padding: const EdgeInsets.only(top: TioSpacing.sm),
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
                            horizontal: TioSpacing.xs,
                            vertical: TioSpacing.sm,
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
                top: TioSpacing.md,
                left: TioSpacing.lg,
                right: TioSpacing.lg,
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

/// Floating error banner matching Tnyx-Hub error state.
class _FloatingErrorBanner extends StatelessWidget {
  const _FloatingErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  // This is a one-off local Material effect, not evidence for a shared
  // TioElevation role.
  static const _elevation = 6.0;

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Material(
      color: Colors.transparent,
      elevation: _elevation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.danger,
          borderRadius: BorderRadius.circular(TioRadius.lg),
          boxShadow: [
            BoxShadow(
              color: TioPalette.black.withValues(alpha: TioOpacity.opacity30),
              blurRadius: TioSize.dp10,
              offset: const Offset(0, TioSize.dp4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: TioPalette.white,
              size: TioSize.dp20,
            ),
            const SizedBox(width: TioSize.dp10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: TioPalette.white,
                  fontSize: TioFontSize.size13,
                  fontWeight: TioFontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                color: TioPalette.whiteAlpha179,
                size: TioSize.dp18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
