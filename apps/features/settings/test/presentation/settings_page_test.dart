import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  testWidgets('SettingsPage renders all Account & Profile tiles cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var profileSettingsTaps = 0;
    var subscriptionTaps = 0;
    var resetPasswordTaps = 0;
    var accountSettingsTaps = 0;
    var workoutTaps = 0;
    var wearOsTaps = 0;
    var nutritionTaps = 0;
    var appSettingsTaps = 0;
    var aboutTaps = 0;
    var logoutTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: SettingsPage(
          onProfileSettingsPressed: () => profileSettingsTaps++,
          onManageSubscriptionPressed: () => subscriptionTaps++,
          onResetPasswordPressed: () => resetPasswordTaps++,
          onAccountSettingsPressed: () => accountSettingsTaps++,
          onWorkoutPressed: () => workoutTaps++,
          onWearOsPressed: () => wearOsTaps++,
          onNutritionPressed: () => nutritionTaps++,
          onAppSettingsPressed: () => appSettingsTaps++,
          onAboutPressed: () => aboutTaps++,
          onLogoutPressed: () => logoutTaps++,
        ),
      ),
    );

    // Section headers
    expect(find.text('ACCOUNT & PROFILE'), findsOneWidget);
    expect(find.text('WORKOUT & WEARABLES'), findsOneWidget);
    expect(find.text('NUTRITION'), findsOneWidget);
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('SESSION'), findsOneWidget);

    // Account items
    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('Manage Subscription'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);

    // Other Tiles
    expect(find.text('Workout Settings'), findsOneWidget);
    expect(find.text('Wear OS / Watch Settings'), findsOneWidget);
    expect(find.text('Nutrition & Diet'), findsOneWidget);
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('About Tio'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Callbacks
    await tester.tap(find.text('Profile Settings'));
    expect(profileSettingsTaps, 1);

    await tester.tap(find.text('Account Settings'));
    expect(accountSettingsTaps, 1);

    await tester.tap(find.text('App Preferences'));
    expect(appSettingsTaps, 1);
  });
}
