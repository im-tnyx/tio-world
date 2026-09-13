import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
      'card tap reads canonical row and Quick Edit saves the same identity',
      (tester) async {
    final now = DateTime(2026, 9, 12, 11);
    final dateController = MealDiaryDateController(clock: () => now);
    final repository = _EditableMealLogRepository(_entry());
    final categories = _MealCategoriesRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealDiaryDateControllerProvider.overrideWith(
            (ref) => dateController,
          ),
          mealDiaryMealLogRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: MealDiaryPage(
              quickAddClock: () => now,
              mealCategoriesRepository: categories,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selectedBefore = dateController.selectedDate;
    await tester.tap(
      find.byKey(const ValueKey('meal-diary-entry-meal-1')),
    );
    await tester.pumpAndSettle();

    expect(repository.readIds, ['meal-1']);
    expect(find.text('Quick Edit'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Log Meal'), findsNothing);
    expect(_fieldText(tester, 'quick-add-meal-name'), 'Dal and roti');
    expect(_fieldText(tester, 'quick-add-calories'), '400');
    expect(_fieldText(tester, 'quick-add-carbs'), '50');
    expect(_fieldText(tester, 'quick-add-protein'), '20');
    expect(_fieldText(tester, 'quick-add-fat'), '12');
    expect(find.text('Lunch'), findsWidgets);

    await tester.enterText(
      _editableFinder('quick-add-meal-name'),
      'Updated dal and roti',
    );
    await tester.enterText(_editableFinder('quick-add-calories'), '425');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.inputs, hasLength(1));
    final input = repository.inputs.single;
    expect(input.id, 'meal-1');
    expect(input.expectedRevision, 3);
    expect(input.note, 'Preserve this note');
    expect(input.manualNutritionSnapshot.amountFor(NutrientId.energy), 425);
    expect(repository.current.id, 'meal-1');
    expect(repository.current.captureSource, MealLogCaptureSource.quickAdd);
    expect(repository.current.mode, MealLogMode.manual);
    expect(repository.current.revision, 4);
    expect(repository.listRequests.length, greaterThanOrEqualTo(2));
    expect(dateController.selectedDate, selectedBefore);
    expect(find.text('Updated dal and roti'), findsOneWidget);
  });

  testWidgets(
      'dismissing an edit that turned out to be a conflict after an '
      'ambiguous outcome still refreshes the original date',
      (tester) async {
    final now = DateTime(2026, 9, 12, 11);
    final dateController = MealDiaryDateController(clock: () => now);
    final repository = _AmbiguousThenConflictRepository(_entry());
    final categories = _MealCategoriesRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealDiaryDateControllerProvider.overrideWith(
            (ref) => dateController,
          ),
          mealDiaryMealLogRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: MealDiaryPage(
              quickAddClock: () => now,
              mealCategoriesRepository: categories,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selectedBefore = dateController.selectedDate;
    await tester.tap(find.byKey(const ValueKey('meal-diary-entry-meal-1')));
    await tester.pumpAndSettle();
    expect(find.text('Quick Edit'), findsOneWidget);

    final listRequestsBeforeSubmit = repository.listRequests.length;

    // First Save Changes: the transport result is ambiguous even though the
    // write actually lands (repository.current is mutated inside the fake).
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(
      find.text(QuickAddMealLogEditController.outcomeUnknownMessage),
      findsOneWidget,
    );

    // While the outcome is uncertain the editor sheet must not be
    // dismissible by any route-pop path (handle drag, back gesture, barrier
    // tap all funnel through the same PopScope/maybePop mechanism) — this is
    // what actually prevents the originally-reported "user dismisses the
    // uncertain sheet" scenario from reaching a live build. Confirmed here so
    // the retry-then-conflict path below is the genuine reachable risk, not
    // an invented one.
    await tester.drag(
      find.byKey(const ValueKey('tio-editor-sheet-handle')),
      const Offset(0, 120),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-add-editor')), findsOneWidget);

    // Retry: the exact same frozen facts now conflict, because the earlier
    // ambiguous attempt already advanced the durable revision.
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(
      find.text(QuickAddMealLogEditController.conflictMessage),
      findsOneWidget,
    );
    expect(repository.inputs, hasLength(2));
    expect(repository.inputs[1], same(repository.inputs[0]));

    // A conflict is not a locked state, so the sheet is dismissible again.
    // The reader abandons the edit here without reapplying — the durable
    // write from the ambiguous attempt is already correct, but the Diary
    // must still learn about it instead of continuing to show what was on
    // screen before Quick Edit opened.
    await tester.drag(
      find.byKey(const ValueKey('tio-editor-sheet-handle')),
      const Offset(0, 120),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-add-editor')), findsNothing);

    expect(
      repository.listRequests.length,
      greaterThan(listRequestsBeforeSubmit),
      reason: 'closing the sheet with no result must still refetch the '
          'original date',
    );
    expect(dateController.selectedDate, selectedBefore);
    // Dismissing must not itself send a third update — only the two
    // deliberate Save Changes taps above may have written anything.
    expect(repository.inputs, hasLength(2));
  });

  group('RF5 — concurrent Quick Edit opens are guarded', () {
    testWidgets(
        'a delayed readById plus a rapid double tap on the same card opens '
        'exactly one editor from one read', (tester) async {
      final now = DateTime(2026, 9, 12, 11);
      final dateController = MealDiaryDateController(clock: () => now);
      final repository = _DelayedReadRepository({'meal-1': _entry()});
      final categories = _MealCategoriesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealDiaryDateControllerProvider.overrideWith(
              (ref) => dateController,
            ),
            mealDiaryMealLogRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            builder: (context, child) => TioTheme(
              config: const TioThemeConfig(mode: TioThemeMode.light),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: MealDiaryPage(
                quickAddClock: () => now,
                mealCategoriesRepository: categories,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('meal-diary-entry-meal-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('meal-diary-entry-meal-1')));
      await tester.pump();

      expect(
        repository.readIds,
        ['meal-1'],
        reason: 'the second tap while the first read is in flight must be '
            'ignored entirely',
      );

      repository.completeNextRead();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quick-add-editor')), findsOneWidget);
      expect(find.text('Quick Edit'), findsOneWidget);
    });

    testWidgets(
        'a delayed readById plus taps on two different cards opens exactly '
        'one editor', (tester) async {
      final now = DateTime(2026, 9, 12, 11);
      final dateController = MealDiaryDateController(clock: () => now);
      final repository = _DelayedReadRepository({
        'meal-1': _entry(),
        'meal-2': _entry(id: 'meal-2', name: 'Second meal'),
      });
      final categories = _MealCategoriesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealDiaryDateControllerProvider.overrideWith(
              (ref) => dateController,
            ),
            mealDiaryMealLogRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            builder: (context, child) => TioTheme(
              config: const TioThemeConfig(mode: TioThemeMode.light),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: MealDiaryPage(
                quickAddClock: () => now,
                mealCategoriesRepository: categories,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('meal-diary-entry-meal-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('meal-diary-entry-meal-2')));
      await tester.pump();

      expect(
        repository.readIds,
        ['meal-1'],
        reason: 'a tap on a second card while the first read is in flight '
            'must be ignored too, not just a repeat tap on the same card',
      );

      repository.completeNextRead();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quick-add-editor')), findsOneWidget);
      // Exactly the first tapped meal's editor opened, not a stacked second
      // one and not the second card's data.
      expect(_fieldText(tester, 'quick-add-meal-name'), 'Dal and roti');
    });

    testWidgets(
        'after the first editor closes, a later edit opens normally',
        (tester) async {
      final now = DateTime(2026, 9, 12, 11);
      final dateController = MealDiaryDateController(clock: () => now);
      final repository = _DelayedReadRepository({'meal-1': _entry()});
      final categories = _MealCategoriesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealDiaryDateControllerProvider.overrideWith(
              (ref) => dateController,
            ),
            mealDiaryMealLogRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            builder: (context, child) => TioTheme(
              config: const TioThemeConfig(mode: TioThemeMode.light),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: MealDiaryPage(
                quickAddClock: () => now,
                mealCategoriesRepository: categories,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('meal-diary-entry-meal-1')));
      await tester.pump();
      repository.completeNextRead();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quick-add-editor')), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quick-add-editor')), findsNothing);

      // No stale guard left behind — a fresh edit reads and opens again.
      await tester.tap(find.byKey(const ValueKey('meal-diary-entry-meal-1')));
      await tester.pump();
      repository.completeNextRead();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quick-add-editor')), findsOneWidget);
      expect(repository.readIds, ['meal-1', 'meal-1']);
    });
  });

  testWidgets(
      'a genuine date move invalidates both the original and destination day',
      (tester) async {
    // The entry starts on "today" so the Diary's default selected date shows
    // it without any extra navigation. The move target is a day in the past
    // — the date/time control has no lower bound, only an upper one clamped
    // to "now" — so this is a genuine cross-date move reachable without
    // fighting that constraint.
    final now = DateTime(2026, 9, 13, 20);
    final dateController = MealDiaryDateController(clock: () => now);
    final repository = _EditableMealLogRepository(_entryOnDay(13));
    final categories = _MealCategoriesRepository();

    final dateA = MealLogLocalDate(year: 2026, month: 9, day: 13);
    final dateB = MealLogLocalDate(year: 2026, month: 9, day: 12);
    final requestB = MealDiaryHistoryRequest(
      mealLogRepository: repository,
      mealCategoriesRepository: categories,
      localDate: dateB,
    );

    final container = ProviderContainer(
      overrides: [
        mealDiaryDateControllerProvider.overrideWith(
          (ref) => dateController,
        ),
        mealDiaryMealLogRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // Keep date B's history request alive for the whole test. It is an
    // autoDispose family provider, so an un-watched instance would already
    // refetch fresh next time anyone reads it regardless of whether the
    // production code explicitly invalidates it. Holding a live listener the
    // whole time removes that confound: any second read we observe here can
    // only come from the explicit new-date invalidation this test exists to
    // verify.
    final subscription = container.listen(
      mealDiaryHistoryProvider(requestB),
      (_, __) {},
    );
    addTearDown(subscription.close);
    await container.read(mealDiaryHistoryProvider(requestB).future);
    expect(repository.listRequests.where((d) => d == dateB), hasLength(1));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: MealDiaryPage(
              quickAddClock: () => now,
              mealCategoriesRepository: categories,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selectedBefore = dateController.selectedDate;

    await tester.tap(find.byKey(const ValueKey('meal-diary-entry-meal-1')));
    await tester.pumpAndSettle();
    expect(find.text('Quick Edit'), findsOneWidget);

    // Move the meal's consumed date/time from A into B through the real
    // date/time control. Dragging a CupertinoDatePicker wheel is not a
    // reliable widget-test gesture, so this invokes the picker's own real
    // callback directly — the same call a settled drag would make — rather
    // than simulating drum physics.
    await tester.tap(find.byKey(const ValueKey('meal-log-footer-date-time')));
    await tester.pumpAndSettle();
    final picker =
        tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
    picker.onDateTimeChanged(DateTime(2026, 9, 12, 9));
    await tester.pumpAndSettle();
    // Dismiss the popup through its own full-screen barrier (tapping the
    // title correctly hits the barrier sitting above it, not the text
    // itself) without dismissing the sheet, so Save Changes is reachable
    // underneath it afterward.
    await tester.tap(find.text('Quick Edit'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repository.inputs.single.id, 'meal-1');
    expect(repository.inputs.single.consumedLocalDate, dateB);
    expect(repository.current.consumedLocalDate, dateB);
    expect(dateController.selectedDate, selectedBefore);

    expect(
      repository.listRequests.where((d) => d == dateA),
      hasLength(greaterThanOrEqualTo(2)),
      reason: 'the original date must refresh',
    );
    expect(
      repository.listRequests.where((d) => d == dateB),
      hasLength(2),
      reason: 'the still-live destination-date listener must see a second, '
          'post-edit read — proof the new date was actually invalidated '
          'rather than relying on nobody watching it',
    );
    final refreshed =
        await container.read(mealDiaryHistoryProvider(requestB).future);
    expect(
      refreshed.sections.expand((section) => section.entries).map((e) => e.id),
      contains('meal-1'),
    );
  });
}

Finder _editableFinder(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(EditableText),
    );

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<EditableText>(_editableFinder(key)).controller.text;

final class _EditableMealLogRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
  _EditableMealLogRepository(this.current);

  MealLogEntry current;
  final List<String> readIds = [];
  final List<MealLogLocalDate> listRequests = [];
  final List<ManualMealLogUpdate> inputs = [];

  @override
  Future<MealLogEntry?> readById(String id) async {
    readIds.add(id);
    return current.id == id ? current : null;
  }

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async {
    listRequests.add(localDate);
    return current.consumedLocalDate == localDate ? [current] : const [];
  }

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) async {
    inputs.add(input);
    final previous = current;
    current = MealLogEntry.manual(
      id: previous.id,
      userId: previous.userId,
      mealCategoryId: input.mealCategoryId,
      mealName: input.mealName,
      note: input.note,
      consumedAt: input.consumedAt,
      consumedLocalDate: input.consumedLocalDate,
      consumedTimezoneId: input.consumedTimezoneId,
      consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
      captureSource: previous.captureSource,
      manualNutritionSnapshot: input.manualNutritionSnapshot,
      revision: input.expectedRevision + 1,
      createdAt: previous.createdAt,
      updatedAt: previous.updatedAt.add(const Duration(minutes: 1)),
    );
    return current;
  }

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();
}

/// A `readById` that never resolves until [completeNextRead] is called,
/// for proving the page-level in-flight guard around the async gap between
/// a tap and the editor's modal barrier actually going up.
final class _DelayedReadRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
  _DelayedReadRepository(this.entries);

  final Map<String, MealLogEntry> entries;
  final List<String> readIds = [];
  final List<ManualMealLogUpdate> inputs = [];
  final List<Completer<MealLogEntry?>> _pendingReads = [];

  @override
  Future<MealLogEntry?> readById(String id) {
    readIds.add(id);
    final completer = Completer<MealLogEntry?>();
    _pendingReads.add(completer);
    return completer.future;
  }

  /// Resolves the oldest not-yet-completed [readById] call with its actual
  /// fixture entry, in call order — matching a real repository's FIFO
  /// resolution rather than requiring the test to track completers itself.
  void completeNextRead() {
    final index = _pendingReads.indexWhere((c) => !c.isCompleted);
    _pendingReads[index].complete(entries[readIds[index]]);
  }

  @override
  Future<List<MealLogEntry>> listByLocalDate(
    MealLogLocalDate localDate,
  ) async =>
      entries.values.where((e) => e.consumedLocalDate == localDate).toList();

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) async {
    inputs.add(input);
    final previous = entries[input.id]!;
    final updated = MealLogEntry.manual(
      id: previous.id,
      userId: previous.userId,
      mealCategoryId: input.mealCategoryId,
      mealName: input.mealName,
      note: input.note,
      consumedAt: input.consumedAt,
      consumedLocalDate: input.consumedLocalDate,
      consumedTimezoneId: input.consumedTimezoneId,
      consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
      captureSource: previous.captureSource,
      manualNutritionSnapshot: input.manualNutritionSnapshot,
      revision: input.expectedRevision + 1,
      createdAt: previous.createdAt,
      updatedAt: previous.updatedAt.add(const Duration(minutes: 1)),
    );
    entries[input.id] = updated;
    return updated;
  }

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();
}

/// Simulates a write whose transport result is ambiguous even though it
/// actually reaches durable storage, followed by a same-facts retry that then
/// genuinely conflicts against the revision the first attempt already
/// advanced.
final class _AmbiguousThenConflictRepository
    implements MealLogRepository, ManualMealLogUpdateRepository {
  _AmbiguousThenConflictRepository(this.current);

  MealLogEntry current;
  final List<String> readIds = [];
  final List<MealLogLocalDate> listRequests = [];
  final List<ManualMealLogUpdate> inputs = [];
  var _attempts = 0;

  @override
  Future<MealLogEntry?> readById(String id) async {
    readIds.add(id);
    return current.id == id ? current : null;
  }

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) async {
    listRequests.add(localDate);
    return current.consumedLocalDate == localDate ? [current] : const [];
  }

  @override
  Future<MealLogEntry> updateManual(ManualMealLogUpdate input) async {
    inputs.add(input);
    _attempts++;
    if (_attempts == 1) {
      current = _applied(current, input);
      throw MealLogUpdateOutcomeUnknown(
        id: input.id,
        expectedRevision: input.expectedRevision,
      );
    }
    throw MealLogUpdateConflict(
      id: input.id,
      expectedRevision: input.expectedRevision,
      actualRevision: current.revision,
    );
  }

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  static MealLogEntry _applied(MealLogEntry base, ManualMealLogUpdate input) {
    return MealLogEntry.manual(
      id: base.id,
      userId: base.userId,
      mealCategoryId: input.mealCategoryId,
      mealName: input.mealName,
      note: input.note,
      consumedAt: input.consumedAt,
      consumedLocalDate: input.consumedLocalDate,
      consumedTimezoneId: input.consumedTimezoneId,
      consumedUtcOffsetMinutes: input.consumedUtcOffsetMinutes,
      captureSource: base.captureSource,
      manualNutritionSnapshot: input.manualNutritionSnapshot,
      revision: input.expectedRevision + 1,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt.add(const Duration(minutes: 1)),
    );
  }
}

final class _MealCategoriesRepository implements MealCategoriesRepository {
  @override
  Future<MealCategoriesConfig> read() async =>
      MealCategoriesConfig.canonicalDefaults();

  @override
  Future<void> upsert(MealCategoriesConfig config) =>
      throw UnimplementedError();
}

MealLogEntry _entry({String id = 'meal-1', String name = 'Dal and roti'}) {
  return MealLogEntry.manual(
    id: id,
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: name,
    note: 'Preserve this note',
    consumedAt: DateTime.utc(2026, 9, 12, 4, 45),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: 12),
    consumedTimezoneId: 'Asia/Kolkata',
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: 400,
        NutrientId.carbohydrate: 50,
        NutrientId.protein: 20,
        NutrientId.fat: 12,
      },
    ),
    revision: 3,
    createdAt: DateTime.utc(2026, 9, 12, 4, 46),
    updatedAt: DateTime.utc(2026, 9, 12, 4, 47),
  );
}

/// Same fixture as [_entry], parameterized by the September 2026 day it is
/// consumed on, for a test that needs the entry to start on "today".
MealLogEntry _entryOnDay(int day) {
  return MealLogEntry.manual(
    id: 'meal-1',
    userId: 'user-1',
    mealCategoryId: 'meal_slot_2',
    mealName: 'Dal and roti',
    note: 'Preserve this note',
    consumedAt: DateTime.utc(2026, 9, day, 4, 45),
    consumedLocalDate: MealLogLocalDate(year: 2026, month: 9, day: day),
    consumedTimezoneId: 'Asia/Kolkata',
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: 400,
        NutrientId.carbohydrate: 50,
        NutrientId.protein: 20,
        NutrientId.fat: 12,
      },
    ),
    revision: 3,
    createdAt: DateTime.utc(2026, 9, day, 4, 46),
    updatedAt: DateTime.utc(2026, 9, day, 4, 47),
  );
}
