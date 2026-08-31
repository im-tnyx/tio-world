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

  static const appModeSetup = TioRouteContract(
    path: '/account-setup/app-mode',
    title: 'Choose App Mode',
    description: 'Choose the Tio experience to use before creating an account.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const accountSetup = TioRouteContract(
    path: '/account-setup',
    title: 'Account Setup',
    description: 'Complete required account details before product onboarding.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  /// Legacy deep-link alias. New bootstrap routing uses [accountSetup].
  static const usernameSetup = TioRouteContract(
    path: '/username-setup',
    title: 'Choose Username',
    description: 'Legacy account setup entry.',
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
    description: 'Manage your profile, account and app preferences.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const appSettings = TioRouteContract(
    path: '/settings/app',
    title: 'App Preferences',
    description: 'Manage app mode, theme and measurement units.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const appModeSettings = TioRouteContract(
    path: '/settings/app-mode',
    title: 'App Mode',
    description: 'Choose your guided app experience.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const measurementUnitsSettings = TioRouteContract(
    path: '/settings/measurement-units',
    title: 'Units',
    description: 'Choose weight, height, distance, and volume display units.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const profileSettings = TioRouteContract(
    path: '/settings/profile',
    title: 'Profile Settings',
    description: 'Manage your name, username, demographics and biometrics.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const accountSettings = TioRouteContract(
    path: '/settings/account',
    title: 'Account Settings',
    description: 'Manage email, mobile number, security and account lifecycle.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const healthGoalsSettings = TioRouteContract(
    path: '/settings/health-goals',
    title: 'Health & Goals',
    description: 'Manage your daily wellness targets and goals.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const nutritionSettings = TioRouteContract(
    path: '/settings/nutrition',
    title: 'Nutrition & Diet',
    description: 'Manage your diet context and nutrition preferences.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const nutritionProfileSettings = TioRouteContract(
    path: '/settings/nutrition/profile',
    title: 'Nutrition Profile',
    description: 'Manage your Diet Type, allergies and restrictions.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const dailyWellnessSettings = TioRouteContract(
    path: '/settings/health-goals/daily-wellness',
    title: 'Daily Wellness',
    description: 'Manage daily steps, water, sleep, and schedule targets.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const bodyWeightSettings = TioRouteContract(
    path: '/settings/health-goals/body-weight',
    title: 'Body & Weight',
    description: 'Manage your current weight and active Body Goal.',
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

  /// Compatibility deep link for Email Login.
  static const emailLogin = TioRouteContract(
    path: '/login/email',
    title: 'Sign In',
    description: 'Sign in with your email and password.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  /// Existing signup route retained for compatibility. Runtime Signup is now
  /// mode-driven and opens Phone-first by default.
  static const emailSignup = TioRouteContract(
    path: '/login/email-signup',
    title: 'Create Account',
    description: 'Create a new Tio account.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  /// Generic name for the current Phone-first Signup surface. It intentionally
  /// aliases the existing path so old deep links remain valid.
  static const signup = emailSignup;

  static const forgotPassword = TioRouteContract(
    path: '/login/forgot-password',
    title: 'Reset Password',
    description: 'Send a password reset email.',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const splash = TioRouteContract(
    path: '/splash',
    title: 'Splash',
    description: 'Initializing session and data access...',
    chromePolicy: ChromePolicy.fullScreen,
  );

  static const congratulations = TioRouteContract(
    path: '/congratulations',
    title: 'Congratulations',
    description: 'Welcome to Tio onboarding celebration.',
    chromePolicy: ChromePolicy.fullScreen,
  );
}
