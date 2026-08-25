import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

/// Canonical Sign Up screen for fresh-account authentication.
///
/// Email/password, Google, future Truecaller, and the legal disclaimer live on
/// this one surface. Entry source affects post-auth continuation in the app
/// router/bootstrap layer, not which signup providers are visible here.
class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({
    this.signUpWithEmailUseCase,
    this.signInWithGoogleUseCase,
    this.googleAuthUseCase,
    this.onSignUpSuccess,
    this.onAuthSuccess,
    this.onTruecallerClick,
    super.key,
  });

  final SignUpWithEmailUseCase? signUpWithEmailUseCase;
  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final GoogleAuthUseCase? googleAuthUseCase;
  final ValueChanged<SignInSuccess>? onSignUpSuccess;
  final ValueChanged<GoogleAuthComplete>? onAuthSuccess;
  final VoidCallback? onTruecallerClick;

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

enum _SignupAuthAction { email, google }

class _EmailSignupPageState extends State<EmailSignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  _SignupAuthAction? _activeAction;
  String? _errorMessage;

  bool get _isBusy => _activeAction != null;
  bool get _isEmailLoading => _activeAction == _SignupAuthAction.email;
  bool get _isGoogleLoading => _activeAction == _SignupAuthAction.google;

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
    return email.contains('@') && email.contains('.') && email.length >= 5;
  }

  bool get _isPasswordValid => _passwordController.text.length >= 6;
  bool get _isFormValid => _isEmailValid && _isPasswordValid;

  Future<void> _handleSignUp() async {
    if (!_isFormValid || _isBusy) return;

    setState(() {
      _activeAction = _SignupAuthAction.email;
      _errorMessage = null;
    });

    final useCase = widget.signUpWithEmailUseCase;
    if (useCase == null) {
      if (mounted) setState(() => _activeAction = null);
      return;
    }

    try {
      final result = await useCase(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      switch (result) {
        case SignInSuccess():
          widget.onSignUpSuccess?.call(result);
          break;
        case SignInFailure(:final message):
          setState(() => _errorMessage = message);
          break;
        case SignInCancelled():
          break;
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted && _activeAction == _SignupAuthAction.email) {
        setState(() => _activeAction = null);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isBusy) return;

    setState(() {
      _activeAction = _SignupAuthAction.google;
      _errorMessage = null;
    });

    try {
      if (widget.signInWithGoogleUseCase != null) {
        final result = await widget.signInWithGoogleUseCase!(
          intent: GoogleSignInIntent.signupOrExisting,
        );
        if (!mounted) return;

        if (result is SignInSuccess) {
          widget.onSignUpSuccess?.call(result);
          return;
        }
        if (result is SignInFailure) {
          setState(() => _errorMessage = result.message);
        }
        return;
      }

      if (widget.googleAuthUseCase != null) {
        final result = await widget.googleAuthUseCase!();
        if (!mounted) return;

        if (result is GoogleAuthComplete) {
          widget.onAuthSuccess?.call(result);
          return;
        }
        if (result is GoogleAuthFailed) {
          setState(() => _errorMessage = result.message);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted && _activeAction == _SignupAuthAction.google) {
        setState(() => _activeAction = null);
      }
    }
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
                          key: const ValueKey('signup-back-button'),
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textPrimary,
                          ),
                          onPressed: () {
                            if (!_isBusy) {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.auth.path);
                              }
                            }
                          },
                        ),
                        const SizedBox(width: TioSpacing.sm),
                        Text('Sign Up', style: textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TioSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: TioSpacing.lg),
                        TextFormField(
                          key: const ValueKey('signup-email-input'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !_isBusy,
                          style: textTheme.bodyLarge,
                          cursorColor: colors.primary,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            labelStyle: textTheme.bodyMedium,
                            floatingLabelStyle: textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: TioFontWeight.w500,
                            ),
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
                            filled: false,
                          ),
                        ),
                        const SizedBox(height: TioSpacing.lg),
                        TextFormField(
                          key: const ValueKey('signup-password-input'),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          enabled: !_isBusy,
                          style: textTheme.bodyLarge,
                          cursorColor: colors.primary,
                          onFieldSubmitted: (_) => _handleSignUp(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'At least 6 characters',
                            labelStyle: textTheme.bodyMedium,
                            floatingLabelStyle: textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: TioFontWeight.w500,
                            ),
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
                              onPressed: _isBusy
                                  ? null
                                  : () {
                                      setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      );
                                    },
                            ),
                            filled: false,
                          ),
                        ),
                        const SizedBox(height: TioSize.dp28),
                        TioButton.primary(
                          key: const ValueKey('signup-submit-button'),
                          label: 'Create Account',
                          expand: true,
                          loading: _isEmailLoading,
                          enabled: _isFormValid && !_isGoogleLoading,
                          onPressed: _handleSignUp,
                        ),
                        const SizedBox(height: TioSpacing.xl),
                        _OrDivider(colors: colors),
                        const SizedBox(height: TioSpacing.xl),
                        TioSocialButton.google(
                          key: const ValueKey('signup-google-button'),
                          loading: _isGoogleLoading,
                          enabled: !_isEmailLoading,
                          onPressed: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: TioSpacing.md),
                        TioSocialButton.truecaller(
                          key: const ValueKey('signup-truecaller-button'),
                          loading: false,
                          enabled: !_isBusy,
                          onPressed: widget.onTruecallerClick ?? () {},
                        ),
                        const SizedBox(height: TioSpacing.lg),
                        const TioTermsDisclaimer(),
                        const SizedBox(
                          height: TioSpacing.xl + TioSpacing.sm,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  key: const ValueKey('signup-auth-switch-footer'),
                  padding: const EdgeInsets.only(top: TioSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: textTheme.bodyMedium,
                      ),
                      TextButton(
                        key: const ValueKey('signup-login-link'),
                        onPressed: _isBusy
                            ? null
                            : () => context.pushReplacement(AppRoutes.login.path),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TioSpacing.xs,
                            vertical: TioSpacing.sm,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Log In', style: textTheme.labelLarge),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.colors});

  final TioColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colors.outlineStrong.withValues(
              alpha: TioOpacity.opacity30,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
          child: Text(
            'OR',
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: TioLetterSpacing.positive10,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colors.outlineStrong.withValues(
              alpha: TioOpacity.opacity30,
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingErrorBanner extends StatelessWidget {
  const _FloatingErrorBanner({
    required this.message,
    required this.onDismiss,
  });

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
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: TioPalette.white,
                  fontSize: TioFontSize.size13,
                  fontWeight: TioFontWeight.w600,
                ),
              ),
            ),
            if (message.toLowerCase().contains('already registered') ||
                message.toLowerCase().contains('log in')) ...[
              const SizedBox(width: TioSpacing.sm),
              TextButton(
                onPressed: () {
                  onDismiss();
                  context.pushReplacement(AppRoutes.login.path);
                },
                style: TextButton.styleFrom(
                  foregroundColor: TioPalette.white,
                  backgroundColor: TioPalette.white.withAlpha(TioAlpha.alpha50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TioSize.dp10,
                    vertical: TioSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TioRadius.sm),
                  ),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    fontWeight: TioFontWeight.w800,
                    fontSize: TioFontSize.size12,
                  ),
                ),
              ),
              const SizedBox(width: TioSpacing.sm),
            ],
            IconButton(
              icon: const Icon(
                Icons.close,
                color: TioPalette.white,
                size: TioSize.dp18,
              ),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
