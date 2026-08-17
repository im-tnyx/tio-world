import 'package:flutter/foundation.dart';
import '../state/welcome_ui_state.dart';
import '../action/welcome_action.dart';

class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel() : _uiState = const WelcomeUiState();

  final WelcomeUiState _uiState;
  WelcomeUiState get uiState => _uiState;

  void onAction(WelcomeAction action) {
    switch (action) {
      case WelcomeGetStartedClicked():
        break;
      case WelcomeSignInClicked():
        break;
      case WelcomeSkipForNowClicked():
        break;
    }
  }
}
