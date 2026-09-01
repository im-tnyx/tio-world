import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../google_identity_link_controller.dart';

const _googleEmailMismatchGuardMessage =
    'Use the Google account matching your Tio email.';
const _googleEmailMismatchUserMessage =
    'Google account doesn’t match. Please choose the Google account with the same email as your Tio account.';
const _googleConnectGenericError =
    'Could not connect Google. Please try again.';

/// Account Settings Page structured with modern capsule input containers,
/// live debounced username availability checking, smart suggestions, and
/// docked action bar.
class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({
    this.username,
    this.email,
    this.phoneNumber,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.linkedProvider = '',
    this.onUsernameChanged,
    this.onPhoneNumberChanged,
    this.onCheckUsernameAvailability,
    this.onVerifyEmailPressed,
    this.onVerifyPhonePressed,
    this.onSave,
    this.onDeleteAccountConfirmed,
    this.onAccountDeleted,
    super.key,
  });

  final String? username;
  final String? email;
  final String? phoneNumber;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  /// Provider-truth label supplied by app composition.
  ///
  /// The Google row derives `Connected` only when this evidence contains an
  /// actual Google identity. Email or Phone verification never implies Google.
  final String linkedProvider;
  final ValueChanged<String>? onUsernameChanged;
  final ValueChanged<String>? onPhoneNumberChanged;
  final Future<UsernameAvailabilityResult> Function(String username)?
      onCheckUsernameAvailability;

  /// Returns true only after real provider-backed verification succeeds.
  final Future<bool> Function(String email)? onVerifyEmailPressed;

  /// Returns true only after real provider-backed verification succeeds.
  final Future<bool> Function(String phoneNumber)? onVerifyPhonePressed;

  final Future<void> Function({
    required String username,
    required String phoneNumber,
  })? onSave;

  /// Performs irreversible server-side deletion only.
  final Future<void> Function()? onDeleteAccountConfirmed;

  /// Runs only after the user closes the confirmed `Account Deleted` state.
  final Future<void> Function()? onAccountDeleted;

  @override
  ConsumerState<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  TioUsernameStatus _usernameStatus = TioUsernameStatus.idle;
  int _usernameAvailabilityRefreshToken = 0;
  String? _verifiedEmail;
  String? _verifiedPhoneDigits;

  bool _isSaving = false;
  bool _isLinkingGoogle = false;
  bool _googleConnected = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _phoneController = TextEditingController(
      text: _nationalPhoneDigits(widget.phoneNumber),
    );
    if (widget.isEmailVerified) {
      _verifiedEmail = _normalizedEmail(widget.email);
    }
    if (widget.isPhoneVerified) {
      _verifiedPhoneDigits = _nationalPhoneDigits(widget.phoneNumber);
    }
    _googleConnected = _linkedProviderContainsGoogle(widget.linkedProvider);
  }

  @override
  void didUpdateWidget(covariant AccountSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEmailVerified && widget.email != oldWidget.email) {
      final verifiedEmail = _normalizedEmail(widget.email);
      _verifiedEmail = verifiedEmail;
      _emailController.text = widget.email ?? '';
    }
    if (widget.isPhoneVerified && widget.phoneNumber != oldWidget.phoneNumber) {
      final verifiedDigits = _nationalPhoneDigits(widget.phoneNumber);
      _verifiedPhoneDigits = verifiedDigits;
      _phoneController.text = verifiedDigits;
    }
    if (widget.linkedProvider != oldWidget.linkedProvider) {
      _googleConnected = _linkedProviderContainsGoogle(widget.linkedProvider);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _emailChanged =>
      _normalizedEmail(_emailController.text) != _normalizedEmail(widget.email);

  bool get _isCurrentEmailVerified {
    final current = _normalizedEmail(_emailController.text);
    if (current == null) return false;
    if (_verifiedEmail == current) return true;
    return widget.isEmailVerified && !_emailChanged;
  }

  bool get _phoneChanged =>
      _nationalPhoneDigits(_phoneController.text) !=
      _nationalPhoneDigits(widget.phoneNumber);

  bool get _isCurrentPhoneVerified {
    final current = _nationalPhoneDigits(_phoneController.text);
    if (current.isEmpty) return false;
    if (_verifiedPhoneDigits == current) return true;
    return widget.isPhoneVerified && !_phoneChanged;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleVerifyEmail() async {
    final email = _emailController.text.trim();
    if (_normalizedEmail(email) == null) {
      _showMessage('Enter an email before verifying it.');
      return;
    }

    final verify = widget.onVerifyEmailPressed;
    if (verify == null) {
      _showMessage('Email verification is unavailable right now.');
      return;
    }

    try {
      final verified = await verify(email);
      if (!verified || !mounted) return;
      setState(() {
        _verifiedEmail = _normalizedEmail(email);
      });
      _showMessage('Email verified successfully!');
    } catch (_) {
      _showMessage('Could not verify email. Please try again.');
    }
  }

  Future<void> _handleVerifyPhone() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      _showMessage('Enter a mobile number before verifying it.');
      return;
    }

    final verify = widget.onVerifyPhonePressed;
    if (verify == null) {
      _showMessage('Phone verification is unavailable right now.');
      return;
    }

    try {
      final verified = await verify(phoneNumber);
      if (!verified || !mounted) return;
      setState(() {
        _verifiedPhoneDigits = _nationalPhoneDigits(phoneNumber);
      });
      _showMessage('Phone number verified successfully!');
    } catch (_) {
      _showMessage('Could not verify phone number. Please try again.');
    }
  }

  Future<void> _handleConnectGoogle() async {
    if (_googleConnected || _isLinkingGoogle) return;

    final controller = ref.read(googleIdentityLinkControllerProvider);
    if (controller == null) {
      _showMessage('Google connection is unavailable right now.');
      return;
    }

    setState(() => _isLinkingGoogle = true);
    try {
      final linked = await controller.linkGoogleIdentity();
      if (!linked || !mounted) return;

      // The controller may return true only after the Auth owner confirms real
      // Google identity evidence for the same canonical UUID.
      setState(() => _googleConnected = true);
      _showMessage('Google connected successfully!');
    } catch (error) {
      _showMessage(_googleConnectFailureMessage(error));
    } finally {
      if (mounted) setState(() => _isLinkingGoogle = false);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving ||
        _usernameStatus == TioUsernameStatus.unavailable ||
        _usernameStatus == TioUsernameStatus.checking) {
      return;
    }

    if (_emailChanged && !_isCurrentEmailVerified) {
      _showMessage('Verify the new email before saving.');
      return;
    }

    if (_phoneChanged && !_isCurrentPhoneVerified) {
      _showMessage('Verify the new phone number before saving.');
      return;
    }

    final onSave = widget.onSave;
    if (onSave == null) {
      _showMessage(
        'Account settings are unavailable right now. Please try again.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await onSave(
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (mounted) {
        _showMessage('Account settings saved!');
        Navigator.of(context).pop();
      }
    } on TioUsernameConflictException catch (error) {
      if (mounted) {
        setState(() {
          _usernameStatus = TioUsernameStatus.unavailable;
          _usernameAvailabilityRefreshToken++;
        });
        _showMessage(error.message);
      }
    } catch (_) {
      _showMessage('Could not save account settings. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final deleted = await showTioDeleteAccountOverlay(
      context: context,
      onDeleteConfirmed: () async {
        await widget.onDeleteAccountConfirmed?.call();
      },
    );

    if (!deleted || !mounted) return;

    final onAccountDeleted = widget.onAccountDeleted;
    if (onAccountDeleted != null) {
      await onAccountDeleted();
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Account Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.md,
            TioSpacing.lg,
            TioSpacing.xl + TioSize.dp80,
          ),
          children: [
            // ── Field 1: USERNAME (Live Availability Check + Suggestions) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USERNAME',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                    fontSize: TioFontSize.size13,
                    letterSpacing: TioLetterSpacing.positive08,
                  ),
                ),
                const SizedBox(height: TioSpacing.sm),
                TioUsernameInputField(
                  controller: _usernameController,
                  currentUsername: widget.username,
                  appearance: TioUsernameFieldAppearance.capsule,
                  hintText: 'username',
                  onCheckAvailability: widget.onCheckUsernameAvailability,
                  availabilityRefreshToken: _usernameAvailabilityRefreshToken,
                  extraInputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9_.]'),
                    ),
                  ],
                  onChanged: widget.onUsernameChanged,
                  onStatusChanged: (status) {
                    if (!mounted) return;
                    setState(() => _usernameStatus = status);
                  },
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            // ── Field 2: EMAIL (editable + trusted Verify / Verified Badge) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMAIL',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                    fontSize: TioFontSize.size13,
                    letterSpacing: TioLetterSpacing.positive08,
                  ),
                ),
                const SizedBox(height: TioSpacing.sm),
                Container(
                  height: TioSize.dp56,
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(TioRadius.lg),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(TioAlpha.alpha40),
                      width: TioStroke.width1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.lg,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: TioSize.dp22,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: TioSize.dp14),
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          cursorColor: colors.primary,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: TioFontSize.size16,
                            fontWeight: TioFontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            fillColor: TioPalette.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'email@example.com',
                            hintStyle: TextStyle(
                              color: colors.textMuted,
                              fontWeight: TioFontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      if (_isCurrentEmailVerified)
                        Icon(
                          Icons.verified_rounded,
                          size: TioSize.dp22,
                          color: colors.info,
                        )
                      else if (_emailController.text.trim().isNotEmpty)
                        GestureDetector(
                          onTap: _handleVerifyEmail,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TioSize.dp10,
                              vertical: TioSize.dp5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withAlpha(TioAlpha.alpha22),
                              borderRadius: BorderRadius.circular(TioRadius.sm),
                            ),
                            child: Text(
                              'Verify',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: TioFontWeight.w700,
                                fontSize: TioFontSize.size12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            // ── Field 3: PHONE NUMBER ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHONE NUMBER',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                    fontSize: TioFontSize.size13,
                    letterSpacing: TioLetterSpacing.positive08,
                  ),
                ),
                const SizedBox(height: TioSpacing.sm),
                TioMobileNumberField(
                  controller: _phoneController,
                  isVerified: _isCurrentPhoneVerified,
                  onVerifyPressed: _handleVerifyPhone,
                  onChanged: (value) {
                    widget.onPhoneNumberChanged?.call(value);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            // ── Field 4: GOOGLE AUTH IDENTITY ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUTHENTICATION',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                    fontSize: TioFontSize.size13,
                    letterSpacing: TioLetterSpacing.positive08,
                  ),
                ),
                const SizedBox(height: TioSpacing.sm),
                Container(
                  height: TioSize.dp56,
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(TioRadius.lg),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(TioAlpha.alpha40),
                      width: TioStroke.width1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.lg,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: TioSize.dp22,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: TioSize.dp14),
                      Expanded(
                        child: Text(
                          'Google',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: TioFontSize.size16,
                            fontWeight: TioFontWeight.w500,
                          ),
                        ),
                      ),
                      if (_googleConnected)
                        Container(
                          key: const ValueKey('google-connected-badge'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: TioSpacing.sm,
                            vertical: TioSize.dp3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withAlpha(TioAlpha.alpha20),
                            borderRadius: BorderRadius.circular(TioSize.dp6),
                          ),
                          child: Text(
                            'Connected',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: TioFontWeight.w700,
                              fontSize: TioFontSize.size11,
                            ),
                          ),
                        )
                      else
                        InkWell(
                          key: const ValueKey('google-connect-action'),
                          onTap: _isLinkingGoogle ? null : _handleConnectGoogle,
                          borderRadius: BorderRadius.circular(TioRadius.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TioSpacing.sm,
                              vertical: TioSize.dp5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withAlpha(TioAlpha.alpha20),
                              borderRadius: BorderRadius.circular(TioRadius.sm),
                            ),
                            child: _isLinkingGoogle
                                ? SizedBox(
                                    width: TioSize.dp16,
                                    height: TioSize.dp16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: TioStroke.width2,
                                      color: colors.primary,
                                    ),
                                  )
                                : Text(
                                    'Connect',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: TioFontWeight.w700,
                                      fontSize: TioFontSize.size11,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: TioSize.dp8,
            sigmaY: TioSize.dp8,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
                colors: [
                  colors.background.withValues(alpha: TioOpacity.opacity0),
                  colors.background.withValues(alpha: TioOpacity.opacity85),
                  colors.background.withValues(alpha: TioOpacity.opacity98),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.sm,
                TioSpacing.lg,
                TioSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TioButton.primary(
                    label: 'Save Changes',
                    loading: _isSaving,
                    loadingLabel: 'Saving',
                    enabled: _usernameStatus != TioUsernameStatus.unavailable &&
                        _usernameStatus != TioUsernameStatus.checking,
                    expand: true,
                    onPressed: _handleSave,
                  ),
                  const SizedBox(height: TioSize.dp6),
                  TextButton(
                    onPressed: _showDeleteAccountDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.danger,
                      padding: const EdgeInsets.symmetric(
                        vertical: TioSpacing.sm,
                      ),
                    ),
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: colors.danger,
                        fontWeight: TioFontWeight.w700,
                        fontSize: TioFontSize.size14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _googleConnectFailureMessage(Object error) {
  if (error is StateError &&
      error.message == _googleEmailMismatchGuardMessage) {
    return _googleEmailMismatchUserMessage;
  }
  return _googleConnectGenericError;
}

bool _linkedProviderContainsGoogle(String value) {
  final providers = value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((part) => part.isNotEmpty)
      .toSet();
  return providers.contains('google');
}

String? _normalizedEmail(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty || !normalized.contains('@')) {
    return null;
  }
  return normalized;
}

String _nationalPhoneDigits(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('91') && digits.length > 10) {
    return digits.substring(2);
  }
  if (digits.length > 10) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}
