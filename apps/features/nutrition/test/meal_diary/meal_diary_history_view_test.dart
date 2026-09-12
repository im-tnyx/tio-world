import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_nutrition/src/meal_diary/presentation/widgets/meal_diary_history_view.dart';
import 'package:tio_shared/shared.dart';

final _today = DateTime(2026, 9, 11, 12);

void main() {
  testWidgets(
      'rich card keeps time inside fixed media and exposes only working Edit',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final categories = _FakeMealCategoriesRepository(
      MealCategoriesConfig.canonicalDefaults(),
    );
    final mealLogs = _ImmediateMealLogRepository({
      _localDate(11): [
        _entry(
          id: 'meal',
          categoryId: 'meal_slot_2',
          mealName: 'A deliberately long meal title that must stay bounded',
          consumedAt: DateTime.utc(2026, 9, 11, 9, 50),
          calories: 254,
          protein: 9,
        ),
      ],
    });
    final edits = <String>[];

    await _pumpHistoryView(
      tester,
      mealLogs: mealLogs,
      categories: categories,
      onEdit: edits.add,
    );
    await tester.pumpAndSettle();

    final mediaFinder =
        find.byKey(const ValueKey('meal-diary-entry-media-meal'));
    final timeFinder = find.byKey(const ValueKey('meal-diary-entry-time-meal'));
    final cardFinder = find.byKey(const ValueKey('meal-diary-entry-meal'));
    final headerSummaryFinder = find.byKey(
      const ValueKey('meal-diary-section-summary-meal_slot_2'),
    );
    final overflowFinder = find.byIcon(Icons.more_vert);
    final mediaRect = tester.getRect(mediaFinder);
    final timeRect = tester.getRect(timeFinder);
    final cardRect = tester.getRect(cardFinder);
    final overflowRect = tester.getRect(overflowFinder);

    expect(mediaRect.size, const Size.square(TioSize.dp120));
    expect(cardRect.height, TioSize.dp120);
    // The media belongs to the card: it fills the card's own leading corner
    // rather than floating inside it as a nested tile.
    expect(mediaRect.left, cardRect.left);
    expect(mediaRect.top, cardRect.top);
    expect(mediaRect.bottom, cardRect.bottom);
    expect(timeRect.bottom, lessThanOrEqualTo(mediaRect.bottom));
    expect(timeRect.top, greaterThanOrEqualTo(mediaRect.top));
    final fallbackIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('meal-diary-entry-fallback-icon-meal')),
    );
    expect(fallbackIcon.icon, Icons.restaurant_outlined);
    expect(fallbackIcon.size, TioSize.dp40);
    final summaryIcons = find.descendant(
      of: headerSummaryFinder,
      matching: find.byType(SvgPicture),
    );
    expect(summaryIcons, findsNWidgets(2));
    // An untinted asset paints the colour it was authored with, which no theme
    // and no analyzer can reach. Every summary glyph must resolve its colour
    // from the runtime theme instead.
    for (final icon in tester.widgetList<SvgPicture>(summaryIcons)) {
      expect(
        icon.colorFilter,
        isNotNull,
        reason: 'summary glyphs must be tinted from a governed theme role',
      );
    }
    expect(
      find.descendant(of: cardFinder, matching: find.byType(SvgPicture)),
      findsNothing,
    );
    expect(cardRect.right - overflowRect.right, TioSize.dp12);
    expect(overflowRect.top - cardRect.top, TioSize.dp12);
    expect(
      tester.getSize(find.byType(IconButton)),
      const Size.square(TioSize.dp48),
    );

    // Time is a scrim over the media surface, never an opaque pill/control.
    final scrim = tester.widget<DecoratedBox>(
      find.ancestor(of: timeFinder, matching: find.byType(DecoratedBox)).first,
    );
    final scrimDecoration = scrim.decoration as BoxDecoration;
    expect(scrimDecoration.gradient, isNotNull);
    expect(scrimDecoration.color, isNull);
    expect(scrimDecoration.borderRadius, isNull);
    expect(
      tester.getSize(find.byWidget(scrim)).width,
      mediaRect.width,
      reason: 'the scrim spans the media surface instead of hugging the text',
    );
    expect(tester.takeException(), isNull);

    await tester
        .tapAt(Offset(cardRect.left + TioSpacing.md, cardRect.bottom - 2));
    await tester.pump();
    expect(edits, ['meal']);

    await tester.tap(overflowFinder);
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Log this again'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(edits, ['meal'], reason: 'opening the menu must not tap the card');

    await tester.tap(find.byKey(const ValueKey('meal-log-edit-meal')));
    await tester.pumpAndSettle();
    expect(edits, ['meal', 'meal']);
  });

  testWidgets(
      'section header lets the divider absorb slack and keeps the summary '
      'flush with the content edge', (tester) async {
    for (final width in <double>[320, 390]) {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final categories = _FakeMealCategoriesRepository(
        MealCategoriesConfig.canonicalDefaults(),
      );
      final mealLogs = _ImmediateMealLogRepository({
        _localDate(11): [
          _entry(
            id: 'meal',
            categoryId: 'meal_slot_2',
            mealName: 'Rice',
            consumedAt: DateTime.utc(2026, 9, 11, 7, 35),
            calories: 9,
            protein: 4,
          ),
        ],
      });

      await _pumpHistoryView(
        tester,
        mealLogs: mealLogs,
        categories: categories,
        onEdit: (_) {},
      );
      await tester.pumpAndSettle();

      final sectionRect = tester.getRect(
        find.byKey(const ValueKey('meal-diary-section-meal_slot_2')),
      );
      final summaryRect = tester.getRect(
        find.byKey(const ValueKey('meal-diary-section-summary-meal_slot_2')),
      );
      final dividerRect = tester.getRect(find.byType(Divider));

      expect(
        summaryRect.right,
        sectionRect.right,
        reason: 'summary must sit at the content edge at ${width}dp',
      );
      expect(
        dividerRect.width,
        greaterThan(0),
        reason: 'the divider must keep absorbing the middle at ${width}dp',
      );
      expect(dividerRect.right, lessThanOrEqualTo(summaryRect.left));
      expect(summaryRect.left - dividerRect.right, TioSpacing.sm);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders dynamic sections and default time/note presentation',
      (tester) async {
    final dateController = MealDiaryDateController(clock: () => _today);
    final categories = _FakeMealCategoriesRepository(
      MealCategoriesConfig.canonicalDefaults(),
    );
    final mealLogs = _ImmediateMealLogRepository({
      _localDate(11): [
        _entry(
          id: 'breakfast',
          categoryId: 'meal_slot_1',
          mealName: 'Oats',
          consumedAt: DateTime.utc(2026, 9, 11, 2, 40),
          calories: 300,
          protein: 15,
        ),
        _entry(
          id: 'lunch-new',
          categoryId: 'meal_slot_2',
          mealName: null,
          note: 'Workout ke baad liya tha',
          consumedAt: DateTime.utc(2026, 9, 11, 9, 50),
          calories: 254,
          protein: 9,
        ),
        _entry(
          id: 'lunch-old',
          categoryId: 'meal_slot_2',
          mealName: 'Dal, 2 Roti, Ghee',
          consumedAt: DateTime.utc(2026, 9, 11, 7, 35),
          calories: 366,
          protein: 29,
        ),
      ],
    });

    await _pump(
      tester,
      dateController: dateController,
      mealLogs: mealLogs,
      categories: categories,
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Add'), findsOneWidget);
    expect(find.text('620 kcal'), findsOneWidget);
    expect(find.text('38g'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-diary-entry-note-lunch-new')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-diary-entry-note-preview-lunch-new')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('meal-diary-entry-time-lunch-new')),
      findsOneWidget,
    );

    final lunchY = tester
        .getTopLeft(
            find.byKey(const ValueKey('meal-diary-section-meal_slot_2')))
        .dy;
    final breakfastY = tester
        .getTopLeft(
            find.byKey(const ValueKey('meal-diary-section-meal_slot_1')))
        .dy;
    expect(lunchY, lessThan(breakfastY));

    final newestLunchY = tester
        .getTopLeft(find.byKey(const ValueKey('meal-diary-entry-lunch-new')))
        .dy;
    final olderLunchY = tester
        .getTopLeft(find.byKey(const ValueKey('meal-diary-entry-lunch-old')))
        .dy;
    expect(newestLunchY, lessThan(olderLunchY));
  });

  testWidgets('display preferences hide time and reveal one-line note preview',
      (tester) async {
    final dateController = MealDiaryDateController(clock: () => _today);
    final categories = _FakeMealCategoriesRepository(
      MealCategoriesConfig.canonicalDefaults(),
    );
    final mealLogs = _ImmediateMealLogRepository({
      _localDate(11): [
        _entry(
          id: 'meal',
          categoryId: 'meal_slot_2',
          mealName: 'Banana Shake',
          note: 'Workout ke baad liya tha aur note kaafi lamba hai',
          consumedAt: DateTime.utc(2026, 9, 11, 9, 50),
          calories: 254,
          protein: 9,
        ),
      ],
    });
    final preferences = MealDiaryDisplayPreferencesController(
      _FakeDisplayPreferencesRepository(
        const MealDiaryDisplayPreferences(
          showMealTimes: false,
          mealNotesEnabled: true,
          showMealNotePreview: true,
        ),
      ),
    );
    await preferences.load();

    await _pump(
      tester,
      dateController: dateController,
      mealLogs: mealLogs,
      categories: categories,
      preferences: preferences,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-entry-time-meal')),
      findsNothing,
    );
    final preview = tester.widget<Text>(
      find.byKey(const ValueKey('meal-diary-entry-note-preview-meal')),
    );
    expect(preview.maxLines, 1);
    expect(preview.overflow, TextOverflow.ellipsis);
  });

  testWidgets('Meal Notes off hides both note icon and preview',
      (tester) async {
    final dateController = MealDiaryDateController(clock: () => _today);
    final categories = _FakeMealCategoriesRepository(
      MealCategoriesConfig.canonicalDefaults(),
    );
    final mealLogs = _ImmediateMealLogRepository({
      _localDate(11): [
        _entry(
          id: 'meal-notes-off',
          categoryId: 'meal_slot_2',
          mealName: 'Banana Shake',
          note: 'Stored note stays on the MealLogEntry',
          consumedAt: DateTime.utc(2026, 9, 11, 9, 50),
          calories: 254,
          protein: 9,
        ),
      ],
    });
    final preferences = MealDiaryDisplayPreferencesController(
      _FakeDisplayPreferencesRepository(
        const MealDiaryDisplayPreferences(
          mealNotesEnabled: false,
          showMealNotePreview: true,
        ),
      ),
    );
    await preferences.load();

    await _pump(
      tester,
      dateController: dateController,
      mealLogs: mealLogs,
      categories: categories,
      preferences: preferences,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-entry-note-meal-notes-off')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('meal-diary-entry-note-preview-meal-notes-off'),
      ),
      findsNothing,
    );
  });

  group('section nutrition summary preference', () {
    testWidgets(
        'ON with both known values renders one aggregate group with both '
        'icons and values', (tester) async {
      final dateController = MealDiaryDateController(clock: () => _today);
      final categories = _FakeMealCategoriesRepository(
        MealCategoriesConfig.canonicalDefaults(),
      );
      final mealLogs = _ImmediateMealLogRepository({
        _localDate(11): [
          _entry(
            id: 'both',
            categoryId: 'meal_slot_2',
            mealName: 'Rice',
            consumedAt: DateTime.utc(2026, 9, 11, 7, 35),
            calories: 254,
            protein: 9,
          ),
        ],
      });
      final preferences = MealDiaryDisplayPreferencesController(
        _FakeDisplayPreferencesRepository(
          const MealDiaryDisplayPreferences(showMealSectionNutrition: true),
        ),
      );
      await preferences.load();

      await _pump(
        tester,
        dateController: dateController,
        mealLogs: mealLogs,
        categories: categories,
        preferences: preferences,
      );
      await tester.pumpAndSettle();

      final summary = find.byKey(
        const ValueKey('meal-diary-section-summary-meal_slot_2'),
      );
      expect(summary, findsOneWidget);
      expect(
        find.descendant(of: summary, matching: find.byType(SvgPicture)),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: summary, matching: find.text('254 kcal')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: summary, matching: find.text('9g')),
        findsOneWidget,
      );

      // Individual card values remain their own, untouched, separate copy.
      expect(
        find.byKey(const ValueKey('meal-diary-entry-calories-both')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('meal-diary-entry-protein-both')),
        findsOneWidget,
      );
    });

    testWidgets('ON with only calories known renders only calories',
        (tester) async {
      final dateController = MealDiaryDateController(clock: () => _today);
      final categories = _FakeMealCategoriesRepository(
        MealCategoriesConfig.canonicalDefaults(),
      );
      final mealLogs = _ImmediateMealLogRepository({
        _localDate(11): [
          _entryWithNutrients(
            id: 'calories-only',
            categoryId: 'meal_slot_2',
            mealName: 'Rice',
            consumedAt: DateTime.utc(2026, 9, 11, 7, 35),
            nutrients: {NutrientId.energy: 254},
          ),
        ],
      });
      final preferences = MealDiaryDisplayPreferencesController(
        _FakeDisplayPreferencesRepository(
          const MealDiaryDisplayPreferences(showMealSectionNutrition: true),
        ),
      );
      await preferences.load();

      await _pump(
        tester,
        dateController: dateController,
        mealLogs: mealLogs,
        categories: categories,
        preferences: preferences,
      );
      await tester.pumpAndSettle();

      final summary = find.byKey(
        const ValueKey('meal-diary-section-summary-meal_slot_2'),
      );
      expect(summary, findsOneWidget);
      expect(
        find.descendant(of: summary, matching: find.byType(SvgPicture)),
        findsOneWidget,
        reason: 'only the calorie glyph, never a fabricated protein value',
      );
      expect(
        find.descendant(of: summary, matching: find.text('254 kcal')),
        findsOneWidget,
      );
    });

    testWidgets('ON with only protein known renders only protein',
        (tester) async {
      final dateController = MealDiaryDateController(clock: () => _today);
      final categories = _FakeMealCategoriesRepository(
        MealCategoriesConfig.canonicalDefaults(),
      );
      final mealLogs = _ImmediateMealLogRepository({
        _localDate(11): [
          _entryWithNutrients(
            id: 'protein-only',
            categoryId: 'meal_slot_2',
            mealName: 'Egg whites',
            consumedAt: DateTime.utc(2026, 9, 11, 7, 35),
            nutrients: {NutrientId.protein: 9},
          ),
        ],
      });
      final preferences = MealDiaryDisplayPreferencesController(
        _FakeDisplayPreferencesRepository(
          const MealDiaryDisplayPreferences(showMealSectionNutrition: true),
        ),
      );
      await preferences.load();

      await _pump(
        tester,
        dateController: dateController,
        mealLogs: mealLogs,
        categories: categories,
        preferences: preferences,
      );
      await tester.pumpAndSettle();

      final summary = find.byKey(
        const ValueKey('meal-diary-section-summary-meal_slot_2'),
      );
      expect(summary, findsOneWidget);
      expect(
        find.descendant(of: summary, matching: find.byType(SvgPicture)),
        findsOneWidget,
        reason: 'only the protein glyph, never a fabricated calorie value',
      );
      expect(
        find.descendant(of: summary, matching: find.text('9g')),
        findsOneWidget,
      );
    });

    testWidgets(
        'OFF hides the whole trailing group but leaves individual card '
        'nutrition unchanged', (tester) async {
      final dateController = MealDiaryDateController(clock: () => _today);
      final categories = _FakeMealCategoriesRepository(
        MealCategoriesConfig.canonicalDefaults(),
      );
      final mealLogs = _ImmediateMealLogRepository({
        _localDate(11): [
          _entry(
            id: 'off',
            categoryId: 'meal_slot_2',
            mealName: 'Rice',
            consumedAt: DateTime.utc(2026, 9, 11, 7, 35),
            calories: 254,
            protein: 9,
          ),
        ],
      });
      final preferences = MealDiaryDisplayPreferencesController(
        _FakeDisplayPreferencesRepository(
          const MealDiaryDisplayPreferences(showMealSectionNutrition: false),
        ),
      );
      await preferences.load();

      await _pump(
        tester,
        dateController: dateController,
        mealLogs: mealLogs,
        categories: categories,
        preferences: preferences,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('meal-diary-section-summary-meal_slot_2'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('meal-diary-section-meal_slot_2'),
          ),
          matching: find.byType(SvgPicture),
        ),
        findsNothing,
        reason: 'no header glyph must survive when the group is hidden',
      );

      // The divider absorbs the freed width instead of leaving a gap; the
      // section content still ends at the same right edge.
      final sectionRect = tester.getRect(
        find.byKey(const ValueKey('meal-diary-section-meal_slot_2')),
      );
      final dividerRect = tester.getRect(find.byType(Divider));
      expect(dividerRect.right, sectionRect.right);

      // Individual card nutrition is a separate concern and stays visible.
      expect(
        find.byKey(const ValueKey('meal-diary-entry-calories-off')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('meal-diary-entry-protein-off')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a slower old date read cannot overwrite the newer selection',
      (tester) async {
    final dateController = MealDiaryDateController(clock: () => _today);
    final categories = _FakeMealCategoriesRepository(
      MealCategoriesConfig.canonicalDefaults(),
    );
    final mealLogs = _ControlledMealLogRepository();

    await _pump(
      tester,
      dateController: dateController,
      mealLogs: mealLogs,
      categories: categories,
    );
    await tester.pump();
    expect(mealLogs.requests, [_localDate(11)]);

    dateController.select(DateTime(2026, 9, 10));
    await tester.pump();
    expect(mealLogs.requests, [_localDate(11), _localDate(10)]);

    mealLogs.complete(
      _localDate(10),
      [
        _entry(
          id: 'new-date',
          categoryId: 'meal_slot_1',
          mealName: 'Newer selection',
          consumedAt: DateTime.utc(2026, 9, 10, 2),
          calories: 200,
          protein: 10,
          localDay: 10,
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Newer selection'), findsOneWidget);

    mealLogs.complete(
      _localDate(11),
      [
        _entry(
          id: 'old-date',
          categoryId: 'meal_slot_1',
          mealName: 'Old slow result',
          consumedAt: DateTime.utc(2026, 9, 11, 2),
          calories: 100,
          protein: 5,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Newer selection'), findsOneWidget);
    expect(find.text('Old slow result'), findsNothing);
  });
}

Future<void> _pumpHistoryView(
  WidgetTester tester, {
  required MealLogRepository mealLogs,
  required MealCategoriesRepository categories,
  required ValueChanged<String> onEdit,
}) async {
  final request = MealDiaryHistoryRequest(
    mealLogRepository: mealLogs,
    mealCategoriesRepository: categories,
    localDate: _localDate(11),
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MealDiaryHistoryView(
              date: DateTime(2026, 9, 11),
              request: request,
              onEdit: onEdit,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required MealDiaryDateController dateController,
  required MealLogRepository mealLogs,
  required MealCategoriesRepository categories,
  MealDiaryDisplayPreferencesController? preferences,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealDiaryDateControllerProvider.overrideWith((ref) => dateController),
        mealDiaryMealLogRepositoryProvider.overrideWithValue(mealLogs),
        if (preferences != null)
          mealDiaryDisplayPreferencesControllerProvider
              .overrideWith((ref) => preferences),
      ],
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: MealDiaryPage(mealCategoriesRepository: categories),
        ),
      ),
    ),
  );
}

MealLogLocalDate _localDate(int day) =>
    MealLogLocalDate(year: 2026, month: 9, day: day);

MealLogEntry _entry({
  required String id,
  required String categoryId,
  required String? mealName,
  String? note,
  required DateTime consumedAt,
  required num calories,
  required num protein,
  int localDay = 11,
}) {
  return MealLogEntry.manual(
    id: id,
    userId: 'user-1',
    mealCategoryId: categoryId,
    mealName: mealName,
    note: note,
    consumedAt: consumedAt,
    consumedLocalDate: _localDate(localDay),
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: {
        NutrientId.energy: calories,
        NutrientId.protein: protein,
      },
    ),
    createdAt: DateTime.utc(2026, 9, localDay),
    updatedAt: DateTime.utc(2026, 9, localDay),
  );
}

/// Like [_entry], but with a caller-chosen exact nutrient set instead of
/// always both energy and protein — needed to reach a section aggregate that
/// legitimately knows only one of the two values.
MealLogEntry _entryWithNutrients({
  required String id,
  required String categoryId,
  required String? mealName,
  required DateTime consumedAt,
  required Map<NutrientId, num> nutrients,
  int localDay = 11,
}) {
  return MealLogEntry.manual(
    id: id,
    userId: 'user-1',
    mealCategoryId: categoryId,
    mealName: mealName,
    consumedAt: consumedAt,
    consumedLocalDate: _localDate(localDay),
    consumedUtcOffsetMinutes: 330,
    captureSource: MealLogCaptureSource.quickAdd,
    manualNutritionSnapshot: NutritionSnapshot(
      schemaVersion: 1,
      nutrients: nutrients,
    ),
    createdAt: DateTime.utc(2026, 9, localDay),
    updatedAt: DateTime.utc(2026, 9, localDay),
  );
}

final class _ImmediateMealLogRepository implements MealLogRepository {
  _ImmediateMealLogRepository(this.entriesByDate);

  final Map<MealLogLocalDate, List<MealLogEntry>> entriesByDate;

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<List<MealLogEntry>> listByLocalDate(
          MealLogLocalDate localDate) async =>
      List<MealLogEntry>.unmodifiable(entriesByDate[localDate] ?? const []);

  @override
  Future<MealLogEntry?> readById(String id) => throw UnimplementedError();
}

final class _ControlledMealLogRepository implements MealLogRepository {
  final Map<MealLogLocalDate, Completer<List<MealLogEntry>>> _completers = {};
  final List<MealLogLocalDate> requests = [];

  @override
  Future<MealLogEntry> createManual(ManualMealLogCreate input) =>
      throw UnimplementedError();

  @override
  Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate) {
    requests.add(localDate);
    return (_completers[localDate] ??= Completer<List<MealLogEntry>>()).future;
  }

  void complete(MealLogLocalDate date, List<MealLogEntry> entries) {
    _completers[date]!.complete(entries);
  }

  @override
  Future<MealLogEntry?> readById(String id) => throw UnimplementedError();
}

final class _FakeMealCategoriesRepository implements MealCategoriesRepository {
  _FakeMealCategoriesRepository(this.config);

  final MealCategoriesConfig config;

  @override
  Future<MealCategoriesConfig> read() async => config;

  @override
  Future<void> upsert(MealCategoriesConfig config) =>
      throw UnimplementedError();
}

final class _FakeDisplayPreferencesRepository
    implements MealDiaryDisplayPreferencesRepository {
  _FakeDisplayPreferencesRepository(this.value);

  MealDiaryDisplayPreferences value;

  @override
  Future<void> clear() async {
    value = const MealDiaryDisplayPreferences();
  }

  @override
  Future<MealDiaryDisplayPreferences> read() async => value;

  @override
  Future<void> write(MealDiaryDisplayPreferences preferences) async {
    value = preferences;
  }
}
