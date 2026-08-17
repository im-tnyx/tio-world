import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls whether [OnboardingFlowPage] waits for draft hydration before
/// rendering the first visible onboarding step.
///
/// Feature-level/default contexts remain eager for backwards compatibility.
/// Production can enable the gate when draft restoration is asynchronous and a
/// default first frame would otherwise flash the wrong step.
final onboardingHydrationGateProvider = Provider<bool>((ref) => false);
