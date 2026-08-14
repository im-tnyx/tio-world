import 'onboarding_status.dart';

class OnboardingStatusSnapshot {
  const OnboardingStatusSnapshot({
    required this.status,
    required this.hasStoredContractVersion,
  });

  final OnboardingStatus? status;
  final bool hasStoredContractVersion;
}
