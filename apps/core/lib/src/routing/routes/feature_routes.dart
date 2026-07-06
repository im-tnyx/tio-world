import 'route_contract.dart';

class FeatureRoutes {
  const FeatureRoutes._();

  static const home = TioRouteContract(
    path: '/',
    title: 'Home',
    description: 'Your daily health and fitness overview.',
  );

  static const nutrition = TioRouteContract(
    path: '/nutrition',
    title: 'Nutrition',
    description: 'Log your meals and monitor your macros.',
  );

  static const ai = TioRouteContract(
    path: '/coach',
    title: 'AI Coach',
    description: 'Get personalized guidance and answers to your questions.',
  );

  static const workout = TioRouteContract(
    path: '/workout',
    title: 'Workout',
    description: 'Track your exercises and follow workout plans.',
  );

  static const progress = TioRouteContract(
    path: '/progress',
    title: 'Progress',
    description: 'Visualize your journey and achievements.',
  );

  static const mainTabs = [home, nutrition, ai, workout, progress];
}
