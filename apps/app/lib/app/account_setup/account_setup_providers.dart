import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_profile/profile.dart';

import '../network_providers.dart';

final accountSetupRepositoryProvider = Provider<AccountSetupRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseAccountSetupRepository(client: client);
});
