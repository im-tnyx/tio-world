# TNYX-186 Meal Category Display-Name Hardening

**Status:** In progress / REVIEW - Slice A merged; Slice B published as PR #235; Slice C published for review
**Canonical GitHub issue:** #233 (open)
**Linear:** TNYX-186 (In Progress)
**Slice A pull request:** #234 (merged into `main@633b210f32cfcf86855aa6524c0ec2c1f26c3de0`)
**Slice B pull request:** #235 (open, database guard, not merged, not applied hosted)
**Slice C branch:** `tnyx/tnyx-186-reserved-canonical-meal-category-names`, based on `main@633b210f32cfcf86855aa6524c0ec2c1f26c3de0`

## Current Position

Slice A is merged: the Dart domain is the single owner of what a category name
may be, after three review corrections.

Slice B is published as PR #235 on its own branch and is not merged. It guards
the database-side shape and content subset, with the 24-grapheme limit and
case-only duplicate names left application-authoritative and named as gaps.

Slice C is this branch: the four original canonical names are permanently
reserved by identity. It is app and domain only, it does not touch PR #235, and
PR #235 needs reconciliation only after Slice C merges.

No hosted Supabase mutation has occurred at any point in this task.

Next action: review of Slice C, then the owner's merge decision, then a
separate reconciliation pass on PR #235.

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

## Slice C - Reserved Canonical Names, App/Domain

Owner decision: the four original canonical names are permanently reserved,
and the reservation belongs to the **identity**, never to what that category is
currently called.

```text
Breakfast -> meal_slot_1 only
Lunch     -> meal_slot_2 only
Dinner    -> meal_slot_3 only
Snacks    -> meal_slot_4 only
```

Renaming a canonical category changes one display name and releases nothing.
After `meal_slot_2: Lunch -> Mid Meal`, the word Lunch is still owned by
`meal_slot_2`, so only that identity may take it back and nothing else may take
it in the meantime.

### What is and is not reserved

| Action | Result |
|---|---|
| `meal_slot_2` takes `Lunch` | valid, before or after any rename |
| `meal_slot_2` takes `Mid Meal` | valid, subject to the ordinary rules |
| `meal_slot_2` goes `Lunch -> Mid Meal -> Lunch` | valid |
| `meal_slot_1` or `meal_slot_3` takes `Lunch` | refused |
| any custom takes `Lunch`, active or archived | refused |
| a custom takes `Mid Meal` once Lunch has moved off it | valid |

The reservation list does not grow. A name a canonical category was once
renamed to does not become a permanent token; it goes back to being governed by
the ordinary active-duplicate rule.

Archived categories are checked too, deliberately. An archived custom called
`Lunch` is invisible to the duplicate rule and would reactivate straight into a
state the domain refuses.

### Ownership

One owner, derived from `canonicalMealCategoryDefaultDefinitions`, so there is
no second hardcoded list of the four words anywhere:

```text
MealCategoriesPolicy.reservedOwnerIdFor(name) -> canonical id, or null
```

Matched through `normalizeDisplayName()`, which is the merged
`MealCategoryDisplayNamePolicy.comparisonKey()`, so `lunch`, `LUNCH`, `LuNcH`
and `  Lunch  ` are all the same word. The reserved words themselves are ASCII;
this is not a general Unicode reserved-word rule.

Enforced in `MealCategoriesPolicy.validate()`, which is where both identity and
name are available. `MealCategory`'s constructor cannot host it without a
circular import, and it does not need to: the codec and every repository path
go through `MealCategoriesConfig.validate()`.

Checked before the duplicate rule, because it is the more specific answer and
because it is the only one that also covers archived items. New deterministic
code: `reservedCanonicalDisplayName`.

The controller calls the same policy for the in-place editor error, with the
edited identity passed as `excludingId`, so the Lunch category can always take
Lunch back. Copy: `That name is reserved for a default meal category.` No
identity or `defaultKey` reaches the screen.

### Interaction with the duplicate rule

They are different rules and are kept apart. Four existing widget and
controller cases exercised the duplicate rule using canonical names as the
clash fixture; those now hit the reserved rule first, so they were retargeted
onto a custom name. The duplicate rule keeps its coverage, and the reserved
rule has its own.

### Reconciliation owed to Slice B

PR #235 does **not** enforce reserved-name ownership in the database. After
Slice C merges, PR #235 needs a separate pass: rebase onto the new `main`, add
the DB-side reservation rule, preflight hosted rows for reserved-name
violations, extend the SQL matrix, replay locally, and get a fresh review before
any hosted apply. Nothing about that was started here, and PR #235 was not
touched.

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
