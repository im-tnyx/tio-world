import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import '../../shared/auth_entry_mode.dart';
import '../../shared/auth_round_actions.dart';
import '../../shared/phone_otp_auth_section.dart';

/// Canonical returning-user Login surface.
///
/// Phone OTP is the default mode. Email + Password remains available on the
/// same screen through the reciprocal Email/Phone round action.
class LoginPage extends StatefulWidget {
  const LoginPage({
    this.signInWithGoogleUseCase,
    this.signInWithEmailUseCase,
    this.googleAuthUseCase,
    this.requestPhoneOtpUseCase,
    this.resendPhoneOtpUseCase,
    this.verifyPhoneOtpUseCase,
    this.initialMode = AuthEntryMode.phone,
    this.onAuthSuccess,
    this.onSignInSuccess,
    super.key,
  });

  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final SignInWithEmailUseCase? signInWithEmailUseCase;
  final GoogleAuthUseCase? googleAuthUseCase;
  final RequestPhoneOtpUseCase? requestPhoneOtpUseCase;
  final ResendPhoneOtpUseCase? resendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase;
  final AuthEntryMode initialMode;
  final ValueChanged<GoogleAuthComplete>? onAuthSuccess;
  final ValueChanged<SignInSuccess>? onSignInSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _LoginAuthAction { email, google }

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AuthEntryMode _mode;
  bool _isPasswordVisible = false;
  bool _isPhoneBusy = false;
  _LoginAuthAction? _activeAction;
  String? _errorMessage;

  bool get _isBusy => _activeAction != null || _isPhoneBusy;
  bool get _isEmailLoading => _activeAction == _LoginAuthAction.email;
  bool get _isGoogleLoading => _activeAction == _LoginAuthAction.google;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
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

  bool get _isPasswordValid => _passwordController.text.isNotEmpty;
  bool get _isFormValid => _isEmailValid && _isPasswordValid;

  void _switchMode() {
    if (_isBusy) return;
    setState(() {
      _mode = _mode == AuthEntryMode.phone
          ? AuthEntryMode.email
          : AuthEntryMode.phone;
      _errorMessage = null;
    });
  }

  Future<void> _handleEmailSignIn() async {
    if (!_isFormValid || _isBusy) return;

    setState(() {
      _activeAction = _LoginAuthAction.email;
      _errorMessage = null;
    });

    final useCase = widget.signInWithEmailUseCase;
    if (useCase == null) {
      if (mounted) {
        setState(() {
          _activeAction = null;
          _errorMessage = 'Email sign-in is unavailable right now.';
        });
      }
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
          widget.onSignInSuccess?.call(result);
        case SignInCancelled():
          break;
        case SignInFailure(:final message):
          setState(() => _errorMessage = message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not sign in. Please try again.');
      }
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
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Google sign-in could not be completed.');
      }
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

  Widget _buildEmailForm(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TioInput(
          key: const ValueKey('login-email-input'),
          controller: _emailController,
          onChanged: (_) {},
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isBusy,
        ),
        const SizedBox(height: TioSpacing.lg),
        TioInput(
          key: const ValueKey('login-password-input'),
          controller: _passwordController,
          onChanged: (_) {},
          label: 'Password',
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          enabled: !_isBusy,
          onSubmitted: (_) => _handleEmailSignIn(),
          trailing: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: colors.textMuted,
              size: TioSize.dp22,
            ),
            onPressed: _isBusy
                ? null
                : () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
          ),
        ),
        const SizedBox(height: TioSpacing.md),
        TextButton(
          key: const ValueKey('login-forgot-password-link'),
          onPressed: _isBusy
              ? null
              : () => context.push(AppRoutes.forgotPassword.path),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Forgot Password?', style: textTheme.labelLarge),
        ),
        const SizedBox(height: TioSpacing.xl),
        TioButton.primary(
          key: const ValueKey('login-submit-button'),
          label: 'Login',
          expand: true,
          loading: _isEmailLoading,
          enabled: _isFormValid && !_isGoogleLoading && !_isPhoneBusy,
          onPressed: _handleEmailSignIn,
        ),
      ],
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    final colors = context.tioColors;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colors.outlineStrong.withValues(alpha: TioOpacity.opacity30),
            thickness: TioStroke.width1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
            color: colors.outlineStrong.withValues(alpha: TioOpacity.opacity30),
            thickness: TioStroke.width1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

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
                          key: const ValueKey('login-back-button'),
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textPrimary,
                            size: TioSize.dp24,
                          ),
                          onPressed: _isBusy
                              ? null
                              : () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRoutes.auth.path);
                                  }
                                },
                        ),
                        const SizedBox(width: TioSpacing.sm),
                        Text('Login', style: textTheme.titleLarge),
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
                        if (_mode == AuthEntryMode.phone)
                          PhoneOtpAuthSection(
                            key: const ValueKey('login-phone-section'),
                            keyPrefix: 'login',
                            intent: PhoneOtpIntent.login,
                            requestPhoneOtpUseCase: widget.requestPhoneOtpUseCase,
                            resendPhoneOtpUseCase: widget.resendPhoneOtpUseCase,
                            verifyPhoneOtpUseCase: widget.verifyPhoneOtpUseCase,
                            enabled: _activeAction == null,
                            onBusyChanged: (busy) {
                              if (mounted) setState(() => _isPhoneBusy = busy);
                            },
                            onError: (message) {
                              if (mounted) {
                                setState(() => _errorMessage = message);
                              }
                            },
                            onSignInSuccess: (result) {
                              widget.onSignInSuccess?.call(result);
                            },
                          )
                        else
                          _buildEmailForm(context),
                        const SizedBox(height: TioSpacing.xl),
                        _buildOrDivider(context),
                        const SizedBox(height: TioSpacing.xl),
                        AuthRoundActions(
                          key: const ValueKey('login-round-actions'),
                          keyPrefix: 'login',
                          mode: _mode,
                          googleLoading: _isGoogleLoading,
                          enabled: !_isPhoneBusy && !_isEmailLoading,
                          onGooglePressed: _handleGoogleSignIn,
                          onTruecallerPressed: _handleTruecallerSignIn,
                          onModeSwitchPressed: _switchMode,
                        ),
                        const SizedBox(
                          height: TioSpacing.xl + TioSpacing.sm,
                        ),
                      ],
                    ),
                  ),
                ),
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
                        onPressed: _isBusy
                            ? null
                            : () => context.pushReplacement(AppRoutes.signup.path),
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
                  fontWeight: TioFontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
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
