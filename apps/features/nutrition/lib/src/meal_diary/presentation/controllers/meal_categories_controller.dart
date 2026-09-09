import 'package:flutter/foundation.dart';

import '../../../domain/models/meal_categories_config.dart';
import '../../../domain/models/meal_categories_policy.dart';
import '../../../domain/models/meal_categories_validation.dart';
import '../../../domain/models/meal_category.dart';
import '../../../domain/models/meal_category_display_name_policy.dart';
import '../../../domain/repositories/meal_categories_repository.dart';
import '../../../domain/usecases/meal_category_id_generator.dart';

/// What the Meal Categories screen is currently doing.
enum MealCategoriesStatus { loading, ready, loadFailed }

/// Immutable snapshot the Meal Categories screen renders.
///
/// Two layers. [confirmed] is what the repository actually holds, and only a
/// successful write ever replaces it. [optimistic] is what the reader just
/// did, shown while the write is in flight and discarded if it fails — so the
/// screen keeps up with the gesture without ever implying something was stored
/// that was not.
@immutable
final class MealCategoriesState {
  const MealCategoriesState({
    required this.status,
    required this.confirmed,
    required this.saving,
    this.optimistic,
    this.loadError,
    this.actionError,
    this.pendingRetry,
  });

  const MealCategoriesState.loading()
      : status = MealCategoriesStatus.loading,
        confirmed = null,
        saving = false,
        optimistic = null,
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

  /// The edit the reader just made, held only while its write is in flight.
  ///
  /// A drag that snapped back for the length of a network round trip and then
  /// moved again read as the list ignoring the gesture. This is what the
  /// screen renders in the meantime; it is never treated as stored, and a
  /// failed write drops it so the list returns to [confirmed].
  final MealCategoriesConfig? optimistic;

  bool get canRetryAction => pendingRetry != null;

  /// What the screen shows: the in-flight edit if there is one, otherwise what
  /// the repository confirmed. Every derived getter reads through this, so the
  /// cap, the archive guard and the archived entry all agree with what is on
  /// screen rather than with a state the reader has already moved past.
  MealCategoriesConfig? get visible => optimistic ?? confirmed;

  List<MealCategory> get activeItems => visible?.activeItems ?? const [];

  List<MealCategory> get archivedItems => List<MealCategory>.unmodifiable(
        visible?.orderedItems.where((item) => !item.active) ?? const [],
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

  /// Everything the configuration holds, archived included.
  int get retainedCount => visible?.orderedItems.length ?? 0;

  /// Whether the retained ceiling is reached. Only adding a category can push
  /// this up: archiving keeps its identity and restoring reuses one.
  bool get isAtRetainedCap =>
      retainedCount >= MealCategoriesPolicy.maxRetainedMealCategories;

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
    MealCategoriesConfig? optimistic,
    bool clearLoadError = false,
    bool clearActionError = false,
    bool clearPendingRetry = false,
    bool clearOptimistic = false,
  }) =>
      MealCategoriesState(
        status: status ?? this.status,
        confirmed: confirmed ?? this.confirmed,
        saving: saving ?? this.saving,
        optimistic:
            clearOptimistic ? null : (optimistic ?? this.optimistic),
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

  /// The deterministic name rejections, worded for the editor rather than for
  /// a snackbar, because that is where they are now surfaced.
  static const String blankNameReason = 'Enter a category name.';
  static const String duplicateNameReason =
      'That name is already used by another active category.';

  /// Why a name is refused for its length.
  ///
  /// It states the limit rather than saying the name is too long, because the
  /// reader is holding a name they now have to shorten and needs the target.
  /// Nothing is trimmed for them: cutting a name to fit would store one they
  /// never chose.
  static const String tooLongNameReason =
      'Use ${MealCategoryDisplayNamePolicy.maxLength} characters or fewer.';

  /// Why a name is refused for what it contains.
  ///
  /// Names the two things a reader can actually have done — pasted a line
  /// break, or pasted text carrying invisible control characters — rather
  /// than naming code points.
  static const String invalidNameCharactersReason =
      'Use a single line without line breaks or special characters.';

  /// Why adding is refused once nothing more can be kept.
  ///
  /// It names the way out, because there is no obvious one: archiving never
  /// deletes, so the reader cannot make room by tidying up. Restoring an
  /// archived category and renaming it reuses an identity instead of minting
  /// another, which is exactly what the ceiling is protecting.
  static const String retainedCapReason =
      'Maximum 32 meal categories, archived included. Restore one from '
      'Archived and rename it instead.';

  /// Shown when the store refused the write because the configuration moved
  /// on somewhere else.
  ///
  /// It says what happened and what the reader is now looking at, because the
  /// list has just changed under them. No Retry is offered: the change was
  /// built on a version that no longer exists.
  static const String conflictReason =
      'Your meal categories were changed on another device. The latest '
      'version is shown — make your change again.';

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

  /// Reloads after the store refused a write as a conflict.
  ///
  /// Deliberately not [load]: that flips the screen to a spinner and clears
  /// the reason, and the reader would be left looking at a list that quietly
  /// changed under them with nothing said. This swaps in what is actually
  /// stored and keeps the explanation on screen.
  ///
  /// No rebase is attempted. Merging the refused edit into the newly read
  /// configuration would be guessing at intent, and guessing wrong here means
  /// silently undoing something done on another device.
  Future<void> _reloadAfterConflict() async {
    try {
      final config = await _repository.read();
      _emit(
        MealCategoriesState(
          status: MealCategoriesStatus.ready,
          confirmed: config,
          saving: false,
          actionError: conflictReason,
        ),
      );
    } catch (_) {
      // The reload failed too. Keep the last known good configuration rather
      // than blanking the screen — the edit did not land either way, and the
      // reader still needs to be told why.
      _emit(
        _state.copyWith(
          saving: false,
          actionError: conflictReason,
          clearOptimistic: true,
          clearPendingRetry: true,
        ),
      );
    }
  }

  /// Renames one category. Only `displayName` moves; identity, order and
  /// active state are carried through untouched.
  Future<bool> rename({required String id, required String displayName}) {
    final String canonical;
    try {
      canonical = MealCategoryDisplayNamePolicy.canonicalize(displayName);
    } on MealCategoriesValidationException catch (error) {
      _emit(_state.copyWith(actionError: _messageFor(error.code)));
      return Future.value(false);
    }
    return _mutate((items) {
      return [
        for (final item in items)
          if (item.id == id) item.renamed(canonical) else item,
      ];
    });
  }

  /// Appends a custom category after the current active items.
  ///
  /// The identity comes from the domain generator, which is given every
  /// retained id — archived ones included — so a new category can never reuse
  /// an identity that history may still point at.
  /// Why this name cannot be used, or null when it can.
  ///
  /// Run while the editor is still open. A deterministic local rejection is
  /// not a failed save: closing the sheet and reporting it afterwards throws
  /// away what the reader typed for a mistake they could have corrected in
  /// place, and offers no way back to it.
  ///
  /// It applies the domain's own rules — the same normalization, and the same
  /// scope, which is active categories only, so a name matching an archived
  /// one is free to use. Nothing here is a second opinion: the domain still
  /// decides at the write, and this only prevents the pointless round trip.
  ///
  /// [excludingId] is the category being renamed, so its own current name
  /// never reads as a clash with itself.
  String? validateDisplayName({required String value, String? excludingId}) {
    final String canonical;
    try {
      canonical = MealCategoryDisplayNamePolicy.canonicalize(value);
    } on MealCategoriesValidationException catch (error) {
      return _messageFor(error.code);
    }

    final normalized = MealCategoriesPolicy.normalizeDisplayName(canonical);
    final clashes = _state.activeItems.any(
      (item) =>
          item.id != excludingId &&
          MealCategoriesPolicy.normalizeDisplayName(item.displayName) ==
              normalized,
    );
    return clashes ? duplicateNameReason : null;
  }

  Future<bool> addCustom(String displayName) {
    final String canonical;
    try {
      canonical = MealCategoryDisplayNamePolicy.canonicalize(displayName);
    } on MealCategoriesValidationException catch (error) {
      _emit(_state.copyWith(actionError: _messageFor(error.code)));
      return Future.value(false);
    }
    if (_state.isAtActiveCap) {
      _emit(_state.copyWith(actionError: activeCapReason));
      return Future.value(false);
    }
    // Adding is the only operation that mints a new identity, so it is the
    // only one the retained ceiling can refuse.
    if (_state.isAtRetainedCap) {
      _emit(_state.copyWith(actionError: retainedCapReason));
      return Future.value(false);
    }
    return _mutate((items) {
      final id = _idGenerator.generate(items.map((item) => item.id));
      return [
        ...items,
        MealCategory(
          id: id,
          defaultKey: null,
          displayName: canonical,
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
    // Shown from here, before the round trip. The configuration has already
    // been through the domain by this point, so nothing invalid is ever put on
    // screen — only something not yet stored.
    _emit(_state.copyWith(optimistic: next));

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
          clearOptimistic: true,
        ),
      );
      return false;
    } on MealCategoriesWriteConflict catch (_) {
      // Never a retry. The payload is a complete configuration built on a
      // snapshot the store has already moved past, so replaying it would
      // either be refused forever or erase whatever moved it. Reload instead,
      // and let the reader see what is actually stored before deciding.
      await _reloadAfterConflict();
      return false;
    } catch (_) {
      // The edit is dropped from the screen as well as from the store: leaving
      // it visible would claim a save that did not happen. The attempt is kept
      // in `pendingRetry`, so Retry still costs one tap.
      _emit(
        _state.copyWith(
          saving: false,
          actionError: 'Could not save your change.',
          pendingRetry: next,
          clearOptimistic: true,
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
        clearOptimistic: true,
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
        MealCategoriesValidationCode.blankDisplayName => blankNameReason,
        MealCategoriesValidationCode.displayNameTooLong => tooLongNameReason,
        MealCategoriesValidationCode.invalidDisplayNameCharacters =>
          invalidNameCharactersReason,
        MealCategoriesValidationCode.duplicateActiveDisplayName =>
          duplicateNameReason,
        MealCategoriesValidationCode.tooManyActiveCategories => activeCapReason,
        MealCategoriesValidationCode.tooManyRetainedCategories =>
          retainedCapReason,
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
