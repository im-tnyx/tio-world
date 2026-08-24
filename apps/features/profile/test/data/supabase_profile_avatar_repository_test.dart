import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('SupabaseProfileAvatarRepository', () {
    test('upload stores media then writes only canonical avatar URL', () async {
      final storage = _RecordingAvatarStorageGateway();
      final account = _RecordingAvatarAccountGateway();
      final repository = SupabaseProfileAvatarRepository(
        client: _FakeSupabaseClient(),
        storageGateway: storage,
        accountGateway: account,
        currentUserId: () => 'user-123',
      );

      final result = await repository.uploadAvatarImage(
        fileName: 'Photo.PNG',
        bytes: const [1, 2, 3],
      );

      expect(result, 'https://example.test/avatar.png');
      expect(storage.uploadCalls, 1);
      expect(storage.lastPath, startsWith('user-123/avatar_'));
      expect(storage.lastPath, endsWith('.png'));
      expect(storage.lastContentType, 'image/png');
      expect(storage.lastBytes, [1, 2, 3]);
      expect(account.writeCalls, 1);
      expect(account.lastUserId, 'user-123');
      expect(account.lastAvatarUrl, result);
    });

    test('upload fails closed without an authenticated user', () async {
      final storage = _RecordingAvatarStorageGateway();
      final account = _RecordingAvatarAccountGateway();
      final repository = SupabaseProfileAvatarRepository(
        client: _FakeSupabaseClient(),
        storageGateway: storage,
        accountGateway: account,
        currentUserId: () => null,
      );

      await expectLater(
        () => repository.uploadAvatarImage(
          fileName: 'avatar.jpg',
          bytes: const [1],
        ),
        throwsStateError,
      );
      expect(storage.uploadCalls, 0);
      expect(account.writeCalls, 0);
    });

    test('delete clears canonical avatar URL only', () async {
      final account = _RecordingAvatarAccountGateway();
      final repository = SupabaseProfileAvatarRepository(
        client: _FakeSupabaseClient(),
        storageGateway: _RecordingAvatarStorageGateway(),
        accountGateway: account,
        currentUserId: () => 'user-123',
      );

      await repository.deleteAvatarImage();

      expect(account.writeCalls, 1);
      expect(account.lastUserId, 'user-123');
      expect(account.lastAvatarUrl, isNull);
    });

    test('delete is a no-op without an authenticated user', () async {
      final account = _RecordingAvatarAccountGateway();
      final repository = SupabaseProfileAvatarRepository(
        client: _FakeSupabaseClient(),
        storageGateway: _RecordingAvatarStorageGateway(),
        accountGateway: account,
        currentUserId: () => '  ',
      );

      await repository.deleteAvatarImage();

      expect(account.writeCalls, 0);
    });
  });
}

class _RecordingAvatarStorageGateway implements ProfileAvatarStorageGateway {
  int uploadCalls = 0;
  String? lastPath;
  List<int>? lastBytes;
  String? lastContentType;

  @override
  Future<String> upload({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    uploadCalls += 1;
    lastPath = path;
    lastBytes = List<int>.of(bytes);
    lastContentType = contentType;
    return 'https://example.test/avatar.png';
  }
}

class _RecordingAvatarAccountGateway implements ProfileAvatarAccountGateway {
  int writeCalls = 0;
  String? lastUserId;
  String? lastAvatarUrl;

  @override
  Future<void> writeAvatarUrl({
    required String userId,
    required String? avatarUrl,
  }) async {
    writeCalls += 1;
    lastUserId = userId;
    lastAvatarUrl = avatarUrl;
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}
