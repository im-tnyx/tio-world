import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  testWidgets('Google success stays on AuthLanding and preserves legal disclaimer',
      (tester) async {
    final repository = _FakeAuthSignInRepository();
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => AuthLandingPage(
            signInWithGoogleUseCase:
                SignInWithGoogleUseCase(signInRepository: repository),
          ),
        ),
        GoRoute(
          path: AppRoutes.emailSignup.path,
          builder: (context, state) => const Scaffold(body: Text('Signup')),
        ),
        GoRoute(
          path: AppRoutes.onboarding.path,
          builder: (context, state) => const Scaffold(body: Text('Onboarding')),
        ),
        GoRoute(
          path: AppRoutes.congratulations.path,
          builder: (context, state) => const Scaffold(body: Text('Congratulations')),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
      ),
    );

    expect(find.byType(AuthLandingPage), findsOneWidget);
    expect(find.byType(TioTermsDisclaimer), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(repository.googleCalls, 1);
    expect(find.byType(AuthLandingPage), findsOneWidget);
    expect(find.byType(TioTermsDisclaimer), findsOneWidget);
    expect(find.text('Onboarding'), findsNothing);
    expect(find.text('Congratulations'), findsNothing);
    expect(find.text('Home'), findsNothing);
  });
}

class _FakeAuthSignInRepository implements AuthSignInRepository {
  int googleCalls = 0;

  @override
  Future<SignInResult> signInWithGoogle() async {
    googleCalls++;
    return const SignInSuccess(AuthSession(userId: 'returning-user'));
  }

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const SignInCancelled();

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async => const SignInCancelled();

  @override
  Future<SignInResult> sendPasswordResetEmail(String email) async =>
      const SignInCancelled();

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInCancelled();
}
