import 'dart:math';

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

class _ProgressWeightLogSheetState extends State<_ProgressWeightLogSheet> {
  static const _minKg = 30.0;
  static const _maxKg = 200.0;

  late double _weightKg;
  late DateTime _measuredLocal;
  late String _submissionId;
  late final TextEditingController _noteController;

  bool _noteVisible = false;
  bool _saving = false;
  bool _attempted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weightKg = (widget.initialKg ?? 70.0).clamp(_minKg, _maxKg).toDouble();
    _measuredLocal = widget.now().toLocal();
    _submissionId = _newUuid();
    _noteController = TextEditingController();
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
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_attempted || _saving || !widget.sessionActive.value) return;
    final today = widget.now().toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: _measuredLocal,
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (date == null || !mounted || !widget.sessionActive.value) return;
    setState(() {
      _measuredLocal = DateTime(
        date.year, date.month, date.day,
        _measuredLocal.hour, _measuredLocal.minute,
      );
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    if (_attempted || _saving || !widget.sessionActive.value) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredLocal),
    );
    if (time == null || !mounted || !widget.sessionActive.value) return;
    setState(() {
      _measuredLocal = DateTime(
        _measuredLocal.year, _measuredLocal.month, _measuredLocal.day,
        time.hour, time.minute,
      );
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !widget.sessionActive.value) return;
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
    final rawNote = _noteVisible ? _noteController.text.trim() : '';
    if (rawNote.length > 500) {
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
    } catch (_) {
      if (!mounted || !widget.sessionActive.value) return;
      setState(() {
        _saving = false;
        _error = 'Save not confirmed. Retry this same entry; no duplicate will be created.';
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
        return TioEditorSheet(
          title: 'Log Weight',
          canDismiss: !_saving,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: TioSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TioButton.supporting(
                      key: const ValueKey('progress-log-date'),
                      label: MaterialLocalizations.of(context)
                          .formatMediumDate(_measuredLocal),
                      onPressed: _attempted ? null : _pickDate,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Expanded(
                    child: TioButton.supporting(
                      key: const ValueKey('progress-log-time'),
                      label: TimeOfDay.fromDateTime(_measuredLocal).format(context),
                      onPressed: _attempted ? null : _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TioSpacing.md),
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('progress-log-note-toggle'),
                    tooltip: _noteVisible ? 'Hide note' : 'Add note',
                    onPressed: _attempted
                        ? null
                        : () => setState(() => _noteVisible = !_noteVisible),
                    icon: Icon(_noteVisible ? Icons.edit_note : Icons.notes_outlined),
                  ),
                  const Text('Note (optional)'),
                  const Spacer(),
                  Tooltip(
                    message: 'Photos available in a later private-media update',
                    child: IconButton(
                      key: const ValueKey('progress-log-photo-later'),
                      tooltip: 'Photos coming later',
                      onPressed: null,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                    ),
                  ),
                ],
              ),
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
                  'Details are locked until this submission is confirmed.',
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
          actions: TioButton.primary(
            key: const ValueKey('progress-log-save'),
            label: _attempted ? 'Retry Log Weight' : 'Save Weight',
            onPressed: _saving ? null : _save,
            loading: _saving,
            expand: true,
          ),
        );
      },
    );
  }
}
