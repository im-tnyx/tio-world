import 'dart:developer' as developer;
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

  String? ownedPathFromPublicUrl({
    required String userId,
    required String avatarUrl,
  });

  Future<void> remove({required String path});
}

abstract interface class ProfileAvatarAccountGateway {
  Future<String?> readAvatarUrl({required String userId});

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

  @override
  String? ownedPathFromPublicUrl({
    required String userId,
    required String avatarUrl,
  }) {
    final markerUrl = _client.storage
        .from('avatars')
        .getPublicUrl('$userId/__tio_avatar_marker__');
    return resolveOwnedAvatarPath(
      avatarUrl: avatarUrl,
      markerUrl: markerUrl,
      userId: userId,
    );
  }

  @override
  Future<void> remove({required String path}) async {
    await _client.storage.from('avatars').remove([path]);
  }

  /// Resolves an object path only when [avatarUrl] belongs to the same public
  /// Storage bucket URL represented by [markerUrl] and is inside [userId]'s
  /// first folder segment.
  ///
  /// Exposed for focused ownership regression tests; production callers should
  /// use [ownedPathFromPublicUrl].
  static String? resolveOwnedAvatarPath({
    required String avatarUrl,
    required String markerUrl,
    required String userId,
  }) {
    final normalizedUserId = userId.trim();
    final candidate = Uri.tryParse(avatarUrl.trim());
    final marker = Uri.tryParse(markerUrl.trim());
    if (normalizedUserId.isEmpty ||
        candidate == null ||
        marker == null ||
        !candidate.hasScheme ||
        candidate.host.isEmpty ||
        !marker.hasScheme ||
        marker.host.isEmpty ||
        candidate.scheme != marker.scheme ||
        candidate.host != marker.host ||
        candidate.port != marker.port) {
      return null;
    }

    final markerSegments = marker.pathSegments;
    // marker = <public avatars prefix>/<userId>/__tio_avatar_marker__
    if (markerSegments.length < 2 ||
        markerSegments[markerSegments.length - 2] != normalizedUserId) {
      return null;
    }

    final prefixLength = markerSegments.length - 2;
    final candidateSegments = candidate.pathSegments;
    if (candidateSegments.length < prefixLength + 2) return null;

    for (var index = 0; index < prefixLength; index += 1) {
      if (candidateSegments[index] != markerSegments[index]) return null;
    }

    if (candidateSegments[prefixLength] != normalizedUserId) return null;

    final objectSegments = candidateSegments.sublist(prefixLength);
    if (objectSegments.length < 2 ||
        objectSegments.any((segment) => segment.trim().isEmpty)) {
      return null;
    }
    return objectSegments.join('/');
  }
}

final class SupabaseProfileAvatarAccountGateway
    implements ProfileAvatarAccountGateway {
  const SupabaseProfileAvatarAccountGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> readAvatarUrl({required String userId}) async {
    final row = await _client
        .from('users')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      throw StateError('Account root is missing for the authenticated user.');
    }

    final raw = row['avatar_url'];
    if (raw == null) return null;
    if (raw is! String) {
      throw const FormatException(
        'Invalid canonical avatar_url: expected string or null.',
      );
    }
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }

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
    final previousAvatarUrl =
        await _accountGateway.readAvatarUrl(userId: userId);
    final extension = _fileExtension(fileName);
    final storagePath =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final publicUrl = await _storageGateway.upload(
      path: storagePath,
      bytes: bytes,
      contentType: _contentType(extension),
    );

    try {
      await _accountGateway.writeAvatarUrl(
        userId: userId,
        avatarUrl: publicUrl,
      );
    } catch (error, stackTrace) {
      await _removeOwnedAvatarBestEffort(
        userId: userId,
        avatarUrl: publicUrl,
        operation: 'rollback newly uploaded avatar after pointer write failure',
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    if (previousAvatarUrl != publicUrl) {
      await _removeOwnedAvatarBestEffort(
        userId: userId,
        avatarUrl: previousAvatarUrl,
        operation: 'remove replaced avatar',
      );
    }
    return publicUrl;
  }

  @override
  Future<void> deleteAvatarImage() async {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) return;

    final previousAvatarUrl =
        await _accountGateway.readAvatarUrl(userId: userId);
    await _accountGateway.writeAvatarUrl(
      userId: userId,
      avatarUrl: null,
    );
    await _removeOwnedAvatarBestEffort(
      userId: userId,
      avatarUrl: previousAvatarUrl,
      operation: 'remove cleared avatar',
    );
  }

  Future<void> _removeOwnedAvatarBestEffort({
    required String userId,
    required String? avatarUrl,
    required String operation,
  }) async {
    final normalizedUrl = avatarUrl?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) return;

    final path = _storageGateway.ownedPathFromPublicUrl(
      userId: userId,
      avatarUrl: normalizedUrl,
    );
    if (path == null) return;

    try {
      await _storageGateway.remove(path: path);
    } catch (error, stackTrace) {
      developer.log(
        'Avatar Storage cleanup failed: $operation',
        name: 'SupabaseProfileAvatarRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
