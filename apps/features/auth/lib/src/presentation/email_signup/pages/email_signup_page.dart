import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import '../../shared/auth_entry_mode.dart';
import '../../shared/auth_round_actions.dart';
import '../../shared/phone_otp_auth_section.dart';

/// Canonical fresh-account Signup surface.
///
/// Phone OTP is the default mode. Email + Password remains available on the
/// same screen through the reciprocal Email/Phone round action.
class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({
    this.signUpWithEmailUseCase,
    this.signInWithGoogleUseCase,
    this.googleAuthUseCase,
    this.requestPhoneOtpUseCase,
    this.resendPhoneOtpUseCase,
    this.verifyPhoneOtpUseCase,
    this.initialMode = AuthEntryMode.phone,
    this.onSignUpSuccess,
    this.onAuthSuccess,
    this.onTruecallerClick,
    super.key,
  });

  final SignUpWithEmailUseCase? signUpWithEmailUseCase;
  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final GoogleAuthUseCase? googleAuthUseCase;
  final RequestPhoneOtpUseCase? requestPhoneOtpUseCase;
  final ResendPhoneOtpUseCase? resendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase;
  final AuthEntryMode initialMode;
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
  late AuthEntryMode _mode;
  bool _isPasswordVisible = false;
  bool _isPhoneBusy = false;
  bool _isResendingEmail = false;
  _SignupAuthAction? _activeAction;
  String? _errorMessage;
  String? _pendingEmail;
  String? _verificationMessage;
  String? _verificationErrorMessage;

  bool get _isBusy =>
      _activeAction != null || _isPhoneBusy || _isResendingEmail;
  bool get _isEmailLoading => _activeAction == _SignupAuthAction.email;
  bool get _isGoogleLoading => _activeAction == _SignupAuthAction.google;

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
    return email.contains('@') && email.contains('.') && email.length >= 5;
  }

  bool get _isPasswordValid => _passwordController.text.length >= 6;
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

  void _goBack(BuildContext context) {
    if (_isBusy) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.auth.path);
    }
  }

  void _returnToSignupForm() {
    if (_isBusy) return;
    setState(() {
      _pendingEmail = null;
      _verificationMessage = null;
      _verificationErrorMessage = null;
    });
  }

  Future<void> _handleSignUp() async {
    if (!_isFormValid || _isBusy) return;

    setState(() {
      _activeAction = _SignupAuthAction.email;
      _errorMessage = null;
    });

    final useCase = widget.signUpWithEmailUseCase;
    if (useCase == null) {
      if (mounted) {
        setState(() {
          _activeAction = null;
          _errorMessage = 'Email signup is unavailable right now.';
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
          widget.onSignUpSuccess?.call(result);
        case SignInFailure(:final message, :final code):
          if (code == 'email_confirmation_required') {
            final canonicalEmail =
                canonicalEmailIdentity(_emailController.text.trim());
            setState(() {
              _pendingEmail = canonicalEmail ??
                  _emailController.text.trim().toLowerCase();
              _verificationMessage = null;
              _verificationErrorMessage = null;
              _errorMessage = null;
            });
          } else {
            setState(() => _errorMessage = message);
          }
        case SignInCancelled():
          break;
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not create the account. Please try again.',
        );
      }
    } finally {
      if (mounted && _activeAction == _SignupAuthAction.email) {
        setState(() => _activeAction = null);
      }
    }
  }

  Future<void> _handleResendEmail() async {
    final pendingEmail = _pendingEmail;
    final useCase = widget.signUpWithEmailUseCase;
    if (pendingEmail == null || useCase == null || _isResendingEmail) return;

    setState(() {
      _isResendingEmail = true;
      _verificationMessage = null;
      _verificationErrorMessage = null;
    });

    try {
      await useCase.resendConfirmation(email: pendingEmail);
      if (!mounted) return;
      setState(() {
        _verificationMessage =
            'If this account is waiting for verification, a new email has been requested.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verificationErrorMessage =
            'Could not resend the verification email. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isResendingEmail = false);
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
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Google signup could not be completed.',
        );
      }
    } finally {
      if (mounted && _activeAction == _SignupAuthAction.google) {
        setState(() => _activeAction = null);
      }
    }
  }

  void _handleTruecaller() {
    if (_isBusy) return;
    final callback = widget.onTruecallerClick;
    if (callback != null) {
      callback();
      return;
    }
    setState(() {
      _errorMessage = 'Truecaller signup is not available yet.';
    });
  }

  Widget _buildEmailForm(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TioInput(
          key: const ValueKey('signup-email-input'),
          controller: _emailController,
          onChanged: (_) {},
          label: 'Email',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isBusy,
        ),
        const SizedBox(height: TioSpacing.lg),
        TioInput(
          key: const ValueKey('signup-password-input'),
          controller: _passwordController,
          onChanged: (_) {},
          label: 'Password',
          hint: 'At least 6 characters',
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          enabled: !_isBusy,
          onSubmitted: (_) => _handleSignUp(),
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
        const SizedBox(height: TioSize.dp28),
        TioButton.primary(
          key: const ValueKey('signup-submit-button'),
          label: 'Create Account',
          expand: true,
          loading: _isEmailLoading,
          enabled: _isFormValid && !_isGoogleLoading && !_isPhoneBusy,
          onPressed: _handleSignUp,
        ),
      ],
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colors.outlineStrong.withValues(alpha: TioOpacity.opacity30),
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
            color: colors.outlineStrong.withValues(alpha: TioOpacity.opacity30),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailVerificationView(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      key: const ValueKey('signup-email-verification-view'),
      backgroundColor: colors.background,
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: TioSpacing.sm),
                child: IconButton(
                  key: const ValueKey('signup-verification-back-button'),
                  icon: Icon(
                    Icons.arrow_back,
                    color: colors.textPrimary,
                  ),
                  onPressed: _isBusy ? null : _returnToSignupForm,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.xl,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Semantics(
                      header: true,
                      label: 'Tio',
                      child: ExcludeSemantics(
                        child: Text(
                          'Tio',
                          key: const ValueKey('signup-verification-wordmark'),
                          style: textTheme.displayLarge?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: TioFontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: TioLetterSpacing.negative05,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    Text(
                      'Please verify your email',
                      key: const ValueKey('signup-verification-title'),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.xl),
                    Text(
                      'Check your inbox for a verification link. Open it to confirm your email, then Tio will continue automatically.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.lg),
                    Text(
                      'If you already have a Tio account, use Log In or Forgot Password.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const Spacer(flex: 2),
                    if (_isResendingEmail) ...[
                      SizedBox(
                        width: TioSize.dp22,
                        height: TioSize.dp22,
                        child: CircularProgressIndicator(
                          key: const ValueKey(
                            'signup-verification-resend-progress',
                          ),
                          strokeWidth: TioStroke.width2,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.md),
                    ],
                    TextButton(
                      key: const ValueKey('signup-resend-email'),
                      onPressed: _isBusy ? null : _handleResendEmail,
                      child: const Text('Resend email'),
                    ),
                    if (_verificationMessage != null) ...[
                      const SizedBox(height: TioSpacing.sm),
                      Text(
                        _verificationMessage!,
                        key: const ValueKey('signup-verification-message'),
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (_verificationErrorMessage != null) ...[
                      const SizedBox(height: TioSpacing.sm),
                      Text(
                        _verificationErrorMessage!,
                        key: const ValueKey('signup-verification-error'),
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.danger,
                        ),
                      ),
                    ],
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingEmail != null) {
      return _buildEmailVerificationView(context);
    }

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
                          key: const ValueKey('signup-back-button'),
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textPrimary,
                          ),
                          onPressed: _isBusy ? null : () => _goBack(context),
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
                        if (_mode == AuthEntryMode.phone)
                          PhoneOtpAuthSection(
                            key: const ValueKey('signup-phone-section'),
                            keyPrefix: 'signup',
                            intent: PhoneOtpIntent.signup,
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
                              widget.onSignUpSuccess?.call(result);
                            },
                          )
                        else
                          _buildEmailForm(context),
                        const SizedBox(height: TioSpacing.xl),
                        _buildOrDivider(context),
                        const SizedBox(height: TioSpacing.xl),
                        AuthRoundActions(
                          key: const ValueKey('signup-round-actions'),
                          keyPrefix: 'signup',
                          mode: _mode,
                          googleLoading: _isGoogleLoading,
                          enabled: !_isPhoneBusy && !_isEmailLoading,
                          onGooglePressed: _handleGoogleSignIn,
                          onTruecallerPressed: _handleTruecaller,
                          onModeSwitchPressed: _switchMode,
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
                            : () => context.pushReplacement(
                                  AppRoutes.login.path,
                                ),
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
