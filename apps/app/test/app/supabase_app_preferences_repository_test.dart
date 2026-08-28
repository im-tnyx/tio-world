import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('SupabaseAppPreferencesRepository', () {
    test('requires an authenticated user before reading', () async {
      final gateway = _FakeGateway();
      final repository = _repository(gateway: gateway, userId: null);

      await expectLater(repository.read(), throwsStateError);
      expect(gateway.readUserIds, isEmpty);
    });

    test('returns explicit missing state when no canonical row exists', () async {
      final gateway = _FakeGateway(readResult: null);
      final repository = _repository(gateway: gateway);

      final state = await repository.read();

      expect(state.isMissing, isTrue);
      expect(state.appMode, isNull);
      expect(state.activeTabs, isNull);
      expect(gateway.readUserIds, ['user-1']);
    });

    test('accepts legacy mode-only canonical rows', () async {
      final gateway = _FakeGateway(readResult: {
        'app_mode': 'nutrition',
        'active_tabs': null,
      });
      final repository = _repository(gateway: gateway);

      final state = await repository.read();

      expect(state.isPresent, isTrue);
      expect(state.appMode, AppMode.nutrition);
      expect(state.activeTabs, isNull);
    });

    test('preserves active tab order from canonical rows', () async {
      final gateway = _FakeGateway(readResult: {
        'app_mode': 'hybrid',
        'active_tabs': ['home', 'nutrition', 'workout', 'progress'],
      });
      final repository = _repository(gateway: gateway);

      final state = await repository.read();

      expect(
        state.activeTabs,
        const [
          AppDestination.home,
          AppDestination.nutrition,
          AppDestination.workout,
          AppDestination.progress,
        ],
      );
    });

    test('rejects invalid canonical mode values', () async {
      final repository = _repository(
        gateway: _FakeGateway(readResult: {
          'app_mode': 'custom',
          'active_tabs': ['home'],
        }),
      );

      await expectLater(repository.read(), throwsFormatException);
    });

    test('rejects unsupported canonical tab values', () async {
      final repository = _repository(
        gateway: _FakeGateway(readResult: {
          'app_mode': 'workout',
          'active_tabs': ['home', 'coach'],
        }),
      );

      await expectLater(repository.read(), throwsFormatException);
    });

    test('rejects duplicate canonical tabs', () async {
      final repository = _repository(
        gateway: _FakeGateway(readResult: {
          'app_mode': 'workout',
          'active_tabs': ['home', 'workout', 'home'],
        }),
      );

      await expectLater(repository.read(), throwsFormatException);
    });

    test('rejects empty canonical tab arrays', () async {
      final repository = _repository(
        gateway: _FakeGateway(readResult: {
          'app_mode': 'workout',
          'active_tabs': <String>[],
        }),
      );

      await expectLater(repository.read(), throwsFormatException);
    });

    test('upserts mode and ordered tabs as one canonical payload', () async {
      final gateway = _FakeGateway();
      final repository = _repository(gateway: gateway);

      await repository.upsert(AppPreferencesUpdate.guided(AppMode.hybrid));

      expect(gateway.upsertPayloads, [
        {
          'user_id': 'user-1',
          'app_mode': 'hybrid',
          'active_tabs': ['home', 'workout', 'nutrition', 'progress'],
        }
      ]);
    });

    test('surfaces gateway read and write failures', () async {
      final readRepository = _repository(
        gateway: _FakeGateway(readError: StateError('read failed')),
      );
      await expectLater(readRepository.read(), throwsStateError);

      final writeRepository = _repository(
        gateway: _FakeGateway(writeError: StateError('write failed')),
      );
      await expectLater(
        writeRepository.upsert(AppPreferencesUpdate.guided(AppMode.workout)),
        throwsStateError,
      );
    });
  });
}

SupabaseAppPreferencesRepository _repository({
  required _FakeGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseAppPreferencesRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeGateway implements AppPreferencesTableGateway {
  _FakeGateway({this.readResult, this.readError, this.writeError});

  final Map<String, dynamic>? readResult;
  final Object? readError;
  final Object? writeError;
  final List<String> readUserIds = [];
  final List<Map<String, dynamic>> upsertPayloads = [];

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    readUserIds.add(userId);
    if (readError case final error?) throw error;
    return readResult;
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    if (writeError case final error?) throw error;
    upsertPayloads.add(Map<String, dynamic>.from(payload));
  }
}
