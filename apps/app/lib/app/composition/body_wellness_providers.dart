import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_progress/progress.dart';

import 'runtime_providers.dart';

/// Canonical Wellness owner. Production writes only `user_wellness_targets`;
/// an in-memory fallback keeps non-Supabase test/local harnesses constructible.
final wellnessTargetsRepositoryProvider =
    Provider<WellnessTargetsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseWellnessTargetsRepository(client: supabaseClient);
  }
  return InMemoryWellnessTargetsRepository();
});

/// Canonical Wellness read state provider for UI routes.
final wellnessTargetsDataProvider =
    FutureProvider<WellnessTargetsData?>((ref) async {
  final repository = ref.watch(wellnessTargetsRepositoryProvider);
  return repository.read();
});

/// Canonical Body owner. The returned object also exposes the canonical
/// Wellness owner boundary so existing onboarding composition can advance O4C
/// without widening router glue. The two owners still delegate to independent
/// repositories/tables.
final bodySetupRepositoryProvider = Provider<BodySetupRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final BodySetupRepository bodyRepository = supabaseClient != null
      ? SupabaseBodySetupRepository(client: supabaseClient)
      : InMemoryBodySetupRepository();

  return _BodyAndWellnessSetupRepository(
    bodyRepository: bodyRepository,
    wellnessRepository: ref.watch(wellnessTargetsRepositoryProvider),
  );
});

/// Canonical Body owner used by post-onboarding Settings surfaces (Body &
/// Weight, Profile Current Weight). Falls back to an in-memory instance
/// without a Supabase client so non-Supabase test/local harnesses stay
/// constructible.
final bodyRepositoryProvider = Provider<BodyRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient != null) {
    return SupabaseBodySetupRepository(client: supabaseClient);
  }
  return InMemoryBodySetupRepository();
});

/// Canonical Body read state provider for UI routes.
final bodyStateDataProvider = FutureProvider<BodyState>((ref) async {
  final repository = ref.watch(bodyRepositoryProvider);
  return repository.getBodyState();
});

final class _BodyAndWellnessSetupRepository
    implements BodySetupRepository, WellnessTargetsRepository {
  const _BodyAndWellnessSetupRepository({
    required BodySetupRepository bodyRepository,
    required WellnessTargetsRepository wellnessRepository,
  })  : _bodyRepository = bodyRepository,
        _wellnessRepository = wellnessRepository;

  final BodySetupRepository _bodyRepository;
  final WellnessTargetsRepository _wellnessRepository;

  @override
  Future<void> saveBodySetup(BodySetupData data) {
    return _bodyRepository.saveBodySetup(data);
  }

  @override
  Future<WellnessTargetsData?> read() {
    return _wellnessRepository.read();
  }

  @override
  Future<void> upsert(WellnessTargetsData targets) {
    return _wellnessRepository.upsert(targets);
  }
}
