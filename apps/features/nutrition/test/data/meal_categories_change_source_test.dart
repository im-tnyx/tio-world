import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  test('Supabase repository emits after a successful confirmed write', () async {
    final gateway = _Gateway();
    final repository = _repository(gateway);
    var changeCount = 0;
    final subscription = repository.changes.listen((_) => changeCount++);
    addTearDown(subscription.cancel);

    await repository.upsert(MealCategoriesConfig.canonicalDefaults());
    await Future<void>.delayed(Duration.zero);

    expect(gateway.upsertCount, 1);
    expect(changeCount, 1);
  });

  test('Supabase repository does not emit when persistence fails', () async {
    final failure = Exception('offline');
    final gateway = _Gateway(error: failure);
    final repository = _repository(gateway);
    var changeCount = 0;
    final subscription = repository.changes.listen((_) => changeCount++);
    addTearDown(subscription.cancel);

    await expectLater(
      () => repository.upsert(MealCategoriesConfig.canonicalDefaults()),
      throwsA(same(failure)),
    );
    await Future<void>.delayed(Duration.zero);

    expect(gateway.upsertCount, 1);
    expect(changeCount, 0);
  });
}

SupabaseMealCategoriesRepository _repository(MealCategoriesTableGateway gateway) {
  return SupabaseMealCategoriesRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => 'user-1',
  );
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

final class _Gateway implements MealCategoriesTableGateway {
  _Gateway({this.error});

  final Object? error;
  int upsertCount = 0;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async => null;

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    upsertCount++;
    final failure = error;
    if (failure != null) throw failure;
  }
}
