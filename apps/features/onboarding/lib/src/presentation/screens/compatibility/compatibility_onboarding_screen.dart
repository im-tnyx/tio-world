import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

class CompatibilityOnboardingScreen extends StatelessWidget {
  const CompatibilityOnboardingScreen({
    required this.title,
    required this.description,
    required this.highlights,
    super.key,
  });

  final String title;
  final String description;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TioScreenHeader(
          title: title,
          subtitle: description,
        ),
        const SizedBox(height: TioSpacing.extraLarge),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TioSpacing.large),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.radiusLarge),
            border: Border.all(color: colors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compatibility preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: TioSpacing.medium),
              for (final highlight in highlights) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.check_circle_outline, size: 16),
                    ),
                    const SizedBox(width: TioSpacing.small),
                    Expanded(
                      child: Text(
                        highlight,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSpacing.small),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CompatibilityReviewScreen extends StatelessWidget {
  const CompatibilityReviewScreen({required this.mode, super.key});

  final AppMode? mode;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final selectedMode = mode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'Review setup',
          subtitle: 'Finish will confirm your selected App Mode and open Home '
              'with the matching guided navigation. Later onboarding slices '
              'will replace these preview steps with module-owned inputs.',
        ),
        const SizedBox(height: TioSpacing.extraLarge),
        if (selectedMode != null) ...[
          _SummaryRow(label: 'Selected mode', value: _modeLabel(selectedMode)),
          const SizedBox(height: TioSpacing.medium),
          _SummaryRow(label: 'Guided tabs', value: _tabSummary(selectedMode)),
          const SizedBox(height: TioSpacing.medium),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TioSpacing.large),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.radiusLarge),
            border: Border.all(color: colors.surfaceVariant),
          ),
          child: Text(
            'Explicit onboarding completion status and validated owner fields '
            'are still planned. This compatibility review confirms route flow, '
            'mode-aware ordering, and final Home navigation.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: TioSpacing.medium),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

String _modeLabel(AppMode mode) {
  return switch (mode) {
    AppMode.workout => 'Workout',
    AppMode.nutrition => 'Nutrition',
    AppMode.hybrid => 'Hybrid',
  };
}

String _tabSummary(AppMode mode) {
  return mode.guidedDestinations
      .map(
        (destination) => switch (destination) {
          AppDestination.home => 'Home',
          AppDestination.workout => 'Workout',
          AppDestination.nutrition => 'Nutrition',
          AppDestination.progress => 'Progress',
        },
      )
      .join(', ');
}
