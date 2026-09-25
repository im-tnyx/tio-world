import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

Map<String, Object?> syntheticRow({
  String id = 'ex_synthetic_alpha',
  String title = 'Synthetic Alpha Lift',
}) =>
    {
      'id': id,
      'title': title,
      'muscleGroup': 'group_upper',
      'primaryMuscles': ['muscle_a'],
      'secondaryMuscles': <String>[],
      'equipment': {'primary': 'gear_a'},
      'category': 'kind_a',
      'levels': ['level_1'],
      'isArchived': false,
      'isCustom': false,
    };

String documentWith(List<Object?> rows, {int schemaVersion = 1}) => jsonEncode({
      'schemaVersion': schemaVersion,
      'catalogVersion': 1,
      'exercises': rows,
    });

final class StringAssetBundle extends AssetBundle {
  StringAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Missing test asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Missing test asset: $key');
    return value;
  }
}

final class ThrowingAssetBundle extends AssetBundle {
  ThrowingAssetBundle(this.error);

  final Object error;

  @override
  Future<ByteData> load(String key) async => throw error;

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      throw error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testAssetKey = 'catalog.json';

  test('loads document rows through the existing W3A1 parser', () async {
    final source = AssetBundleExerciseCatalogSource(
      StringAssetBundle({
        testAssetKey: documentWith([syntheticRow()]),
      }),
      assetKey: testAssetKey,
    );

    final catalog = await source.load();

    expect(catalog.all, hasLength(1));
    expect(catalog.all.single.ref, isA<CatalogExerciseRef>());
    expect(catalog.all.single.displayName, 'Synthetic Alpha Lift');
  });

  test('reports a missing asset distinctly', () {
    final source = AssetBundleExerciseCatalogSource(
      StringAssetBundle(const {}),
      assetKey: testAssetKey,
    );

    expect(
      source.load(),
      throwsA(
        isA<MissingExerciseCatalogAssetException>()
            .having((error) => error.assetKey, 'assetKey', testAssetKey)
            .having((error) => error.cause, 'cause', isA<FlutterError>())
            .having((error) => error.stackTrace, 'stackTrace', isNotNull),
      ),
    );
  });

  test('does not misclassify unexpected bundle failures as missing', () {
    final failure = StateError('Unexpected bundle failure');
    final source = AssetBundleExerciseCatalogSource(
      ThrowingAssetBundle(failure),
      assetKey: testAssetKey,
    );

    expect(source.load(), throwsA(same(failure)));
  });

  test('reports malformed JSON as an invalid document', () {
    final source = AssetBundleExerciseCatalogSource(
      StringAssetBundle(const {testAssetKey: '{'}),
      assetKey: testAssetKey,
    );

    expect(
      source.load(),
      throwsA(isA<InvalidExerciseCatalogDocumentException>()),
    );
  });

  test('reports unsupported schema versions distinctly', () {
    final source = AssetBundleExerciseCatalogSource(
      StringAssetBundle({
        testAssetKey: documentWith(const [], schemaVersion: 2),
      }),
      assetKey: testAssetKey,
    );

    expect(
      source.load(),
      throwsA(isA<UnsupportedExerciseCatalogSchemaVersionException>()),
    );
  });

  test('preserves InvalidExerciseCatalogException for invalid rows', () {
    final source = AssetBundleExerciseCatalogSource(
      StringAssetBundle({
        testAssetKey: documentWith([
          {'id': 'ex_incomplete'},
        ]),
      }),
      assetKey: testAssetKey,
    );

    expect(source.load(), throwsA(isA<InvalidExerciseCatalogException>()));
  });

  test('rejects duplicate refs through the existing W3A1 parser', () {
    final source = AssetBundleExerciseCatalogSource(
      StringAssetBundle({
        testAssetKey: documentWith([
          syntheticRow(),
          syntheticRow(title: 'Synthetic Duplicate'),
        ]),
      }),
      assetKey: testAssetKey,
    );

    expect(source.load(), throwsA(isA<InvalidExerciseCatalogException>()));
  });

  group('production package asset', () {
    test('loads and maps the exact registered catalog', () async {
      final source = AssetBundleExerciseCatalogSource(rootBundle);

      final catalog = await source.load();

      expect(catalog.all, isNotEmpty);
      expect(
        catalog.all.every((exercise) => exercise.ref is CatalogExerciseRef),
        isTrue,
      );
      expect(catalog.all.map((exercise) => exercise.ref).toSet(),
          hasLength(catalog.all.length));
      for (final exercise in catalog.all) {
        expect(catalog.byRef(exercise.ref), same(exercise));
      }
    });

    test('contains only the approved sanitized document fields', () async {
      final source = await rootBundle.loadString(exerciseCatalogAssetKey);
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      final exercises = decoded['exercises'] as List<dynamic>;

      expect(
          decoded.keys,
          unorderedEquals([
            'schemaVersion',
            'catalogVersion',
            'exercises',
          ]));
      expect(decoded['schemaVersion'], 1);
      expect(decoded['catalogVersion'], 1);
      expect(exercises, isNotEmpty);

      const allowedRowKeys = {
        'id',
        'title',
        'muscleGroup',
        'primaryMuscles',
        'secondaryMuscles',
        'equipment',
        'category',
        'levels',
        'isArchived',
        'isCustom',
      };
      for (final row in exercises.cast<Map<String, dynamic>>()) {
        expect(row.keys, unorderedEquals(allowedRowKeys),
            reason: '${row['id']}');
        expect(
          (row['equipment'] as Map<String, dynamic>).keys,
          unorderedEquals(['primary']),
          reason: '${row['id']}.equipment',
        );
      }

      expect(source, isNot(contains('http://')));
      expect(source, isNot(contains('https://')));
      expect(source.toLowerCase(), isNot(contains('youtube')));
      expect(source.toLowerCase(), isNot(contains('apilyfta')));
      expect(source.toLowerCase(), isNot(contains('cloudfront')));
      final forbiddenKey = RegExp(
        r'"(?:media|source|legacyExerciseIds|localizedInstructions|standards|goals|tracking)"\s*:',
      );
      expect(forbiddenKey.hasMatch(source), isFalse);
    });
  });
}
