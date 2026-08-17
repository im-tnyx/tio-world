import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  testWidgets('SettingsPage renders categorized settings entries cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var profileSettingsTaps = 0;
    var accountSettingsTaps = 0;
    var appSettingsTaps = 0;
    var measurementUnitsTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: SettingsPage(
          onProfileSettingsPressed: () => profileSettingsTaps++,
          onAccountSettingsPressed: () => accountSettingsTaps++,
          onAppSettingsPressed: () => appSettingsTaps++,
          onMeasurementUnitsPressed: () => measurementUnitsTaps++,
        ),
      ),
    );

    expect(find.text('ACCOUNT & PROFILE'), findsOneWidget);
    expect(find.text('WORKOUT & WEARABLES'), findsOneWidget);
    expect(find.text('NUTRITION'), findsOneWidget);
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('SESSION'), findsOneWidget);

    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('Measurement Units'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    await tester.tap(find.text('Profile Settings'));
    expect(profileSettingsTaps, 1);

    await tester.tap(find.text('Account Settings'));
    expect(accountSettingsTaps, 1);

    await tester.tap(find.text('App Preferences'));
    expect(appSettingsTaps, 1);

    await tester.tap(find.text('Measurement Units'));
    expect(measurementUnitsTaps, 1);
  });
}
