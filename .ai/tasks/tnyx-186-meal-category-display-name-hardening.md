# TNYX-186 Meal Category Display-Name Hardening

**Status:** In progress / REVIEW — Slice A published as PR #234, review correction in progress, not merged
**Canonical GitHub issue:** #233
**Linear:** TNYX-186
**Pull request:** #234 (open, Slice A only)
**Base:** `main@debda76c2a638f9475ef1aa0cf9b82ecd1c64caf`
**Branch:** `tnyx/tnyx-186-meal-category-name-policy`

## Current Position

Slice A is implemented and published for review on the branch above. Nothing is merged.

- Review raised one contract bug on the published head: `canonicalize()` matched the forbidden set against a trimmed copy, so a leading or trailing newline, tab or control was removed before it could be refused and `Lunch\n` was accepted as `Lunch`. The forbidden set is now matched against the raw input, after blankness is settled and before any trimming or collapsing, with leading/trailing regressions in the domain and codec suites.
- Review raised a second contract bug on the same head: the editor capped the raw field text at 24 while the domain caps the canonical value, so a pasted name whose length came from collapsible whitespace could be cut down and stored as a shorter name the reader never typed. The field no longer caps anything; it shows a counter read from the canonical length, and a name past the limit is refused through the existing validation path.
- Review raised a third contract bug: U+200B ZERO WIDTH SPACE passed every check, because it is not matched by `\s` and is not Unicode White_Space, so a category could be stored with a visually blank label or an invisible break inside it. U+200B is now named in the forbidden set. The set stays a list of ranges and code points rather than a class: U+200C ZWNJ is required for correct Hindi and Persian text, U+200D ZWJ is owner-locked as allowed, and U+2060 WORD JOINER is outside the locked boundary.
- Review also raised the stale published-state wording in this brief, which this section replaces.
- Slice B remains deferred at its design gate. No migration exists.
- No hosted Supabase mutation has occurred at any point in this task.

Next action: exact-head CI and review resolution, then the owner's merge decision. Publication is done; what remains is verification and review closure.

## Owner Approval and Scope Boundary

Owner authorized starting the next focused Meal Category name-policy slice after the hosted TNYX-67 retained-cap closeout.

Owner-locked V1 contract:

```text
MAX_MEAL_CATEGORY_DISPLAY_NAME_LENGTH = 24 visible grapheme clusters
```

Applies equally to canonical/default category renames, custom category creation/rename, non-UI domain/repository callers, and the later DB direct-write guard.

Canonical stored-name rules:

- trim leading/trailing whitespace;
- preserve user-facing case;
- reject newline, tab, C0/C1 controls and other line-breaking control/separator input rather than storing it;
- normalize repeated compatible internal whitespace to one ordinary space;
- blank/whitespace-only remains invalid;
- normalized active duplicate names remain invalid;
- maximum length is 24 extended grapheme clusters;
- never silently truncate a stored value.

No category identity, `defaultKey`, ordering, archive/reactivate, retained-ID, Meal Type, reminder, MealLog, or Core visual contract changes are authorized.

## Fresh Audit

### Repository

Current `MealCategory` only trims `displayName`. It does not enforce the 24-grapheme limit, collapse internal whitespace before storage, or reject controls in non-blank names.

`MealCategoriesPolicy.normalizeDisplayName()` currently collapses `\s+`, trims, and lowercases only for duplicate comparison. Stored canonicalization and duplicate comparison therefore use different normalization contracts.

`MealCategoriesController.validateDisplayName()` currently handles blank and active-duplicate checks only. `rename()` / `addCustom()` pre-trim and rely on construction for the rest.

`MealCategoriesConfigCodec.decode()` constructs `MealCategory`, so constructor-level hardening will protect persisted-state reads and direct domain callers without a second codec algorithm.

The add/rename editor already uses canonical `TioInput`, which exposes `helperText`; no Core redesign is required. `maxLength` is deliberately not used, for the reason recorded under Controller/editor below.

Nutrition does not declare `characters` directly, although `apps/features/nutrition/pubspec.lock` currently resolves `characters 1.4.1` transitively. Grapheme semantics must be an explicit Nutrition dependency if imported by the domain.

### Existing tests

`meal_categories_config_test.dart` already covers:

- outer trim on rename;
- blank/whitespace-only rejection;
- active duplicate comparison using case/whitespace normalization;
- inactive duplicate-name allowance;
- stable identity behavior.

`meal_categories_settings_test.dart` already covers:

- add/rename editor using one `_NameEditorSheet`;
- blank submit disabled;
- normalized active duplicate rejection in-place;
- stable-ID rename;
- add through the domain generator.

Add focused regressions rather than replacing these.

### Hosted Supabase read-only evidence

Project: `tio-world` / `oykupyiitspujzpwwvuj`.

Existing stored names are safe for a later tightening:

```text
stored items:                 5
max observed code-point len:  9
>24 code-point rows:          0
control-character rows:       0
surrounding-whitespace rows:  0
repeated ASCII-space rows:    0
```

Hosted `private.is_valid_meal_categories_config_v1(jsonb)` currently enforces the completed TNYX-67 identity/count/order contract but only type-checks `display_name`; it does not enforce this new policy.

PostgreSQL 17 has no built-in extended-grapheme-cluster length primitive. Do not label `char_length()` as grapheme-safe. Slice B must stop at a design gate if exact DB semantics require an unjustified extension/runtime dependency.

## Slice A — Authorized Now

Flutter/domain/UI only. No hosted Supabase mutation and no migration apply.

### Domain ownership

Prefer one small domain owner such as `MealCategoryDisplayNamePolicy` so `MealCategory`, duplicate comparison, controller/editor validation, and tests use one algorithm without introducing a circular dependency between `meal_category.dart` and `meal_categories_policy.dart`.

Expected public contract direction:

```text
MealCategoryDisplayNamePolicy.maxLength = 24
MealCategoryDisplayNamePolicy.canonicalize(raw) -> canonical stored value
MealCategoryDisplayNamePolicy.comparisonKey(raw/canonical) -> case-insensitive duplicate key
MealCategoryDisplayNamePolicy.canonicalLength(raw) -> graphemes the domain will count
```

`canonicalize` must:

1. return `blankDisplayName` for all-whitespace input;
2. reject controls/line-breaking input deterministically, including U+200B, which `trim()` and `\s` both leave alone;
3. collapse allowed repeated whitespace and trim;
4. count `.characters.length` after canonicalization;
5. reject >24 with a dedicated validation code;
6. never truncate.

Do not reject Unicode formatting code points required for legitimate emoji graphemes (for example ZWJ) merely because they are non-printing. The control rule must not break valid grapheme clusters.

Add deterministic validation codes for at least:

- too-long display name;
- invalid control/single-line characters.

Keep existing `MealCategoriesPolicy.normalizeDisplayName()` API if existing callers/tests depend on it, but derive it from the new canonical policy rather than preserving a second normalization algorithm.

### Dependency

If using `package:characters/characters.dart`, add it as a direct Nutrition dependency using the already-resolved compatible version (`^1.4.1` is the current lock resolution).

Only the Nutrition package dependency/lock may change. The pre-existing modified root `pubspec.lock` is protected local work and must remain untouched/uncommitted.

### Controller/editor

Map new typed validation failures to actionable editor copy. Blank/duplicate copy should remain unchanged unless the owner-visible behavior requires otherwise.

Add/rename must store the domain canonical value, not their own independent `trim()` result.

The existing editor must remain the existing `TioInput` surface. No new feature-specific Core component and no Core visual variant.

Show the limit while typing; do not impose it on the keystroke. `TioInput.maxLength` caps the raw field text, and the domain caps the canonical value, which are not the same number: `Pre` and `Workout` separated by twenty-five spaces is thirty-five characters in the field and eleven once stored. A raw cap would cut such a paste down and store a shorter name the reader never typed, while the domain would have accepted the whole thing.

The editor therefore carries no `maxLength`. It shows `MealCategoryDisplayNamePolicy.canonicalLength()` as a counter against the limit, which reads through the same collapse the stored value does, and a name past the limit is refused through the existing validation path, which keeps the sheet open and holds what was typed. Domain enforcement remains authoritative and must still reject >24 if a non-UI caller bypasses the editor.

Do not silently truncate at save time.

### Tests

Add focused coverage for:

- 24 ASCII graphemes accepted, 25 rejected;
- 24 multi-code-unit/ZWJ emoji graphemes accepted, 25 rejected;
- combining-mark grapheme boundary accepted/rejected correctly;
- `  Pre   Workout  ` stores canonical `Pre Workout`;
- newline in a non-blank name rejected;
- tab/control input rejected;
- blank behavior preserved;
- active duplicate behavior preserved after canonical storage normalization;
- canonical/default rename and custom add use the same policy;
- codec/direct `MealCategory` construction cannot bypass limit/control rules;
- editor carries no raw cap, shows a canonical-length counter, and still preserves current in-place deterministic error behavior;
- a raw value long only because of collapsible whitespace reaches the domain whole rather than being cut into a different name;
- U+200B rejected leading, trailing, embedded and alone, through construction and through the codec;
- U+200C ZWNJ and U+200D ZWJ remain accepted.

Run at least:

```text
cd apps/features/nutrition
flutter analyze
flutter test test/domain/meal_categories_config_test.dart
flutter test test/meal_diary/meal_categories_settings_test.dart
```

Run any repository/data tests affected by the dependency or codec changes plus `git diff --check`.

## Slice B — Deferred Design Gate

Do not implement/apply hosted DB hardening in Slice A.

After Slice A review, audit the smallest exact DB mechanism for direct-write enforcement. Preserve the existing validator function name, CHECK constraint, SECURITY INVOKER posture, grants, retained-ID trigger, retained cap, min-active and canonical-order rules.

A future migration must preflight stored rows and reject incompatible state; no repair/truncation/grandfathering.

If Postgres cannot enforce exact extended grapheme clusters without disproportionate extension/runtime complexity, report that explicitly. Do not silently replace the owner contract with a code-point limit.

Hosted apply always requires a separate explicit owner authorization.

## Protected State

Do not reset, stash, overwrite, clean, or commit:

- root `pubspec.lock` local modification;
- `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` local untracked file.

Before commit/push, scope-audit every changed file.

## Completion Gate for Slice A

Slice A is ready for review only when:

- exact domain/UI tests are green;
- Nutrition analyze is green;
- no Core redesign or unrelated Nutrition work entered the diff;
- no Supabase migration/schema mutation occurred;
- protected local state remains untouched;
- branch diff is clean under `git diff --check`;
- PR references GitHub #233 and Linear TNYX-186;
- task brief remains conservative until exact-head CI and review are complete.
