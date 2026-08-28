import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('AppDestination storage contract', () {
    test('uses stable canonical ids', () {
      expect(AppDestination.home.storageValue, 'home');
      expect(AppDestination.workout.storageValue, 'workout');
      expect(AppDestination.nutrition.storageValue, 'nutrition');
      expect(AppDestination.progress.storageValue, 'progress');
    });

    test('parses only supported ids', () {
      expect(
        AppDestination.fromStorageValue('nutrition'),
        AppDestination.nutrition,
      );
      expect(AppDestination.fromStorageValue('coach'), isNull);
      expect(AppDestination.fromStorageValue(null), isNull);
    });
  });

  group('AppPreferencesState', () {
    test('represents a missing canonical row explicitly', () {
      const state = AppPreferencesState.missing();

      expect(state.isMissing, isTrue);
      expect(state.isPresent, isFalse);
      expect(state.appMode, isNull);
      expect(state.activeTabs, isNull);
    });

    test('supports a present legacy row with mode but no active tabs', () {
      final state = AppPreferencesState.present(
        appMode: AppMode.workout,
        activeTabs: null,
      );

      expect(state.isPresent, isTrue);
      expect(state.appMode, AppMode.workout);
      expect(state.activeTabs, isNull);
    });

    test('preserves active tab order and defensively copies it', () {
      final source = <AppDestination>[
        AppDestination.home,
        AppDestination.nutrition,
        AppDestination.progress,
      ];
      final state = AppPreferencesState.present(
        appMode: AppMode.nutrition,
        activeTabs: source,
      );

      source
        ..clear()
        ..add(AppDestination.workout);

      expect(
        state.activeTabs,
        const [
          AppDestination.home,
          AppDestination.nutrition,
          AppDestination.progress,
        ],
      );
      expect(
        () => state.activeTabs!.add(AppDestination.workout),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate active tabs', () {
      expect(
        () => AppPreferencesState.present(
          appMode: AppMode.hybrid,
          activeTabs: const [
            AppDestination.home,
            AppDestination.workout,
            AppDestination.home,
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a present empty active-tabs array', () {
      expect(
        () => AppPreferencesState.present(
          appMode: AppMode.hybrid,
          activeTabs: const [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('AppPreferencesUpdate', () {
    test('guided factory derives current canonical destination order', () {
      expect(
        AppPreferencesUpdate.guided(AppMode.workout).activeTabs,
        const [
          AppDestination.home,
          AppDestination.workout,
          AppDestination.progress,
        ],
      );
      expect(
        AppPreferencesUpdate.guided(AppMode.nutrition).activeTabs,
        const [
          AppDestination.home,
          AppDestination.nutrition,
          AppDestination.progress,
        ],
      );
      expect(
        AppPreferencesUpdate.guided(AppMode.hybrid).activeTabs,
        const [
          AppDestination.home,
          AppDestination.workout,
          AppDestination.nutrition,
          AppDestination.progress,
        ],
      );
    });

    test('preserves caller order for future valid custom navigation', () {
      final update = AppPreferencesUpdate(
        appMode: AppMode.hybrid,
        activeTabs: const [
          AppDestination.home,
          AppDestination.nutrition,
          AppDestination.workout,
          AppDestination.progress,
        ],
      );

      expect(
        update.activeTabs,
        const [
          AppDestination.home,
          AppDestination.nutrition,
          AppDestination.workout,
          AppDestination.progress,
        ],
      );
    });

    test('rejects empty and duplicate write payloads', () {
      expect(
        () => AppPreferencesUpdate(
          appMode: AppMode.workout,
          activeTabs: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => AppPreferencesUpdate(
          appMode: AppMode.workout,
          activeTabs: const [
            AppDestination.home,
            AppDestination.home,
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
