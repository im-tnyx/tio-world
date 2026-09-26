import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../profile/profile_settings_route.dart';

List<RouteBase> buildProfileRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  return [
    GoRoute(
      path: AppRoutes.profileSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ProfileSettingsRoute(),
    ),
  ];
}
