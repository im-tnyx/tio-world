import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/repositories/profile_account_repository.dart';

class UsernameSetupPage extends StatefulWidget {
  const UsernameSetupPage({
    required this.repository,
    required this.onCompleted,
    this.onBack,
    super.key,
  });

  final ProfileAccountRepository repository;
  final Future<void> Function() onCompleted;
  final Future<void> Function()? onBack;

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final TextEditingController _usernameController = TextEditingController();
  TioUsernameStatus _status = TioUsernameStatus.idle;
  bool _saving = false;
  String? _saveError;
  int _availabilityRefreshToken = 0;

  @override
  void dispose() {
    _usernameController.dispose();
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

  Future<void> _handleBack() async {
    if (_saving) return;
    final onBack = widget.onBack;
    if (onBack != null) {
      await onBack();
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).maybePop();
  }

  Future<void> _save() async {
    if (_saving || _status != TioUsernameStatus.available) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await widget.repository.updateUsername(_usernameController.text);
      if (!mounted) return;
      await widget.onCompleted();
    } on UsernameUnavailableException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = TioUsernameStatus.unavailable;
        _saveError = _saveConflictMessage(error);
        _availabilityRefreshToken++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError = 'Could not save your username. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.tioColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
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
                      key: const ValueKey('username-setup-back-button'),
                      icon: Icon(
                        Icons.arrow_back,
                        color: colors.textPrimary,
                        size: 24,
                      ),
                      onPressed: _saving ? null : _handleBack,
                    ),
                    const SizedBox(width: TioSpacing.small),
                    Text(
                      'Username',
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
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('username-setup-content'),
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.large,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: TioSpacing.large),
                      Text(
                        'Choose your username',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.small),
                      Text(
                        'Your username is your unique public Tio handle. You can use lowercase letters, numbers, dots, and underscores.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.extraLarge),
                      TioUsernameInputField(
                        controller: _usernameController,
                        enabled: !_saving,
                        textInputAction: TextInputAction.done,
                        onCheckAvailability: _checkAvailability,
                        availabilityRefreshToken: _availabilityRefreshToken,
                        onChanged: (_) {
                          if (_saveError == null || !mounted) return;
                          setState(() => _saveError = null);
                        },
                        onStatusChanged: (status) {
                          if (!mounted) return;
                          setState(() => _status = status);
                        },
                        onSubmitted: (_) => _save(),
                      ),
                      if (_saveError != null) ...[
                        const SizedBox(height: TioSpacing.medium),
                        Text(
                          _saveError!,
                          key: const ValueKey('username-setup-error'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: TioSpacing.extraLarge),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              key: const ValueKey('username-setup-footer'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.large,
                TioSpacing.small,
                TioSpacing.large,
                TioSpacing.large,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineStrong.withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Username is required before continuing.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.small),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('username-setup-continue'),
                          onPressed:
                              _status == TioUsernameStatus.available && !_saving
                                  ? _save
                                  : null,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
