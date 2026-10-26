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
    expect(wheel.showUnitSwitcher, isTrue);
    expect(find.text('Weight (lb)'), findsNothing);
    final drums = find.descendant(
      of: find.byKey(const ValueKey('progress-log-wheel')),
      matching: find.byType(ListWheelScrollView),
    );
    expect(drums, findsNWidgets(3));
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
    expect(find.text('2 kg to go'), findsOneWidget);
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
    expect(before.height, greaterThanOrEqualTo(TioButtonTokens.height));
    expect(before.height, lessThan(TioSize.dp56));
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
    // Assert the actual single-point label independent of locale formatting
    // and viewport visibility; the chart itself is already mounted above.
    final label = tester.widget<Text>(
      find.byKey(const ValueKey('progress-weight-single-date'),
          skipOffstage: false),
    );
    final expectedDate = MaterialLocalizations.of(
      tester.element(find.byKey(const ValueKey('progress-weight-chart'))),
    ).formatMediumDate(now.subtract(const Duration(days: 1)).toLocal());
    expect(label.data, expectedDate);
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

  testWidgets('Weight graph card is separate from three summary stat cards',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 74,
        measuredAt: now.subtract(const Duration(days: 20)),
        source: BodyWeightSources.manual,
      ),
    );
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 75,
        measuredAt: now.subtract(const Duration(days: 6)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    final graph = find.byKey(const ValueKey('progress-weight-graph-card'));
    expect(graph, findsOneWidget);
    expect(
      find.descendant(of: graph, matching: find.text('CURRENT')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: graph, matching: find.text('30 DAY CHANGE')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: graph, matching: find.text('RATE OF CHANGE')),
      findsNothing,
    );
    expect(find.text('STARTING'), findsOneWidget);
    expect(find.text('CHANGE'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-stat-current')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-stat-change')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-stat-starting')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-stat-overall-change')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-stat-rate')),
        findsOneWidget);
    expect(find.text('30 DAY CHANGE'), findsOneWidget);
    expect(find.text('+1 kg'), findsOneWidget);
    expect(find.text('+0.5 kg/week'), findsOneWidget);
  });

  testWidgets('reference summary has equal phone cards and distinct changes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(BodyWeightRecord(
      weightKg: 74, measuredAt: now.subtract(const Duration(days: 20)),
      source: BodyWeightSources.manual,
    ));
    await repo.setActiveBodyGoal(const BodyGoalUpdate(
      goalType: BodyGoalType.loseWeight, targetWeightKg: 70,
      weeklyWeightChangeKg: 0.5,
    ));
    await repo.recordCurrentWeight(BodyWeightRecord(
      weightKg: 73, measuredAt: now.subtract(const Duration(days: 6)),
      source: BodyWeightSources.manual,
    ));
    await pumpPage(tester, repo);
    final graph = find.byKey(const ValueKey('progress-weight-graph-card'));
    expect(find.descendant(of: graph, matching: find.text('CURRENT')),
        findsOneWidget);
    expect(find.descendant(of: graph, matching: find.text('30 DAY CHANGE')),
        findsOneWidget);
    expect(find.text('STARTING'), findsOneWidget);
    expect(find.text('CHANGE'), findsOneWidget);
    expect(find.text('RATE OF CHANGE'), findsOneWidget);
    expect(find.text('74 kg'), findsWidgets);
    expect(find.text('-1 kg'), findsWidgets);
    final metrics = [
      'progress-weight-stat-starting',
      'progress-weight-stat-overall-change',
      'progress-weight-stat-rate',
    ].map((k) => tester.getSize(find.byKey(ValueKey(k)))).toList();
    expect(metrics[0].height, metrics[1].height);
    expect(metrics[1].height, metrics[2].height);
    expect(metrics[0].width, closeTo(metrics[1].width, 0.001));
    expect(metrics[1].width, closeTo(metrics[2].width, 0.001));
    expect(find.text('On track to target'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart range menu reuses elevated TioCard and marks selection',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    await tester.tap(find.byKey(const ValueKey('progress-weight-range')));
    await tester.pumpAndSettle();
    final popup = find.byKey(
      const ValueKey('progress-weight-range-menu-card'),
    );
    expect(popup, findsOneWidget);
    expect(tester.widget<TioCard>(popup).variant,
        TioCardVariant.elevated);
    expect(
      find.descendant(of: popup, matching: find.byType(MenuItemButton)),
      findsNWidgets(3),
    );
    expect(
      find.byKey(const ValueKey('progress-weight-range-option-30')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('progress-weight-range-option-90')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Last 90 days'), findsOneWidget);
    expect(find.text('90 DAY CHANGE'), findsOneWidget);
    expect(popup, findsNothing);
  });

  testWidgets('weekly change is truthful in lb and unavailable for one point',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 70,
        measuredAt: now.subtract(const Duration(days: 14)),
        source: BodyWeightSources.manual,
      ),
    );
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 71,
        measuredAt: now.subtract(const Duration(days: 7)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository, unit: WeightUnit.lb);
    expect(find.text('+2.2 lb/week'), findsOneWidget);
    expect(find.text('30 DAY CHANGE'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-graph-card')),
        findsOneWidget);
  });

  testWidgets('small viewport and accessible text keep stats readable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1350);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 74,
        measuredAt: now.subtract(const Duration(days: 3)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    final stat = find.byKey(const ValueKey('progress-weight-stat-rate'));
    expect(stat, findsOneWidget);
    expect(find.text('RATE OF CHANGE'), findsOneWidget);
    expect(find.text('Not enough history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal marker is exclusive to the latest row, with target below graph',
      (tester) async {
    final repo = InMemoryBodySetupRepository();
    for (final weight in [74.0, 73.0, 72.0]) {
      await repo.recordCurrentWeight(BodyWeightRecord(
        weightKg: weight,
        measuredAt: now.subtract(Duration(days: weight.toInt() - 71)),
        source: BodyWeightSources.manual,
      ));
    }
    await repo.setActiveBodyGoal(const BodyGoalUpdate(
      goalType: BodyGoalType.loseWeight,
      targetWeightKg: 70,
      weeklyWeightChangeKg: 0.5,
    ));
    await pumpPage(tester, repo);
    expect(find.text('New low'), findsOneWidget);
    expect(find.text('New high'), findsNothing);
    expect(find.byKey(const ValueKey('progress-weight-target-card')), findsOneWidget);
    final chart = find.byKey(const ValueKey('progress-weight-graph-card'));
    expect(find.descendant(of: chart, matching: find.textContaining('to go')), findsNothing);
  });

  testWidgets('deleting exact Timeline entry requires confirmation and reloads',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(BodyWeightRecord(
      weightKg: 72, measuredAt: now.subtract(const Duration(days: 2)),
      source: BodyWeightSources.manual,
    ));
    await repository.recordCurrentWeight(BodyWeightRecord(
      weightKg: 76, measuredAt: now.subtract(const Duration(days: 1)),
      source: BodyWeightSources.manual,
    ));
    await pumpPage(tester, repository);
    expect(find.text('76 kg'), findsOneWidget);
    final newestId = repository.weightEntries.last.id!;
    final edit = find.byKey(ValueKey('progress-weight-edit-$newestId'));
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.text('Edit Weight'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-edit-delete')), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.byKey(ValueKey('progress-weight-delete-$newestId')),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('progress-edit-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete weight log?'), findsOneWidget);
    expect(repository.weightEntries, hasLength(2));
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(2));
    expect(find.text('Edit Weight'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('progress-edit-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.weightKg, 72);
    expect(find.text('72 kg'), findsWidgets);
    expect(find.text('76 kg'), findsNothing);
  });

  testWidgets('pencil edits only selected record and preserves row identity',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(BodyWeightRecord(
      weightKg: 72,
      measuredAt: now.subtract(const Duration(days: 2)),
      source: BodyWeightSources.manual,
      note: 'Keep existing note',
    ));
    await repository.recordCurrentWeight(BodyWeightRecord(
      weightKg: 76,
      measuredAt: now.subtract(const Duration(days: 1)),
      source: BodyWeightSources.manual,
    ));
    await pumpPage(tester, repository);
    final oldest = repository.weightEntries.first;
    final selected = repository.weightEntries.last;
    final pencil = find.byKey(ValueKey('progress-weight-edit-${selected.id}'));
    await tester.ensureVisible(pencil);
    await tester.tap(pencil);
    await tester.pumpAndSettle();
    expect(find.text('Edit Weight'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-log-note-toggle')), findsNothing);
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsOneWidget);
    await tester.tap(find.byKey(
      const ValueKey('progress-log-weight-mode-toggle')));
    await tester.pumpAndSettle();
    final editor = find.byKey(
      const ValueKey('progress-log-manual-weight'));
    expect(editor, findsOneWidget);
    await tester.enterText(find.descendant(
      of: editor, matching: find.byType(EditableText)), '77.0');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(2));
    expect(repository.weightEntries.last.id, selected.id);
    expect(repository.weightEntries.last.weightKg, 77);
    expect(repository.weightEntries.first.id, oldest.id);
    expect(repository.weightEntries.first.note, 'Keep existing note');
    expect(find.text('Edit Weight'), findsNothing);
  });

  testWidgets('Timeline groups months and uses real older-record changes',
      (tester) async {
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 74,
        measuredAt: DateTime.utc(2026, 9, 20, 10),
        source: BodyWeightSources.manual,
      ),
    );
    await repo.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 73,
        measuredAt: now.subtract(const Duration(days: 1)),
        source: BodyWeightSources.manual,
        note: 'Morning check-in',
      ),
    );
    await pumpPage(tester, repo);
    expect(find.byKey(const ValueKey('progress-weight-timeline-month-2026-10')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-timeline-month-2026-9')),
        findsOneWidget);
    expect(find.text('-1.0'), findsOneWidget);
    expect(find.text('New low'), findsNothing);
    expect(find.text('Morning check-in'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
  });

  testWidgets('compact Timeline card keeps recorded date and weight visible',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 73,
        measuredAt: now.subtract(const Duration(days: 1)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    final cards = find.byWidgetPredicate((widget) =>
        widget is DecoratedBox &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value
            .startsWith('progress-weight-history-'));
    expect(cards, findsOneWidget);
    // A two-line date/time replaces the previous three-line dot/date/time
    // column; the no-note baseline must fit below the old tall-card footprint.
    expect(tester.getSize(cards).height, TioSize.dp72);
    expect(find.text('73.0 kg'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-log-action')),
        findsOneWidget);
  });

  testWidgets('Timeline cards keep the same height with notes and badges',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = InMemoryBodySetupRepository();
    for (final record in [
      BodyWeightRecord(
        weightKg: 76,
        measuredAt: now.subtract(const Duration(days: 3)),
        source: BodyWeightSources.manual,
      ),
      BodyWeightRecord(
        weightKg: 74,
        measuredAt: now.subtract(const Duration(days: 2)),
        source: BodyWeightSources.manual,
        note: 'Saved note that can be much longer than one preview line',
      ),
      BodyWeightRecord(
        weightKg: 73,
        measuredAt: now.subtract(const Duration(minutes: 10)),
        source: BodyWeightSources.manual,
      ),
    ]) {
      await repository.recordCurrentWeight(record);
    }
    await pumpPage(tester, repository);
    final cards = find.byWidgetPredicate((widget) =>
        widget is DecoratedBox &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value
            .startsWith('progress-weight-history-'));
    expect(cards, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      expect(tester.getSize(cards.at(i)).height, TioSize.dp72);
    }
    expect(find.text('New low'), findsNothing);
    expect(find.textContaining('Saved note that can be much longer'),
        findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today inset keeps narrow Timeline cards the same height',
      (tester) async {
    tester.view.physicalSize = const Size(337, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = InMemoryBodySetupRepository();
    for (final record in [
      BodyWeightRecord(
        weightKg: 75,
        measuredAt: now.subtract(const Duration(days: 2)),
        source: BodyWeightSources.manual,
      ),
      BodyWeightRecord(
        weightKg: 73,
        measuredAt: now.subtract(const Duration(minutes: 10)),
        source: BodyWeightSources.manual,
      ),
    ]) {
      await repository.recordCurrentWeight(record);
    }
    await pumpPage(tester, repository);
    final cards = find.byWidgetPredicate((widget) =>
        widget is DecoratedBox &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value
            .startsWith('progress-weight-history-'));
    expect(cards, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      expect(
        tester.getSize(cards.at(i)).height,
        TioSize.dp72 + TioSize.dp40,
      );
    }
    expect(find.text('New low'), findsNothing);
    expect(find.text('-2.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text preserves full lb value and equal Timeline rows',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 75,
        measuredAt: now.subtract(const Duration(days: 2)),
        source: BodyWeightSources.manual,
      ),
    );
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 73,
        measuredAt: now.subtract(const Duration(minutes: 10)),
        source: BodyWeightSources.manual,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.8),
          ),
          child: TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.dark),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: Scaffold(
          body: ProgressWeightPage(
            repository: repository,
            unit: WeightUnit.lb,
            sessionKey: 'large-text',
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cards = find.byWidgetPredicate((widget) =>
        widget is DecoratedBox &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value
            .startsWith('progress-weight-history-'));
    // Extra graph-summary cards put the Timeline below the initial viewport
    // at 1.8x text scale. Scroll to the real Today row before measuring it;
    // neither Timeline card needs to be initially mounted by the ListView.
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('progress-weight-scroll')),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(
      find.text('Today'),
      TioSize.dp120,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final todayCard = find.ancestor(
      of: find.text('Today'),
      matching: cards,
    );
    expect(todayCard, findsOneWidget);
    final todayHeight = tester.getSize(todayCard).height;
    expect(todayHeight, greaterThan(TioSize.dp72));
    final timelineLb = find.descendant(
      of: todayCard,
      matching: find.text('160.9 lb'),
    );
    expect(timelineLb, findsOneWidget);
    expect(tester.widget<Text>(timelineLb).overflow, TextOverflow.visible);
    expect(find.text('New low'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('165.3 lb'),
      TioSize.dp120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('progress-weight-scroll')),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pumpAndSettle();
    final olderCard = find.ancestor(
      of: find.text('165.3 lb'),
      matching: cards,
    );
    expect(olderCard, findsOneWidget);
    expect(tester.getSize(olderCard).height, todayHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today row and units follow actual reading date and global lb',
      (tester) async {
    final repo = InMemoryBodySetupRepository();
    await repo.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 73,
        measuredAt: now.subtract(const Duration(minutes: 10)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repo, unit: WeightUnit.lb);
    expect(find.text('Today'), findsOneWidget);
    // Summary and Timeline may both show the current reading; assert that
    // the Timeline card itself displays the global lb conversion.
    final timelineLb = find.descendant(
      of: find.byWidgetPredicate((widget) =>
          widget is DecoratedBox &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value
              .startsWith('progress-weight-history-')),
      matching: find.text('160.9 lb'),
    );
    expect(timelineLb, findsOneWidget);
    expect(find.text('New low'), findsNothing);
    expect(find.text('0.0'), findsNothing);
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
    expect(find.byKey(const ValueKey('progress-weight-target-card')), findsOneWidget);
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

  testWidgets('optional chart fallback failure keeps valid baseline data',
      (tester) async {
    final repository = _FailingFallbackWeightRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 74,
        measuredAt: now.subtract(const Duration(days: 60)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    expect(repository.fallbackFailed, isTrue);
    expect(find.text('Weight could not be loaded.'), findsNothing);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('74 kg'), findsWidgets);
    expect(find.text('No measurements in this range'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-log-action')),
        findsOneWidget);
  });

  testWidgets('load failure offers retry without exposing stale weights',
      (tester) async {
    await pumpPage(tester, _FailingWeightRepository());
    expect(find.text('Weight could not be loaded.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-chart')), findsNothing);
  });
}

class _FailingFallbackWeightRepository extends InMemoryBodySetupRepository {
  bool fallbackFailed = false;

  @override
  Future<BodyWeightHistoryPage> getWeightHistory(
    BodyWeightHistoryQuery query,
  ) {
    // The optional 90-day chart query starts 90 days before the fixed clock.
    // Current, 30-day chart and Timeline queries still succeed.
    if (query.fromInclusive ==
        DateTime.utc(2026, 10, 26, 10).subtract(const Duration(days: 90))) {
      fallbackFailed = true;
      return Future.error(StateError('transient chart transport failure'));
    }
    return super.getWeightHistory(query);
  }
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
