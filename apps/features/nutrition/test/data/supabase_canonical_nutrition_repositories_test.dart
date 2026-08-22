import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('SupabaseNutritionProfileRepository', () {
    test('signed-out read is null and write fails closed before gateway access',
        () async {
      final gateway = _FakeProfileGateway();
      final repository = _profileRepository(gateway: gateway, userId: null);

      expect(await repository.read(), isNull);
      await expectLater(
        () => repository.upsert(const NutritionProfileData()),
        throwsStateError,
      );
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('read preserves null arrays separately from explicit empty arrays',
        () async {
      final unknown = _profileRepository(
        gateway: _FakeProfileGateway(
          readResult: {
            'preferred_diet': null,
            'allergies': null,
            'disliked_foods': null,
            'medical_conditions': null,
          },
        ),
      );
      final unknownData = await unknown.read();
      expect(unknownData?.preferredDiet, isNull);
      expect(unknownData?.allergies, isNull);

      final explicitNone = _profileRepository(
        gateway: _FakeProfileGateway(
          readResult: {
            'preferred_diet': 'vegetarian',
            'allergies': <dynamic>[],
            'disliked_foods': <dynamic>[],
            'medical_conditions': <dynamic>[],
          },
        ),
      );
      final explicitData = await explicitNone.read();
      expect(explicitData?.preferredDiet, 'vegetarian');
      expect(explicitData?.allergies, isEmpty);
      expect(explicitData?.dislikedFoods, isEmpty);
      expect(explicitData?.medicalConditions, isEmpty);
    });

    test('strictly rejects malformed canonical Profile arrays', () async {
      for (final row in <Map<String, dynamic>>[
        {
          'preferred_diet': null,
          'allergies': 'nuts',
          'disliked_foods': null,
          'medical_conditions': null,
        },
        {
          'preferred_diet': null,
          'allergies': <dynamic>[1],
          'disliked_foods': null,
          'medical_conditions': null,
        },
      ]) {
        final repository = _profileRepository(
          gateway: _FakeProfileGateway(readResult: row),
        );
        await expectLater(repository.read(), throwsFormatException);
      }
    });

    test('writes only canonical Nutrition Profile context columns', () async {
      final gateway = _FakeProfileGateway();
      final repository = _profileRepository(gateway: gateway);

      await repository.upsert(
        const NutritionProfileData(
          preferredDiet: 'vegan',
          allergies: {'nuts', 'gluten'},
          dislikedFoods: {'okra'},
          medicalConditions: null,
        ),
      );

      expect(gateway.upsertPayloads, [
        {
          'user_id': 'user-1',
          'preferred_diet': 'vegan',
          'allergies': ['gluten', 'nuts'],
          'disliked_foods': ['okra'],
          'medical_conditions': null,
        }
      ]);
    });
  });

  group('SupabaseNutritionTargetsRepository', () {
    test('signed-out read is null and write fails closed before gateway access',
        () async {
      final gateway = _FakeTargetsGateway();
      final repository = _targetsRepository(gateway: gateway, userId: null);

      expect(await repository.read(), isNull);
      await expectLater(
        () => repository.upsert(const NutritionTargetsData()),
        throwsStateError,
      );
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('strictly parses complete canonical Nutrition Targets row', () async {
      final repository = _targetsRepository(
        gateway: _FakeTargetsGateway(
          readResult: {
            'calories_kcal': 2200,
            'protein_grams': 150,
            'carbohydrate_grams': 245.5,
            'fat_grams': 70,
            'fiber_grams': 32,
            'customization_state': 'mixed',
            'customized_fields': <dynamic>['protein_grams'],
            'recommendation_metadata': <String, dynamic>{
              'source': 'onboarding',
              'version': 1,
            },
          },
        ),
      );

      final data = await repository.read();
      expect(data?.caloriesKcal, 2200);
      expect(data?.proteinGrams, 150);
      expect(data?.carbohydrateGrams, 245.5);
      expect(data?.fatGrams, 70);
      expect(data?.fiberGrams, 32);
      expect(data?.customizationState, NutritionTargetCustomizationState.mixed);
      expect(data?.customizedFields, {'protein_grams'});
      expect(data?.recommendationMetadata['source'], 'onboarding');
    });

    test('canonical nullable numeric targets remain null', () async {
      final repository = _targetsRepository(
        gateway: _FakeTargetsGateway(
          readResult: {
            'calories_kcal': null,
            'protein_grams': null,
            'carbohydrate_grams': null,
            'fat_grams': null,
            'fiber_grams': null,
            'customization_state': 'unknown',
            'customized_fields': <dynamic>[],
            'recommendation_metadata': <String, dynamic>{},
          },
        ),
      );

      final data = await repository.read();
      expect(data?.caloriesKcal, isNull);
      expect(data?.proteinGrams, isNull);
      expect(data?.carbohydrateGrams, isNull);
      expect(data?.fatGrams, isNull);
      expect(data?.fiberGrams, isNull);
      expect(data?.customizationState, NutritionTargetCustomizationState.unknown);
    });

    test('rejects malformed canonical Targets rows instead of fabricating data',
        () async {
      final invalidRows = <Map<String, dynamic>>[
        {
          ..._validTargetsRow(),
          'customization_state': 'future',
        },
        {
          ..._validTargetsRow(),
          'customized_fields': null,
        },
        {
          ..._validTargetsRow(),
          'recommendation_metadata': <dynamic>[],
        },
        {
          ..._validTargetsRow(),
          'calories_kcal': 0,
        },
        {
          ..._validTargetsRow(),
          'protein_grams': -1,
        },
      ];

      for (final row in invalidRows) {
        final repository = _targetsRepository(
          gateway: _FakeTargetsGateway(readResult: row),
        );
        await expectLater(repository.read(), throwsFormatException);
      }
    });

    test('writes only canonical user_nutrition_targets columns', () async {
      final gateway = _FakeTargetsGateway();
      final repository = _targetsRepository(gateway: gateway);

      await repository.upsert(
        const NutritionTargetsData(
          caloriesKcal: 2100,
          proteinGrams: 140,
          carbohydrateGrams: 230,
          fatGrams: 65,
          fiberGrams: 30,
          customizationState: NutritionTargetCustomizationState.custom,
          customizedFields: {'protein_grams', 'calories_kcal'},
          recommendationMetadata: {'source': 'onboarding'},
        ),
      );

      expect(gateway.upsertPayloads, [
        {
          'user_id': 'user-1',
          'calories_kcal': 2100,
          'protein_grams': 140.0,
          'carbohydrate_grams': 230.0,
          'fat_grams': 65.0,
          'fiber_grams': 30.0,
          'customization_state': 'custom',
          'customized_fields': ['calories_kcal', 'protein_grams'],
          'recommendation_metadata': {'source': 'onboarding'},
        }
      ]);
    });

    test('rejects invalid write before canonical gateway access', () async {
      final gateway = _FakeTargetsGateway();
      final repository = _targetsRepository(gateway: gateway);

      await expectLater(
        () => repository.upsert(
          const NutritionTargetsData(caloriesKcal: -1),
        ),
        throwsArgumentError,
      );
      expect(gateway.upsertPayloads, isEmpty);
    });
  });
}

SupabaseNutritionProfileRepository _profileRepository({
  required _FakeProfileGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseNutritionProfileRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

SupabaseNutritionTargetsRepository _targetsRepository({
  required _FakeTargetsGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseNutritionTargetsRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

Map<String, dynamic> _validTargetsRow() => {
      'calories_kcal': 2000,
      'protein_grams': 120,
      'carbohydrate_grams': 220,
      'fat_grams': 60,
      'fiber_grams': 28,
      'customization_state': 'recommended',
      'customized_fields': <dynamic>[],
      'recommendation_metadata': <String, dynamic>{},
    };

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeProfileGateway implements NutritionProfileTableGateway {
  _FakeProfileGateway({this.readResult});

  final Map<String, dynamic>? readResult;
  final List<String> readUserIds = [];
  final List<Map<String, dynamic>> upsertPayloads = [];

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    readUserIds.add(userId);
    return readResult;
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    upsertPayloads.add(Map<String, dynamic>.from(payload));
  }
}

class _FakeTargetsGateway implements NutritionTargetsTableGateway {
  _FakeTargetsGateway({this.readResult});

  final Map<String, dynamic>? readResult;
  final List<String> readUserIds = [];
  final List<Map<String, dynamic>> upsertPayloads = [];

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    readUserIds.add(userId);
    return readResult;
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    upsertPayloads.add(Map<String, dynamic>.from(payload));
  }
}
