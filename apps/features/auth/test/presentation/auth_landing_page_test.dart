import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  Widget buildApp(_FakeAuthSignInRepository repository) {
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

    return MaterialApp.router(
      routerConfig: router,
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
    );
  }

  testWidgets('Google success stays on AuthLanding and preserves legal disclaimer',
      (tester) async {
    final repository = _FakeAuthSignInRepository(
      googleResult: const SignInSuccess(
        AuthSession(userId: 'returning-user'),
      ),
    );

    await tester.pumpWidget(buildApp(repository));

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

  testWidgets('Google failure clears loading and shows feedback on AuthLanding',
      (tester) async {
    const failureMessage =
        'Tio could not finish Google sign-in in time. Please try again.';
    final repository = _FakeAuthSignInRepository(
      googleResult: const SignInFailure(
        failureMessage,
        code: 'google_supabase_exchange_timeout',
      ),
    );

    await tester.pumpWidget(buildApp(repository));

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    await tester.pump();

    expect(repository.googleCalls, 1);
    expect(find.text(failureMessage), findsOneWidget);

    final googleButton = tester.widget<TioSocialButton>(
      find.byType(TioSocialButton).at(1),
    );
    expect(googleButton.loading, isFalse);
    expect(find.byType(AuthLandingPage), findsOneWidget);
    expect(find.byType(TioTermsDisclaimer), findsOneWidget);
  });
}

class _FakeAuthSignInRepository implements AuthSignInRepository {
  _FakeAuthSignInRepository({required this.googleResult});

  final SignInResult googleResult;
  int googleCalls = 0;

  @override
  Future<SignInResult> signInWithGoogle() async {
    googleCalls++;
    return googleResult;
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
