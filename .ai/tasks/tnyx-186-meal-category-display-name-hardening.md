# TNYX-186 Meal Category Display-Name Hardening

**Status:** REVIEW - Slices A and C merged; Slice B PR #235 reconciled and locally validated on the merged Slice C base
**Canonical GitHub issue:** #233 (open: Slice B is not merged or applied)
**Linear:** TNYX-186 (In Review; verified 2026-09-09)
**Slice A pull request:** #234 (merged into `main@633b210f32cfcf86855aa6524c0ec2c1f26c3de0`)
**Slice B pull request:** #235 (open, database guard, not merged, not applied hosted)
**Slice C pull request:** #236 (merged into `main@1c92a1261c52e22824907bcc307a350d0c03f7e5`)
**Slice B branch:** `tnyx/tnyx-186-meal-category-name-db-guard`, rebasing onto `main@1c92a1261c52e22824907bcc307a350d0c03f7e5`

## Current Position

Slice A is merged. The Dart domain owns the canonical display-name contract,
including the exact 24 extended-grapheme-cluster limit and the ordinary
case-normalized active-duplicate rule.

Slice C is merged in PR #236. The four original canonical names are permanently
reserved by identity: `Breakfast -> meal_slot_1`, `Lunch -> meal_slot_2`,
`Dinner -> meal_slot_3`, and `Snacks -> meal_slot_4`. Renaming an owner does not
release its token, and a temporary replacement label does not become reserved.

Slice B is published as PR #235 and is not merged. Its existing pending
migration version remains `20260909131518`; it enforces the exact database-side
shape/content subset while the 24-EGC and ordinary Unicode case-only duplicate
gaps remain application-authoritative. This reconciliation adds the exact
ASCII reserved-token ownership rule to that same pending migration.

Slice B's earlier review correction added exact stored-name uniqueness for
active categories and aligned its migration preflight, SQL matrix, and task/PR
wording. The local SQL matrices were run successfully before this rebase; fresh
validation is required for the reconciled head.

No hosted Supabase mutation has occurred at any point in this task. Hosted
inspection and preflight remain read-only; applying the migration requires a
separate explicit owner authorization.

Next action: commit and update the same PR #235 with lease, verify exact-head CI
and review state, and stop for final review without merging or applying hosted.

## Active Handoff

Implementation ownership transfer: previous PR #235 implementation session ->
current Codex implementation session.

Takeover state verified before source edits: PR #235 remote head was
`aeaf41e4f4c2264e4496f950d92311fb05d164c8`, its branch was two commits ahead
and one behind `main`, PR #236 was merged, the protected local files were still
uncommitted, and no concurrent Implementation owner was recorded. Recovery ref
`recovery/tnyx-186-db-guard-pre-slice-c` preserves the exact pre-rebase head.

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

## Slice B - Implemented Locally and Published, Not Applied Hosted

Verdict: **IMPLEMENTED LOCALLY / REVIEW**, with the exact database enforcement
boundary stated rather than hidden and no hosted apply.

### Hosted audit, read-only

Project `tio-world` / `oykupyiitspujzpwwvuj`, PostgreSQL 17.6.1.155. Every
statement below was a SELECT. No schema, data, config, function, grant or
migration-ledger change was made.

- Migration ledger ends at `20260908120000 cap_retained_meal_categories`, identical to the repository. No Slice A database work exists, which is correct: Slice A was app-only.
- `private.is_valid_meal_categories_config_v1(jsonb)` is immutable, strict, `security invoker`, `search_path=''`, executable by `authenticated` and `service_role` only. It mentions `display_name` for its type check alone: no `char_length` and no U+200B rule.
- CHECK constraint `user_nutrition_profiles_meal_categories_config_valid` still calls that function by name.
- Trigger `trg_user_nutrition_profiles_protect_meal_category_retained_ids` is present and enabled.
- All TNYX-67 rules are intact.

### Data preflight

Counts only; no name or user identifier was read into the report.

```text
non-null configs                         1
display names total                      5
active / archived                        5 / 0
forbidden-character violations           0
outer-whitespace violations              0
repeated-whitespace violations           0
non-canonical whitespace violations      0
blank or invisible names                 0
rows failing the current validator       0
max code-point length                    9   (diagnostic only, NOT graphemes)
names over 24 code points                0   (diagnostic only, NOT graphemes)
canonical owner using own reserved token 4
custom rows using a reserved token        0
wrong canonical reserved-token owner     0
archived reserved-name violations         0
total reserved-name violations            0
```

### Exact grapheme enforcement: not available

Option A was audited and rejected on evidence, not assumption.

- `char_length` counts code points. Measured on this database: one family emoji is 7, a regional-indicator flag is 2, `e` plus a combining acute is 2. A 24-grapheme name of family emoji is 168 code points.
- A `char_length(display_name) <= 24` guard would therefore refuse names the merged app accepts. That is worse than no guard, and it is exactly the false guard the owner contract forbids.
- Installed procedural languages are `plpgsql` and `sql` only. No PL/Perl, whose `\X` is the usual grapheme escape, and no PL/Python.
- Installed extensions are `pgcrypto`, `pg_stat_statements`, `supabase_vault`, `uuid-ossp` and `plpgsql`. None exposes grapheme segmentation, and nothing was installed.
- PostgreSQL's own regex has no grapheme-cluster construct, and ICU collations do not expose a break iterator to SQL.

The exact 24-EGC limit therefore stays owned by
`MealCategoryDisplayNamePolicy`. A direct API write can still store an
over-long name. That hole is named in the migration header, the column comment
and the test file rather than papered over.

### PostgreSQL and Dart disagree on whitespace

Measured per code point, which is why the drafted SQL names its character sets
instead of writing `\s`:

- U+0085 NEL matches PostgreSQL's `\s` and not Dart's.
- U+FEFF matches Dart's `\s` and not PostgreSQL's.
- `btrim` with no second argument removes only ASCII space, unlike `String.trim()`.
- U+200B matches neither, which is why both sides name it explicitly.

### The boundary chosen: Option B

The database enforces what it can decide exactly. The application keeps the
rest.

Forbidden: C0 controls, DEL, C1 controls, U+2028, U+2029, U+200B.
Allowed and pinned by tests: U+200C ZWNJ, U+200D ZWJ, U+2060 WORD JOINER.
Canonical shape: non-blank, no outer collapsible whitespace, no repeated
collapsible whitespace, every space an ordinary U+0020.
Active display names must be unique, compared exactly as stored; archived
ordinary duplicates stay allowed, matching the Dart scope.

The four original ASCII tokens are enforced exactly and permanently by
identity: `Breakfast -> meal_slot_1`, `Lunch -> meal_slot_2`,
`Dinner -> meal_slot_3`, and `Snacks -> meal_slot_4`. Matching uses only
`pg_catalog.translate(value, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
'abcdefghijklmnopqrstuvwxyz')`; it does not use `lower()`, `citext`, ICU
equality or generic Unicode case folding. The rule applies to active and
archived items. An owner rename releases nothing, and the replacement label
does not become reserved.

Expressed as a validator, not a repair layer: a write is refused when
`display_name` is not already equal to its canonical form. Nothing trims,
collapses, truncates, renames or rewrites what the caller sent.

### Two gaps that stay with the application

**The 24-grapheme limit.** PostgreSQL 17 has no grapheme primitive.
`char_length` counts code points, and a 24-grapheme family-emoji name is 168 of
them, so a code-point cap would refuse names the app accepts. Only `plpgsql`
and `sql` are installed, and no installed extension exposes grapheme
segmentation.

**Case-only duplicate active names.** The Dart key is lowercased; PostgreSQL's
`lower()` is not Dart's `toLowerCase()` on this database. Audited on ICU
en_US.UTF-8 over sixteen vectors: fourteen agreed, two diverged in opposite
directions. U+0130 lowercases to `i` plus U+0307 here and to a plain `i` in
Dart, so `lower()` would miss a collision the app catches. A Greek word ending
in a final sigma and the same word with a medial sigma fold to one key here and
to two in Dart, so `lower()` would refuse a configuration the app accepts. The
second is disqualifying on its own. Exact equality cannot over-reject, because
the shape rules already force the stored value to be canonical, so identical
active names always produce identical Dart keys.

Both gaps are named in the migration header, the column comment, the test file
and the PR body. Three tests assert the case-only variants are accepted, so a
future `lower()` fails loudly rather than arriving as assumed parity.

### Equivalence evidence

The drafted shape rules were run against the merged Dart contract on the hosted
database, read-only, using the exact escaped patterns that ship in the
migration: 22 vectors, then 18 further inputs covering the remaining test
cases. 40 of 40 agreed, including all three allowed format characters and the
24-family-emoji name a length guard would have wrongly refused.

The case-normalization audit was run separately: Dart keys printed from the
merged `MealCategoriesPolicy.normalizeDisplayName()`, PostgreSQL keys from
`lower()` on the same values, compared directly.

### Local execution, done

The database tests in this repository are plain psql scripts driven by
`.github/workflows/supabase-db-ci.yml`, not pgTAP, so `supabase test db` is not
the flow. `supabase db reset` is not either: an existing migration uses
`LOCK TABLE`, which needs a transaction block, so migrations are replayed
individually with `psql --single-transaction`, exactly as that workflow does.

Executed on the local Docker stack:

- all 42 migrations replayed from scratch, last `20260909131518`;
- ledger verified against the files, no diff;
- TNYX-186 display-name matrix passed, 90 assertions, including the full 4x4
  reserved-owner matrix, owner ASCII case variants, active and archived custom
  rejections, rename-does-not-release, and renamed-label-not-reserved;
- TNYX-67 B1 matrix passed, no regression;
- TNYX-67 real two-session concurrency test passed;
- mutation-verified: the previous validator accepted a custom `Lunch` after
  `meal_slot_2` was renamed to `Mid Meal`; restoring the reconciled migration
  made the 90-assertion matrix green;
- database lint matched the pre-B1 baseline with no schema errors;
- post-apply read-back confirms immutable, strict, `SECURITY INVOKER`, empty
  `search_path`, unchanged ACL, unchanged CHECK constraint, enabled retained-ID
  trigger, U+200B and the reserved `translate()` mapping present, and no
  `char_length` or `lower()` in executable code.

`git diff --check` is clean. PR #235 is published; the pre-rebase head CI was
green, and exact-head CI must be rechecked after the reconciled branch is
force-pushed with lease.

### Still required before any hosted apply

Separate explicit owner authorization, after review of this design and of the
stated enforcement boundary.

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

### Slice B reconciliation after merged Slice C

PR #235 is rebased onto `main@1c92a1261c52e22824907bcc307a350d0c03f7e5`.
The same pending migration `20260909131518` now enforces reserved-name ownership
with ASCII-only folding, preflights stored rows with count-only evidence, and
fails rather than repairing or grandfathering violations. The SQL matrix covers
owners, wrong canonical identities, active and archived customs, ASCII case
variants, rename permanence and non-growing reservations. Hosted data and the
migration ledger were inspected read-only; no migration was applied hosted.

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
