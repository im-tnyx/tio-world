import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

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
/// - Live debounced availability check
/// - Smart suggestion pills with tap-to-autofill
/// - Suffix status indicators (Checking spinner, Available check, Unavailable warning)
/// - Reused across Sign Up, Account Settings, and Profile Editing screens
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
  final Future<UsernameAvailabilityResult> Function(String username)? onCheckAvailability;
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

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isNotEmpty &&
        widget.controller.text.trim().toLowerCase() == (widget.currentUsername ?? '').trim().toLowerCase()) {
      _status = TioUsernameStatus.available;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onInputChanged(String val) {
    widget.onChanged?.call(val);
    final raw = val.trim().toLowerCase();
    _debounceTimer?.cancel();

    if (raw.isEmpty || raw == (widget.currentUsername ?? '').trim().toLowerCase()) {
      _updateState(
        status: TioUsernameStatus.idle,
        suggestions: const [],
        feedback: null,
      );
      return;
    }

    if (raw.length < 3) {
      _updateState(
        status: TioUsernameStatus.unavailable,
        suggestions: const [],
        feedback: 'Username must be at least 3 characters.',
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(raw)) {
      _updateState(
        status: TioUsernameStatus.unavailable,
        suggestions: const [],
        feedback: 'Only letters, numbers, underscores and dots allowed.',
      );
      return;
    }

    _updateState(
      status: TioUsernameStatus.checking,
      suggestions: const [],
      feedback: null,
    );

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final result = await _checkAvailability(raw);
      if (!mounted) return;

      if (result.isAvailable) {
        _updateState(
          status: TioUsernameStatus.available,
          suggestions: const [],
          feedback: '@$raw is available!',
        );
      } else {
        _updateState(
          status: TioUsernameStatus.unavailable,
          suggestions: result.suggestions,
          feedback: result.message ?? 'This username is already taken. Try another:',
        );
      }
    });
  }

  Future<UsernameAvailabilityResult> _checkAvailability(String handle) async {
    if (widget.onCheckAvailability != null) {
      return widget.onCheckAvailability!(handle);
    }

    // Default intelligent suggestion fallback
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

  void _applySuggestion(String suggestion) {
    _debounceTimer?.cancel();
    final clean = suggestion.replaceAll('@', '').trim();
    widget.controller.text = clean;
    widget.onChanged?.call(clean);

    _updateState(
      status: TioUsernameStatus.available,
      suggestions: const [],
      feedback: '@$clean is available!',
    );
  }

  void _updateState({
    required TioUsernameStatus status,
    required List<String> suggestions,
    required String? feedback,
  }) {
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
          onChanged: _onInputChanged,
          onSubmitted: widget.onSubmitted,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: Icon(Icons.alternate_email, color: colors.textMuted, size: 20),
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
