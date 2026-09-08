import 'package:flutter/foundation.dart';

import '../../../domain/models/meal_categories_config.dart';
import '../../../domain/models/meal_categories_policy.dart';
import '../../../domain/models/meal_categories_validation.dart';
import '../../../domain/models/meal_category.dart';
import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/usecases/meal_category_id_generator.dart';

/// What the Meal Categories screen is currently doing.
enum MealCategoriesStatus { loading, ready, loadFailed }

/// Immutable snapshot the Meal Categories screen renders.
///
/// [confirmed] is what the repository actually holds. Nothing here mutates it
/// except a write that succeeded, so a failed save leaves the screen showing
/// the user's attempt without ever implying it was stored.
@immutable
final class MealCategoriesState {
  const MealCategoriesState({
    required this.status,
    required this.confirmed,
    required this.saving,
    this.loadError,
    this.actionError,
    this.pendingRetry,
  });

  const MealCategoriesState.loading()
      : status = MealCategoriesStatus.loading,
        confirmed = null,
        saving = false,
        loadError = null,
        actionError = null,
        pendingRetry = null;

  final MealCategoriesStatus status;

  /// The last configuration the repository confirmed. Null until the first
  /// successful read.
  final MealCategoriesConfig? confirmed;

  /// Whether a write is in flight. The screen disables mutating affordances
  /// while true so two taps cannot race one another into the repository.
  final bool saving;

  /// Why the initial read failed, if it did.
  final String? loadError;

  /// Why the most recent edit failed, if it did. Cleared when the next one is
  /// attempted, so stale copy never sits under a fresh action.
  final String? actionError;

  /// The configuration a failed write was trying to store.
  ///
  /// Kept so retrying costs one tap rather than repeating the whole
  /// interaction — the name sheet has already closed by the time a write
  /// fails, so without this the typed name is simply gone.
  final MealCategoriesConfig? pendingRetry;

  bool get canRetryAction => pendingRetry != null;

  List<MealCategory> get activeItems => confirmed?.activeItems ?? const [];

  List<MealCategory> get archivedItems => List<MealCategory>.unmodifiable(
        confirmed?.orderedItems.where((item) => !item.active) ?? const [],
      );

  int get activeCount => activeItems.length;

  /// Whether anything is archived. The archived destination exists exactly
  /// while this is true, derived from the configuration rather than tracked
  /// alongside it.
  bool get hasArchivedCategories => archivedItems.isNotEmpty;

  /// Whether the eight-active cap is reached. Add and reactivate both read
  /// this rather than counting for themselves.
  bool get isAtActiveCap =>
      activeCount >= MealCategoriesPolicy.maxActiveMealCategories;

  /// Whether archiving is possible at all. At one active category the answer
  /// is no: every meal has to be filed under something.
  bool get canArchive =>
      activeCount > MealCategoriesPolicy.minActiveMealCategories;

  MealCategoriesState copyWith({
    MealCategoriesStatus? status,
    MealCategoriesConfig? confirmed,
    bool? saving,
    String? loadError,
    String? actionError,
    MealCategoriesConfig? pendingRetry,
    bool clearLoadError = false,
    bool clearActionError = false,
    bool clearPendingRetry = false,
  }) =>
      MealCategoriesState(
        status: status ?? this.status,
        confirmed: confirmed ?? this.confirmed,
        saving: saving ?? this.saving,
        loadError: clearLoadError ? null : (loadError ?? this.loadError),
        actionError:
            clearActionError ? null : (actionError ?? this.actionError),
        pendingRetry:
            clearPendingRetry ? null : (pendingRetry ?? this.pendingRetry),
      );
}

/// Feature-owned state for the Meal Categories management screen.
///
/// Every product rule this screen appears to enforce — stable identities,
/// the eight-active cap, blank and duplicate rejection, retained identities
/// surviving an upsert — is owned by the Nutrition domain. This controller
/// adds none of them. It sequences repository calls, keeps the confirmed
/// configuration honest, and turns typed domain failures into copy.
class MealCategoriesController extends ChangeNotifier {
  MealCategoriesController({
    required MealCategoriesRepository repository,
    MealCategoryIdGenerator? idGenerator,
  })  : _repository = repository,
        _idGenerator = idGenerator ?? UuidMealCategoryIdGenerator();

  /// Shown when the cap blocks an action. The wording is the product's, not a
  /// paraphrase, so it is stated once here rather than at each call site.
  static const String activeCapReason = 'Maximum 8 active meal categories';

  /// Shown when archiving would leave nothing active.
  static const String lastActiveReason =
      'At least one meal category is required.';

  /// Shown if a default row is somehow asked to move.
  static const String defaultsFixedReason =
      'Breakfast, Lunch, Dinner and Snacks keep a fixed order.';

  final MealCategoriesRepository _repository;
  final MealCategoryIdGenerator _idGenerator;

  MealCategoriesState _state = const MealCategoriesState.loading();
  MealCategoriesState get state => _state;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _emit(MealCategoriesState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  /// Reads the stored configuration, resolving canonical defaults when none is
  /// stored. Deliberately a read: opening this screen must never write, so an
  /// untouched user keeps inheriting defaults rather than having four rows
  /// materialised into their row the first time they look.
  Future<void> load() async {
    _emit(
      _state.copyWith(
        status: MealCategoriesStatus.loading,
        saving: false,
        clearLoadError: true,
        clearActionError: true,
      ),
    );
    try {
      final config = await _repository.read();
      _emit(
        MealCategoriesState(
          status: MealCategoriesStatus.ready,
          confirmed: config,
          saving: false,
        ),
      );
    } on MealCategoriesValidationException catch (error) {
      _emit(
        MealCategoriesState(
          status: MealCategoriesStatus.loadFailed,
          confirmed: null,
          saving: false,
          loadError: _loadMessageFor(error.code),
        ),
      );
    } catch (_) {
      _emit(
        const MealCategoriesState(
          status: MealCategoriesStatus.loadFailed,
          confirmed: null,
          saving: false,
          loadError: 'Could not load meal categories. Check your connection '
              'and try again.',
        ),
      );
    }
  }

  Future<void> retryLoad() => load();

  /// Renames one category. Only `displayName` moves; identity, order and
  /// active state are carried through untouched.
  Future<bool> rename({required String id, required String displayName}) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      _emit(_state.copyWith(actionError: 'Enter a category name.'));
      return Future.value(false);
    }
    return _mutate((items) {
      return [
        for (final item in items)
          if (item.id == id) item.renamed(trimmed) else item,
      ];
    });
  }

  /// Appends a custom category after the current active items.
  ///
  /// The identity comes from the domain generator, which is given every
  /// retained id — archived ones included — so a new category can never reuse
  /// an identity that history may still point at.
  Future<bool> addCustom(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      _emit(_state.copyWith(actionError: 'Enter a category name.'));
      return Future.value(false);
    }
    if (_state.isAtActiveCap) {
      _emit(_state.copyWith(actionError: activeCapReason));
      return Future.value(false);
    }
    return _mutate((items) {
      final id = _idGenerator.generate(items.map((item) => item.id));
      return [
        ...items,
        MealCategory(
          id: id,
          defaultKey: null,
          displayName: trimmed,
          active: true,
          order: _nextOrder(items),
        ),
      ];
    });
  }

  /// Moves the active item at [oldIndex] to [newIndex].
  ///
  /// Both are positions within the *active* list, which is what the screen
  /// shows. The move is applied to the full ordered list — archived items
  /// included — because that list is what carries the canonical anchors, and
  /// renumbering only it keeps Breakfast before Lunch before Dinner before
  /// Snacks whatever the reader drags.
  ///
  /// Only custom categories move. A default is not draggable, and a request to
  /// move one is refused rather than quietly ignored.
  Future<bool> reorderActive({required int oldIndex, required int newIndex}) {
    final active = _state.activeItems;
    if (oldIndex < 0 || oldIndex >= active.length) return Future.value(false);
    if (newIndex < 0 || newIndex >= active.length || newIndex == oldIndex) {
      return Future.value(false);
    }

    final moved = active[oldIndex];
    if (moved.defaultKey != null) {
      _emit(_state.copyWith(actionError: defaultsFixedReason));
      return Future.value(false);
    }

    final anchor = active[newIndex];

    return _mutate((items) {
      final ordered = [...items]..sort((a, b) => a.order.compareTo(b.order));
      ordered.removeWhere((item) => item.id == moved.id);

      // Land beside the active row the drag pointed at, on the side the drag
      // came from, so the visible result matches the gesture.
      final anchorIndex = ordered.indexWhere((item) => item.id == anchor.id);
      final insertAt = newIndex > oldIndex ? anchorIndex + 1 : anchorIndex;
      ordered.insert(insertAt.clamp(0, ordered.length), moved);

      var order = 0;
      return [for (final item in ordered) item.reordered(order++)];
    });
  }

  /// Archives a category: it stays in the configuration and in its position,
  /// and only stops being active. Nothing is deleted and nothing moves.
  ///
  /// Holding its slot is what lets a later restore land back between the right
  /// neighbours rather than at the end of the list.
  Future<bool> archive(String id) {
    if (!_state.canArchive) {
      _emit(_state.copyWith(actionError: lastActiveReason));
      return Future.value(false);
    }
    return _mutate((items) => [
          for (final item in items)
            if (item.id == id) item.withActive(false) else item,
        ]);
  }

  /// Restores an archived category under its original identity and its
  /// original position.
  Future<bool> reactivate(String id) {
    if (_state.isAtActiveCap) {
      _emit(_state.copyWith(actionError: activeCapReason));
      return Future.value(false);
    }
    return _mutate((items) => [
          for (final item in items)
            if (item.id == id) item.withActive(true) else item,
        ]);
  }

  /// Runs one edit against a copy of the confirmed configuration and writes it.
  ///
  /// The order matters: build, let the domain validate, write, and only then
  /// adopt the result as confirmed. A rejected or failed write therefore
  /// leaves the previous confirmed configuration exactly as it was.
  Future<bool> _mutate(
    List<MealCategory> Function(List<MealCategory> items) transform,
  ) async {
    final confirmed = _state.confirmed;
    if (confirmed == null || _state.saving) return false;

    _emit(
      _state.copyWith(
        saving: true,
        clearActionError: true,
        clearPendingRetry: true,
      ),
    );

    MealCategoriesConfig next;
    try {
      next = MealCategoriesConfig(
        schemaVersion: confirmed.schemaVersion,
        items: transform(confirmed.orderedItems),
      );
    } on MealCategoriesValidationException catch (error) {
      _emit(
        _state.copyWith(saving: false, actionError: _messageFor(error.code)),
      );
      return false;
    }

    // An edit that changes nothing must not write. Persisting here would
    // materialise a customized configuration out of an unstored one, and that
    // user would silently stop inheriting future canonical default updates.
    if (next == confirmed) {
      _emit(_state.copyWith(saving: false, clearActionError: true));
      return true;
    }

    return _write(next);
  }

  /// Retries the write a previous action failed on, without asking the user to
  /// perform that action again.
  Future<bool> retryPendingAction() async {
    final pending = _state.pendingRetry;
    if (pending == null || _state.saving) return false;
    _emit(_state.copyWith(saving: true, clearActionError: true));
    return _write(pending);
  }

  /// Discards a failed attempt so the screen stops offering to retry it.
  void discardPendingAction() {
    if (_state.pendingRetry == null && _state.actionError == null) return;
    _emit(_state.copyWith(clearActionError: true, clearPendingRetry: true));
  }

  Future<bool> _write(MealCategoriesConfig next) async {
    try {
      await _repository.upsert(next);
    } on MealCategoriesValidationException catch (error) {
      // A rejected configuration will be rejected again, so it is not offered
      // as a retry — only transport-shaped failures are.
      _emit(
        _state.copyWith(
          saving: false,
          actionError: _messageFor(error.code),
          clearPendingRetry: true,
        ),
      );
      return false;
    } catch (_) {
      _emit(
        _state.copyWith(
          saving: false,
          actionError: 'Could not save your change.',
          pendingRetry: next,
        ),
      );
      return false;
    }

    _emit(
      _state.copyWith(
        confirmed: next,
        saving: false,
        clearActionError: true,
        clearPendingRetry: true,
      ),
    );
    return true;
  }

  /// Dismisses the current action error without retrying it.
  void clearActionError() {
    if (_state.actionError == null) return;
    _emit(_state.copyWith(clearActionError: true));
  }

  static int _nextOrder(List<MealCategory> items) {
    var highest = -1;
    for (final item in items) {
      if (item.order > highest) highest = item.order;
    }
    return highest + 1;
  }

  /// Read-time failures need read-time copy.
  ///
  /// The mutation messages are written for someone holding an open editor, and
  /// the load-failure screen has none — telling a reader to "enter a category
  /// name" there is advice they cannot act on.
  static String _loadMessageFor(MealCategoriesValidationCode code) =>
      switch (code) {
        MealCategoriesValidationCode.malformedConfig ||
        MealCategoriesValidationCode.unsupportedSchemaVersion =>
          'Your saved meal categories are from a newer version of the app. '
              'Update Tio to manage them.',
        _ => 'Your saved meal categories could not be read. Try again, and '
            'contact support if this keeps happening.',
      };

  /// Maps a typed domain failure to copy a reader can act on. Database detail
  /// and internal identifiers never reach the screen.
  static String _messageFor(MealCategoriesValidationCode code) =>
      switch (code) {
        MealCategoriesValidationCode.blankDisplayName =>
          'Enter a category name.',
        MealCategoriesValidationCode.duplicateActiveDisplayName =>
          'That name is already used by another active category.',
        MealCategoriesValidationCode.tooManyActiveCategories => activeCapReason,
        MealCategoriesValidationCode.tooFewActiveCategories => lastActiveReason,
        MealCategoriesValidationCode.canonicalDefaultOrderViolated =>
          defaultsFixedReason,
        MealCategoriesValidationCode.retainedIdentityRemoved =>
          'That category is kept for your meal history and cannot be removed.',
        MealCategoriesValidationCode.malformedConfig ||
        MealCategoriesValidationCode.unsupportedSchemaVersion =>
          'Your meal categories could not be read. Update the app and try '
              'again.',
        _ => 'Could not save your change. Try again.',
      };
}
