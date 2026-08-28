import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

class HealthConnectionsScreen extends StatelessWidget {
  const HealthConnectionsScreen({
    required this.status,
    required this.isBusy,
    super.key,
    this.error,
  });

  final HealthConnectionStatus? status;
  final bool isBusy;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final presentation = _presentationFor(status, isBusy: isBusy, hasError: error != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'Connect health data',
          subtitle:
              'Connect supported health services to help Tio use activity, sleep, and workout context. You can skip this and connect later.',
        ),
        const SizedBox(height: TioSpacing.xl),
        Semantics(
          liveRegion: true,
          label: '${presentation.title}. ${presentation.message}',
          child: TioCard(
            variant: TioCardVariant.outlined,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  presentation.icon,
                  color: presentation.emphasize
                      ? colors.primary
                      : colors.textSecondary,
                ),
                const SizedBox(width: TioSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: TioSpacing.sm),
                      Text(
                        presentation.message,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TioSpacing.lg),
        Text(
          'Tio will only ask for health access after you choose Connect. Opening this screen never requests permission.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

_HealthConnectionPresentation _presentationFor(
  HealthConnectionStatus? status, {
  required bool isBusy,
  required bool hasError,
}) {
  if (status == null || isBusy && !hasError) {
    return const _HealthConnectionPresentation(
      icon: Icons.sync,
      title: 'Checking availability',
      message: 'Tio is checking whether a supported health connection is available.',
      emphasize: false,
    );
  }

  if (hasError) {
    return const _HealthConnectionPresentation(
      icon: Icons.info_outline,
      title: 'Could not check health access',
      message:
          'You can continue setup now and try connecting health data again later.',
      emphasize: false,
    );
  }

  return switch (status) {
    HealthConnectionStatus.unavailable => const _HealthConnectionPresentation(
        icon: Icons.health_and_safety_outlined,
        title: 'Health connection is not available yet',
        message:
            'You can continue setup and connect later when this device supports a health integration.',
        emphasize: false,
      ),
    HealthConnectionStatus.notRequested => const _HealthConnectionPresentation(
        icon: Icons.favorite_outline,
        title: 'Connect when you are ready',
        message:
            'Choose Connect to start the platform authorization flow. You can also choose Not now and continue setup.',
        emphasize: true,
      ),
    HealthConnectionStatus.denied => const _HealthConnectionPresentation(
        icon: Icons.shield_outlined,
        title: 'Health access was not granted',
        message:
            'You can try again or choose Not now. Your Product Onboarding setup can continue either way.',
        emphasize: false,
      ),
    HealthConnectionStatus.connected => const _HealthConnectionPresentation(
        icon: Icons.check_circle_outline,
        title: 'Health data connected',
        message:
            'Your device confirmed the connection. You can continue with setup.',
        emphasize: true,
      ),
  };
}

class _HealthConnectionPresentation {
  const _HealthConnectionPresentation({
    required this.icon,
    required this.title,
    required this.message,
    required this.emphasize,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool emphasize;
}
