import '../domain/body_setup.dart';

/// Non-durable fallback for tests/local harnesses without an initialized
/// Supabase client. Production persistence uses [SupabaseBodySetupRepository].
class InMemoryBodySetupRepository implements BodySetupRepository {
  BodySetupData? _data;

  BodySetupData? get data => _data;

  @override
  Future<void> saveBodySetup(BodySetupData data) async {
    _data = data;
  }
}
