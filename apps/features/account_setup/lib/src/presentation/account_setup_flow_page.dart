import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

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
          onChanged: (value) => _mobile = value,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_flowError != null && (_plan == null || _accountState == null)) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(TioSpacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _flowError!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: TioSpacing.medium),
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
      );
    }

    final plan = _plan!;
    final account = _accountState!;
    final step = _currentStep;
    final canContinue = step == AccountSetupStepId.mobile ||
        (step == AccountSetupStepId.username && _usernameCanContinue);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.small,
                0,
                TioSpacing.large,
                0,
              ),
              child: SizedBox(
                height: 48,
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
                          fontWeight: FontWeight.w600,
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
                  horizontal: TioSpacing.large,
                  vertical: TioSpacing.medium,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _buildStep(account),
                  ),
                ),
              ),
            ),
            Container(
              key: const ValueKey('account-setup-footer'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.large,
                TioSpacing.small,
                TioSpacing.large,
                TioSpacing.large,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineStrong.withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: TioSpacing.small),
                      ],
                      Text(
                        step == AccountSetupStepId.username
                            ? 'Username is required before continuing.'
                            : 'Mobile is optional. You can leave it blank and continue.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.small),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('account-setup-continue'),
                          onPressed: canContinue && !_busy
                              ? _handleContinue
                              : null,
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
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
    );
  }
}
