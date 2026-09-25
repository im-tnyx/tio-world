import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

import 'exercises_fixtures.dart';

Future<void> _pumpPage(
  WidgetTester tester, {
  required ExerciseCatalogRepository repository,
  ExerciseMediaGender? mediaGender,
  TioThemeMode mode = TioThemeMode.light,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exerciseCatalogRepositoryProvider.overrideWithValue(repository),
        exerciseViewerMediaGenderProvider.overrideWithValue(mediaGender),
      ],
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const ExercisesPage(),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Finder _row(String id) => find.byKey(ValueKey('exercise-row-$id'));

Finder _thumbnail(String id) => find.byKey(ValueKey('exercise-thumbnail-$id'));

Finder _message(String text) => find.text(text);

Future<void> _openFilters(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('exercises-filter')));
  await tester.pumpAndSettle();
}

Future<void> _showResults(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('exercise-filter-show-results')));
  await tester.pumpAndSettle();
}

late _FakeImageHttpClient _images;

/// [testWidgets] with network images served by [_images].
///
/// The painting debug hook must be unset before the test body ends, so it
/// is scoped here rather than in setUp/tearDown.
void _testWidgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    _images = _FakeImageHttpClient();
    debugNetworkImageHttpClientProvider = () => _images;
    try {
      await body(tester);
    } finally {
      debugNetworkImageHttpClientProvider = null;
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    }
  });
}

void main() {
  group('states', () {
    _testWidgets('loading shows a labelled spinner and disables browsing',
        (tester) async {
      final repository = FakeExerciseCatalogRepository(
        catalog: syntheticCatalog(),
        hold: true,
      );
      await _pumpPage(tester, repository: repository, settle: false);
      await tester.pump();

      expect(find.byKey(const ValueKey('exercises-loading')), findsOneWidget);
      expect(find.bySemanticsLabel(ExercisesPage.loadingLabel), findsOneWidget);
      expect(
        tester
            .widget<TioInput>(find.byKey(const ValueKey('exercises-search')))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<TioButton>(find.byKey(const ValueKey('exercises-filter')))
            .enabled,
        isFalse,
      );

      repository.release();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('exercises-loading')), findsNothing);
      expect(find.byKey(const ValueKey('exercises-list')), findsOneWidget);
    });

    _testWidgets('empty catalog', (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(
          catalog: ExerciseCatalog(const []),
        ),
      );

      expect(_message(ExercisesPage.emptyCatalogMessage), findsOneWidget);
      expect(find.byKey(const ValueKey('exercises-list')), findsNothing);
    });

    _testWidgets('search with no match shows the no-match state',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );

      await tester.enterText(
        find.byKey(const ValueKey('exercises-search')),
        'zzz',
      );
      await tester.pumpAndSettle();

      expect(_message(ExercisesPage.noMatchMessage), findsOneWidget);
      expect(find.byKey(const ValueKey('exercises-list')), findsNothing);
    });

    final failures = <String, (Object, String)>{
      'missing catalog': (
        MissingExerciseCatalogAssetException(
          assetKey: exerciseCatalogAssetKey,
          cause: FlutterError('missing'),
          stackTrace: StackTrace.empty,
        ),
        ExercisesPage.missingCatalogMessage,
      ),
      'malformed catalog': (
        const InvalidExerciseCatalogDocumentException(
          path: r'$',
          problem: 'must be a JSON object',
        ),
        ExercisesPage.malformedCatalogMessage,
      ),
      'unexpected failure': (
        ExerciseCatalogAssetLoadException(
          assetKey: exerciseCatalogAssetKey,
          cause: PlatformException(code: 'io'),
          stackTrace: StackTrace.empty,
        ),
        ExercisesPage.failedMessage,
      ),
    };

    for (final entry in failures.entries) {
      _testWidgets('${entry.key} shows its message with no Retry',
          (tester) async {
        await _pumpPage(
          tester,
          repository: FakeExerciseCatalogRepository(error: entry.value.$1),
        );

        expect(_message(entry.value.$2), findsOneWidget);
        expect(find.textContaining('Retry'), findsNothing);
        expect(find.textContaining('Try again'), findsNothing);
        // The only button on the page is the disabled filter action.
        expect(find.byType(TioButton), findsOneWidget);
        expect(
          tester
              .widget<TioButton>(find.byKey(const ValueKey('exercises-filter')))
              .enabled,
          isFalse,
        );
      });
    }
  });

  group('screen', () {
    _testWidgets('shows the approved title, search, filter action and rows',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );

      expect(
        find.descendant(
            of: find.byType(AppBar), matching: find.text('Exercises')),
        findsOneWidget,
      );
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Search exercises'), findsOneWidget);
      expect(find.text('Filter exercises'), findsOneWidget);

      final searchWidth =
          tester.getSize(find.byKey(const ValueKey('exercises-search'))).width;
      expect(
          searchWidth,
          tester.view.physicalSize.width / tester.view.devicePixelRatio -
              TioSpacing.lg * 2);

      expect(_row('ex_synthetic_curl'), findsOneWidget);
      expect(find.text('Synthetic Curl'), findsOneWidget);
      expect(find.text('Dumbbell • Upper arms'), findsOneWidget);
      expect(find.text('EZ bar • Chest'), findsOneWidget);
      expect(find.text('Upper arms'), findsOneWidget);
      expect(find.text('Synthetic Archived Curl'), findsNothing);
    });

    _testWidgets('rows have no icon, chevron, action or tap behavior',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );

      for (final id in [
        'ex_synthetic_curl',
        'ex_synthetic_press',
        'ex_synthetic_stretch',
      ]) {
        final row = _row(id);
        for (final type in [
          Icon,
          IconButton,
          InkWell,
          GestureDetector,
          ListTile,
          TioButton,
        ]) {
          expect(
            find.descendant(of: row, matching: find.byType(type)),
            findsNothing,
            reason: '$id must not contain $type',
          );
        }
        final semantics = tester.getSemantics(row).getSemanticsData();
        expect(semantics.hasAction(SemanticsAction.tap), isFalse);
        expect(semantics.flagsCollection.isButton, isFalse);
      }

      await tester.tap(_row('ex_synthetic_curl'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ExercisesPage), findsOneWidget);
    });

    _testWidgets('a row reads its name and metadata as one node',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );

      expect(
        tester.getSemantics(_row('ex_synthetic_curl')),
        matchesSemantics(label: 'Synthetic Curl\nDumbbell • Upper arms'),
      );
      handle.dispose();
    });

    for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
      _testWidgets('renders on the ${mode.name} theme background',
          (tester) async {
        await _pumpPage(
          tester,
          repository:
              FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
          mode: mode,
        );

        final context = tester.element(find.byType(ExercisesPage));
        final scaffold = tester.widget<Scaffold>(
          find.byKey(const ValueKey('exercises-page')),
        );
        expect(scaffold.backgroundColor, context.tioColors.background);
        final title = tester.widget<Text>(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Exercises'),
          ),
        );
        expect(title.style?.color, context.tioColors.textPrimary);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('thumbnails', () {
    _testWidgets('a loaded image renders the viewer-gender URL',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
        mediaGender: ExerciseMediaGender.female,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(
        find.descendant(
          of: _thumbnail('ex_synthetic_curl'),
          matching: find.byType(Image),
        ),
      );
      expect(
        (image.image as NetworkImage).url,
        'https://media.example/curl-female.png',
      );
      expect(image.excludeFromSemantics, isTrue);
      expect(
        tester.getSize(_thumbnail('ex_synthetic_curl')).height,
        ExerciseThumbnail.size,
      );
      expect(_images.requested,
          contains(Uri.parse('https://media.example/curl-female.png')));
    });

    _testWidgets('an Exercise without media is a text-only row',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );

      expect(_thumbnail('ex_synthetic_stretch'), findsNothing);
      expect(
        find.descendant(
          of: _row('ex_synthetic_stretch'),
          matching: find.byType(Image),
        ),
        findsNothing,
      );
      expect(find.text('Synthetic Stretch'), findsOneWidget);
    });

    _testWidgets('a failed image collapses to a clean text-only row',
        (tester) async {
      _images.statusCode = HttpStatus.notFound;
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      final row = _row('ex_synthetic_curl');
      expect(
        find.descendant(of: row, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        tester.getSize(_thumbnail('ex_synthetic_curl')),
        Size.zero,
      );
      expect(
        tester.getTopLeft(find.text('Synthetic Curl')).dx,
        tester.getTopLeft(find.text('Synthetic Stretch')).dx,
        reason: 'the name aligns with rows that never had media',
      );
    });
  });

  group('filters', () {
    _testWidgets('sheet lists Muscle, Equipment and Category options',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );
      await _openFilters(tester);

      final sheet = find.byKey(const ValueKey('exercise-filter-sheet'));
      expect(sheet, findsOneWidget);
      for (final text in [
        'Filter exercises',
        'Muscle',
        'Equipment',
        'Category',
        'Chest',
        'Upper arms',
        'Dumbbell',
        'EZ bar',
        'Strength',
        'Stretch',
        'Clear all',
        'Show results',
      ]) {
        expect(
          find.descendant(of: sheet, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(
        find.descendant(of: sheet, matching: find.text('Waist')),
        findsNothing,
        reason: 'archived-only values are not offered',
      );
    });

    _testWidgets('each dimension is single-select and applies on Show results',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );
      await _openFilters(tester);

      await tester.tap(find.byKey(
        const ValueKey('exercise-filter-muscle-chest'),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(
        const ValueKey('exercise-filter-muscle-upper_arms'),
      ));
      await tester.pumpAndSettle();

      ChoiceChip chip(String key) =>
          tester.widget<ChoiceChip>(find.byKey(ValueKey(key)));
      expect(chip('exercise-filter-muscle-chest').selected, isFalse);
      expect(chip('exercise-filter-muscle-upper_arms').selected, isTrue);

      // Still a draft: rows are unchanged until Show results.
      expect(_row('ex_synthetic_press'), findsOneWidget);

      await tester.tap(find.byKey(
        const ValueKey('exercise-filter-category-stretch'),
      ));
      await _showResults(tester);

      expect(find.byKey(const ValueKey('exercise-filter-sheet')), findsNothing);
      expect(_row('ex_synthetic_stretch'), findsOneWidget);
      expect(_row('ex_synthetic_curl'), findsNothing);
      expect(_row('ex_synthetic_press'), findsNothing);
      expect(
        tester
            .widget<TioButton>(find.byKey(const ValueKey('exercises-filter')))
            .semanticLabel,
        'Filter exercises, 2 filters active',
      );
    });

    _testWidgets('equipment filter narrows rows', (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );
      await _openFilters(tester);
      await tester.tap(find.byKey(
        const ValueKey('exercise-filter-equipment-ez_bar'),
      ));
      await _showResults(tester);

      expect(_row('ex_synthetic_press'), findsOneWidget);
      expect(_row('ex_synthetic_curl'), findsNothing);
      expect(
        tester
            .widget<TioButton>(find.byKey(const ValueKey('exercises-filter')))
            .semanticLabel,
        'Filter exercises, 1 filter active',
      );
    });

    _testWidgets('tapping a selected chip deselects it', (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );
      await _openFilters(tester);
      const key = ValueKey('exercise-filter-category-strength');

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      expect(tester.widget<ChoiceChip>(find.byKey(key)).selected, isFalse);
    });

    _testWidgets('filters combine with search and can reach no-match',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercises-search')),
        'curl',
      );
      await tester.pumpAndSettle();
      await _openFilters(tester);
      await tester.tap(find.byKey(
        const ValueKey('exercise-filter-category-stretch'),
      ));
      await _showResults(tester);

      expect(_message(ExercisesPage.noMatchMessage), findsOneWidget);
    });

    _testWidgets('Clear all empties the draft and reopening keeps selection',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );
      await _openFilters(tester);
      await tester.tap(find.byKey(
        const ValueKey('exercise-filter-muscle-chest'),
      ));
      await _showResults(tester);
      expect(_row('ex_synthetic_curl'), findsNothing);

      await _openFilters(tester);
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(
              const ValueKey('exercise-filter-muscle-chest'),
            ))
            .selected,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('exercise-filter-clear-all')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(
              const ValueKey('exercise-filter-muscle-chest'),
            ))
            .selected,
        isFalse,
      );
      await _showResults(tester);

      expect(_row('ex_synthetic_curl'), findsOneWidget);
      expect(
        tester
            .widget<TioButton>(find.byKey(const ValueKey('exercises-filter')))
            .semanticLabel,
        'Filter exercises',
      );
    });

    _testWidgets('dismissing the sheet does not apply the draft',
        (tester) async {
      await _pumpPage(
        tester,
        repository: FakeExerciseCatalogRepository(catalog: syntheticCatalog()),
      );
      await _openFilters(tester);
      await tester.tap(find.byKey(
        const ValueKey('exercise-filter-muscle-chest'),
      ));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('exercise-filter-sheet')), findsNothing);
      expect(_row('ex_synthetic_curl'), findsOneWidget);
    });
  });
}

/// 1×1 transparent PNG.
final _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Serves [_transparentPng] (or [statusCode]) for every image request.
class _FakeImageHttpClient extends Fake implements HttpClient {
  int statusCode = HttpStatus.ok;
  final requested = <Uri>[];

  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requested.add(url);
    return _FakeImageRequest(statusCode);
  }
}

class _FakeImageRequest extends Fake implements HttpClientRequest {
  _FakeImageRequest(this.statusCode);

  final int statusCode;

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeImageResponse(statusCode);
}

class _FakeHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeImageResponse extends Fake implements HttpClientResponse {
  _FakeImageResponse(this.statusCode);

  @override
  final int statusCode;

  List<int> get _body => statusCode == HttpStatus.ok ? _transparentPng : [];

  @override
  int get contentLength => _body.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.value(_body).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}
