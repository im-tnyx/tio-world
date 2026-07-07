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

  static const settings = TioRouteContract(
    path: '/settings',
    title: 'Settings',
    description: 'Configure your app preferences and notifications.',
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
