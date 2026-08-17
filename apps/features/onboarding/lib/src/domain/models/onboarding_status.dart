enum OnboardingStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed');

  const OnboardingStatus(this.storageValue);

  final String storageValue;

  static OnboardingStatus? fromStorageValue(String? value) {
    for (final status in values) {
      if (status.storageValue == value) return status;
    }
    return null;
  }
}
