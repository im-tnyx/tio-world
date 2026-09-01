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

/// Visual contract for [TioUsernameInputField].
enum TioUsernameFieldAppearance {
  /// Floating-label outlined field. Current default, matching Account Setup.
  outlined,

  /// Fixed-height filled capsule row with an externally-supplied label,
  /// matching the same shape [TioMobileNumberField] already uses. Evidenced
  /// by Account Settings.
  capsule,
}

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
    this.availabilityRefreshToken = 0,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.labelText = 'Username',
    this.hintText = 'e.g. your.name',
    this.appearance = TioUsernameFieldAppearance.outlined,
    this.extraInputFormatters,
  });

  final TextEditingController controller;
  final String? currentUsername;
  final ValueChanged<String>? onChanged;
  final ValueChanged<TioUsernameStatus>? onStatusChanged;
  final Future<UsernameAvailabilityResult> Function(String username)?
      onCheckAvailability;

  /// Increment to invalidate the current availability result and recheck the
  /// controller value. Used after a persistence race or server policy change.
  final int availabilityRefreshToken;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String labelText;
  final String hintText;

  /// Visual contract. Defaults to [TioUsernameFieldAppearance.outlined],
  /// preserving current Account Setup behavior exactly.
  final TioUsernameFieldAppearance appearance;

  /// Additional formatters applied after the built-in lowercase and
  /// max-length formatters, e.g. a character allow-list. Plumbing only: core
  /// enforces no character policy of its own beyond lowercase/length: this is
  /// how Account Settings preserves its keystroke-level character filtering
  /// without forcing it onto every consumer.
  final List<TextInputFormatter>? extraInputFormatters;

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
  void didUpdateWidget(covariant TioUsernameInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availabilityRefreshToken != widget.availabilityRefreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onInputChanged(widget.controller.text, notifyChanged: false);
      });
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

  void _onInputChanged(String value, {bool notifyChanged = true}) {
    final raw = value.trim().toLowerCase();
    if (notifyChanged) widget.onChanged?.call(raw);
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
        feedback: 'Username must be at least $tioUsernameMinLength characters.',
      );
      return;
    }

    if (raw.length > tioUsernameMaxLength) {
      _updateState(
        status: TioUsernameStatus.unavailable,
        suggestions: const [],
        feedback: 'Username must be at most $tioUsernameMaxLength characters.',
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

  Widget? _buildOutlinedSuffixIcon(TioColors colors) {
    switch (_status) {
      case TioUsernameStatus.checking:
        return const SizedBox(
          width: TioInputTokens.usernameIconSize,
          height: TioInputTokens.usernameIconSize,
          child: Center(
            child: SizedBox(
              width: TioInputTokens.usernameCheckingIndicatorSize,
              height: TioInputTokens.usernameCheckingIndicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: TioInputTokens.usernameCheckingStrokeWidth,
              ),
            ),
          ),
        );
      case TioUsernameStatus.available:
        return Icon(
          Icons.check_circle_rounded,
          color: colors.success,
          size: TioInputTokens.usernameIconSize,
        );
      case TioUsernameStatus.unavailable:
        return Icon(
          Icons.error_outline_rounded,
          color: colors.danger,
          size: TioInputTokens.usernameIconSize,
        );
      case TioUsernameStatus.idle:
        return null;
    }
  }

  /// Suggestion pills, shared by both appearances. Only the border alpha and
  /// the optional "Suggestions:" caption are evidenced as appearance-specific
  /// -- everything else (radius, padding, font, tap behavior) is identical.
  Widget _buildSuggestions(
    TioColors colors, {
    required int borderAlpha,
    required bool showCaption,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCaption) ...[
          Text(
            'Suggestions:',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size12,
              fontWeight: TioFontWeight.w600,
            ),
          ),
          const SizedBox(height: TioSize.dp6),
        ],
        Wrap(
          spacing: TioSpacing.sm,
          runSpacing: TioSpacing.sm,
          children: _suggestions.map((suggestion) {
            return InkWell(
              onTap: () => _applySuggestion(suggestion),
              borderRadius: BorderRadius.circular(
                TioInputTokens.usernameSuggestionRadius,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.md,
                  vertical: TioInputTokens.usernameSuggestionVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(
                    TioInputTokens.usernameSuggestionRadius,
                  ),
                  border: Border.all(
                    color: colors.primary.withAlpha(borderAlpha),
                  ),
                ),
                child: Text(
                  '@$suggestion',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: TioInputTokens.usernameSuggestionFontSize,
                    fontWeight: TioFontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return switch (widget.appearance) {
      TioUsernameFieldAppearance.outlined => _buildOutlined(colors),
      TioUsernameFieldAppearance.capsule => _buildCapsule(colors),
    };
  }

  Widget _buildOutlined(TioColors colors) {
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
            ...?widget.extraInputFormatters,
          ],
          onChanged: _onInputChanged,
          onSubmitted: widget.onSubmitted,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: Icon(
              Icons.alternate_email,
              color: colors.textMuted,
              size: TioInputTokens.usernameIconSize,
            ),
            suffixIcon: _buildOutlinedSuffixIcon(colors),
            labelStyle: TextStyle(color: colors.textMuted),
            hintStyle: TextStyle(
              color: colors.textMuted.withValues(
                alpha: TioInputTokens.usernameHintOpacity,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TioInputTokens.horizontalPadding,
              vertical: TioInputTokens.usernameContentVerticalPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TioRadius.lg),
              borderSide: BorderSide(
                color: _status == TioUsernameStatus.unavailable
                    ? colors.danger
                    : colors.outlineStrong.withValues(
                        alpha: TioInputTokens.usernameOutlineOpacity,
                      ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TioRadius.lg),
              borderSide: BorderSide(
                color: _status == TioUsernameStatus.unavailable
                    ? colors.danger
                    : colors.outlineStrong.withValues(
                        alpha: TioInputTokens.usernameOutlineOpacity,
                      ),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TioRadius.lg),
              borderSide: BorderSide(
                color: _status == TioUsernameStatus.unavailable
                    ? colors.danger
                    : colors.primary,
                width: TioInputTokens.usernameFocusedOutlineWidth,
              ),
            ),
            filled: false,
          ),
        ),
        if (_feedbackMessage != null) ...[
          const SizedBox(height: TioInputTokens.usernameSupportingGap),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.xs,
            ),
            child: Text(
              _feedbackMessage!,
              style: TextStyle(
                color: _status == TioUsernameStatus.available
                    ? colors.success
                    : _status == TioUsernameStatus.unavailable
                        ? colors.danger
                        : colors.textMuted,
                fontSize: TioInputTokens.usernameFeedbackFontSize,
                fontWeight: TioFontWeight.w600,
              ),
            ),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: TioInputTokens.usernameSupportingGap),
          _buildSuggestions(
            colors,
            borderAlpha: TioInputTokens.usernameSuggestionOutlineAlpha,
            showCaption: false,
          ),
        ],
      ],
    );
  }

  /// Fixed-height filled capsule row, evidenced by Account Settings and
  /// matching [TioMobileNumberField]'s existing structure: an outer
  /// decorated [Container] with a borderless, transparent inner [TextField]
  /// -- not Material's own [InputDecoration] border/fill system. The
  /// external label ("USERNAME") stays page-owned, matching the current
  /// Account Settings composition; this appearance renders no floating
  /// label of its own.
  Widget _buildCapsule(TioColors colors) {
    final isUnavailable = _status == TioUsernameStatus.unavailable;
    final isAvailable = _status == TioUsernameStatus.available;
    final borderColor = isUnavailable
        ? colors.danger
        : isAvailable
            ? colors.primary
            : colors.outlineStrong;
    final borderAlpha = (isUnavailable || isAvailable)
        ? TioInputTokens.usernameCapsuleStatusBorderAlpha
        : TioInputTokens.usernameCapsuleNormalBorderAlpha;
    final borderWidth = (isUnavailable || isAvailable)
        ? TioInputTokens.usernameCapsuleStatusBorderWidth
        : TioInputTokens.usernameCapsuleNormalBorderWidth;
    final iconColor = isUnavailable
        ? colors.danger
        : isAvailable
            ? colors.primary
            : colors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: TioInputTokens.usernameCapsuleHeight,
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(TioRadius.lg),
            border: Border.all(
              color: borderColor.withAlpha(borderAlpha),
              width: borderWidth,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
          alignment: Alignment.center,
          child: Row(
            children: [
              Icon(
                Icons.alternate_email_rounded,
                size: TioInputTokens.usernameCapsuleIconSize,
                color: iconColor,
              ),
              const SizedBox(width: TioInputTokens.usernameCapsuleIconGap),
              Expanded(
                child: TextField(
                  key: const ValueKey('tio-username-input'),
                  controller: widget.controller,
                  keyboardType: TextInputType.text,
                  textInputAction: widget.textInputAction,
                  enabled: widget.enabled,
                  cursorColor: colors.primary,
                  inputFormatters: [
                    const _LowercaseTextInputFormatter(),
                    LengthLimitingTextInputFormatter(tioUsernameMaxLength),
                    ...?widget.extraInputFormatters,
                  ],
                  onChanged: _onInputChanged,
                  onSubmitted: widget.onSubmitted,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: TioInputTokens.usernameCapsuleTextFontSize,
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
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: colors.textMuted,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                ),
              ),
              switch (_status) {
                TioUsernameStatus.checking => SizedBox(
                    width: TioInputTokens.usernameCapsuleCheckingIndicatorSize,
                    height: TioInputTokens.usernameCapsuleCheckingIndicatorSize,
                    child: CircularProgressIndicator(
                      strokeWidth: TioInputTokens.usernameCheckingStrokeWidth,
                      color: colors.primary,
                    ),
                  ),
                TioUsernameStatus.available => Icon(
                    Icons.check_circle_rounded,
                    size: TioInputTokens.usernameCapsuleIconSize,
                    color: colors.primary,
                  ),
                TioUsernameStatus.unavailable => Icon(
                    Icons.error_outline_rounded,
                    size: TioInputTokens.usernameCapsuleIconSize,
                    color: colors.danger,
                  ),
                TioUsernameStatus.idle => const SizedBox.shrink(),
              },
            ],
          ),
        ),
        if (_feedbackMessage != null) ...[
          const SizedBox(height: TioSize.dp6),
          Padding(
            padding: const EdgeInsets.only(left: TioSpacing.xs),
            child: Text(
              _feedbackMessage!,
              style: TextStyle(
                color: isAvailable ? colors.primary : colors.danger,
                fontSize: TioInputTokens.usernameCapsuleFeedbackFontSize,
                fontWeight: TioFontWeight.w500,
              ),
            ),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: TioSize.dp10),
          Padding(
            padding: const EdgeInsets.only(left: TioSpacing.xs),
            child: _buildSuggestions(
              colors,
              borderAlpha: TioInputTokens.usernameCapsuleSuggestionOutlineAlpha,
              showCaption: true,
            ),
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
