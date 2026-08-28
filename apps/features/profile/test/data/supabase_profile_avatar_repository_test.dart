import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('SupabaseProfileAvatarRepository', () {
    test('replacement stores new media, writes pointer, then removes old owned object',
        () async {
      final events = <String>[];
      final storage = _RecordingAvatarStorageGateway(events: events);
      final account = _RecordingAvatarAccountGateway(
        events: events,
        avatarUrl:
            'https://project.test/storage/v1/object/public/avatars/user-123/avatar_old.jpg',
      );
      final repository = _repository(storage: storage, account: account);

      final result = await repository.uploadAvatarImage(
        fileName: 'Photo.PNG',
        bytes: const [1, 2, 3],
      );

      expect(result, startsWith(
        'https://project.test/storage/v1/object/public/avatars/user-123/avatar_',
      ));
      expect(result, endsWith('.png'));
      expect(storage.uploadCalls, 1);
      expect(storage.lastPath, startsWith('user-123/avatar_'));
      expect(storage.lastPath, endsWith('.png'));
      expect(storage.lastContentType, 'image/png');
      expect(storage.lastBytes, [1, 2, 3]);
      expect(account.readCalls, 1);
      expect(account.writeCalls, 1);
      expect(account.lastUserId, 'user-123');
      expect(account.lastAvatarUrl, result);
      expect(storage.removedPaths, ['user-123/avatar_old.jpg']);
      expect(events, [
        'account.read',
        'storage.upload',
        'account.write',
        'storage.remove:user-123/avatar_old.jpg',
      ]);
    });

    test('replacement never removes an external provider avatar', () async {
      final storage = _RecordingAvatarStorageGateway();
      final account = _RecordingAvatarAccountGateway(
        avatarUrl: 'https://lh3.googleusercontent.com/provider-avatar.jpg',
      );
      final repository = _repository(storage: storage, account: account);

      final result = await repository.uploadAvatarImage(
        fileName: 'avatar.jpg',
        bytes: const [1],
      );

      expect(account.lastAvatarUrl, result);
      expect(storage.removedPaths, isEmpty);
    });

    test('pointer write failure best-effort removes newly uploaded object and rethrows',
        () async {
      final storage = _RecordingAvatarStorageGateway();
      final account = _RecordingAvatarAccountGateway(
        avatarUrl:
            'https://project.test/storage/v1/object/public/avatars/user-123/avatar_old.jpg',
        writeError: StateError('pointer write failed'),
      );
      final repository = _repository(storage: storage, account: account);

      await expectLater(
        () => repository.uploadAvatarImage(
          fileName: 'avatar.jpg',
          bytes: const [1],
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'pointer write failed',
          ),
        ),
      );

      expect(account.writeCalls, 1);
      expect(storage.removedPaths, hasLength(1));
      expect(storage.removedPaths.single, storage.lastPath);
      expect(storage.removedPaths, isNot(contains('user-123/avatar_old.jpg')));
    });

    test('cleanup failure after successful replacement does not report false failure',
        () async {
      final storage = _RecordingAvatarStorageGateway(
        removeError: StateError('cleanup unavailable'),
      );
      final account = _RecordingAvatarAccountGateway(
        avatarUrl:
            'https://project.test/storage/v1/object/public/avatars/user-123/avatar_old.jpg',
      );
      final repository = _repository(storage: storage, account: account);

      final result = await repository.uploadAvatarImage(
        fileName: 'avatar.webp',
        bytes: const [1],
      );

      expect(result, account.lastAvatarUrl);
      expect(storage.removeCalls, 1);
      expect(storage.removedPaths, isEmpty);
    });

    test('upload fails closed without an authenticated user', () async {
      final storage = _RecordingAvatarStorageGateway();
      final account = _RecordingAvatarAccountGateway();
      final repository = _repository(
        storage: storage,
        account: account,
        userId: null,
      );

      await expectLater(
        () => repository.uploadAvatarImage(
          fileName: 'avatar.jpg',
          bytes: const [1],
        ),
        throwsStateError,
      );
      expect(storage.uploadCalls, 0);
      expect(account.readCalls, 0);
      expect(account.writeCalls, 0);
    });

    test('delete clears canonical pointer then removes the previous owned object',
        () async {
      final events = <String>[];
      final storage = _RecordingAvatarStorageGateway(events: events);
      final account = _RecordingAvatarAccountGateway(
        events: events,
        avatarUrl:
            'https://project.test/storage/v1/object/public/avatars/user-123/avatar_old.jpg',
      );
      final repository = _repository(storage: storage, account: account);

      await repository.deleteAvatarImage();

      expect(account.readCalls, 1);
      expect(account.writeCalls, 1);
      expect(account.lastUserId, 'user-123');
      expect(account.lastAvatarUrl, isNull);
      expect(storage.removedPaths, ['user-123/avatar_old.jpg']);
      expect(events, [
        'account.read',
        'account.write',
        'storage.remove:user-123/avatar_old.jpg',
      ]);
    });

    test('delete clears an external avatar without Storage delete', () async {
      final storage = _RecordingAvatarStorageGateway();
      final account = _RecordingAvatarAccountGateway(
        avatarUrl: 'https://lh3.googleusercontent.com/provider-avatar.jpg',
      );
      final repository = _repository(storage: storage, account: account);

      await repository.deleteAvatarImage();

      expect(account.lastAvatarUrl, isNull);
      expect(storage.removeCalls, 0);
    });

    test('cleanup failure after successful clear does not report false failure',
        () async {
      final storage = _RecordingAvatarStorageGateway(
        removeError: StateError('cleanup unavailable'),
      );
      final account = _RecordingAvatarAccountGateway(
        avatarUrl:
            'https://project.test/storage/v1/object/public/avatars/user-123/avatar_old.jpg',
      );
      final repository = _repository(storage: storage, account: account);

      await repository.deleteAvatarImage();

      expect(account.lastAvatarUrl, isNull);
      expect(storage.removeCalls, 1);
      expect(storage.removedPaths, isEmpty);
    });

    test('delete is a no-op without an authenticated user', () async {
      final storage = _RecordingAvatarStorageGateway();
      final account = _RecordingAvatarAccountGateway();
      final repository = _repository(
        storage: storage,
        account: account,
        userId: '  ',
      );

      await repository.deleteAvatarImage();

      expect(account.readCalls, 0);
      expect(account.writeCalls, 0);
      expect(storage.removeCalls, 0);
    });
  });

  group('SupabaseProfileAvatarStorageGateway ownership', () {
    const marker =
        'https://project.supabase.co/storage/v1/object/public/avatars/user-123/__tio_avatar_marker__';

    test('resolves only this project avatars URL inside the current user folder',
        () {
      expect(
        SupabaseProfileAvatarStorageGateway.resolveOwnedAvatarPath(
          avatarUrl:
              'https://project.supabase.co/storage/v1/object/public/avatars/user-123/avatar_1.png',
          markerUrl: marker,
          userId: 'user-123',
        ),
        'user-123/avatar_1.png',
      );
      expect(
        SupabaseProfileAvatarStorageGateway.resolveOwnedAvatarPath(
          avatarUrl:
              'https://project.supabase.co/storage/v1/object/public/avatars/other-user/avatar_1.png',
          markerUrl: marker,
          userId: 'user-123',
        ),
        isNull,
      );
      expect(
        SupabaseProfileAvatarStorageGateway.resolveOwnedAvatarPath(
          avatarUrl:
              'https://other.supabase.co/storage/v1/object/public/avatars/user-123/avatar_1.png',
          markerUrl: marker,
          userId: 'user-123',
        ),
        isNull,
      );
      expect(
        SupabaseProfileAvatarStorageGateway.resolveOwnedAvatarPath(
          avatarUrl: 'https://lh3.googleusercontent.com/avatar.png',
          markerUrl: marker,
          userId: 'user-123',
        ),
        isNull,
      );
    });

    test('bucket-route mismatch cannot be converted into a delete path', () {
      expect(
        SupabaseProfileAvatarStorageGateway.resolveOwnedAvatarPath(
          avatarUrl:
              'https://project.supabase.co/storage/v1/object/public/documents/user-123/avatar.png',
          markerUrl: marker,
          userId: 'user-123',
        ),
        isNull,
      );
    });
  });
}

SupabaseProfileAvatarRepository _repository({
  required _RecordingAvatarStorageGateway storage,
  required _RecordingAvatarAccountGateway account,
  String? userId = 'user-123',
}) {
  return SupabaseProfileAvatarRepository(
    client: _FakeSupabaseClient(),
    storageGateway: storage,
    accountGateway: account,
    currentUserId: () => userId,
  );
}

class _RecordingAvatarStorageGateway implements ProfileAvatarStorageGateway {
  _RecordingAvatarStorageGateway({
    this.events,
    this.removeError,
  });

  final List<String>? events;
  final Object? removeError;
  int uploadCalls = 0;
  int removeCalls = 0;
  String? lastPath;
  List<int>? lastBytes;
  String? lastContentType;
  final List<String> removedPaths = [];

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
    events?.add('storage.upload');
    return 'https://project.test/storage/v1/object/public/avatars/$path';
  }

  @override
  String? ownedPathFromPublicUrl({
    required String userId,
    required String avatarUrl,
  }) {
    return SupabaseProfileAvatarStorageGateway.resolveOwnedAvatarPath(
      avatarUrl: avatarUrl,
      markerUrl:
          'https://project.test/storage/v1/object/public/avatars/$userId/__tio_avatar_marker__',
      userId: userId,
    );
  }

  @override
  Future<void> remove({required String path}) async {
    removeCalls += 1;
    events?.add('storage.remove:$path');
    final error = removeError;
    if (error != null) throw error;
    removedPaths.add(path);
  }
}

class _RecordingAvatarAccountGateway implements ProfileAvatarAccountGateway {
  _RecordingAvatarAccountGateway({
    this.events,
    this.avatarUrl,
    this.writeError,
  });

  final List<String>? events;
  final Object? writeError;
  String? avatarUrl;
  int readCalls = 0;
  int writeCalls = 0;
  String? lastUserId;
  String? lastAvatarUrl;

  @override
  Future<String?> readAvatarUrl({required String userId}) async {
    readCalls += 1;
    lastUserId = userId;
    events?.add('account.read');
    return avatarUrl;
  }

  @override
  Future<void> writeAvatarUrl({
    required String userId,
    required String? avatarUrl,
  }) async {
    writeCalls += 1;
    lastUserId = userId;
    lastAvatarUrl = avatarUrl;
    events?.add('account.write');
    final error = writeError;
    if (error != null) throw error;
    this.avatarUrl = avatarUrl;
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}
