import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';

final healthConnectionGatewayProvider = Provider<HealthConnectionGateway>((ref) {
  return const UnavailableHealthConnectionGateway();
});

final healthConnectionsControllerProvider =
    ChangeNotifierProvider.autoDispose<HealthConnectionsController>((ref) {
  final controller = HealthConnectionsController(
    gateway: ref.watch(healthConnectionGatewayProvider),
  );
  unawaited(controller.refresh());
  return controller;
});

/// Owns only live Health Connections interaction state.
///
/// This state is intentionally separate from [OnboardingDraft]: platform
/// authorization truth is device/runtime state, not onboarding-owned durable
/// health data.
class HealthConnectionsController extends ChangeNotifier {
  HealthConnectionsController({required HealthConnectionGateway gateway})
      : _gateway = gateway;

  final HealthConnectionGateway _gateway;

  HealthConnectionStatus? _status;
  bool _isRefreshing = false;
  bool _isRequesting = false;
  Object? _error;

  HealthConnectionStatus? get status => _status;
  bool get isRefreshing => _isRefreshing;
  bool get isRequesting => _isRequesting;
  bool get isBusy => _isRefreshing || _isRequesting;
  Object? get error => _error;

  bool get canRequestConnection =>
      _status == HealthConnectionStatus.notRequested ||
      _status == HealthConnectionStatus.denied;

  Future<void> refresh() async {
    if (isBusy) return;
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      _status = await _gateway.readStatus();
    } catch (error) {
      // Fail safe: unknown platform/read failures must never become connected.
      _status = HealthConnectionStatus.unavailable;
      _error = error;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> requestConnection() async {
    if (isBusy || !canRequestConnection) return;
    _isRequesting = true;
    _error = null;
    notifyListeners();

    try {
      _status = await _gateway.requestConnection();
    } catch (error) {
      // Keep the last known non-connected state so the user can retry or skip.
      _error = error;
    } finally {
      _isRequesting = false;
      notifyListeners();
    }
  }
}
