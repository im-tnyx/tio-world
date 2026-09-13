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

  test('raw near-step text still rejects excess fractional digits', () {
    for (final text in ['0.30000000009', '1.00']) {
      expect(
        ManualNutritionAmountPolicy.validateText(
          field: ManualNutritionAmountField.carbs,
          text: text,
        ).error,
        ManualNutritionAmountError.excessPrecision,
        reason: text,
      );
    }
  });

  test('scientific notation is rejected at the raw text boundary', () {
    for (final text in ['1e-14', '1e1', '1E2']) {
      expect(
        ManualNutritionAmountPolicy.validateText(
          field: ManualNutritionAmountField.carbs,
          text: text,
        ).error,
        ManualNutritionAmountError.excessPrecision,
        reason: text,
      );
    }
  });

  test('direct numeric near-step and tiny values cannot bypass precision', () {
    for (final value in [0.30000000009, 1e-14]) {
      expect(
        ManualNutritionAmountPolicy.validateAmount(
          field: ManualNutritionAmountField.carbs,
          value: value,
        ),
        ManualNutritionAmountError.excessPrecision,
        reason: '$value',
      );
    }
  });

  test('normal floating-point noise remains valid across magnitudes', () {
    const macroComputed = 0.1 + 0.2;
    const calorieComputed = 8206.2 - 8.9;

    expect(
      ManualNutritionAmountPolicy.validateAmount(
        field: ManualNutritionAmountField.carbs,
        value: macroComputed,
      ),
      isNull,
    );
    expect(
      ManualNutritionAmountPolicy.validateAmount(
        field: ManualNutritionAmountField.calories,
        value: calorieComputed,
      ),
      isNull,
    );
    expect(
      ManualNutritionAmountPolicy.validateAmount(
        field: ManualNutritionAmountField.calories,
        value: 8197.3000001,
      ),
      ManualNutritionAmountError.excessPrecision,
    );
  });

  test('canonical editor text is produced only for accepted numeric values', () {
    expect(
      ManualNutritionAmountPolicy.canonicalEditorText(
        field: ManualNutritionAmountField.carbs,
        value: 0.1 + 0.2,
      ),
      '0.3',
    );
    expect(
      ManualNutritionAmountPolicy.canonicalEditorText(
        field: ManualNutritionAmountField.calories,
        value: 8206.2 - 8.9,
      ),
      '8197.3',
    );
    expect(
      ManualNutritionAmountPolicy.canonicalEditorText(
        field: ManualNutritionAmountField.carbs,
        value: 0.30000000009,
      ),
      isNull,
    );
    expect(
      ManualNutritionAmountPolicy.canonicalEditorText(
        field: ManualNutritionAmountField.calories,
        value: 15000,
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
