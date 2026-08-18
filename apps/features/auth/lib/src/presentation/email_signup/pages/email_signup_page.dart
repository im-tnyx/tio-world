import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import '../../theme/auth_form_tokens.dart';
import '../../theme/auth_signup_tokens.dart';
import '../../theme/auth_visual_tokens.dart';

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

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
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
                          key: const ValueKey('signup-back-button'),
                          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
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
                        const SizedBox(width: TioSpacing.small),
                        Text('Sign Up', style: textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TioSpacing.large,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: TioSpacing.large),
                        TextField(
                          key: const ValueKey('signup-email-input'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !_isBusy,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: colors.textMuted,
                              size: AuthSignupTokens.inputPrefixIconSize,
                            ),
                            labelStyle: TextStyle(color: colors.textMuted),
                            hintStyle: TextStyle(
                              color: colors.textMuted.withValues(
                                alpha: AuthSignupTokens.inputHintOpacity,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioInputTokens.horizontalPadding,
                              vertical:
                                  AuthSignupTokens.inputContentVerticalPadding,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(
                                color: colors.outlineStrong.withValues(
                                  alpha: AuthSignupTokens.inputOutlineOpacity,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(
                                color: colors.outlineStrong.withValues(
                                  alpha: AuthSignupTokens.inputOutlineOpacity,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: AuthSignupTokens.inputFocusedOutlineWidth,
                              ),
                            ),
                            filled: false,
                          ),
                        ),
                        const SizedBox(height: TioSpacing.large),
                        TextField(
                          key: const ValueKey('signup-password-input'),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          enabled: !_isBusy,
                          style: TextStyle(color: colors.textPrimary),
                          onSubmitted: (_) => _handleSignUp(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'At least 6 characters',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: colors.textMuted,
                              size: AuthSignupTokens.inputPrefixIconSize,
                            ),
                            labelStyle: TextStyle(color: colors.textMuted),
                            hintStyle: TextStyle(
                              color: colors.textMuted.withValues(
                                alpha: AuthSignupTokens.inputHintOpacity,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioInputTokens.horizontalPadding,
                              vertical:
                                  AuthSignupTokens.inputContentVerticalPadding,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(
                                color: colors.outlineStrong.withValues(
                                  alpha: AuthSignupTokens.inputOutlineOpacity,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(
                                color: colors.outlineStrong.withValues(
                                  alpha: AuthSignupTokens.inputOutlineOpacity,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: AuthSignupTokens.inputFocusedOutlineWidth,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: colors.textMuted,
                                size: AuthFormTokens.passwordVisibilityIconSize,
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
                        const SizedBox(height: AuthSignupTokens.submitTopGap),
                        TioButton.primary(
                          key: const ValueKey('signup-submit-button'),
                          label: 'Create Account',
                          expand: true,
                          loading: _isEmailLoading,
                          enabled: _isFormValid && !_isGoogleLoading,
                          onPressed: _handleSignUp,
                        ),
                        const SizedBox(height: TioSpacing.extraLarge),
                        _OrDivider(colors: colors),
                        const SizedBox(height: TioSpacing.extraLarge),
                        TioSocialButton.google(
                          key: const ValueKey('signup-google-button'),
                          loading: _isGoogleLoading,
                          enabled: !_isEmailLoading,
                          onPressed: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: AuthFormTokens.socialProviderGap),
                        TioSocialButton.truecaller(
                          key: const ValueKey('signup-truecaller-button'),
                          loading: false,
                          enabled: !_isBusy,
                          onPressed: widget.onTruecallerClick ?? () {},
                        ),
                        const SizedBox(height: TioSpacing.large),
                        const TioTermsDisclaimer(),
                        const SizedBox(
                          height: TioSpacing.extraLarge + TioSpacing.small,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: TioSpacing.large,
                    top: TioSpacing.small,
                  ),
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
                            horizontal: AuthFormTokens.footerLinkHorizontalPadding,
                            vertical: AuthFormTokens.footerLinkVerticalPadding,
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
              alpha: AuthFormTokens.dividerOpacity,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuthFormTokens.dividerHorizontalPadding,
          ),
          child: Text(
            'OR',
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: AuthSignupTokens.dividerLabelLetterSpacing,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colors.outlineStrong.withValues(
              alpha: AuthFormTokens.dividerOpacity,
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
                  fontWeight: AuthVisualTokens.floatingErrorSignupMessageFontWeight,
                ),
              ),
            ),
            if (message.toLowerCase().contains('already registered') ||
                message.toLowerCase().contains('log in')) ...[
              const SizedBox(width: TioSpacing.small),
              TextButton(
                onPressed: () {
                  onDismiss();
                  context.pushReplacement(AppRoutes.login.path);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AuthVisualTokens.floatingErrorContentColor,
                  backgroundColor: AuthVisualTokens.signupRecoveryActionBackgroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuthVisualTokens.signupRecoveryActionHorizontalPadding,
                    vertical: AuthVisualTokens.signupRecoveryActionVerticalPadding,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AuthVisualTokens.signupRecoveryActionRadius,
                    ),
                  ),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    fontWeight: AuthVisualTokens.signupRecoveryActionFontWeight,
                    fontSize: AuthVisualTokens.signupRecoveryActionFontSize,
                  ),
                ),
              ),
              const SizedBox(width: TioSpacing.small),
            ],
            IconButton(
              icon: const Icon(
                Icons.close,
                color: AuthVisualTokens.floatingErrorContentColor,
                size: AuthVisualTokens.floatingErrorDismissIconSize,
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
