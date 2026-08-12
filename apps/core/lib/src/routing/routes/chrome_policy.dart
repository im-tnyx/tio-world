enum ChromePolicy {
  mainChrome,
  noBottomBar,
  fullScreen,
  bottomSheet,
  dialog;

  bool get showsBottomNav => this == ChromePolicy.mainChrome;
  bool get showsRootTopBar => this == ChromePolicy.mainChrome;
  bool get isFullScreen => this == ChromePolicy.fullScreen;
}
