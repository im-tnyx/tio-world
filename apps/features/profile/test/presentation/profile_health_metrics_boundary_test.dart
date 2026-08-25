import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  test('ProfilePage contains no Age BMI or BMR formula ownership', () {
    final source = File(
      'lib/src/presentation/pages/profile_page.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('_calculateAge')));
    expect(source, isNot(contains('_calculateBmi')));
    expect(source, isNot(contains('_calculateBmr')));
    expect(source, isNot(contains('heightM * heightM')));
    expect(source, isNot(contains('(10 * weightKg)')));
    expect(source, isNot(contains('DateTime.now()')));
    expect(source, contains('CalculateProfileHealthMetrics'));
  });

  testWidgets('ProfilePage renders domain-owned BMI and BMR metrics',
      (tester) async {
    final profile = ProfileSetupData(
      name: 'Rahul',
      gender: ProfileGender.male,
      goals: const {ProfileGoal.buildMuscle},
      dateOfBirth: DateTime(2000, 1, 1),
      heightCm: 180,
      currentWeightKg: 75,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {ProfileHealthCondition.none},
    );
    final expected = const CalculateProfileHealthMetrics().call(profile);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: ProfilePage(
          onSettingsPressed: () {},
          onAvatarPressed: () {},
          profileData: profile,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('profile-bmi-metric')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-bmr-metric')), findsOneWidget);
    expect(find.text('${expected.bmi}'), findsOneWidget);
    expect(find.text('${expected.bmrKcal}'), findsOneWidget);
  });
}
