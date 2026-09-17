import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../domain/repositories/meal_text_parse_repository.dart';

enum MealTextParseStatus {
  idle,
  processing,
  failed,
  succeeded,
}

@immutable
final class MealTextParseState {
  const MealTextParseState._({
    required this.status,
    this.submittedText,
    this.message,
    this.draft,
  });

  const MealTextParseState.idle()
      : this._(status: MealTextParseStatus.idle);

  final MealTextParseStatus status;

  /// Last normalized text accepted for processing.
  ///
  /// It remains available after a recoverable failure so presentation can
  /// retry the same description without reconstructing it from provider state.
  final String? submittedText;
  final String? message;
  final MealLoggingDraft? draft;

  bool get isProcessing => status == MealTextParseStatus.processing;
  bool get canRetry =>
      status == MealTextParseStatus.failed && submittedText != null;
}

/// Owns one provider-neutral natural-language meal processing interaction.
///
/// This controller is intentionally transport-agnostic. It normalizes input,
/// suppresses duplicate in-flight submissions, maps safe repository failures to
/// presentation-ready state, and only exposes Tio-owned [MealLoggingDraft]
/// results. It never persists a MealLog or knows provider/network details.
final class MealTextParseController extends ChangeNotifier {
  MealTextParseController({required MealTextParseRepository repository})
      : _repository = repository;

  static const String unrecognizedMessage =
      "Couldn't understand that meal. Try editing the description.";
  static const String incompleteMessage =
      "Couldn't resolve enough meal details. Try adding amounts or serving sizes.";
  static const String unavailableMessage =
      "Couldn't process that meal right now. Try again.";

  final MealTextParseRepository _repository;

  MealTextParseState _state = const MealTextParseState.idle();
  MealTextParseState get state => _state;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool canSubmit(String rawText) =>
      !_state.isProcessing && rawText.trim().isNotEmpty;

  Future<MealLoggingDraft?> submit(String rawText) async {
    if (_state.isProcessing) return null;

    final text = rawText.trim();
    if (text.isEmpty) return null;

    return _process(text);
  }

  Future<MealLoggingDraft?> retry() async {
    if (_state.isProcessing || !_state.canRetry) return null;
    final text = _state.submittedText;
    if (text == null) return null;
    return _process(text);
  }

  Future<MealLoggingDraft?> _process(String text) async {
    _setState(
      MealTextParseState._(
        status: MealTextParseStatus.processing,
        submittedText: text,
      ),
    );

    try {
      final draft = await _repository.parseMealText(text);
      if (draft.captureSource != MealLogCaptureSource.text) {
        _setFailure(text, MealTextParseFailureReason.unavailable);
        return null;
      }

      _setState(
        MealTextParseState._(
          status: MealTextParseStatus.succeeded,
          submittedText: text,
          draft: draft,
        ),
      );
      return draft;
    } on MealTextParseFailure catch (error) {
      _setFailure(text, error.reason);
      return null;
    } on Object {
      _setFailure(text, MealTextParseFailureReason.unavailable);
      return null;
    }
  }

  void _setFailure(String text, MealTextParseFailureReason reason) {
    final message = switch (reason) {
      MealTextParseFailureReason.unrecognized => unrecognizedMessage,
      MealTextParseFailureReason.incomplete => incompleteMessage,
      MealTextParseFailureReason.unavailable => unavailableMessage,
    };
    _setState(
      MealTextParseState._(
        status: MealTextParseStatus.failed,
        submittedText: text,
        message: message,
      ),
    );
  }

  void _setState(MealTextParseState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }
}
