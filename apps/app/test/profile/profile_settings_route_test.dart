import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/profile/profile_settings_route.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  Widget testApp(Stream<ProfileSetupData?> stream) {
    return ProviderScope(
      overrides: [
        profileDataProvider.overrideWith((ref) => stream),
      ],
      child: MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: const ProfileSettingsRoute(),
      ),
    );
  }

  testWidgets('does not expose editable form while profile is unresolved',
      (tester) async {
    final controller = StreamController<ProfileSetupData?>();
    addTearDown(controller.close);

    await tester.pumpWidget(testApp(controller.stream));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save Changes'), findsNothing);
  });

  testWidgets('does not expose editable form when persisted profile is missing',
      (tester) async {
    final controller = StreamController<ProfileSetupData?>();
    addTearDown(controller.close);

    await tester.pumpWidget(testApp(controller.stream));
    controller.add(null);
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Your profile is not available yet. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Save Changes'), findsNothing);
  });

  testWidgets('renders existing Profile Settings form after real profile loads',
      (tester) async {
    final controller = StreamController<ProfileSetupData?>();
    addTearDown(controller.close);

    await tester.pumpWidget(testApp(controller.stream));
    controller.add(
      ProfileSetupData(
        name: 'Santosh Jangid',
        username: 'santosh',
        gender: ProfileGender.male,
        goals: const {ProfileGoal.keepFit},
        dateOfBirth: DateTime(1995, 6, 5),
        heightCm: 180,
        currentWeightKg: 80,
        targetWeightKg: 75,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
        mobile: '+91 9000000000',
        isMobileVerified: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Save Changes'), findsOneWidget);

    final textFields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(textFields, isNotEmpty);
    expect(textFields.first.controller?.text, 'Santosh Jangid');
  });
}
