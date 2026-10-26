import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/body_setup.dart';

/// Progress-owned composition; the Core wheel and editor own reusable visuals.
/// Uploading photos is a separately gated private-media slice.
Future<bool?> showProgressWeightLogSheet({
  required BuildContext context,
  required WeightUnit unit,
  required double? currentWeightKg,
  required ValueListenable<bool> sessionActive,
  required Future<void> Function(BodyWeightRecord) onSubmit,
  DateTime Function()? now,
}) =>
    showTioEditorSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isDismissible: false,
      builder: (context) => _ProgressWeightLogSheet(
        unit: unit,
        initialKg: currentWeightKg,
        sessionActive: sessionActive,
        onSubmit: onSubmit,
        now: now ?? DateTime.now,
      ),
    );

class _ProgressWeightLogSheet extends StatefulWidget {
  const _ProgressWeightLogSheet({
    required this.unit,
    required this.initialKg,
    required this.sessionActive,
    required this.onSubmit,
    required this.now,
  });

  final WeightUnit unit;
  final double? initialKg;
  final ValueListenable<bool> sessionActive;
  final Future<void> Function(BodyWeightRecord) onSubmit;
  final DateTime Function() now;

  @override
  State<_ProgressWeightLogSheet> createState() => _ProgressWeightLogSheetState();
}

class _ProgressWeightLogSheetState extends State<_ProgressWeightLogSheet>
    with WidgetsBindingObserver {
  static const _minKg = 30.0;
  static const _maxKg = 200.0;

  late double _weightKg;
  late DateTime _measuredLocal;
  late String _submissionId;
  late final TextEditingController _noteController;

  final _dateTimeAnchorKey = GlobalKey();
  late DateTime _maximumLocal;
  bool _dateTimePickerOpen = false;
  bool _noteVisible = false;
  // A wheel placeholder is not a user-entered measurement. History-derived
  // values are trusted only if they fit this wheel's supported range.
  bool _weightConfirmed = false;
  bool _saving = false;
  bool _attempted = false;
  // Once any request outcome is UNKNOWN, a later definite rejection of a
  // retry cannot prove the earlier request did not commit.
  bool _hasUnknownOutcome = false;
  bool _dismissQueued = false;
  ModalRoute<dynamic>? _sheetRoute;
  NavigatorState? _sheetNavigator;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialKg;
    _weightConfirmed = initial != null &&
        initial.isFinite &&
        initial >= _minKg &&
        initial <= _maxKg;
    // Keep a visible wheel position without treating it as the first log.
    // Out-of-range historical measurements are not silently re-recorded as
    // the nearest wheel bound, either.
    _weightKg = _weightConfirmed ? initial! : 70.0;
    _measuredLocal = widget.now().toLocal();
    _maximumLocal = widget.now().toLocal();
    WidgetsBinding.instance.addObserver(this);
    _submissionId = _newUuid();
    _noteController = TextEditingController();
    widget.sessionActive.addListener(_onSessionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Session invalidation can arrive while this element is deactivating.
    // Resolve route and navigator while the inherited context is still safe.
    _sheetRoute = ModalRoute.of(context);
    _sheetNavigator = Navigator.of(context);
  }

  void _onSessionChanged() {
    if (widget.sessionActive.value || _dismissQueued) return;
    _dismissQueued = true;
    // Deactivation can be triggered by disposal while Flutter builds a new
    // owner/login cycle. Remove this exact modal after the frame; do not pop
    // an unrelated top route or leave a blank barrier covering the app.
    // Core's anchored DateTime picker is an OverlayPortal descendant of
    // this sheet, not a separate route. Removing only the sheet route also
    // disposes the draft-owned overlay without touching unrelated routes.
    final sheetRoute = _sheetRoute;
    final navigator = _sheetNavigator;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || navigator == null || !navigator.mounted) return;
      if (sheetRoute != null && sheetRoute.isActive) {
        navigator.removeRoute(sheetRoute);
      }
    });
  }

  /// RFC 4122 version-4 UUID from OS-backed cryptographic random bytes.
  /// One ID belongs to one immutable attempted draft, including retries.
  static String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  @override
  void dispose() {
    widget.sessionActive.removeListener(_onSessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    _noteController.dispose();
    super.dispose();
  }

  void _openDateTimePicker() {
    if (_attempted || _saving || !widget.sessionActive.value) return;
    // Closing the editing keyboard first gives the popup the usable viewport
    // above the pinned footer, as in Nutrition's Quick Add editor.
    FocusScope.of(context).unfocus();
    final current = widget.now().toLocal();
    setState(() {
      _maximumLocal = current;
      if (_measuredLocal.isAfter(current)) _measuredLocal = current;
      _dateTimePickerOpen = true;
      _error = null;
    });
  }

  void _closeDateTimePicker() {
    if (!_dateTimePickerOpen || !mounted) return;
    setState(() => _dateTimePickerOpen = false);
  }

  void _refreshDateTimeMaximum() {
    if (!mounted || !_dateTimePickerOpen || !widget.sessionActive.value) {
      return;
    }
    final current = widget.now().toLocal();
    setState(() {
      _maximumLocal = current;
      if (_measuredLocal.isAfter(current)) _measuredLocal = current;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDateTimeMaximum();
  }

  DateTime _resolveDateTime(DateTime candidate) {
    final current = widget.now().toLocal();
    return candidate.isAfter(current) ? current : candidate;
  }

  void _onDateTimeChanged(DateTime selected) {
    if (!mounted || _saving || _attempted || !widget.sessionActive.value) {
      return;
    }
    setState(() {
      _measuredLocal = _resolveDateTime(selected);
      _maximumLocal = widget.now().toLocal();
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !widget.sessionActive.value) return;
    if (!_weightConfirmed) {
      setState(() => _error = 'Confirm your weight before saving.');
      return;
    }
    final now = widget.now().toUtc();
    if (!_weightKg.isFinite ||
        _weightKg < _minKg ||
        _weightKg > _maxKg) {
      setState(() => _error = 'Choose a valid weight.');
      return;
    }
    if (_measuredLocal.toUtc().isAfter(now)) {
      setState(() => _error = 'Measurement time cannot be in the future.');
      return;
    }
    final rawNote = _noteController.text.trim();
    if (rawNote.characters.length > 500) {
      setState(() => _error = 'Notes must be 500 characters or fewer.');
      return;
    }

    final record = BodyWeightRecord(
      submissionId: _submissionId,
      weightKg: _weightKg,
      measuredAt: _measuredLocal.toUtc(),
      source: BodyWeightSources.manual,
      note: rawNote.isEmpty ? null : rawNote,
    );
    setState(() {
      _saving = true;
      _attempted = true; // No draft mutations after ambiguous remote writes.
      _error = null;
    });
    try {
      await widget.onSubmit(record);
      if (!mounted) return;
      if (!widget.sessionActive.value) {
        Navigator.of(context).pop(false);
        return;
      }
      Navigator.of(context).pop(true);
    } on BodyWeightSubmissionRejected {
      if (!mounted || !widget.sessionActive.value) return;
      setState(() {
        _saving = false;
        // Only a *first* proven no-write result may unlock corrections and
        // Close. An earlier UNKNOWN still requires same-UUID reconciliation.
        if (!_hasUnknownOutcome) _attempted = false;
        _error = _hasUnknownOutcome
            ? 'Save not confirmed. Retry this same entry before closing.'
            : 'Weight was not saved. Check your entry or close.';
      });
    } catch (_) {
      if (!mounted || !widget.sessionActive.value) return;
      setState(() {
        _saving = false;
        _hasUnknownOutcome = true;
        _error = 'Save not confirmed. Retry this same entry before closing.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.sessionActive,
      builder: (context, active, _) {
        if (!active) {
          // Dismissed session: never render another owner's health draft.
          return const SizedBox.shrink();
        }
        final colors = context.tioColors;
        final typography = Theme.of(context).textTheme;
        return PopScope(
          // Unknown writes must retain the same UUID for a safe retry.
          // Never let Close/Back create a fresh draft with a new UUID.
          canPop: !_attempted && !_saving && !_dateTimePickerOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _dateTimePickerOpen) _closeDateTimePicker();
          },
          child: TioDateTimePickerPopup(
            anchorKey: _dateTimeAnchorKey,
            isOpen: _dateTimePickerOpen,
            onDismiss: _closeDateTimePicker,
            value: _measuredLocal,
            minimumDate: DateTime(1900),
            maximumDate: _maximumLocal,
            resolveDateTime: _resolveDateTime,
            onChanged: _onDateTimeChanged,
            onPickerInteractionStart: _refreshDateTimeMaximum,
            child: TioEditorSheet(
          title: 'Log Weight',
          flushActions: true,
          canDismiss: !_attempted && !_saving,
          titleTrailing: IconButton(
            key: const ValueKey('progress-log-close'),
            tooltip: 'Close Log Weight',
            onPressed: (_saving || _attempted)
                 ? null
                 : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unit selection is global, not another mutable option here.
              Text(
                widget.unit == WeightUnit.lb ? 'Weight (lb)' : 'Weight (kg)',
                key: const ValueKey('progress-log-weight-unit-label'),
                style: typography.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: TioSpacing.sm),
              IgnorePointer(
                ignoring: _attempted,
                child: TioWeightWheel(
                key: const ValueKey('progress-log-wheel'),
                valueKg: _weightKg,
                unit: widget.unit,
                showUnitSwitcher: false,
                minKg: _minKg,
                maxKg: _maxKg,
                onChanged: (kg) {
                  if (_attempted) return;
                  setState(() {
                    _weightKg = kg;
                    _error = null;
                  });
                },
                ),
              ),
              if (!_weightConfirmed) ...[
                const SizedBox(height: TioSpacing.sm),
                Text(
                  'Confirm the wheel value to use it as your measurement.',
                  style: typography.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: TioSpacing.sm),
                TioButton.supporting(
                  key: const ValueKey('progress-log-confirm-weight'),
                  label: 'Use selected weight',
                  onPressed: _attempted
                      ? null
                      : () => setState(() {
                          _weightConfirmed = true;
                          _error = null;
                        }),
                ),
              ],
              if (_noteVisible) ...[
                const SizedBox(height: TioSpacing.sm),
                TioInput.multiline(
                  key: const ValueKey('progress-log-note-field'),
                  controller: _noteController,
                  onChanged: (_) {},
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !_attempted,
                  hint: 'Add a note about this measurement',
                ),
              ],
              if (_attempted && !_saving) ...[
                const SizedBox(height: TioSpacing.sm),
                Text(
                  'Details are locked until this submission is confirmed. '
                  'Keep this sheet open and retry; the entry ID is unchanged.',
                  style: typography.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: TioSpacing.sm),
                Text(
                  _error!,
                  style: typography.bodySmall?.copyWith(color: colors.danger),
                ),
              ],
            ],
          ),
          actions: TioEditorActionFooter(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const ValueKey('progress-log-note-toggle'),
                  tooltip: _noteVisible ? 'Hide note' : 'Add note',
                  onPressed: _attempted || _saving
                      ? null
                      : () => setState(() => _noteVisible = !_noteVisible),
                  icon: Icon(
                    _noteVisible ? Icons.edit_note : Icons.notes_outlined,
                  ),
                ),
                const Tooltip(
                  message: 'Photos available in a later private-media update',
                  child: IconButton(
                    key: ValueKey('progress-log-photo-later'),
                    tooltip: 'Photos coming later',
                    onPressed: null,
                    icon: Icon(Icons.add_photo_alternate_outlined),
                  ),
                ),
              ],
            ),
            trailing: KeyedSubtree(
              key: _dateTimeAnchorKey,
              child: TioEditorFooterAction(
                controlKey: const ValueKey('progress-log-date-time'),
                semanticLabel: 'Change measurement date and time',
                onTap: _attempted || _saving ? null : _openDateTimePicker,
                builder: (context, textStyle, iconColor) {
                  final localizations = MaterialLocalizations.of(context);
                  final dateTimeLabel =
                      '${localizations.formatShortMonthDay(_measuredLocal)}, '
                      '${_measuredLocal.hour.toString().padLeft(2, '0')}:'
                      '${_measuredLocal.minute.toString().padLeft(2, '0')}';
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/svg_icon/ic_calendar_1.svg',
                        package: 'tio_core',
                        width: TioSize.dp20,
                        height: TioSize.dp20,
                        colorFilter: ColorFilter.mode(
                          iconColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: TioSpacing.sm),
                      Flexible(
                        child: Text(
                          dateTimeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            primary: TioButton.primary(
              key: const ValueKey('progress-log-save'),
              label: _attempted ? 'Retry Log Weight' : 'Save Weight',
              onPressed: (_saving || (!_attempted && !_weightConfirmed))
                  ? null
                  : _save,
              loading: _saving,
              expand: true,
            ),
          ),
          ),
        );
      },
    );
  }
}
