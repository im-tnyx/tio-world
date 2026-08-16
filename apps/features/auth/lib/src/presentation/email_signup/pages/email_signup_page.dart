import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

/// Clean, modern Sign Up screen aligned with Tnyx-Hub authentication design.
///
/// Supports conditional social buttons:
/// - When [showSocialButtons] is false (e.g. pushed from mid-flow AuthLandingPage),
///   it presents a clean, focused Email + Password creation form.
/// - When [showSocialButtons] is true, it includes Google and Truecaller options.
class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({
    this.signUpWithEmailUseCase,
    this.signInWithGoogleUseCase,
    this.googleAuthUseCase,
    this.onSignUpSuccess,
    this.onAuthSuccess,
    this.onTruecallerClick,
    this.showSocialButtons = false,
    super.key,
  });

  final SignUpWithEmailUseCase? signUpWithEmailUseCase;
  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final GoogleAuthUseCase? googleAuthUseCase;
  final ValueChanged<SignInSuccess>? onSignUpSuccess;
  final ValueChanged<GoogleAuthComplete>? onAuthSuccess;
  final VoidCallback? onTruecallerClick;
  final bool showSocialButtons;

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends State<EmailSignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  TioUsernameStatus _usernameStatus = TioUsernameStatus.idle;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<UsernameAvailabilityResult> _checkUsernameAvailability(String handle) async {
    try {
      final client = Supabase.instance.client;
      final row = await client
          .from('users')
          .select('id')
          .eq('username', handle)
          .maybeSingle();

      if (row == null) {
        return const UsernameAvailabilityResult(isAvailable: true);
      } else {
        final year = DateTime.now().year % 100;
        return UsernameAvailabilityResult(
          isAvailable: false,
          suggestions: [
            '${handle}_fit',
            '${handle}_$year',
            '${handle}_tio',
          ],
          message: 'This username is already taken. Try another:',
        );
      }
    } catch (_) {
      return const UsernameAvailabilityResult(isAvailable: true);
    }
  }

  bool get _isUsernameValid {
    final username = _usernameController.text.trim();
    return username.isEmpty ||
        (_usernameStatus != TioUsernameStatus.unavailable &&
            _usernameStatus != TioUsernameStatus.checking);
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.') && email.length >= 5;
  }

  bool get _isPasswordValid => _passwordController.text.length >= 6;
  bool get _isFormValid => _isEmailValid && _isPasswordValid && _isUsernameValid;

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

  Future<void> _handleSignUp() async {
    if (!_isFormValid || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.signUpWithEmailUseCase == null) {
      await _navigateOnAuthSuccess();
      return;
    }

    try {
      final username = _usernameController.text.trim();
      final result = await widget.signUpWithEmailUseCase!(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: username.isNotEmpty ? username : null,
      );
      if (!mounted) return;
      switch (result) {
        case SignInSuccess():
          widget.onSignUpSuccess?.call(result);
          await _navigateOnAuthSuccess(result.session.userId);
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
      if (mounted) setState(() => _isLoading = false);
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
          setState(() => _errorMessage = result.message);
        }
      } else if (widget.googleAuthUseCase != null) {
        final result = await widget.googleAuthUseCase!();
        if (!mounted) return;
        if (result is GoogleAuthComplete) {
          widget.onAuthSuccess?.call(result);
          await _navigateOnAuthSuccess(result.session.userId);
          return;
        } else if (result is GoogleAuthFailed) {
          setState(() => _errorMessage = result.message);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top App Bar (100% Identical alignment with OnboardingTopBar & Login)
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
                          key: const ValueKey('signup-back-button'),
                          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                          onPressed: () {
                            if (!_isLoading) {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.auth.path);
                              }
                            }
                          },
                        ),
                        const SizedBox(width: TioSpacing.small),
                        Text(
                          'Sign Up',
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

                        // Reusable TioUsernameInputField Component from tio_core
                        TioUsernameInputField(
                          key: const ValueKey('signup-username-input'),
                          controller: _usernameController,
                          enabled: !_isLoading,
                          onStatusChanged: (status) {
                            if (mounted) setState(() => _usernameStatus = status);
                          },
                          onCheckAvailability: _checkUsernameAvailability,
                        ),

                        const SizedBox(height: TioSpacing.large),

                        // Email Input Field
                        TextField(
                          key: const ValueKey('signup-email-input'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined, color: colors.textMuted, size: 20),
                            labelStyle: TextStyle(color: colors.textMuted),
                            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.6)),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioSpacing.large,
                              vertical: TioSpacing.large - 2,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(color: colors.outlineStrong.withValues(alpha: 0.4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(color: colors.outlineStrong.withValues(alpha: 0.4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(color: colors.primary, width: 2),
                            ),
                            filled: false,
                          ),
                        ),

                        const SizedBox(height: TioSpacing.large),

                        // Password Input Field
                        TextField(
                          key: const ValueKey('signup-password-input'),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          enabled: !_isLoading,
                          style: TextStyle(color: colors.textPrimary),
                          onSubmitted: (_) => _handleSignUp(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'At least 6 characters',
                            prefixIcon: Icon(Icons.lock_outline, color: colors.textMuted, size: 20),
                            labelStyle: TextStyle(color: colors.textMuted),
                            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.6)),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioSpacing.large,
                              vertical: TioSpacing.large - 2,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(color: colors.outlineStrong.withValues(alpha: 0.4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(color: colors.outlineStrong.withValues(alpha: 0.4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(TioRadius.large),
                              borderSide: BorderSide(color: colors.primary, width: 2),
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

                        const SizedBox(height: 28),

                        // Create Account Action Button (Reusable TioButton Component)
                        TioButton.primary(
                          key: const ValueKey('signup-submit-button'),
                          label: 'Create Account',
                          expand: true,
                          loading: _isLoading,
                          enabled: _isFormValid,
                          onPressed: _handleSignUp,
                        ),

                        // Conditional Social Buttons
                        if (widget.showSocialButtons) ...[
                          const SizedBox(height: 24),
                          _OrDivider(colors: colors),
                          const SizedBox(height: 24),
                          TioSocialButton.google(
                            key: const ValueKey('signup-google-button'),
                            loading: _isLoading,
                            onPressed: _handleGoogleSignIn,
                          ),
                          const SizedBox(height: 12),
                          TioSocialButton.truecaller(
                            key: const ValueKey('signup-truecaller-button'),
                            loading: false,
                            onPressed: widget.onTruecallerClick ?? () {},
                          ),
                        ],

                        const SizedBox(height: TioSpacing.extraLarge + TioSpacing.small),
                      ],
                    ),
                  ),
                ),

                // Footer: Already have an account? Log In
                Padding(
                  padding: const EdgeInsets.only(bottom: TioSpacing.large, top: TioSpacing.small),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('signup-login-link'),
                        onPressed: () {
                          if (!_isLoading) {
                            context.pushReplacement(AppRoutes.emailLogin.path);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Log In',
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

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.colors});
  final TioColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: colors.outlineStrong.withValues(alpha: 0.3)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: colors.outlineStrong.withValues(alpha: 0.3)),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (message.toLowerCase().contains('already registered') ||
                message.toLowerCase().contains('log in')) ...[
              const SizedBox(width: TioSpacing.small),
              TextButton(
                onPressed: () {
                  onDismiss();
                  context.pushReplacement(AppRoutes.emailLogin.path);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withAlpha(50),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TioRadius.small),
                  ),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              const SizedBox(width: TioSpacing.small),
            ],
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
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
