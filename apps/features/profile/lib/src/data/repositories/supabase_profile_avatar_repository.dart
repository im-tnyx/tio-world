import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/profile_avatar_repository.dart';

typedef CurrentProfileAvatarUserId = String? Function();

abstract interface class ProfileAvatarStorageGateway {
  Future<String> upload({
    required String path,
    required List<int> bytes,
    required String contentType,
  });
}

abstract interface class ProfileAvatarAccountGateway {
  Future<void> writeAvatarUrl({
    required String userId,
    required String? avatarUrl,
  });
}

final class SupabaseProfileAvatarStorageGateway
    implements ProfileAvatarStorageGateway {
  const SupabaseProfileAvatarStorageGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<String> upload({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    await _client.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }
}

final class SupabaseProfileAvatarAccountGateway
    implements ProfileAvatarAccountGateway {
  const SupabaseProfileAvatarAccountGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<void> writeAvatarUrl({
    required String userId,
    required String? avatarUrl,
  }) async {
    await _client.from('users').update({
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }
}

/// Supabase adapter for avatar media only.
///
/// New writes use `public.users.avatar_url` exclusively. The retired
/// `profile_image` compatibility column is never read or written here.
final class SupabaseProfileAvatarRepository implements ProfileAvatarRepository {
  SupabaseProfileAvatarRepository({
    required SupabaseClient client,
    ProfileAvatarStorageGateway? storageGateway,
    ProfileAvatarAccountGateway? accountGateway,
    CurrentProfileAvatarUserId? currentUserId,
  })  : _storageGateway =
            storageGateway ?? SupabaseProfileAvatarStorageGateway(client),
        _accountGateway =
            accountGateway ?? SupabaseProfileAvatarAccountGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final ProfileAvatarStorageGateway _storageGateway;
  final ProfileAvatarAccountGateway _accountGateway;
  final CurrentProfileAvatarUserId _currentUserId;

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async {
    final userId = _requireUserId();
    final extension = _fileExtension(fileName);
    final storagePath =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final publicUrl = await _storageGateway.upload(
      path: storagePath,
      bytes: bytes,
      contentType: _contentType(extension),
    );
    await _accountGateway.writeAvatarUrl(
      userId: userId,
      avatarUrl: publicUrl,
    );
    return publicUrl;
  }

  @override
  Future<void> deleteAvatarImage() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return;
    await _accountGateway.writeAvatarUrl(
      userId: userId,
      avatarUrl: null,
    );
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('User is not authenticated');
    }
    return userId;
  }
}

String _fileExtension(String fileName) {
  final trimmed = fileName.trim();
  if (!trimmed.contains('.')) return 'jpg';
  final extension = trimmed.split('.').last.toLowerCase();
  return extension.isEmpty ? 'jpg' : extension;
}

String _contentType(String extension) {
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/$extension',
  };
}
