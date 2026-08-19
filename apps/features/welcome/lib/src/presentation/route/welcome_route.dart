import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import '../action/welcome_action.dart';
import '../screen/welcome_screen.dart';
import '../view_model/welcome_view_model.dart';

class WelcomeRoute extends StatefulWidget {
  const WelcomeRoute({super.key});

  @override
  State<WelcomeRoute> createState() => _WelcomeRouteState();
}

class _WelcomeRouteState extends State<WelcomeRoute> {
  late final WelcomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WelcomeViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onAction(WelcomeAction action) {
    _viewModel.onAction(action);
    switch (action) {
      case WelcomeGetStartedClicked():
        // The fresh-account journey starts by choosing the local App Mode.
        // Authentication remains the boundary before account-owned fields and
        // Product Onboarding.
        context.push(AppRoutes.appModeSetup.path);
        break;
      case WelcomeSignInClicked():
        context.push(AppRoutes.login.path);
        break;
      case WelcomeSkipForNowClicked():
        context.push(AppRoutes.login.path);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return WelcomeScreen(
          state: _viewModel.uiState,
          onAction: _onAction,
        );
      },
    );
  }
}
