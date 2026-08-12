import '../state/shell_state.dart';

sealed class ShellAction {
  const ShellAction();
}

class ShellTabSelected extends ShellAction {
  const ShellTabSelected(this.tab);

  final ShellTab tab;
}

class ShellScrollChanged extends ShellAction {
  const ShellScrollChanged(this.offset);

  final double offset;
}

class ShellPremiumClicked extends ShellAction {
  const ShellPremiumClicked();
}

class ShellStreakClicked extends ShellAction {
  const ShellStreakClicked();
}

class ShellProfileClicked extends ShellAction {
  const ShellProfileClicked();
}
