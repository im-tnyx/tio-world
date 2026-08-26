import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_shared/shared.dart';

import '../domain/models/account_setup_flow_plan.dart';
import '../domain/models/account_setup_step_id.dart';
import '../domain/usecases/build_account_setup_flow_use_case.dart';
import 'steps/mobile_step.dart';
import 'steps/username_step.dart';

class AccountSetupFlowPage extends StatefulWidget {
  const AccountSetupFlowPage({
    required this.usernameRepository,
    required this.accountSetupRepository,
    required this.hasTrustedPhoneIdentity,
    required this.onCompleted,
    required this.onExitRequested,
    this.planner = const BuildAccountSetupFlowUseCase(),
    super.key,
  });

  final ProfileAccountRepository usernameRepository;
  final AccountSetupRepository accountSetupRepository;
  final bool hasTrustedPhoneIdentity;
  final Future<void> Function() onCompleted;
  final Future<void> Function() onExitRequested;
  final BuildAccountSetupFlowUseCase planner;

  @override
  State<AccountSetupFlowPage> createState() => _AccountSetupFlowPageState();
}

class _AccountSetupFlowPageState extends State<AccountSetupFlowPage> {
  final GlobalKey<UsernameStepState> _usernameKey =
      GlobalKey<UsernameStepState>();

  AccountSetupAccountState? _accountState;
  AccountSetupFlowPlan? _plan;
  int _currentIndex = 0;
  bool _loading = true;
  bool _busy = false;
  bool _usernameCanContinue = false;
  String _mobile = '';
  String? _flowError;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _flowError = null;
      });
    }

    try {
      final account = await widget.accountSetupRepository.readAccountSetupState();
      final plan = widget.planner(
        hasUsername: account.hasUsername,
        accountSetupCompleted: account.isCompleted,
        hasTrustedPhoneIdentity: widget.hasTrustedPhoneIdentity,
      );

      if (!mounted) return;

      if (plan.isEmpty) {
        if (!account.isCompleted) {
          await widget.accountSetupRepository.completeAccountSetup();
        }
        if (!mounted) return;
        await widget.onCompleted();
        return;
      }

      setState(() {
        _accountState = account;
        _plan = plan;
        _currentIndex = 0;
        _mobile = account.mobile;
        _usernameCanContinue = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _flowError = 'Could not load account setup. Please try again.';
      });
    }
  }

  AccountSetupStepId get _currentStep => _plan!.steps[_currentIndex];

  bool get _mobileCanContinue {
    if (_mobile.trim().isEmpty) return true;
    try {
      return normalizePhoneNumberE164(_mobile).isNotEmpty;
    } on ArgumentError {
      return false;
    }
  }

  Future<void> _handleBack() async {
    if (_busy) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _flowError = null;
      });
      return;
    }
    await widget.onExitRequested();
  }

  Widget _withBackHandling(Widget child) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: child,
    );
  }

  Future<void> _showMobileInformation() async {
    await showTioInformationBottomSheet(
      context: context,
      sheetKey: const ValueKey('account-setup-mobile-info-sheet'),
      title: 'Why we ask for your mobile number',
      message:
          'Your mobile number can help with account recovery, security features, and future verification. It is optional during setup, and you can add or verify it later from Account Settings.',
      actionLabel: 'Understood',
    );
  }

  Future<void> _handleContinue() async {
    if (_busy || _plan == null) return;

    setState(() {
      _busy = true;
      _flowError = null;
    });

    try {
      switch (_currentStep) {
        case AccountSetupStepId.username:
          final stepState = _usernameKey.currentState;
          if (stepState == null || !await stepState.submit()) {
            if (mounted) setState(() => _busy = false);
            return;
          }

          final current = _accountState ?? const AccountSetupAccountState();
          _accountState = AccountSetupAccountState(
            username: stepState.username,
            mobile: current.mobile,
            isMobileVerified: current.isMobileVerified,
            isCompleted: current.isCompleted,
          );

          if (_currentIndex + 1 < _plan!.steps.length) {
            if (!mounted) return;
            setState(() {
              _currentIndex++;
              _busy = false;
            });
            return;
          }

          if (!current.isCompleted) {
            await widget.accountSetupRepository.completeAccountSetup();
          }
          if (!mounted) return;
          await widget.onCompleted();
          return;

        case AccountSetupStepId.mobile:
          await widget.accountSetupRepository.completeAccountSetup(
            mobile: _mobile,
          );
          if (!mounted) return;
          await widget.onCompleted();
          return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _flowError = 'Could not save account setup. Please try again.';
      });
    }
  }

  Widget _buildStep(AccountSetupAccountState account) {
    return switch (_currentStep) {
      AccountSetupStepId.username => UsernameStep(
          key: _usernameKey,
          repository: widget.usernameRepository,
          initialUsername: account.username ?? '',
          enabled: !_busy,
          onCanContinueChanged: (canContinue) {
            if (!mounted || _usernameCanContinue == canContinue) return;
            setState(() => _usernameCanContinue = canContinue);
          },
        ),
      AccountSetupStepId.mobile => MobileStep(
          initialMobile: _mobile,
          isVerified: account.isMobileVerified,
          enabled: !_busy,
          onChanged: (value) {
            if (!mounted) return;
            setState(() => _mobile = value);
          },
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final theme = Theme.of(context);

    if (_loading) {
      return _withBackHandling(
        Scaffold(
          backgroundColor: colors.background,
          body: const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    if (_flowError != null && (_plan == null || _accountState == null)) {
      return _withBackHandling(
        Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(TioSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _flowError!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: TioSpacing.md),
                    FilledButton(
                      key: const ValueKey('account-setup-retry'),
                      onPressed: _hydrate,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final plan = _plan!;
    final account = _accountState!;
    final step = _currentStep;
    final canContinue = step == AccountSetupStepId.mobile
        ? _mobileCanContinue
        : _usernameCanContinue;

    return _withBackHandling(
      Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.sm,
                  0,
                  TioSpacing.lg,
                  0,
                ),
                child: SizedBox(
                  height: TioSize.dp48,
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('account-setup-back-button'),
                        onPressed: _busy ? null : _handleBack,
                        icon: Icon(
                          Icons.arrow_back,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Semantics(
                        label:
                            'Account setup step ${_currentIndex + 1} of ${plan.steps.length}',
                        child: Text(
                          '${_currentIndex + 1} / ${plan.steps.length}',
                          key: const ValueKey('account-setup-progress'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: TioFontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('account-setup-content'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.lg,
                    vertical: TioSpacing.md,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: TioSize.dp480,
                      ),
                      child: _buildStep(account),
                    ),
                  ),
                ),
              ),
              Container(
                key: const ValueKey('account-setup-footer'),
                width: double.infinity,
                color: colors.background,
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.lg,
                  TioSpacing.sm,
                  TioSpacing.lg,
                  TioSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: TioSize.dp480,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_flowError case final error?) ...[
                          Text(
                            error,
                            key: const ValueKey('account-setup-flow-error'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: TioFontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: TioSpacing.sm),
                        ],
                        if (step == AccountSetupStepId.mobile)
                          TioInlineInfoAction(
                            key: const ValueKey('account-setup-mobile-info'),
                            label: 'Why do we need this information?',
                            onTap: _busy ? null : _showMobileInformation,
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const ValueKey('account-setup-continue'),
                            onPressed: canContinue && !_busy
                                ? _handleContinue
                                : null,
                            child: _busy
                                ? const SizedBox(
                                    width: TioSize.dp20,
                                    height: TioSize.dp20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: TioStroke.width2,
                                    ),
                                  )
                                : const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
