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
    this.runFatSecretIndiaProbe,
    this.runOpenFoodFactsProbe,
  });

  final MealTextParseRepository repository;
  final Future<Map<String, dynamic>> Function()? runFatSecretIndiaProbe;
  final Future<Map<String, dynamic>> Function()? runOpenFoodFactsProbe;

  @override
  State<MealParserSmokePage> createState() => _MealParserSmokePageState();
}

final class _MealParserSmokePageState extends State<MealParserSmokePage> {
  late final MealTextParseController _controller;
  _SmokeResult? _result;
  List<_CapabilityStage>? _fatSecretResult;
  String? _fatSecretError;
  bool _fatSecretRunning = false;
  List<_OpenFoodFactsResult>? _openFoodFactsResult;
  String? _openFoodFactsError;
  bool _openFoodFactsRunning = false;

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


  Future<void> _runFatSecretIndiaProbe() async {
    final run = widget.runFatSecretIndiaProbe;
    if (run == null || _fatSecretRunning) return;
    setState(() {
      _fatSecretRunning = true;
      _fatSecretResult = null;
      _fatSecretError = null;
    });
    try {
      final payload = await run();
      final rawResult = payload['result'];
      if (rawResult is! List) {
        throw const FormatException('Invalid capability result.');
      }
      final stages = <_CapabilityStage>[];
      for (final raw in rawResult) {
        if (raw is! Map) throw const FormatException('Invalid capability stage.');
        final stage = raw['stage'];
        final category = raw['category'];
        final status = raw['httpStatus'];
        if (stage is! String || category is! String ||
            (status != null && status is! num)) {
          throw const FormatException('Invalid capability stage.');
        }
        stages.add(_CapabilityStage(
          stage: stage,
          category: category,
          httpStatus: status is num ? status.toInt() : null,
        ));
      }
      if (!mounted) return;
      setState(() => _fatSecretResult = stages);
    } catch (_) {
      if (!mounted) return;
      setState(() => _fatSecretError = 'FatSecret capability probe failed safely.');
    } finally {
      if (mounted) setState(() => _fatSecretRunning = false);
    }
  }

  Future<void> _runOpenFoodFactsProbe() async {
    final run = widget.runOpenFoodFactsProbe;
    if (run == null || _openFoodFactsRunning) return;
    setState(() {
      _openFoodFactsRunning = true;
      _openFoodFactsResult = null;
      _openFoodFactsError = null;
    });
    try {
      final payload = await run();
      final rawResults = payload['results'];
      if (rawResults is! List) throw const FormatException('Invalid capability result.');
      final results = <_OpenFoodFactsResult>[];
      for (final raw in rawResults) {
        if (raw is! Map) throw const FormatException('Invalid capability result.');
        final query = raw['query'];
        final category = raw['category'];
        if (query is! String || category is! String) {
          throw const FormatException('Invalid capability result.');
        }
        results.add(_OpenFoodFactsResult(query: query, category: category));
      }
      if (!mounted) return;
      setState(() => _openFoodFactsResult = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _openFoodFactsError = 'Open Food Facts capability probe failed safely.');
    } finally {
      if (mounted) setState(() => _openFoodFactsRunning = false);
    }
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

            const SizedBox(height: TioSpacing.lg),
            TioButton.secondary(
              label: 'FatSecret IN capability',
              onPressed: widget.runFatSecretIndiaProbe == null || _fatSecretRunning
                  ? null
                  : () => unawaited(_runFatSecretIndiaProbe()),
            ),
            if (_fatSecretRunning) ...[
              const SizedBox(height: TioSpacing.sm),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_fatSecretError != null) ...[
              const SizedBox(height: TioSpacing.sm),
              Text(_fatSecretError!),
            ],
            if (_fatSecretResult != null) ...[
              const SizedBox(height: TioSpacing.sm),
              for (final stage in _fatSecretResult!)
                Text(
                  '${stage.stage}: ${stage.category}'
                  '${stage.httpStatus == null ? '' : ' (${stage.httpStatus})'}',
                ),
            ],
            const SizedBox(height: TioSpacing.lg),
            TioButton.secondary(
              label: 'Open Food Facts capability',
              onPressed: widget.runOpenFoodFactsProbe == null || _openFoodFactsRunning
                  ? null
                  : () => unawaited(_runOpenFoodFactsProbe()),
            ),
            if (_openFoodFactsRunning) ...[
              const SizedBox(height: TioSpacing.sm),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_openFoodFactsError != null) ...[
              const SizedBox(height: TioSpacing.sm),
              Text(_openFoodFactsError!),
            ],
            if (_openFoodFactsResult != null) ...[
              const SizedBox(height: TioSpacing.sm),
              for (final result in _openFoodFactsResult!)
                Text('${result.query}: ${result.category}'),
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


final class _CapabilityStage {
  const _CapabilityStage({
    required this.stage,
    required this.category,
    required this.httpStatus,
  });

  final String stage;
  final String category;
  final int? httpStatus;
}

final class _OpenFoodFactsResult {
  const _OpenFoodFactsResult({required this.query, required this.category});
  final String query;
  final String category;
}
