import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// Debug-only execution surface for TNYX-229.
///
/// This widget is intentionally not exported from a feature package and is
/// only mounted by app composition in debug builds. It reuses the production
/// parser repository/controller and never persists a meal.
final class MealParserSmokePage extends StatefulWidget {
  const MealParserSmokePage({
    super.key,
    required this.repository,
  });

  final MealTextParseRepository repository;

  @override
  State<MealParserSmokePage> createState() => _MealParserSmokePageState();
}

final class _MealParserSmokePageState extends State<MealParserSmokePage> {
  late final MealTextParseController _controller;
  _SmokeResult? _result;

  static const _cases = <String, String>{
    'Success candidate': '200 g plain yogurt',
    'Unrecognized candidate': 'qwerty asdf',
    'Incomplete candidate': 'dal',
  };

  @override
  void initState() {
    super.initState();
    _controller = MealTextParseController(repository: widget.repository)
      ..addListener(_handleState);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleState)
      ..dispose();
    super.dispose();
  }

  void _handleState() {
    if (mounted) setState(() {});
  }

  Future<void> _run(String label, String text) async {
    if (_controller.state.isProcessing) return;

    final stopwatch = Stopwatch()..start();
    final draft = await _controller.submit(text);
    stopwatch.stop();
    if (!mounted) return;

    final state = _controller.state;
    setState(() {
      _result = _SmokeResult(
        label: label,
        elapsed: stopwatch.elapsed,
        status: state.status,
        message: state.message,
        draft: draft,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Parser Smoke')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TioSpacing.xl),
          children: [
            Text(
              'Debug-only. Synthetic non-personal text only.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: TioSpacing.lg),
            for (final entry in _cases.entries) ...[
              TioButton.secondary(
                label: entry.key,
                onPressed: _controller.state.isProcessing
                    ? null
                    : () => unawaited(_run(entry.key, entry.value)),
              ),
              const SizedBox(height: TioSpacing.sm),
            ],
            if (_controller.state.isProcessing) ...[
              const SizedBox(height: TioSpacing.lg),
              const Center(child: CircularProgressIndicator()),
            ],
            if (result != null) ...[
              const SizedBox(height: TioSpacing.xl),
              TioCard(
                child: Padding(
                  padding: const EdgeInsets.all(TioSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: TioSpacing.sm),
                      Text('status: ${result.status.name}'),
                      Text('elapsedMs: ${result.elapsed.inMilliseconds}'),
                      if (result.message != null)
                        Text('message: ${result.message}'),
                      if (result.draft != null) ...[
                        Text('items: ${result.draft!.items.length}'),
                        Text(
                          'captureSource: ${result.draft!.captureSource.name}',
                        ),
                        if (result.draft!.mealName != null)
                          Text('mealName: ${result.draft!.mealName}'),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _SmokeResult {
  const _SmokeResult({
    required this.label,
    required this.elapsed,
    required this.status,
    required this.message,
    required this.draft,
  });

  final String label;
  final Duration elapsed;
  final MealTextParseStatus status;
  final String? message;
  final MealLoggingDraft? draft;
}
