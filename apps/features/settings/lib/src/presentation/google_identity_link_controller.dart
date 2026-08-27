import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Narrow app-composed capability used by Account Settings to connect Google.
///
/// Provider SDK and Supabase details remain outside the Settings feature.
abstract interface class GoogleIdentityLinkController {
  /// Returns true only after the Auth owner has authoritatively confirmed that
  /// Google is linked to the same canonical authenticated user. Returns false
  /// when the user cancels the provider chooser.
  Future<bool> linkGoogleIdentity();
}

final googleIdentityLinkControllerProvider =
    Provider<GoogleIdentityLinkController?>((ref) => null);
