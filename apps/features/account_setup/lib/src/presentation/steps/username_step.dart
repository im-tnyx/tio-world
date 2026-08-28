import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

class UsernameStep extends StatefulWidget {
  const UsernameStep({
    required this.repository,
    required this.initialUsername,
    required this.enabled,
    required this.onCanContinueChanged,
    super.key,
  });

  final ProfileAccountRepository repository;
  final String initialUsername;
  final bool enabled;
  final ValueChanged<bool> onCanContinueChanged;

  @override
  State<UsernameStep> createState() => UsernameStepState();
}

class UsernameStepState extends State<UsernameStep> {
  late final TextEditingController _controller;
  late TioUsernameStatus _status;
  String? _saveError;
  int _availabilityRefreshToken = 0;

  String get username => _controller.text.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
    _status = widget.initialUsername.trim().isEmpty
        ? TioUsernameStatus.idle
        : TioUsernameStatus.available;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCanContinueChanged(_status == TioUsernameStatus.available);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _availabilityMessage(UsernameAvailabilityCheck check) {
    return switch (check.reason) {
      UsernameAvailabilityReason.reserved =>
        'That username is reserved. Try one of these instead:',
      UsernameAvailabilityReason.invalid =>
        'Choose a valid username using lowercase letters, numbers, dots, and underscores.',
      UsernameAvailabilityReason.taken =>
        'This username is already taken. Try one of these instead:',
      UsernameAvailabilityReason.profileMissing ||
      UsernameAvailabilityReason.unknown =>
        'Could not verify this username. Please try again.',
      null => 'This username is unavailable. Please try another.',
    };
  }

  Future<UsernameAvailabilityResult> _checkAvailability(String username) async {
    try {
      final check = await widget.repository.checkUsernameAvailability(username);
      return UsernameAvailabilityResult(
        isAvailable: check.isAvailable,
        suggestions: check.suggestions,
        message: check.isAvailable ? null : _availabilityMessage(check),
      );
    } catch (_) {
      return const UsernameAvailabilityResult(
        isAvailable: false,
        message: 'Could not verify this username. Please try again.',
      );
    }
  }

  String _saveConflictMessage(UsernameUnavailableException error) {
    return switch (error.reason) {
      UsernameAvailabilityReason.reserved =>
        'That username is reserved. Please choose another.',
      UsernameAvailabilityReason.invalid =>
        'That username is no longer valid. Please choose another.',
      _ => 'That username was just taken. Please choose another.',
    };
  }

  Future<bool> submit() async {
    if (_status != TioUsernameStatus.available) return false;

    final normalized = username;
    if (normalized == widget.initialUsername.trim().toLowerCase() &&
        normalized.isNotEmpty) {
      return true;
    }

    setState(() => _saveError = null);
    try {
      await widget.repository.updateUsername(normalized);
      return true;
    } on UsernameUnavailableException catch (error) {
      if (!mounted) return false;
      setState(() {
        _status = TioUsernameStatus.unavailable;
        _saveError = _saveConflictMessage(error);
        _availabilityRefreshToken++;
      });
      widget.onCanContinueChanged(false);
      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _saveError = 'Could not save your username. Please try again.';
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TioScreenHeader(
          title: 'Choose your username',
          subtitle:
              'Your username is your unique public Tio handle. Use lowercase letters, numbers, dots, and underscores.',
        ),
        const SizedBox(height: TioSpacing.lg),
        TioUsernameInputField(
          controller: _controller,
          enabled: widget.enabled,
          textInputAction: TextInputAction.done,
          onCheckAvailability: _checkAvailability,
          availabilityRefreshToken: _availabilityRefreshToken,
          onChanged: (_) {
            if (_saveError != null && mounted) {
              setState(() => _saveError = null);
            }
          },
          onStatusChanged: (status) {
            if (!mounted) return;
            setState(() => _status = status);
            widget.onCanContinueChanged(status == TioUsernameStatus.available);
          },
        ),
        const SizedBox(height: TioSpacing.sm),
        Text(
          'Username is required before continuing.',
          key: const ValueKey('account-setup-username-helper'),
          style: TextStyle(
            color: colors.textMuted,
            fontSize: TioFontSize.size12,
            height: TioLineHeight.height130,
          ),
        ),
        if (_saveError case final error?) ...[
          const SizedBox(height: TioSpacing.md),
          Text(
            error,
            key: const ValueKey('account-setup-username-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: TioFontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
