import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

import '../../app_mode/app_mode.dart';
import '../../app_theme_controller.dart';
import '../../calendar_preferences_providers.dart';

List<RouteBase> buildSettingsRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required Future<void> Function() onLogoutRequested,
  required AppModeController appModeController,
  required AppThemeController appThemeController,
}) {
  return [
    GoRoute(
      path: AppRoutes.settings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final selectedMode =
              ref.watch(appModeControllerProvider).selectedMode;
          final showNutrition = selectedMode == AppMode.nutrition ||
              selectedMode == AppMode.hybrid;

          return SettingsPage(
            onProfileSettingsPressed: () =>
                context.push(AppRoutes.profileSettings.path),
            onAccountSettingsPressed: () =>
                context.push(AppRoutes.accountSettings.path),
            onHealthGoalsPressed: () =>
                context.push(AppRoutes.healthGoalsSettings.path),
            showNutritionSection: showNutrition,
            onNutritionPressed: () =>
                context.push(AppRoutes.nutritionSettings.path),
            onAppSettingsPressed: () =>
                context.push(AppRoutes.appSettings.path),
            onLogoutPressed: () async {
              await onLogoutRequested();
              if (context.mounted) context.go(AppRoutes.auth.path);
            },
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.appModeSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final currentMode = appModeController.selectedMode;
        if (currentMode == null) return const SizedBox.shrink();

        return AppModeSettingsPage(
          currentMode: currentMode,
          onModeChanged: (mode) async {
            await appModeController.select(mode);
            if (context.mounted) context.go(FeatureRoutes.home.path);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.calendarSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final calendar = ref.watch(calendarPreferencesControllerProvider);
          return CalendarSettingsPage(
            firstDayOfWeek: calendar.firstDayOfWeek,
            onFirstDayOfWeekChanged: calendar.select,
            errorText: calendar.saveError == null
                ? null
                : 'Could not save your calendar preference. Please try again.',
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.themeSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => ThemeSettingsPage(
        currentMode: appThemeController.selectedMode,
        onThemeChanged: (mode) async {
          await appThemeController.select(mode);
          if (context.mounted) context.pop();
        },
      ),
    ),
  ];
}
