import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_settings/settings.dart';

import 'network_providers.dart';

final appGoogleIdentityLinkControllerProvider =
    Provider<GoogleIdentityLinkController?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;

  final repository = SupabaseGoogleIdentityLinkRepository(
    client: client,
    googleSignIn: ref.watch(googleSignInProviderProvider).signInClient,
  );

  return _AppGoogleIdentityLinkController(
    repository: repository,
    onLinked: () {
      ref.invalidate(authSessionStateProvider);
    },
  );
});

final class _AppGoogleIdentityLinkController
    implements GoogleIdentityLinkController {
  const _AppGoogleIdentityLinkController({
    required GoogleIdentityLinkRepository repository,
    required void Function() onLinked,
  })  : _repository = repository,
        _onLinked = onLinked;

  final GoogleIdentityLinkRepository _repository;
  final void Function() _onLinked;

  @override
  Future<bool> linkGoogleIdentity() async {
    final linked = await _repository.linkGoogleIdentity();
    if (linked) _onLinked();
    return linked;
  }
}
