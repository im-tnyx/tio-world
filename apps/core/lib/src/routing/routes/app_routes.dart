import 'chrome_policy.dart';
import 'route_contract.dart';

class AppRoutes {
  const AppRoutes._();

  static const home = TioRouteContract(
    path: '/',
    title: 'Home',
    description: 'Your daily health and fitness overview.',
  );

  static const auth = TioRouteContract(
    path: '/auth',
    title: 'Auth',
    description: 'Sign in and manage session access.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const onboarding = TioRouteContract(
    path: '/onboarding',
    title: 'Onboarding',
    description: 'Set goals, preferences, and first profile context.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const profile = TioRouteContract(
    path: '/profile',
    title: 'Profile',
    description: 'Manage your personal information and health data.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const profileAvatar = TioRouteContract(
    path: '/profile/avatar',
    title: 'Profile photo',
    description: 'View and manage your profile photo.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const settings = TioRouteContract(
    path: '/settings',
    title: 'Settings',
    description: 'Configure your app preferences and notifications.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const appSettings = TioRouteContract(
    path: '/settings/app',
    title: 'App Settings',
    description: 'Manage app mode and theme preferences.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const appModeSettings = TioRouteContract(
    path: '/settings/app-mode',
    title: 'App Mode',
    description: 'Choose your guided app experience.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const themeSettings = TioRouteContract(
    path: '/settings/theme',
    title: 'Theme',
    description: 'Choose your app appearance.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const login = TioRouteContract(
    path: '/login',
    title: 'Login',
    description: 'Sign in to your account and manage session access.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const splash = TioRouteContract(
    path: '/splash',
    title: 'Splash',
    description: 'Initializing session and data access...',
    chromePolicy: ChromePolicy.fullScreen,
  );
}
