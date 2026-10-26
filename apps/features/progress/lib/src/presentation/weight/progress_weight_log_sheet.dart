import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Exact-record editor uses the established Log Weight wheel/date/action shell.
/// The record ID and original metadata are retained by BodyRepository.updateWeightLog.
Future<bool?> showProgressWeightEditSheet({
  required BuildContext context,
  required WeightUnit unit,
  required BodyWeightEntry entry,
  required ValueListenable<bool> sessionActive,
  required Future<bool> Function(BodyWeightLogEdit) onUpdate,
  required Future<bool> Function(String) onDelete,
  DateTime Function()? now,
}) {
  BodyWeightLogIds.requireValid(entry.id!);
  return showTioEditorSheet<bool>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isDismissible: false,
    builder: (context) => _ProgressWeightLogSheet(
      unit: unit,
      initialKg: entry.weightKg,
      editingEntry: entry,
      sessionActive: sessionActive,
      onUpdate: onUpdate,
      onDelete: onDelete,
      now: now ?? DateTime.now,
    ),
  );
}

class _ProgressWeightLogSheet extends StatefulWidget {
  const _ProgressWeightLogSheet({
    required this.unit,
    required this.initialKg,
    required this.sessionActive,
    this.onSubmit,
    this.editingEntry,
    this.onUpdate,
    this.onDelete,
    required this.now,
  });

  final WeightUnit unit;
  final double? initialKg;
  final ValueListenable<bool> sessionActive;
  final Future<void> Function(BodyWeightRecord)? onSubmit;
  final BodyWeightEntry? editingEntry;
  final Future<bool> Function(BodyWeightLogEdit)? onUpdate;
  final Future<bool> Function(String)? onDelete;
  final DateTime Function() now;

  @override
  State<_ProgressWeightLogSheet> createState() => _ProgressWeightLogSheetState();
}

class _ProgressWeightLogSheetState extends State<_ProgressWeightLogSheet>
    with WidgetsBindingObserver {
  static const _minKg = 30.0;
  static const _maxKg = 200.0;

  late double _weightKg;
  late WeightUnit _displayUnit;
  late DateTime _measuredLocal;
  late String _submissionId;
  late final TextEditingController _noteController;
  late final TextEditingController _weightController;
  bool _manualMode = false;
  bool _manualValid = true;
  static final _wordPattern = RegExp(r'\S+');

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
    _displayUnit = widget.unit;
    final initial = widget.initialKg;
    _weightConfirmed = initial != null &&
        initial.isFinite &&
        initial >= _minKg &&
        initial <= _maxKg;
    // Keep a visible wheel position without treating it as the first log.
    // Out-of-range historical measurements are not silently re-recorded as
    // the nearest wheel bound, either.
    _weightKg = _weightConfirmed ? initial! : 70.0;
    _measuredLocal =
        widget.editingEntry?.measuredAt.toLocal() ?? widget.now().toLocal();
    _maximumLocal = widget.now().toLocal();
    WidgetsBinding.instance.addObserver(this);
    _submissionId = _newUuid();
    _noteController = TextEditingController(
      text: widget.editingEntry?.note ?? '',
    );
    _weightController = TextEditingController(text: _weightDisplayValue());
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
    _weightController.dispose();
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

  double _displayWeightKg(double displayValue) =>
      _displayUnit == WeightUnit.kg
          ? displayValue
          : UnitConverters.lbToKg(displayValue);

  String _weightDisplayValue() {
    final display = _displayUnit == WeightUnit.kg
        ? _weightKg
        : UnitConverters.kgToLb(_weightKg);
    return display.toStringAsFixed(1);
  }

  void _onWheelUnitChanged(WeightUnit unit) {
    if (_saving || _attempted || !widget.sessionActive.value) return;
    setState(() {
      _displayUnit = unit;
      _weightController.text = _weightDisplayValue();
    });
  }

  void _toggleWeightInputMode() {
    if (_attempted || _saving || !widget.sessionActive.value) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _manualMode = !_manualMode;
      _manualValid = true;
      _weightController.text = _weightDisplayValue();
      _error = null;
    });
  }

  void _handleManualWeightChanged(String value) {
    if (_attempted || _saving || !widget.sessionActive.value) return;
    final display = double.tryParse(value.trim());
    final kg = display == null ? null : _displayWeightKg(display);
    final valid = kg != null &&
        kg.isFinite &&
        kg >= _minKg &&
        kg <= _maxKg;
    setState(() {
      _manualValid = valid;
      if (valid) {
        _weightKg = kg;
        _weightConfirmed = true;
      }
      _error = null;
    });
  }

  static int _wordCount(String value) =>
      _wordPattern.allMatches(value.trim()).length;

  Future<void> _confirmDelete() async {
    final id = widget.editingEntry?.id;
    if (id == null || widget.onDelete == null ||
        _saving || _attempted || !widget.sessionActive.value) {
      return;
    }
    FocusScope.of(context).unfocus();
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: 'Delete weight log?',
      message: 'Delete only this measurement? Weight summary, graph and '
          'Timeline will refresh. This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      intent: TioConfirmationIntent.destructive,
    );
    if (!mounted || !widget.sessionActive.value || confirmed != true) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // A missing row still calls for a fresh canonical read, not an
      // optimistic local removal or an invented delete-success state.
      await widget.onDelete!(id);
      if (!mounted || !widget.sessionActive.value) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted || !widget.sessionActive.value) return;
      setState(() {
        _saving = false;
        _error = 'Could not delete weight log. Try again.';
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !widget.sessionActive.value) return;
    if (!_weightConfirmed || (_manualMode && !_manualValid)) {
      setState(() => _error = 'Confirm a valid weight before saving.');
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
    if (widget.editingEntry == null &&
        (_wordCount(rawNote) > 100 || rawNote.characters.length > 500)) {
      setState(() => _error = 'Note is too long.');
      return;
    }

    setState(() {
      _saving = true;
      _attempted = true; // No draft mutations after ambiguous remote writes.
      _error = null;
    });
    try {
      final editing = widget.editingEntry;
      if (editing != null) {
        final saved = await widget.onUpdate!(BodyWeightLogEdit(
          id: editing.id!,
          weightKg: _weightKg,
          measuredAt: _measuredLocal.toUtc(),
        ));
        if (!saved) throw const BodyWeightSubmissionRejected();
      } else {
        await widget.onSubmit!(BodyWeightRecord(
          submissionId: _submissionId,
          weightKg: _weightKg,
          measuredAt: _measuredLocal.toUtc(),
          source: BodyWeightSources.manual,
          note: rawNote.isEmpty ? null : rawNote,
        ));
      }
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
            // The raised Weight editor surface is already visible below
            // this overlay. Suppress only the popup shadow's extra layer;
            // preserve the single Core DateTime card and native wheel.
            elevatedCard: false,
            child: TioEditorSheet(
          title: widget.editingEntry == null ? 'Log Weight' : 'Edit Weight',
          flushActions: true,
          canDismiss: !_attempted && !_saving,
          titleTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.editingEntry != null)
                IconButton(
                  key: const ValueKey('progress-edit-delete'),
                  tooltip: 'Delete weight log',
                  onPressed: (_saving || _attempted)
                      ? null : _confirmDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      color: colors.danger),
                ),
              IconButton(
                key: const ValueKey('progress-log-weight-mode-toggle'),
                tooltip: _manualMode ? 'Use weight wheel' : 'Type weight',
                onPressed: _saving || _attempted
                    ? null
                    : _toggleWeightInputMode,
                icon: Icon(_manualMode ? Icons.tune : Icons.keyboard_outlined),
              ),
              IconButton(
                key: const ValueKey('progress-log-close'),
                tooltip: widget.editingEntry == null
                    ? 'Close Log Weight'
                    : 'Close Edit Weight',
                onPressed: (_saving || _attempted)
                    ? null
                    : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The canonical wheel is the default full-height editor.
              // The header keyboard action switches only input mode, not the
              // global kg/lb preference or the canonical storage unit.
              if (_manualMode)
                TioInput.numericEditor(
                  key: const ValueKey('progress-log-manual-weight'),
                  controller: _weightController,
                  autofocus: true,
                  enabled: !_attempted && !_saving,
                  suffixText: _displayUnit == WeightUnit.lb ? 'lb' : 'kg',
                  onChanged: _handleManualWeightChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                )
              else
                IgnorePointer(
                  ignoring: _attempted,
                  child: TioWeightWheel(
                    key: const ValueKey('progress-log-wheel'),
                    valueKg: _weightKg,
                    unit: _displayUnit,
                    showUnitSwitcher: true,
                    onUnitChanged: _onWheelUnitChanged,
                    minKg: _minKg,
                    maxKg: _maxKg,
                    onChanged: (kg) {
                      if (_attempted) return;
                      setState(() {
                        _weightKg = kg;
                        _weightController.text = _weightDisplayValue();
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
              if (widget.editingEntry == null && _noteVisible) ...[
                const SizedBox(height: TioSpacing.sm),
                TioInput.multiline(
                  key: const ValueKey('progress-log-note-field'),
                  controller: _noteController,
                  onChanged: (_) {},
                  minLines: 1,
                  maxLines: 2,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(500),
                    TextInputFormatter.withFunction((oldValue, newValue) =>
                        _wordCount(newValue.text) <= 100
                            ? newValue
                            : oldValue),
                  ],
                  enabled: !_attempted,
                  hint: 'Add a note about this measurement',
                ),
              ],
              // Existing note is read-only on edit, never a new input.
              if (widget.editingEntry != null && _noteVisible) ...[
                const SizedBox(height: TioSpacing.sm),
                Text(
                  widget.editingEntry!.note?.isNotEmpty == true
                      ? widget.editingEntry!.note!
                      : 'No note on this measurement.',
                  key: const ValueKey('progress-edit-note-readonly'),
                  style: typography.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
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
                  tooltip: widget.editingEntry == null
                      ? (_noteVisible ? 'Hide note' : 'Add note')
                      : (_noteVisible ? 'Hide saved note' : 'View saved note'),
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
                semanticLabel:
                    'Measurement date and time: '
                    '${MaterialLocalizations.of(context).formatMediumDate(_measuredLocal)}, '
                    '${TimeOfDay.fromDateTime(_measuredLocal).format(context)}',
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
              label: widget.editingEntry == null
                  ? (_attempted ? 'Retry Log Weight' : 'Save Weight')
                  : (_attempted ? 'Retry Changes' : 'Save Changes'),
              onPressed: (_saving || (!_attempted &&
                  (!_weightConfirmed || (_manualMode && !_manualValid))))
                  ? null
                  : _save,
              loading: _saving,
              expand: true,
            ),
          ),
          ),
          ),
        );
      },
    );
  }
}
