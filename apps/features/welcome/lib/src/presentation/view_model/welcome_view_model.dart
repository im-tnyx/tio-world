import 'package:flutter/foundation.dart';
import '../state/welcome_ui_state.dart';
import '../action/welcome_action.dart';

class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel() : _uiState = const WelcomeUiState();

  WelcomeUiState _uiState;
  WelcomeUiState get uiState => _uiState;

  void onAction(WelcomeAction action) {
    switch (action) {
      case WelcomeLanguageChanged(localeCode: final code):
        _handleLanguageChange(code);
      case WelcomeGetStartedClicked():
        break;
      case WelcomeSignInClicked():
        break;
      case WelcomeSkipForNowClicked():
        break;
      case WelcomeTermsTapped():
      case WelcomePrivacyTapped():
        break;
    }
  }

  void _handleLanguageChange(String code) {
    _uiState = _uiState.copyWith(
      localeCode: code,
    );
    notifyListeners();
  }
}
