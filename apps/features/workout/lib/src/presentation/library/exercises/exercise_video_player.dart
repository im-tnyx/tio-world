import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:video_player/video_player.dart';

/// The small lifecycle surface the detail widget needs from a video player.
/// Tests can provide a deterministic implementation without touching the
/// platform video plugin.
abstract interface class ExerciseVideoControllerHandle {
  ValueListenable<ExerciseVideoPlayerState> get state;

  Future<void> initialize();
  Future<void> setLooping(bool looping);
  Future<void> play();
  Future<void> pause();
  Widget build(BuildContext context);
  Future<void> dispose();
}

final class ExerciseVideoPlayerState {
  const ExerciseVideoPlayerState({
    this.initialized = false,
    this.hasError = false,
    this.isBuffering = false,
    this.aspectRatio = 16 / 9,
    this.errorMessage,
  });

  final bool initialized;
  final bool hasError;
  final bool isBuffering;
  final double aspectRatio;
  final String? errorMessage;
}

typedef ExerciseVideoControllerFactory = ExerciseVideoControllerHandle Function(
    Uri url);

/// Public observer so a route-pushed editor can pause the detail player while
/// the detail page remains mounted underneath it.
final exerciseDetailRouteObserver = RouteObserver<ModalRoute<void>>();

class ExerciseMediaLoading extends StatelessWidget {
  const ExerciseMediaLoading({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.tioColors.mediaBackground,
        child: const Center(
          key: ValueKey('exercise-media-loading'),
          child: CircularProgressIndicator(),
        ),
      );
}

class ExerciseMediaFallback extends StatelessWidget {
  const ExerciseMediaFallback({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.tioColors.mediaBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TioSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  color: context.tioColors.onMediaSecondary,
                  size: TioSize.dp32,
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.tioColors.onMediaSecondary,
                    fontSize: TioFontSize.size14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class ExerciseVideoPlayer extends StatefulWidget {
  const ExerciseVideoPlayer({
    required this.url,
    this.controllerFactory = createExerciseVideoController,
    super.key,
  });

  final Uri url;
  final ExerciseVideoControllerFactory controllerFactory;

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer>
    with WidgetsBindingObserver, RouteAware {
  late ExerciseVideoControllerHandle _controller;
  var _isRouteVisible = true;
  var _isLifecycleResumed = true;
  var _subscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controllerFactory(widget.url);
    _controller.state.addListener(_onStateChanged);
    unawaited(_initialize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribed) return;
    final route = ModalRoute.of(context);
    if (route != null) {
      exerciseDetailRouteObserver.subscribe(
        this,
        route as ModalRoute<void>,
      );
      _subscribed = true;
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) return;
    final previous = _controller;
    previous.state.removeListener(_onStateChanged);
    _controller = widget.controllerFactory(widget.url);
    _controller.state.addListener(_onStateChanged);
    unawaited(previous.dispose());
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _syncPlayback();
    } catch (_) {
      // The handle owns the user-visible error state. This guard prevents an
      // initialization race from trying to play a disposed controller.
      if (mounted) setState(() {});
    }
  }

  Future<void> _syncPlayback() async {
    final state = _controller.state.value;
    if (!state.initialized || state.hasError) return;
    if (_isRouteVisible && _isLifecycleResumed) {
      await _controller.play();
    } else {
      await _controller.pause();
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isLifecycleResumed = state == AppLifecycleState.resumed;
    unawaited(_syncPlayback());
  }

  @override
  void didPushNext() {
    _isRouteVisible = false;
    unawaited(_syncPlayback());
  }

  @override
  void didPopNext() {
    _isRouteVisible = true;
    unawaited(_syncPlayback());
  }

  @override
  void didPop() {
    _isRouteVisible = false;
    unawaited(_syncPlayback());
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state.value;
    if (state.hasError) {
      return const ExerciseMediaFallback(
        message: 'Video unavailable. Instructions are still available.',
      );
    }
    if (!state.initialized) {
      return const ExerciseMediaLoading();
    }
    final ratio = state.aspectRatio.isFinite && state.aspectRatio > 0
        ? state.aspectRatio
        : 16 / 9;
    return AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _controller.build(context),
          if (state.isBuffering)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_subscribed) exerciseDetailRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.state.removeListener(_onStateChanged);
    unawaited(_controller.dispose());
    super.dispose();
  }
}

ExerciseVideoControllerHandle createExerciseVideoController(Uri url) =>
    _VideoPlayerControllerHandle(VideoPlayerController.networkUrl(url));

final class _VideoPlayerControllerHandle
    implements ExerciseVideoControllerHandle {
  _VideoPlayerControllerHandle(this._controller)
      : _state = ValueNotifier(const ExerciseVideoPlayerState()) {
    _controller.addListener(_onValueChanged);
  }

  final VideoPlayerController _controller;
  final ValueNotifier<ExerciseVideoPlayerState> _state;
  var _disposed = false;

  @override
  ValueListenable<ExerciseVideoPlayerState> get state => _state;

  @override
  Future<void> initialize() async {
    try {
      await _controller.initialize();
      _onValueChanged();
    } catch (error) {
      _state.value = ExerciseVideoPlayerState(
        hasError: true,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> setLooping(bool looping) => _controller.setLooping(looping);

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Widget build(BuildContext context) => VideoPlayer(_controller);

  void _onValueChanged() {
    if (_disposed) return;
    final value = _controller.value;
    _state.value = ExerciseVideoPlayerState(
      initialized: value.isInitialized,
      hasError: value.hasError,
      isBuffering: value.isBuffering,
      aspectRatio: value.isInitialized ? value.aspectRatio : 16 / 9,
      errorMessage: value.errorDescription,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_onValueChanged);
    await _controller.dispose();
    _state.dispose();
  }
}
