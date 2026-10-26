import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  final now = DateTime.utc(2026, 10, 26, 10);

  Future<void> pumpPage(
    WidgetTester tester,
    BodyRepository repository, {
    WeightUnit unit = WeightUnit.kg,
    String cycle = 'cycle-one',
    VoidCallback? onWeightLogged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: ProgressWeightPage(
            key: ValueKey(cycle),
            repository: repository,
            unit: unit,
            sessionKey: cycle,
            onWeightLogged: onWeightLogged,
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirmInitialWeight(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('progress-log-confirm-weight'));
    // An actual in-range History weight is already a valid known prefill.
    if (button.evaluate().isEmpty) return;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> tapNoteToggle(WidgetTester tester) async {
    // The Notes action is now pinned below the scrolling editor body.
    final toggle = find.byKey(const ValueKey('progress-log-note-toggle'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }

  testWidgets('Progress shell title is not duplicated below the top bar',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    expect(find.byKey(const ValueKey('progress-weight-heading')), findsNothing);
    expect(find.text('Weight'), findsNothing);
    expect(find.text('Weight summary'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-scroll')), findsOneWidget);
  });

  testWidgets('empty Weight shows truthful first-entry help, no active edit',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    expect(find.text('Weight summary'), findsOneWidget);
    expect(find.text('No measurements in this range'), findsOneWidget);
    expect(find.textContaining('No weight measurements yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-log-action')), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNothing);
  });


  testWidgets('empty History never submits an unacknowledged 70 kg',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('progress-log-confirm-weight')),
        findsOneWidget);
    final save = tester.widget<TioButton>(
      find.byKey(const ValueKey('progress-log-save')),
    );
    expect(save.onPressed, isNull);
    expect(repository.weightEntries, isEmpty);

    // Explicitly acknowledging the visible wheel value is a deliberate
    // measurement, unlike opening and immediately saving the placeholder.
    await confirmInitialWeight(tester);
    expect(
      tester.widget<TioButton>(
        find.byKey(const ValueKey('progress-log-save')),
      ).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.weightKg, closeTo(70, 0.001));
  });

  testWidgets('real in-range History weight prefill remains ready to log',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 73.5,
        measuredAt: now.subtract(const Duration(days: 1)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('progress-log-confirm-weight')),
        findsNothing);
    expect(
      tester.widget<TioButton>(
        find.byKey(const ValueKey('progress-log-save')),
      ).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(2));
    expect(repository.weightEntries.last.weightKg, closeTo(73.5, 0.001));
  });

  testWidgets('out-of-range historical weight cannot silently save clamp',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 250,
        measuredAt: now.subtract(const Duration(days: 1)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('progress-log-confirm-weight')),
        findsOneWidget);
    expect(
      tester.widget<TioButton>(
        find.byKey(const ValueKey('progress-log-save')),
      ).onPressed,
      isNull,
    );
    expect(repository.weightEntries, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('progress-log-close')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries.single.weightKg, 250);
  });

  testWidgets('Log sheet reuses wheel; Notes icon alone expands text field',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsOneWidget);
    expect(find.text('Weight (kg)'), findsNothing);
    expect(find.byKey(const ValueKey('progress-log-weight-unit-label')),
        findsNothing);
    expect(find.byKey(const ValueKey('progress-log-weight-mode-toggle')),
        findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('progress-log-wheel'))).height,
      TioWheelPickerTokens.viewportHeight,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('progress-log-weight-mode-toggle')))
          .right,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const ValueKey('progress-log-close'))).left,
      ),
    );
    expect(find.byKey(const ValueKey('progress-log-note-field')), findsNothing);
    final photo = tester.widget<IconButton>(
      find.byKey(const ValueKey('progress-log-photo-later')),
    );
    expect(photo.onPressed, isNull);
    await tapNoteToggle(tester);
    expect(find.byKey(const ValueKey('progress-log-note-field')), findsOneWidget);
  });

  testWidgets('reusable Notes starts one line and grows to two without count',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tapNoteToggle(tester);
    final input = tester.widget<TioInput>(
      find.byKey(const ValueKey('progress-log-note-field')),
    );
    expect(input.minLines, 1);
    expect(input.maxLines, 2);
    expect(input.maxLength, isNull);
    expect(find.text('0/500'), findsNothing);
    final editor = find.descendant(
      of: find.byKey(const ValueKey('progress-log-note-field')),
      matching: find.byType(EditableText),
    );
    final hundred = List.filled(100, 'a').join(' ');
    await tester.enterText(editor, hundred);
    expect(tester.widget<EditableText>(editor).controller.text, hundred);
    await tester.enterText(editor, '$hundred extra');
    expect(tester.widget<EditableText>(editor).controller.text, hundred);
    await tester.enterText(editor, 'First line\nSecond line');
    expect(tester.widget<EditableText>(editor).controller.text,
        'First line\nSecond line');
  });

  testWidgets('pencil allows bounded manual kg entry then restores full wheel',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    final pencil = find.byKey(
      const ValueKey('progress-log-weight-mode-toggle'),
    );
    await tester.tap(pencil);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-manual-weight')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsNothing);
    final manual = find.descendant(
      of: find.byKey(const ValueKey('progress-log-manual-weight')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(manual, '5');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TioButton>(find.byKey(const ValueKey('progress-log-save')))
          .onPressed,
      isNull,
    );
    await tester.enterText(manual, '72.5');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TioButton>(find.byKey(const ValueKey('progress-log-save')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(pencil);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('progress-log-wheel'))).height,
      TioWheelPickerTokens.viewportHeight,
    );
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries.single.weightKg, closeTo(72.5, 0.01));
  });

  testWidgets('manual entry honors lb preference but stores kg',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository, unit: WeightUnit.lb);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
      const ValueKey('progress-log-weight-mode-toggle'),
    ));
    await tester.pumpAndSettle();
    final manualInput = tester.widget<TioInput>(
      find.byKey(const ValueKey('progress-log-manual-weight')),
    );
    expect(manualInput.suffixText, 'lb');
    // Initial 70 kg placeholder formats as 154.3 lb. Unchanged placeholder
    // must not silently count as a first measurement; edit a real value.
    expect(
      tester.widget<TioButton>(
        find.byKey(const ValueKey('progress-log-save')),
      ).onPressed,
      isNull,
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('progress-log-manual-weight')),
        matching: find.byType(EditableText),
      ),
      '155.0',
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('progress-log-save'));
    expect(tester.widget<TioButton>(save).onPressed, isNotNull);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.weightKg, closeTo(UnitConverters.lbToKg(155), 0.01));
  });

  testWidgets('opening DateTime from Notes dismisses keyboard, keeps note',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tapNoteToggle(tester);
    final note = find.descendant(
      of: find.byKey(const ValueKey('progress-log-note-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(note, 'After keyboard entry');
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(const ValueKey('progress-log-date-time')));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.byKey(const ValueKey('tio-date-time-picker-popup')),
        findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries.single.note, 'After keyboard entry');
  });

  testWidgets('pinned footer uses one anchored DateTime popup',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('progress-log-date')), findsNothing);
    expect(find.byKey(const ValueKey('progress-log-time')), findsNothing);
    expect(find.byKey(const ValueKey('progress-log-date-time')), findsOneWidget);
    expect(find.byType(TioEditorActionFooter), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-log-photo-later')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('progress-log-date-time')));
    await tester.pumpAndSettle();
    final picker = tester.widget<TioDateTimeWheelPicker>(
      find.byType(TioDateTimeWheelPicker),
    );
    expect(picker.maximumDate, now.toLocal());
    expect(picker.minimumDate, DateTime(1900));
    expect(picker.value, now.toLocal());
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.byType(TimePickerDialog), findsNothing);
  });

  testWidgets('popup date/time selection persists canonical UTC Weight entry',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-date-time')));
    await tester.pumpAndSettle();

    final selected = now.toLocal().subtract(
      const Duration(days: 2, minutes: 15),
    );
    tester.widget<TioDateTimeWheelPicker>(
      find.byType(TioDateTimeWheelPicker),
    ).onChanged(selected);
    await tester.pumpAndSettle();
    // The wheel cannot select a future actual measurement.
    tester.widget<TioDateTimeWheelPicker>(
      find.byType(TioDateTimeWheelPicker),
    ).onChanged(now.toLocal().add(const Duration(days: 1)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TioDateTimeWheelPicker>(
        find.byType(TioDateTimeWheelPicker),
      ).value.isAfter(now.toLocal()),
      isFalse,
    );
    tester.widget<TioDateTimeWheelPicker>(
      find.byType(TioDateTimeWheelPicker),
    ).onChanged(selected);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-date-time-picker-popup')),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.measuredAt.isUtc, isTrue);
    expect(repository.weightEntries.single.measuredAt, selected.toUtc());
  });

  testWidgets('disposing Weight page with open Log sheet is lifecycle-safe',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsOneWidget);

    // Regression: the page invalidates its session as Flutter unmounts the
    // navigator tree. The sheet listener must not ask its deactivated BuildContext
    // for ModalRoute/Navigator ancestors during that notification.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('A3 optional note persists on Save and History refreshes',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tapNoteToggle(tester);
    final field = find.descendant(
      of: find.byKey(const ValueKey('progress-log-note-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(field, 'Morning check-in');
    await tester.ensureVisible(find.byKey(const ValueKey('progress-log-save')));
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.note, 'Morning check-in');
    expect(repository.weightEntries.single.source, BodyWeightSources.manual);
    expect(find.text('Morning check-in'), findsOneWidget);
  });


  testWidgets('collapsing notes field preserves its typed text on Save',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tapNoteToggle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('progress-log-note-field')),
        matching: find.byType(EditableText),
      ),
      '  After the run  ',
    );
    await tapNoteToggle(tester);
    expect(find.byKey(const ValueKey('progress-log-note-field')), findsNothing);
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries.single.note, 'After the run');
    expect(find.text('After the run'), findsOneWidget);
  });

  testWidgets('300 emoji graphemes save as 300 visible characters',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tapNoteToggle(tester);
    final message = List.filled(300, '😀').join();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('progress-log-note-field')),
        matching: find.byType(EditableText),
      ),
      message,
    );
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.note, message);
  });

  testWidgets('ambiguous failed submission retries same ID exactly once',
      (tester) async {
    final repository = _AmbiguousSaveWeightRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(find.textContaining('Save not confirmed'), findsOneWidget);
    expect(find.textContaining('Details are locked'), findsOneWidget);
    expect(
      tester.widget<IconButton>(
        find.byKey(const ValueKey('progress-log-close')),
      ).onPressed,
      isNull,
    );
    // An UNKNOWN result must not be dismissed and reopened with a new UUID.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    expect(repository.weightEntries, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.attempts, 2);
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsNothing);
  });


  testWidgets('definitive rejection leaves draft editable and allows Close',
      (tester) async {
    final repository = _DefinitelyRejectedWeightRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();

    expect(repository.attempts, 1);
    expect(repository.weightEntries, isEmpty);
    expect(find.textContaining('Weight was not saved'), findsOneWidget);
    expect(find.textContaining('Details are locked'), findsNothing);
    expect(
      tester.widget<IconButton>(
        find.byKey(const ValueKey('progress-log-close')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<TioButton>(
        find.byKey(const ValueKey('progress-log-save')),
      ).label,
      'Save Weight',
    );
    await tapNoteToggle(tester);
    expect(find.byKey(const ValueKey('progress-log-note-field')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-log-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(repository.weightEntries, isEmpty);
  });

  testWidgets('definite retry rejection does not unlock earlier UNKNOWN',
      (tester) async {
    final repository = _UnknownThenRejectedWeightRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Save not confirmed'), findsOneWidget);
    expect(repository.weightEntries, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.attempts, 2);
    expect(find.textContaining('Save not confirmed'), findsOneWidget);
    expect(find.textContaining('Details are locked'), findsOneWidget);
    expect(
      tester.widget<IconButton>(
        find.byKey(const ValueKey('progress-log-close')),
      ).onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    expect(repository.weightEntries, hasLength(1));
  });

  testWidgets('Back and barrier cannot close while weight save is in flight',
      (tester) async {
    final repository = _DelayedSaveRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pump();
    // A pending save has a stable operation ID and must retain its modal.
    await tester.tapAt(const Offset(1, 1));
    await tester.pump();
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    repository.release.complete();
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsNothing);
  });

  testWidgets('confirmed save notifies owning app composition exactly once',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    var invalidations = 0;
    await pumpPage(
      tester,
      repository,
      onWeightLogged: () => invalidations++,
    );
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(invalidations, 1);
    expect(repository.weightEntries, hasLength(1));
  });

  testWidgets('lb wheel displays 154.3 then saves matching canonical 70 kg',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository, unit: WeightUnit.lb);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    final wheel = tester.widget<TioWeightWheel>(
      find.byKey(const ValueKey('progress-log-wheel')),
    );
    expect(wheel.unit, WeightUnit.lb);
    expect(wheel.showUnitSwitcher, isFalse);
    expect(find.text('Weight (lb)'), findsNothing);
    final drums = find.descendant(
      of: find.byKey(const ValueKey('progress-log-wheel')),
      matching: find.byType(ListWheelScrollView),
    );
    expect(drums, findsNWidgets(2));
    final whole = tester.widget<ListWheelScrollView>(drums.at(0)).controller!
        as FixedExtentScrollController;
    final decimal = tester.widget<ListWheelScrollView>(drums.at(1)).controller!
        as FixedExtentScrollController;
    expect(whole.selectedItem, 154 - 66);
    expect(decimal.selectedItem, 3);
    await confirmInitialWeight(tester);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.weightKg, closeTo(70, 0.001));
  });

  testWidgets('shows measured Current Weight and global pounds preference',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 70,
        measuredAt: now.subtract(const Duration(days: 3)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository, unit: WeightUnit.lb);
    expect(find.text('154.3 lb'), findsWidgets);
    expect(find.text('Not enough history'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-chart')), findsOneWidget);
  });

  testWidgets('a changed session key discards the previous owner screen',
      (tester) async {
    final first = InMemoryBodySetupRepository();
    await first.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 99,
        measuredAt: now.subtract(const Duration(days: 2)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, first, cycle: 'owner-a-cycle-one');
    expect(find.text('99 kg'), findsWidgets);
    final second = InMemoryBodySetupRepository();
    await pumpPage(tester, second, cycle: 'owner-b-cycle-two');
    expect(find.text('99 kg'), findsNothing);
    expect(find.text('No measurements in this range'), findsOneWidget);
  });


  testWidgets('September records auto-select 90 days, but manual 30 stays empty',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    // Screenshot case: Oct 26, 2026 with real Sep 3/Sep 19 logs.
    for (final daysAgo in [53, 37, 37]) {
      await repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 74,
          measuredAt: now.subtract(Duration(days: daysAgo)),
          source: BodyWeightSources.manual,
        ),
      );
    }
    await pumpPage(tester, repository);
    expect(find.text('Last 90 days'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-chart')), findsOneWidget);
    expect(find.text('No change'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);

    // An explicit filter always wins, even when it has zero data.
    await tester.tap(find.byKey(const ValueKey('progress-weight-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 30 days').last);
    await tester.pumpAndSettle();
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-chart')), findsNothing);
    expect(find.text('No measurements in this range'), findsOneWidget);
  });

  testWidgets('365-day fallback finds genuine older entries, compact plot',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 74,
        measuredAt: now.subtract(const Duration(days: 180)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    expect(find.text('Last 365 days'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('progress-weight-chart'))).height,
      TioSize.dp120,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('progress-weight-chart-axis')),
        matching: find.byType(Text),
      ),
      findsNWidgets(3),
    );
    // 74 kg alone needs a real visible scale, rather than empty grid lines.
    expect(find.text('75'), findsOneWidget);
    expect(find.text('74'), findsOneWidget);
    expect(find.text('73'), findsOneWidget);
    expect(find.text('Not enough history'), findsOneWidget);
  });

  testWidgets('empty chart is compact and retains honest goal reference',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    // A directional goal needs a real starting weight; keep it outside
    // every supported chart window so the empty-state semantics stay honest.
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 74,
        measuredAt: now.subtract(const Duration(days: 400)),
        source: BodyWeightSources.manual,
      ),
    );
    await repository.setActiveBodyGoal(
      const BodyGoalUpdate(
        goalType: BodyGoalType.loseWeight,
        targetWeightKg: 72,
        weeklyWeightChangeKg: 0.5,
      ),
    );
    await pumpPage(tester, repository);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('progress-weight-chart-empty')),
      ).height,
      lessThan(TioSize.dp160),
    );
    expect(find.text('Your target: 72 kg'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-chart')), findsNothing);
  });

  testWidgets('Log Weight stays anchored while Timeline scrolls',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    for (var day = 0; day < 16; day++) {
      await repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 70 + day / 10,
          measuredAt: now.subtract(Duration(days: day + 1)),
          source: BodyWeightSources.manual,
        ),
      );
    }
    await pumpPage(tester, repository);
    final action = find.byKey(const ValueKey('progress-weight-log-action'));
    final list = find.byKey(const ValueKey('progress-weight-scroll'));
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('History'), findsNothing);
    expect(find.descendant(of: list, matching: action), findsNothing);
    expect(tester.widget<TioButton>(action).variant, TioButtonVariant.primary);
    final before = tester.getRect(action);
    // Owner reduced the action from Nutrition's 56dp to Core's 46dp.
    expect(before.height, TioButtonTokens.height);
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.getRect(action), before);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsOneWidget);
  });

  testWidgets('pounds display uses lb chart axis and one date for one point',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 70,
        measuredAt: now.subtract(const Duration(days: 1)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository, unit: WeightUnit.lb);
    final axis = find.byKey(const ValueKey('progress-weight-chart-axis'));
    expect(axis, findsOneWidget);
    final values = tester.widgetList<Text>(
      find.descendant(of: axis, matching: find.byType(Text)),
    ).map((label) => label.data).toList();
    expect(values, ['156.5', '154.3', '152.1']);
    expect(
      tester.getSize(find.byKey(const ValueKey('progress-weight-chart'))).height,
      TioSize.dp120,
    );
    // Avoid printing the same date at both ends for just one measurement.
    expect(find.text('Oct 25, 2026'), findsOneWidget);
  });

  testWidgets('range menu compares two actual records in the selected window',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 66,
        measuredAt: now.subtract(const Duration(days: 61)),
        source: BodyWeightSources.manual,
      ),
    );
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 67,
        measuredAt: now.subtract(const Duration(days: 20)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    expect(find.text('Not enough history'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-weight-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 90 days').last);
    await tester.pumpAndSettle();
    expect(find.text('+1 kg'), findsOneWidget);
  });

  testWidgets('Load more appends History without duplicate pagination',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    for (var day = 0; day < 32; day++) {
      await repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 70 + day / 10,
          measuredAt: now.subtract(Duration(days: day + 1)),
          source: BodyWeightSources.manual,
        ),
      );
    }
    await pumpPage(tester, repository);
    final loadMore = find.byKey(const ValueKey('progress-weight-load-more'));
    // Jump to the bottom, not merely until the widget is built:
    // a lazily rendered button can still have its tap centre off-screen.
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('progress-weight-scroll')),
        matching: find.byType(Scrollable),
      ).first,
    );
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(loadMore);
    await tester.pumpAndSettle();
    expect(loadMore, findsNothing);
  });

  testWidgets('shows active canonical goal as a target reference',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 70,
        measuredAt: now.subtract(const Duration(days: 1)),
        source: BodyWeightSources.manual,
      ),
    );
    await repository.setActiveBodyGoal(
      const BodyGoalUpdate(
        goalType: BodyGoalType.loseWeight,
        targetWeightKg: 65,
        weeklyWeightChangeKg: 0.5,
      ),
    );
    await pumpPage(tester, repository);
    expect(find.text('Your target: 65 kg'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });


  testWidgets('pull-to-refresh works with empty short History', (tester) async {
    final repo = _CountingProgressHistoryRepository();
    await pumpPage(tester, repo);
    final callsBefore = repo.historyCalls;
    expect(find.text('No measurements in this range'), findsOneWidget);
    final scroll = find.byKey(const ValueKey('progress-weight-scroll'));
    final widget = tester.widget<ListView>(scroll);
    expect(widget.physics, isA<AlwaysScrollableScrollPhysics>());
    await tester.drag(scroll, const Offset(0, 350));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(repo.historyCalls, greaterThan(callsBefore));
    expect(find.textContaining('No weight measurements yet'), findsOneWidget);
  });

  testWidgets('load failure offers retry without exposing stale weights',
      (tester) async {
    await pumpPage(tester, _FailingWeightRepository());
    expect(find.text('Weight could not be loaded.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-chart')), findsNothing);
  });
}

class _FailingWeightRepository extends InMemoryBodySetupRepository {
  @override
  Future<BodyWeightHistoryPage> getWeightHistory(
    BodyWeightHistoryQuery query,
  ) => Future.error(StateError('private transport failure'));
}

class _CountingProgressHistoryRepository extends InMemoryBodySetupRepository {
  int historyCalls = 0;

  @override
  Future<BodyWeightHistoryPage> getWeightHistory(
    BodyWeightHistoryQuery query,
  ) {
    historyCalls++;
    return super.getWeightHistory(query);
  }
}

class _AmbiguousSaveWeightRepository extends InMemoryBodySetupRepository {
  int attempts = 0;

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    attempts++;
    await super.recordCurrentWeight(record);
    if (attempts == 1) {
      throw StateError('Response lost after write committed');
    }
  }
}

class _DelayedSaveRepository extends InMemoryBodySetupRepository {
  final Completer<void> release = Completer<void>();

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    await release.future;
    return super.recordCurrentWeight(record);
  }
}

class _DefinitelyRejectedWeightRepository extends InMemoryBodySetupRepository {
  int attempts = 0;

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    attempts++;
    throw const BodyWeightSubmissionRejected();
  }
}

class _UnknownThenRejectedWeightRepository extends InMemoryBodySetupRepository {
  int attempts = 0;

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    attempts++;
    if (attempts == 1) {
      await super.recordCurrentWeight(record);
      throw StateError('Response lost after committed insert');
    }
    throw const BodyWeightSubmissionRejected();
  }
}
