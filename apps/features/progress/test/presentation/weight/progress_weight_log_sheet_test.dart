import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_progress/src/presentation/weight/progress_weight_log_sheet.dart';

void main() {
  testWidgets('edit modal closes on owner invalidation without mutating log',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    var updates = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showProgressWeightEditSheet(
                context: context,
                unit: WeightUnit.kg,
                entry: BodyWeightEntry(
                  id: '11111111-1111-4111-8111-111111111111',
                  weightKg: 74,
                  measuredAt: DateTime.utc(2026, 10, 20, 10),
                ),
                sessionActive: active,
                onUpdate: (_) async { updates++; return true; },
                onDelete: (_) async => true,
                now: () => DateTime.utc(2026, 10, 26, 10),
              ),
              child: const Text('Open edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Weight'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-edit-delete')), findsOneWidget);
    active.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Edit Weight'), findsNothing);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(updates, 0);
  });

  testWidgets('session change dismisses nested Delete confirmation route',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    var deletes = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showProgressWeightEditSheet(
                context: context,
                unit: WeightUnit.kg,
                entry: BodyWeightEntry(
                  id: '11111111-1111-4111-8111-111111111111',
                  weightKg: 74,
                  measuredAt: DateTime.utc(2026, 10, 20, 10),
                ),
                sessionActive: active,
                onUpdate: (_) async => true,
                onDelete: (_) async { deletes++; return true; },
                now: () => DateTime.utc(2026, 10, 26, 10),
              ),
              child: const Text('Open edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-edit-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete weight log?'), findsOneWidget);
    final confirmation = find.byKey(
      const ValueKey('progress-weight-delete-confirmation-dialog'),
    );
    expect(confirmation, findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    final card = find.descendant(
      of: confirmation,
      matching: find.byType(TioCard),
    );
    expect(card, findsOneWidget);
    expect(tester.getSize(card).width, lessThanOrEqualTo(TioSize.dp320));
    final actionsTheme = Theme.of(tester.element(find.text('Delete').last));
    expect(
      actionsTheme.filledButtonTheme.style?.minimumSize?.resolve({})?.height,
      TioSize.dp38,
    );
    expect(
      actionsTheme.outlinedButtonTheme.style?.minimumSize?.resolve({})?.height,
      TioSize.dp38,
    );

    active.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Delete weight log?'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(confirmation, findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    expect(find.text('Open edit'), findsOneWidget);
    expect(deletes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown Edit then missing-row retry exits for reconciliation',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    var attempts = 0;
    bool? reconciliationRequested;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                reconciliationRequested = await showProgressWeightEditSheet(
                  context: context,
                  unit: WeightUnit.kg,
                  entry: BodyWeightEntry(
                    id: '11111111-1111-4111-8111-111111111111',
                    weightKg: 74,
                    measuredAt: DateTime.utc(2026, 10, 20, 10),
                  ),
                  sessionActive: active,
                  onUpdate: (_) async {
                    attempts++;
                    if (attempts == 1) {
                      throw StateError('Update response lost');
                    }
                    return false; // Row absent on the same-ID retry.
                  },
                  onDelete: (_) async => true,
                  now: () => DateTime.utc(2026, 10, 26, 10),
                );
              },
              child: const Text('Open edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(find.text('Retry Changes'), findsOneWidget);
    expect(find.textContaining('Save not confirmed'), findsOneWidget);
    expect(
      tester.widget<IconButton>(
        find.byKey(const ValueKey('progress-log-close')),
      ).onPressed,
      isNull,
    );
    await tester.tap(find.text('Retry Changes'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(reconciliationRequested, isTrue);
    expect(find.text('Edit Weight'), findsNothing);
    expect(find.text('Open edit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit header and footer preserve note actions and icon order',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    final note = List.filled(105, 'recorded').join(' ');
    BodyWeightLogEdit? saved;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showProgressWeightEditSheet(
          context: context,
          unit: WeightUnit.kg,
          entry: BodyWeightEntry(
            id: '11111111-1111-4111-8111-111111111111',
            weightKg: 74,
            measuredAt: DateTime.utc(2026, 10, 20, 10),
            note: note,
          ),
          sessionActive: active,
          onUpdate: (edit) async { saved = edit; return true; },
          onDelete: (_) async => true,
          now: () => DateTime.utc(2026, 10, 26, 10),
        ),
        child: const Text('Open edit'),
      ))),
    ));
    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();
    final del = find.byKey(const ValueKey('progress-edit-delete'));
    final keyboard = find.byKey(
        const ValueKey('progress-log-weight-mode-toggle'));
    final close = find.byKey(const ValueKey('progress-log-close'));
    expect(tester.getTopLeft(del).dx,
        lessThan(tester.getTopLeft(keyboard).dx));
    expect(tester.getTopLeft(keyboard).dx,
        lessThan(tester.getTopLeft(close).dx));
    final icon = tester.widget<IconButton>(keyboard).icon as Icon;
    expect(icon.icon, Icons.keyboard_outlined);
    final noteAction = find.byKey(const ValueKey('progress-log-note-toggle'));
    expect(noteAction, findsOneWidget);
    final photo = tester.widget<IconButton>(
        find.byKey(const ValueKey('progress-log-photo-later')));
    expect(photo.onPressed, isNull);
    expect(find.byKey(const ValueKey('progress-log-date-time')),
        findsOneWidget);
    await tester.tap(noteAction);
    await tester.pumpAndSettle();
    expect(find.text(note), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-log-note-field')),
        findsNothing);
    await tester.tap(noteAction);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(saved?.id, '11111111-1111-4111-8111-111111111111');
    expect(saved?.weightKg, 74);
  });

  testWidgets('owner deactivation removes root modal and private draft',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showProgressWeightLogSheet(
                context: context,
                unit: WeightUnit.kg,
                currentWeightKg: null,
                sessionActive: active,
                onSubmit: (_) async {},
              ),
              child: const Text('Open log'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open log'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    final noteToggle = find.byKey(const ValueKey('progress-log-note-toggle'));
    await tester.ensureVisible(noteToggle);
    await tester.pumpAndSettle();
    await tester.tap(noteToggle);
    await tester.pumpAndSettle();
    final note = find.descendant(
      of: find.byKey(const ValueKey('progress-log-note-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(note, 'Private old-owner note');
    active.value = false;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(find.text('Private old-owner note'), findsNothing);
    expect(find.text('Open log'), findsOneWidget);
    // A blank root modal would also hide its content. Assert the route itself
    // has been removed and no longer blocks the underlying application.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('owner invalidation removes open anchored popup and sheet',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showProgressWeightLogSheet(
                context: context,
                unit: WeightUnit.kg,
                currentWeightKg: 70,
                sessionActive: active,
                onSubmit: (_) async {},
                now: () => DateTime(2026, 10, 26, 13, 30),
              ),
              child: const Text('Open log'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open log'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-date-time')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tio-date-time-picker-popup')),
      findsOneWidget,
    );
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.byType(TimePickerDialog), findsNothing);

    active.value = false;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-date-time-picker-popup')), findsNothing);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    expect(find.text('Open log'), findsOneWidget);
  });

  testWidgets('popup maximum refreshes on app resume and remains owner-bound',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    var clock = DateTime(2026, 10, 26, 13, 30);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showProgressWeightLogSheet(
                context: context,
                unit: WeightUnit.kg,
                currentWeightKg: 70,
                sessionActive: active,
                onSubmit: (_) async {},
                now: () => clock,
              ),
              child: const Text('Open log'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open log'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-date-time')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TioDateTimeWheelPicker>(
        find.byType(TioDateTimeWheelPicker),
      ).maximumDate,
      clock,
    );
    clock = clock.add(const Duration(minutes: 30));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TioDateTimeWheelPicker>(
        find.byType(TioDateTimeWheelPicker),
      ).maximumDate,
      clock,
    );
  });

  testWidgets('Weight date-time uses one flat popup card and one wheel',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showProgressWeightLogSheet(
                context: context,
                unit: WeightUnit.kg,
                currentWeightKg: 70,
                sessionActive: active,
                now: () => DateTime(2026, 10, 26, 13, 30),
                onSubmit: (_) async {},
              ),
              child: const Text('Open log'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open log'));
    await tester.pumpAndSettle();
    expect(find.byType(TioDateTimePickerPopup), findsOneWidget);
    expect(
      tester.widget<TioDateTimePickerPopup>(
        find.byType(TioDateTimePickerPopup),
      ).elevatedCard,
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('progress-log-date-time')));
    await tester.pumpAndSettle();
    final popup = find.byKey(const ValueKey('tio-date-time-picker-popup'));
    expect(popup, findsOneWidget);
    final cards = find.descendant(of: popup, matching: find.byType(TioCard));
    expect(cards, findsOneWidget);
    expect(tester.widget<TioCard>(cards).variant, TioCardVariant.surface);
    expect(
      find.descendant(
        of: popup,
        matching: find.byType(TioDateTimeWheelPicker),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tio-date-time-wheel-selection-pill')),
        findsOneWidget);
    final cardRect = tester.getRect(popup);
    final footerRect = tester.getRect(
      find.byKey(const ValueKey('progress-log-date-time')),
    );
    expect(cardRect.bottom, lessThan(footerRect.top));
  });

  testWidgets('DateTime popup Back dismisses only the picker and retains sheet',
      (tester) async {
    final active = ValueNotifier<bool>(true);
    addTearDown(active.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showProgressWeightLogSheet(
                context: context,
                unit: WeightUnit.lb,
                currentWeightKg: 70,
                sessionActive: active,
                onSubmit: (_) async {},
                now: () => DateTime(2026, 10, 26, 13, 30),
              ),
              child: const Text('Open log'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open log'));
    await tester.pumpAndSettle();
    expect(find.text('Weight (lb)'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('progress-log-date-time')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-date-time-picker-popup')), findsNothing);
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('progress-log-date-time')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tio-date-time-picker-popup')), findsNothing);
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
  });
}
