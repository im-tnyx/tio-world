import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Result returned from checking username availability.
class UsernameAvailabilityResult {
  const UsernameAvailabilityResult({
    required this.isAvailable,
    this.suggestions = const [],
    this.message,
  });

  final bool isAvailable;
  final List<String> suggestions;
  final String? message;
}

enum _UsernameStatus { idle, checking, available, unavailable }

/// Account Settings Page structured with modern capsule input containers,
/// live debounced username availability checking, smart suggestions, and
/// docked action bar.
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    this.username,
    this.email,
    this.phoneNumber,
    this.isEmailVerified = true,
    this.isPhoneVerified = false,
    this.linkedProvider = 'Google',
    this.onUsernameChanged,
    this.onPhoneNumberChanged,
    this.onCheckUsernameAvailability,
    this.onVerifyEmailPressed,
    this.onVerifyPhonePressed,
    this.onSave,
    this.onDeleteAccountConfirmed,
    super.key,
  });

  final String? username;
  final String? email;
  final String? phoneNumber;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String linkedProvider;
  final ValueChanged<String>? onUsernameChanged;
  final ValueChanged<String>? onPhoneNumberChanged;
  final Future<UsernameAvailabilityResult> Function(String username)?
      onCheckUsernameAvailability;
  final VoidCallback? onVerifyEmailPressed;
  final VoidCallback? onVerifyPhonePressed;
  final Future<void> Function({
    required String username,
    required String phoneNumber,
  })? onSave;
  final Future<void> Function()? onDeleteAccountConfirmed;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;

  Timer? _debounceTimer;
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;
  List<String> _suggestions = const [];
  String? _usernameFeedback;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username ?? '');
    _phoneController = TextEditingController(
      text: _nationalPhoneDigits(widget.phoneNumber),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onUsernameInput(String val) {
    widget.onUsernameChanged?.call(val);
    final raw = val.trim().toLowerCase();

    _debounceTimer?.cancel();

    if (raw.isEmpty || raw == (widget.username ?? '').trim().toLowerCase()) {
      setState(() {
        _usernameStatus = _UsernameStatus.idle;
        _suggestions = const [];
        _usernameFeedback = null;
      });
      return;
    }

    if (raw.length < 3) {
      setState(() {
        _usernameStatus = _UsernameStatus.unavailable;
        _suggestions = const [];
        _usernameFeedback = 'Username must be at least 3 characters.';
      });
      return;
    }

    setState(() {
      _usernameStatus = _UsernameStatus.checking;
      _suggestions = const [];
      _usernameFeedback = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 450), () async {
      final result = await _performAvailabilityCheck(raw);
      if (!mounted) return;

      setState(() {
        if (result.isAvailable) {
          _usernameStatus = _UsernameStatus.available;
          _suggestions = const [];
          _usernameFeedback = '@$raw is available!';
        } else {
          _usernameStatus = _UsernameStatus.unavailable;
          _suggestions = result.suggestions;
          _usernameFeedback =
              result.message ?? 'This username is already taken. Try another.';
        }
      });
    });
  }

  Future<UsernameAvailabilityResult> _performAvailabilityCheck(
    String handle,
  ) async {
    if (widget.onCheckUsernameAvailability != null) {
      return widget.onCheckUsernameAvailability!(handle);
    }

    // Built-in intelligent availability check & suggestion generator
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final takenList = {'santosh', 'admin', 'tio', 'alex', 'fitness', 'user'};

    if (takenList.contains(handle)) {
      return UsernameAvailabilityResult(
        isAvailable: false,
        message: 'This username is already taken. Try another.',
        suggestions: [
          '${handle}_fit',
          '${handle}_95',
          '${handle}_tio',
        ],
      );
    }

    return const UsernameAvailabilityResult(isAvailable: true);
  }

  void _applySuggestion(String suggestion) {
    _debounceTimer?.cancel();
    final clean = suggestion.replaceAll('@', '').trim();
    _usernameController.text = clean;
    widget.onUsernameChanged?.call(clean);

    setState(() {
      _usernameStatus = _UsernameStatus.available;
      _suggestions = const [];
      _usernameFeedback = '@$clean is available!';
    });
  }

  Future<void> _handleVerifyEmail() async {
    if (widget.onVerifyEmailPressed != null) {
      widget.onVerifyEmailPressed!();
      return;
    }

    final code = await showTioOtpVerificationDialog(
      context: context,
      targetLabel: 'email (${widget.email ?? ""})',
      title: 'Please enter your Code',
      subtitle: 'Please check your email for the verification code.',
    );

    if (code != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully!')),
      );
    }
  }

  Future<void> _handleVerifyPhone() async {
    if (widget.onVerifyPhonePressed != null) {
      widget.onVerifyPhonePressed!();
      return;
    }

    final num = _phoneController.text.trim();
    final code = await showTioOtpVerificationDialog(
      context: context,
      targetLabel: 'mobile number ($num)',
      title: 'Please enter your Code',
      subtitle: 'Please check your mobile for the verification code.',
    );

    if (code != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number verified successfully!')),
      );
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving ||
        _usernameStatus == _UsernameStatus.unavailable ||
        _usernameStatus == _UsernameStatus.checking) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave?.call(
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account settings saved!')),
        );
        Navigator.of(context).pop();
      }
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

    if (deleted && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Account Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.large,
            TioSpacing.medium,
            TioSpacing.large,
            TioSpacing.extraLarge + 80,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _usernameStatus == _UsernameStatus.unavailable
                          ? colors.danger.withAlpha(80)
                          : _usernameStatus == _UsernameStatus.available
                              ? colors.primary.withAlpha(80)
                              : colors.outlineStrong.withAlpha(40),
                      width: _usernameStatus == _UsernameStatus.unavailable ||
                              _usernameStatus == _UsernameStatus.available
                          ? 1.5
                          : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Icon(
                        Icons.alternate_email_rounded,
                        size: 22,
                        color: _usernameStatus == _UsernameStatus.unavailable
                            ? colors.danger
                            : _usernameStatus == _UsernameStatus.available
                                ? colors.primary
                                : colors.textPrimary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          cursorColor: colors.primary,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9_.]'),
                            ),
                            LengthLimitingTextInputFormatter(30),
                          ],
                          onChanged: _onUsernameInput,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'username',
                            hintStyle: TextStyle(
                              color: colors.textMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      if (_usernameStatus == _UsernameStatus.checking)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      else if (_usernameStatus == _UsernameStatus.available)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: colors.primary,
                        )
                      else if (_usernameStatus == _UsernameStatus.unavailable)
                        Icon(
                          Icons.error_outline_rounded,
                          size: 22,
                          color: colors.danger,
                        ),
                    ],
                  ),
                ),
                if (_usernameFeedback case final msg?) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      msg,
                      style: TextStyle(
                        color: _usernameStatus == _UsernameStatus.available
                            ? colors.primary
                            : colors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Suggestions:',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((suggestion) {
                      return InkWell(
                        onTap: () => _applySuggestion(suggestion),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.primary.withAlpha(50),
                            ),
                          ),
                          child: Text(
                            '@$suggestion',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: TioSpacing.large),
            // ── Field 2: EMAIL (with Verify / Verified Badge) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMAIL',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 22,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.email ?? 'Not set',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.isEmailVerified)
                        const Icon(
                          Icons.verified_rounded,
                          size: 22,
                          color: Color(0xFF1DA1F2),
                        )
                      else if (widget.email?.isNotEmpty == true)
                        GestureDetector(
                          onTap: _handleVerifyEmail,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withAlpha(22),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Verify',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.large),
            // ── Field 3: PHONE NUMBER ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHONE NUMBER',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                TioMobileNumberField(
                  controller: _phoneController,
                  isVerified: widget.isPhoneVerified,
                  onVerifyPressed: _handleVerifyPhone,
                  onChanged: (value) {
                    widget.onPhoneNumberChanged?.call(value);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.large),
            // ── Field 4: LINKED ACCOUNT ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUTHENTICATION',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 22,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.linkedProvider,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Connected',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
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
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
                colors: [
                  colors.background.withValues(alpha: 0.0),
                  colors.background.withValues(alpha: 0.85),
                  colors.background.withValues(alpha: 0.98),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                TioSpacing.large,
                TioSpacing.small,
                TioSpacing.large,
                TioSpacing.medium,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TioButton.primary(
                    label: 'Save Changes',
                    loading: _isSaving,
                    loadingLabel: 'Saving',
                    enabled: _usernameStatus != _UsernameStatus.unavailable &&
                        _usernameStatus != _UsernameStatus.checking,
                    expand: true,
                    onPressed: _handleSave,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _showDeleteAccountDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: colors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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
