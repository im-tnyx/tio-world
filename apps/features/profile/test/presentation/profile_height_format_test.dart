import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  testWidgets('Profile formats height with at most two decimal places',
      (tester) async {
    await tester.pumpWidget(
      _ProfileTestApp(
        child: ProfilePage(
          onAvatarPressed: () {},
          onSettingsPressed: () {},
          profileData: ProfileSetupData(
            name: 'Rahul',
            gender: ProfileGender.male,
            goals: const {ProfileGoal.buildMuscle},
            dateOfBirth: DateTime(2000, 1, 1),
            heightCm: 167.64000000000001,
            currentWeightKg: 75,
            activityLevel: ProfileActivityLevel.active,
            healthConditions: const {ProfileHealthCondition.none},
          ),
        ),
      ),
    );

    expect(find.text('167.64 cm'), findsOneWidget);
    expect(find.text('167.6 cm'), findsNothing);
    expect(find.text('167.64000000000001 cm'), findsNothing);
  });

  testWidgets('Profile renders persisted imperial display units without changing canonical values',
      (tester) async {
    await tester.pumpWidget(
      _ProfileTestApp(
        child: ProfilePage(
          onAvatarPressed: () {},
          onSettingsPressed: () {},
          profileData: ProfileSetupData(
            name: 'Rahul',
            gender: ProfileGender.male,
            goals: const {ProfileGoal.buildMuscle},
            dateOfBirth: DateTime(2000, 1, 1),
            heightCm: 182.88,
            currentWeightKg: 81.6466266,
            unitPreferences: UnitPreferences.imperial,
            activityLevel: ProfileActivityLevel.active,
            healthConditions: const {ProfileHealthCondition.none},
          ),
        ),
      ),
    );

    expect(find.text('6 ft 0 in'), findsOneWidget);
    expect(find.text('180 lb'), findsOneWidget);
    expect(find.text('182.88 cm'), findsNothing);
    expect(find.textContaining('81.6 kg'), findsNothing);
  });
}

class _ProfileTestApp extends StatelessWidget {
  const _ProfileTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, appChild) =>
          TioTheme(child: appChild ?? const SizedBox.shrink()),
      home: child,
    );
  }
}
