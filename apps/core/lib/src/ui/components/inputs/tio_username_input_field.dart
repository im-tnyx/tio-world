import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

const int tioUsernameMinLength = 3;
const int tioUsernameMaxLength = 30;

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

enum TioUsernameStatus { idle, checking, available, unavailable }

/// Reusable Username input field following AGENTS.md design tokens:
/// - Canonical lowercase input with a 3-30 character contract
/// - Live debounced availability check
/// - Suggestion pills that are rechecked before becoming available
/// - Suffix status indicators (Checking spinner, Available check, Unavailable warning)
/// - Reused across Username setup, Account Settings, and Profile Editing screens
class TioUsernameInputField extends StatefulWidget {
  const TioUsernameInputField({
    required this.controller,
    super.key,
    this.currentUsername,
    this.onChanged,
    this.onStatusChanged,
    this.onCheckAvailability,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.labelText = 'Username',
    this.hintText = 'e.g. santosh_99',
  });

  final TextEditingController controller;
  final String? currentUsername;
  final ValueChanged<String>? onChanged;
  final ValueChanged<TioUsernameStatus>? onStatusChanged;
  final Future<UsernameAvailabilityResult> Function(String username)?
      onCheckAvailability;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String labelText;
  final String hintText;

  @override
  State<TioUsernameInputField> createState() => _TioUsernameInputFieldState();
}

class _TioUsernameInputFieldState extends State<TioUsernameInputField> {
  Timer? _debounceTimer;
  TioUsernameStatus _status = TioUsernameStatus.idle;
  List<String> _suggestions = const [];
  String? _feedbackMessage;
  int _availabilityGeneration = 0;

  String get _normalizedCurrentUsername =>
      (widget.currentUsername ?? '').trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    final initial = widget.controller.text.trim().toLowerCase();
    if (initial.isNotEmpty && initial == _normalizedCurrentUsername) {
      _status = TioUsernameStatus.available;
    }
  }

  @override
  void dispose() {
    _cancelPendingCheck();
    super.dispose();
  }

  void _cancelPendingCheck() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _availabilityGeneration++;
  }

  void _onInputChanged(String value) {
    final raw = value.trim().toLowerCase();
    widget.onChanged?.call(raw);
    _cancelPendingCheck();

    if (raw.isEmpty) {
      _updateState(
        status: TioUsernameStatus.idle,
        suggestions: const [],
        feedback: null,
      );
      return;
    }

    if (raw == _normalizedCurrentUsername && raw.isNotEmpty) {
      _updateState(
        status: TioUsernameStatus.available,
        suggestions: const [],
        feedback: null,
      );
      return;
    }

    if (raw.length < tioUsernameMinLength) {
      _updateState(
        status: TioUsernameStatus.unavailable,
        suggestions: const [],
        feedback:
            'Username must be at least $tioUsernameMinLength characters.',
      );
      return;
    }

    if (raw.length > tioUsernameMaxLength) {
      _updateState(
        status: TioUsernameStatus.unavailable,
        suggestions: const [],
        feedback:
            'Username must be at most $tioUsernameMaxLength characters.',
      );
      return;
    }

    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(raw)) {
      _updateState(
        status: TioUsernameStatus.unavailable,
        suggestions: const [],
        feedback:
            'Only lowercase letters, numbers, underscores and dots allowed.',
      );
      return;
    }

    _scheduleAvailabilityCheck(raw);
  }

  void _scheduleAvailabilityCheck(String handle) {
    _updateState(
      status: TioUsernameStatus.checking,
      suggestions: const [],
      feedback: null,
    );

    final generation = ++_availabilityGeneration;
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final result = await _checkAvailability(handle);
      if (!mounted || generation != _availabilityGeneration) return;

      final current = widget.controller.text.trim().toLowerCase();
      if (current != handle) return;

      if (result.isAvailable) {
        _updateState(
          status: TioUsernameStatus.available,
          suggestions: const [],
          feedback: '@$handle is available!',
        );
      } else {
        _updateState(
          status: TioUsernameStatus.unavailable,
          suggestions: result.suggestions,
          feedback:
              result.message ?? 'This username is already taken. Try another:',
        );
      }
    });
  }

  Future<UsernameAvailabilityResult> _checkAvailability(String handle) async {
    if (widget.onCheckAvailability != null) {
      return widget.onCheckAvailability!(handle);
    }

    return const UsernameAvailabilityResult(
      isAvailable: false,
      message: 'Username availability could not be verified.',
    );
  }

  void _applySuggestion(String suggestion) {
    _cancelPendingCheck();
    final clean = suggestion.replaceAll('@', '').trim().toLowerCase();
    if (clean.isEmpty) return;

    widget.controller.value = TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );
    widget.onChanged?.call(clean);
    _onInputChanged(clean);
  }

  void _updateState({
    required TioUsernameStatus status,
    required List<String> suggestions,
    required String? feedback,
  }) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _suggestions = suggestions;
      _feedbackMessage = feedback;
    });
    widget.onStatusChanged?.call(status);
  }

  Widget? _buildSuffixIcon(TioColors colors) {
    switch (_status) {
      case TioUsernameStatus.checking:
        return const SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case TioUsernameStatus.available:
        return Icon(Icons.check_circle_rounded, color: colors.success, size: 20);
      case TioUsernameStatus.unavailable:
        return Icon(Icons.error_outline_rounded, color: colors.danger, size: 20);
      case TioUsernameStatus.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const ValueKey('tio-username-input'),
          controller: widget.controller,
          keyboardType: TextInputType.text,
          textInputAction: widget.textInputAction,
          enabled: widget.enabled,
          inputFormatters: [
            const _LowercaseTextInputFormatter(),
            LengthLimitingTextInputFormatter(tioUsernameMaxLength),
          ],
          onChanged: _onInputChanged,
          onSubmitted: widget.onSubmitted,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon:
                Icon(Icons.alternate_email, color: colors.textMuted, size: 20),
            suffixIcon: _buildSuffixIcon(colors),
            labelStyle: TextStyle(color: colors.textMuted),
            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.large,
              vertical: TioSpacing.large - 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TioRadius.large),
              borderSide: BorderSide(
                color: _status == TioUsernameStatus.unavailable
                    ? colors.danger
                    : colors.outlineStrong.withValues(alpha: 0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TioRadius.large),
              borderSide: BorderSide(
                color: _status == TioUsernameStatus.unavailable
                    ? colors.danger
                    : colors.outlineStrong.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TioRadius.large),
              borderSide: BorderSide(
                color: _status == TioUsernameStatus.unavailable
                    ? colors.danger
                    : colors.primary,
                width: 2,
              ),
            ),
            filled: false,
          ),
        ),
        if (_feedbackMessage != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _feedbackMessage!,
              style: TextStyle(
                color: _status == TioUsernameStatus.available
                    ? colors.success
                    : _status == TioUsernameStatus.unavailable
                        ? colors.danger
                        : colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
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
                      color: colors.primary.withAlpha(80),
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
    );
  }
}

class _LowercaseTextInputFormatter extends TextInputFormatter {
  const _LowercaseTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lower = newValue.text.toLowerCase();
    if (lower == newValue.text) return newValue;
    return newValue.copyWith(text: lower);
  }
}
