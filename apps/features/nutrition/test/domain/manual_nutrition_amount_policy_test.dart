import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  for (final field in ManualNutritionAmountField.values) {
    final spec = ManualNutritionAmountPolicy.specFor(field);

    group(field.name, () {
      test('accepts zero and the exact maximum', () {
        expect(
          ManualNutritionAmountPolicy.validateAmount(field: field, value: 0),
          isNull,
        );
        expect(
          ManualNutritionAmountPolicy.validateAmount(
            field: field,
            value: spec.maximum,
          ),
          isNull,
        );
      });

      test('rejects maximum plus 0.1', () {
        expect(
          ManualNutritionAmountPolicy.validateAmount(
            field: field,
            value: spec.maximum + 0.1,
          ),
          ManualNutritionAmountError.aboveMaximum,
        );
      });

      test('accepts one decimal and rejects two decimals', () {
        expect(
          ManualNutritionAmountPolicy.validateAmount(
            field: field,
            value: spec.maximum - 0.1,
          ),
          isNull,
        );
        expect(
          ManualNutritionAmountPolicy.validateAmount(
            field: field,
            value: spec.maximum - 0.01,
          ),
          ManualNutritionAmountError.excessPrecision,
        );
      });

      test('rejects negative and non-finite values', () {
        expect(
          ManualNutritionAmountPolicy.validateAmount(
            field: field,
            value: -0.1,
          ),
          ManualNutritionAmountError.negative,
        );
        expect(
          ManualNutritionAmountPolicy.validateAmount(
            field: field,
            value: double.infinity,
          ),
          ManualNutritionAmountError.invalidNumber,
        );
        expect(
          ManualNutritionAmountPolicy.validateAmount(
            field: field,
            value: double.nan,
          ),
          ManualNutritionAmountError.invalidNumber,
        );
      });
    });
  }

  test('text parsing reports invalid input without silently rounding', () {
    expect(
      ManualNutritionAmountPolicy.validateText(
        field: ManualNutritionAmountField.calories,
        text: 'not-a-number',
      ).error,
      ManualNutritionAmountError.invalidNumber,
    );
    expect(
      ManualNutritionAmountPolicy.validateText(
        field: ManualNutritionAmountField.protein,
        text: '1.11',
      ).error,
      ManualNutritionAmountError.excessPrecision,
    );
  });

  test('normal floating-point noise around one decimal remains valid', () {
    const computed = 0.1 + 0.2;

    expect(
      ManualNutritionAmountPolicy.validateAmount(
        field: ManualNutritionAmountField.carbs,
        value: computed,
      ),
      isNull,
    );
  });

  test('optional null stays absent while explicit zero stays valid', () {
    expect(
      ManualNutritionAmountPolicy.areAmountsValid(
        caloriesKcal: 0,
        carbohydrateGrams: null,
        proteinGrams: 0,
        fatGrams: null,
      ),
      isTrue,
    );
  });
}
