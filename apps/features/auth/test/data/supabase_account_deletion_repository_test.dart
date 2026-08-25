import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SupabaseAccountDeletionRepository', () {
    test('deletes owned Storage objects before invoking the destructive RPC',
        () async {
      final events = <String>[];
      final storage = _RecordingStorageGateway(events: events);
      final rpc = _RecordingRpcGateway(events: events);
      final repository = _repository(storage: storage, rpc: rpc);

      await repository.deleteCurrentAccount();

      expect(storage.userIds, ['user-123']);
      expect(rpc.calls, 1);
      expect(events, ['storage:user-123', 'rpc']);
    });

    test('an empty owned Storage folder is still allowed to reach the RPC',
        () async {
      final storage = _RecordingStorageGateway();
      final rpc = _RecordingRpcGateway();
      final repository = _repository(storage: storage, rpc: rpc);

      await repository.deleteCurrentAccount();

      expect(storage.userIds, ['user-123']);
      expect(rpc.calls, 1);
    });

    test('fails closed without an authenticated user', () async {
      final storage = _RecordingStorageGateway();
      final rpc = _RecordingRpcGateway();
      final repository = _repository(
        storage: storage,
        rpc: rpc,
        userId: '  ',
      );

      await expectLater(
        repository.deleteCurrentAccount,
        throwsA(isA<StateError>()),
      );

      expect(storage.userIds, isEmpty);
      expect(rpc.calls, 0);
    });

    test('Storage cleanup failure prevents irreversible account deletion',
        () async {
      final storage = _RecordingStorageGateway(
        error: StateError('storage cleanup failed'),
      );
      final rpc = _RecordingRpcGateway();
      final repository = _repository(storage: storage, rpc: rpc);

      await expectLater(
        repository.deleteCurrentAccount,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'storage cleanup failed',
          ),
        ),
      );

      expect(storage.userIds, ['user-123']);
      expect(rpc.calls, 0);
    });

    test('RPC failure is surfaced after Storage cleanup and is never swallowed',
        () async {
      final events = <String>[];
      final storage = _RecordingStorageGateway(events: events);
      final rpc = _RecordingRpcGateway(
        events: events,
        error: StateError('rpc failed'),
      );
      final repository = _repository(storage: storage, rpc: rpc);

      await expectLater(
        repository.deleteCurrentAccount,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'rpc failed',
          ),
        ),
      );

      expect(events, ['storage:user-123', 'rpc']);
      expect(rpc.calls, 1);
    });
  });
}

SupabaseAccountDeletionRepository _repository({
  required _RecordingStorageGateway storage,
  required _RecordingRpcGateway rpc,
  String? userId = 'user-123',
}) {
  return SupabaseAccountDeletionRepository(
    client: _FakeSupabaseClient(),
    storageGateway: storage,
    rpcGateway: rpc,
    currentUserId: () => userId,
  );
}

class _RecordingStorageGateway implements AccountDeletionStorageGateway {
  _RecordingStorageGateway({this.events, this.error});

  final List<String>? events;
  final Object? error;
  final List<String> userIds = [];

  @override
  Future<void> deleteUserOwnedObjects({required String userId}) async {
    userIds.add(userId);
    events?.add('storage:$userId');
    final failure = error;
    if (failure != null) throw failure;
  }
}

class _RecordingRpcGateway implements AccountDeletionRpcGateway {
  _RecordingRpcGateway({this.events, this.error});

  final List<String>? events;
  final Object? error;
  int calls = 0;

  @override
  Future<void> deleteCurrentUser() async {
    calls += 1;
    events?.add('rpc');
    final failure = error;
    if (failure != null) throw failure;
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}
