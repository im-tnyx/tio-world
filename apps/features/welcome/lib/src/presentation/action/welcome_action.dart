sealed class WelcomeAction {
  const WelcomeAction();
}

class WelcomeGetStartedClicked extends WelcomeAction {
  const WelcomeGetStartedClicked();
}

class WelcomeSignInClicked extends WelcomeAction {
  const WelcomeSignInClicked();
}

class WelcomeSkipForNowClicked extends WelcomeAction {
  const WelcomeSkipForNowClicked();
}

class WelcomeLanguageChanged extends WelcomeAction {
  final String localeCode;
  const WelcomeLanguageChanged(this.localeCode);
}

class WelcomeTermsTapped extends WelcomeAction {
  const WelcomeTermsTapped();
}

class WelcomePrivacyTapped extends WelcomeAction {
  const WelcomePrivacyTapped();
}
