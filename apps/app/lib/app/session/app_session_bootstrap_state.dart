sealed class AppSessionBootstrapState {
  const AppSessionBootstrapState();
}

class AppSessionBootstrapLoading extends AppSessionBootstrapState {
  const AppSessionBootstrapLoading();

  @override
  bool operator ==(Object other) => other is AppSessionBootstrapLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AppSessionBootstrapUnauthenticated extends AppSessionBootstrapState {
  const AppSessionBootstrapUnauthenticated();

  @override
  bool operator ==(Object other) => other is AppSessionBootstrapUnauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AppSessionBootstrapRequiresOnboarding extends AppSessionBootstrapState {
  const AppSessionBootstrapRequiresOnboarding({required this.userId});

  final String userId;

  @override
  bool operator ==(Object other) =>
      other is AppSessionBootstrapRequiresOnboarding && other.userId == userId;

  @override
  int get hashCode => Object.hash(runtimeType, userId);
}

class AppSessionBootstrapReady extends AppSessionBootstrapState {
  const AppSessionBootstrapReady({required this.userId});

  final String userId;

  @override
  bool operator ==(Object other) =>
      other is AppSessionBootstrapReady && other.userId == userId;

  @override
  int get hashCode => Object.hash(runtimeType, userId);
}

class AppSessionBootstrapFailure extends AppSessionBootstrapState {
  const AppSessionBootstrapFailure(this.error);

  final Object error;
}
