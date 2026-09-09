import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tio_core/core.dart';

import '../network_providers.dart';

/// Confirmation shown once a new profile image is stored.
const profileImageUpdatedMessage = 'Profile image updated successfully.';

/// One image the user chose, already read into memory.
typedef PickedProfileImage = ({String fileName, List<int> bytes});

/// Picks a profile image, or resolves null when the user backs out.
typedef ProfileImagePicker = Future<PickedProfileImage?> Function(
  TioImageSource source,
);

/// The picker the upload flow uses.
///
/// A provider so tests can supply a chosen image, or a cancellation, without
/// a platform picker. Production resolves to the real one.
final profileImagePickerProvider =
    Provider<ProfileImagePicker>((ref) => _pickProfileImage);

Future<PickedProfileImage?> _pickProfileImage(TioImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source == TioImageSource.gallery
        ? ImageSource.gallery
        : ImageSource.camera,
    imageQuality: 85,
    maxWidth: 1024,
    maxHeight: 1024,
  );
  if (picked == null) return null;
  return (fileName: picked.name, bytes: await picked.readAsBytes());
}

/// Picks a profile image, uploads it, refreshes the profile and confirms.
///
/// Profile, Avatar preview and Profile Settings each ran this exact sequence
/// inline. The confirmation lives here rather than at three call sites so a
/// fourth entry point inherits it and none of the three can drift apart.
///
/// The confirmation is deliberately after the upload `await`: a message that
/// ran earlier would promise a save that had not happened, and a throwing
/// upload propagates before reaching it.
///
/// Cropping is absent on purpose. #201 owns the pick -> crop -> upload path;
/// this only removes duplication that already existed.
Future<void> pickAndUploadProfileImage({
  required WidgetRef ref,
  required BuildContext context,
  required TioImageSource source,
}) async {
  final picked = await ref.read(profileImagePickerProvider)(source);
  if (picked == null) return;

  final avatarRepository = ref.read(profileAvatarRepositoryProvider);
  if (avatarRepository == null) {
    throw StateError('Profile avatar persistence is unavailable.');
  }

  await avatarRepository.uploadAvatarImage(
    fileName: picked.fileName,
    bytes: picked.bytes,
  );
  ref.invalidate(profileDataProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(profileImageUpdatedMessage)),
    );
  }
}
