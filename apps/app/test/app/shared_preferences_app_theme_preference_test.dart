import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_core/core.dart';

const _v2Key = 'app_theme_mode_v2';
const _legacyKey = 'app_theme_mode';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingPreferences store;

  void useStore(Map<String, Object> data) {
    store = _RecordingPreferences(data);
    SharedPreferencesAsyncPlatform.instance = store;
  }

  setUp(() => useStore({}));

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  group('legacy migration', () {
    for (final testCase in const [
      (legacy: 'system', v2: 'system', mode: TioThemeMode.system),
      (legacy: 'light', v2: 'light', mode: TioThemeMode.light),
      (legacy: 'dark', v2: 'tio_dark', mode: TioThemeMode.tioDark),
      (legacy: 'oled', v2: 'dark', mode: TioThemeMode.dark),
    ]) {
      test(
          'legacy ${testCase.legacy} migrates to V2 ${testCase.v2} '
          'and keeps the legacy mirror', () async {
        useStore({_legacyKey: testCase.legacy});

        final mode = await SharedPreferencesAppThemePreference().read();

        expect(mode, testCase.mode);
        expect(store.data[_v2Key], testCase.v2);
        expect(store.data[_legacyKey], testCase.legacy,
            reason: 'the legacy rollback mirror is retained unchanged');
        expect(store.removedKeys, isEmpty);
      });
    }

    test('a failed V2 migration write keeps the mapped mode and legacy key',
        () async {
      useStore({_legacyKey: 'oled'});
      store.failSetStringKeys.add(_v2Key);

      final mode = await SharedPreferencesAppThemePreference().read();

      expect(mode, TioThemeMode.dark,
          reason: 'the session keeps the migrated selection, not System');
      expect(store.data.containsKey(_v2Key), isFalse);
      expect(store.data[_legacyKey], 'oled');

      store.failSetStringKeys.clear();
      final retried = await SharedPreferencesAppThemePreference().read();

      expect(retried, TioThemeMode.dark);
      expect(store.data[_v2Key], 'dark');
      expect(store.data[_legacyKey], 'oled');
    });

    test('corrupt legacy does not create V2', () async {
      useStore({_legacyKey: 'unsupported'});

      expect(await SharedPreferencesAppThemePreference().read(), isNull);
      expect(store.data.containsKey(_v2Key), isFalse);
      expect(store.data[_legacyKey], 'unsupported');
      expect(store.writes, isEmpty);
    });

    test('no stored value reads as missing', () async {
      expect(await SharedPreferencesAppThemePreference().read(), isNull);
      expect(store.writes, isEmpty);
    });
  });

  group('V2 precedence', () {
    for (final testCase in const [
      (v2: 'dark', legacy: 'dark', mode: TioThemeMode.dark),
      (v2: 'tio_dark', legacy: 'oled', mode: TioThemeMode.tioDark),
      (v2: 'light', legacy: 'system', mode: TioThemeMode.light),
      (v2: 'system', legacy: 'light', mode: TioThemeMode.system),
    ]) {
      test('valid V2 ${testCase.v2} wins over legacy ${testCase.legacy}',
          () async {
        useStore({_v2Key: testCase.v2, _legacyKey: testCase.legacy});

        expect(
            await SharedPreferencesAppThemePreference().read(), testCase.mode);
        expect(store.writes, isEmpty);
        expect(store.removedKeys, isEmpty);
      });
    }

    test('corrupt V2 reads as missing without consulting legacy', () async {
      useStore({_v2Key: 'oled', _legacyKey: 'dark'});

      expect(await SharedPreferencesAppThemePreference().read(), isNull);
      expect(store.data[_v2Key], 'oled');
      expect(store.data[_legacyKey], 'dark');
      expect(store.writes, isEmpty);
      expect(store.removedKeys, isEmpty);
    });

    test('corrupt V2 without legacy reads as missing', () async {
      useStore({_v2Key: 'unsupported'});

      expect(await SharedPreferencesAppThemePreference().read(), isNull);
      expect(store.writes, isEmpty);
    });
  });

  group('write', () {
    for (final testCase in const [
      (mode: TioThemeMode.system, v2: 'system', legacy: 'system'),
      (mode: TioThemeMode.light, v2: 'light', legacy: 'light'),
      (mode: TioThemeMode.dark, v2: 'dark', legacy: 'oled'),
      (mode: TioThemeMode.tioDark, v2: 'tio_dark', legacy: 'dark'),
    ]) {
      test(
          '${testCase.mode.name} writes V2 ${testCase.v2} first and mirrors '
          'legacy ${testCase.legacy}', () async {
        await SharedPreferencesAppThemePreference().write(testCase.mode);

        expect(store.writes, [
          (key: _v2Key, value: testCase.v2),
          (key: _legacyKey, value: testCase.legacy),
        ]);
        expect(
          await SharedPreferencesAppThemePreference().read(),
          testCase.mode,
          reason: 'a restarted adapter reads the canonical V2 value',
        );
      });
    }

    test('the legacy key never receives tio_dark', () async {
      final preference = SharedPreferencesAppThemePreference();
      for (final mode in TioThemeMode.values) {
        await preference.write(mode);
      }

      final legacyValues = store.writes
          .where((write) => write.key == _legacyKey)
          .map((write) => write.value);
      expect(legacyValues, isNot(contains('tio_dark')));
      expect(legacyValues.toSet(), {'system', 'light', 'dark', 'oled'});
    });

    test('a failed legacy mirror write does not fail the V2 selection',
        () async {
      useStore({_legacyKey: 'light'});
      store.failSetStringKeys.add(_legacyKey);

      await SharedPreferencesAppThemePreference().write(TioThemeMode.tioDark);

      expect(store.data[_v2Key], 'tio_dark');
      expect(store.data[_legacyKey], 'light');
      expect(await SharedPreferencesAppThemePreference().read(),
          TioThemeMode.tioDark);
    });

    test('a failed V2 write propagates and does not touch the legacy mirror',
        () async {
      useStore({_v2Key: 'light', _legacyKey: 'light'});
      store.failSetStringKeys.add(_v2Key);

      await expectLater(
        SharedPreferencesAppThemePreference().write(TioThemeMode.dark),
        throwsA(isA<StateError>()),
      );

      expect(store.data[_v2Key], 'light');
      expect(store.data[_legacyKey], 'light');
      expect(store.writes, isEmpty);
    });
  });

  group('clear', () {
    test('removes both keys, legacy first and V2 last', () async {
      useStore({_v2Key: 'tio_dark', _legacyKey: 'dark'});

      await SharedPreferencesAppThemePreference().clear();

      expect(store.removedKeys, [_legacyKey, _v2Key]);
      expect(store.data, isEmpty);
      expect(await SharedPreferencesAppThemePreference().read(), isNull);
    });

    test('removes a legacy-only selection so it cannot be migrated back',
        () async {
      useStore({_legacyKey: 'oled'});

      await SharedPreferencesAppThemePreference().clear();

      expect(store.data, isEmpty);
      expect(await SharedPreferencesAppThemePreference().read(), isNull);
      expect(store.data.containsKey(_v2Key), isFalse);
    });

    test('a failed legacy removal keeps both keys and the V2 selection',
        () async {
      useStore({_v2Key: 'dark', _legacyKey: 'oled'});
      store.failRemoveKeys.add(_legacyKey);

      await expectLater(
        SharedPreferencesAppThemePreference().clear(),
        throwsA(isA<StateError>()),
      );

      expect(store.data, {_v2Key: 'dark', _legacyKey: 'oled'});
      expect(await SharedPreferencesAppThemePreference().read(),
          TioThemeMode.dark);
    });

    test('a failed V2 removal still resolves V2, never stale legacy', () async {
      useStore({_v2Key: 'tio_dark', _legacyKey: 'dark'});
      store.failRemoveKeys.add(_v2Key);

      await expectLater(
        SharedPreferencesAppThemePreference().clear(),
        throwsA(isA<StateError>()),
      );

      expect(store.data, {_v2Key: 'tio_dark'});
      expect(await SharedPreferencesAppThemePreference().read(),
          TioThemeMode.tioDark);
    });
  });
}

/// In-memory store that records writes/removals and can fail chosen keys.
base class _RecordingPreferences extends InMemorySharedPreferencesAsync {
  _RecordingPreferences(this.data) : super.empty();

  final Map<String, Object> data;
  final writes = <({String key, String value})>[];
  final removedKeys = <String>[];
  final failSetStringKeys = <String>{};
  final failRemoveKeys = <String>{};

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (failSetStringKeys.contains(key)) {
      throw StateError('setString($key) failed');
    }
    data[key] = value;
    writes.add((key: key, value: value));
    return true;
  }

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return data[key] as String?;
  }

  @override
  Future<bool> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final keys = parameters.filter.allowList ?? data.keys.toSet();
    for (final key in keys) {
      if (failRemoveKeys.contains(key)) {
        throw StateError('remove($key) failed');
      }
      data.remove(key);
      removedKeys.add(key);
    }
    return true;
  }
}
