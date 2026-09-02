# TNYX-141 — Additional Nutrient Goals V1

**Status:** In progress
**Primary owner:** Flutter mobile / Nutrition feature
**Affected platforms:** Flutter Android and iOS; local Supabase migration

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; product-visible UI/UX change; Supabase column shape change
**Approval status:** Approved
**Approval evidence:** Linear TNYX-141 `READY — OWNER AUTHORIZED`, frozen 2026-09-02 against `main` `b1747a9d00bd492b1d894eec87c5e5ef6433f736`; this implementation prompt authorizes branch, source/tests, one local migration, validation, commit/push, Draft PR, and tracker evidence.
**Approved product/UI/data-shape boundaries:** Exactly `saturated_fat`, `trans_fat`, `sodium`, and `vitamin_d`; one nullable `public.user_nutrition_targets.additional_nutrient_goals jsonb` column with an object-or-null check; a nested Additional Nutrient Goals screen under Nutrition Targets; typed domain contracts and V1 serialization.
**Explicit non-changes:** No other nutrient; no reference-sex/life-stage fields; no core-five storage change; no `customized_fields` or `recommendation_metadata` change; no RLS/RPC/trigger change; no hosted DDL/apply/push; no migration-history repair; no GitHub #24 mutation; no merge; no Linear Done.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Owner (final substantive review); Codex performs implementation self-review only
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-02
**Branch:** `codex/tnyx-141-additional-nutrient-goals-v1`
**HEAD SHA:** `d5021d85631abaa0c9623c9596180509fad772c4` — the last commit that changes code. Anything after it on this branch is documentation only, so this stays the SHA every validation figure below was measured at rather than a number that goes stale the moment the brief is edited.
**Observed working-tree state:** Clean before this task brief
**Observed uncommitted/dirty files:** None before implementation
**PR / tracker:** No open PR at baseline; Linear TNYX-141 is `In Progress`; GitHub #24 remains OPEN/PAUSED and untouched
**Current implementation state:** Complete. Codex C1-C6 resolved, C7-C9 triaged as stale-duplicate or already-fixed, C10 open as a deployment gate. Final manual re-review then found three more: M1 (P1, the delta write was still not atomic), M2 (P2, delta identity), M3 (P2, route dismissal during save). All three fixed and mutation-verified.
**Relevant execution surface:** `apps/features/nutrition`, `apps/app`, `apps/core` route contract, `supabase/migrations`
**Validation completed at SHA:** Full-workspace `flutter analyze` (16/16 packages) and `flutter test` (14/14 test-bearing packages, 1745 tests) at `d5021d85`; `dart format` clean; `git diff --check origin/main...HEAD` exits 0; exact-head CI SUCCESS.
**Validation remaining:** Physical-device acceptance and hosted migration authorization. Both are outside this task's authorization.
**Current blocker:** None for implementation. Hosted rollout is gated on migration-ledger repair (see below) and separate owner authorization.
**Open review finding IDs:** `C10` only — the migration-before-client deployment gate, left unresolved on purpose so it cannot be lost. M1-M3 are fixed, replied to and resolved; every Codex thread is fixed or answered.
**Next exact action:** Owner physical-device acceptance, then hosted migration authorization (ledger repair first). PR #202 stays Draft. Do not merge, mark Ready, or apply hosted DDL.

## Global UI / Design-System Guardrail

`apps/core/lib/src/theme/README.md`, `apps/features/AGENTS.md`, the existing
Nutrition settings surfaces, and the core component barrel were inspected.
This slice reuses `TioGroupCard`, settings rows, input/editor-sheet and button
contracts. It introduces no token, theme contract, or unrelated visual change.

## 1. Discovery

### User Outcome

An eligible adult can open Settings → Nutrition & Diet → Nutrition Targets →
Additional Nutrient Goals and configure exactly four governed goals. Each goal
can use the current recommendation, carry an explicit custom override including
zero, or be disabled without changing the five core targets.

### Success Criteria

- Only the four authorized canonical `NutrientId` values are exposed.
- Recommendations derive at runtime; only configuration/override state persists.
- Missing required canonical inputs and age under 19 show unavailable; no value
  is fabricated and `Use Recommended` is disabled.
- V1 serialization distinguishes absent, null, custom, and explicit zero.
- Unknown V1 fields survive edits; malformed known V1 is rejected; unsupported
  future schema is read-only and never rewritten.
- Core-five writes preserve the JSONB column, and focused local PostgREST proof
  demonstrates omitted-key preservation and explicit-null clearing.

### Scope

Typed domain rules, one persistence envelope/codec, repository support, one
additive local migration, the nested route/screen, focused tests, validation,
and a reviewed Draft PR.

### Non-Goals

All Nutrition backlog outside the four IDs; hosted mutation; migration-history
repair; production rollout; RLS/RPC/trigger changes; child tables; per-nutrient
columns; copied Profile/Body truth; new design-system contracts.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: canonical `NutrientId`, Nutrition target domain and
  repositories, Supabase adapter, providers, router, current target pages/tests,
  migration directory/config, and hosted `user_nutrition_targets` metadata.
- Existing pattern to follow: app-owned provider/router composition; feature-owned
  typed domain and UI; current whole-row core-target upsert; core settings widgets.
- Hosted table currently has 11 columns and no `additional_nutrient_goals`;
  RLS is enabled with four owner policies, existing constraints and update trigger;
  no dependent views/functions were found.
- Repository/hosted migration timestamps do not reconcile. This pass may create
  and validate a local migration but may not repair history or apply hosted DDL.

### Migration-ledger reconciliation (read-only, performed this pass)

```text
repo migrations                38 files (37 pre-existing + 1 new)
hosted applied migrations      26
hosted latest                  20260831064841_add_nutrition_other_free_text
repo latest (pre-existing)     20260831064500_add_nutrition_other_free_text
new local migration            20260902041627_add_nutrition_additional_nutrient_goals.sql
hosted migrations missing from repo   none
```

Two distinct kinds of drift exist, and they matter for rollout in different
ways.

**1. Eleven repo migrations were never recorded in the hosted ledger.** All of
them are timestamped `20260814000001` through `20260816000004`, and the
earliest hosted entry is `20260817090811` — the hosted ledger simply begins
after them. Several are visibly from the sibling `tnyx-hub` lineage
(`create_tnyxhub_canonical_tables`, `create_user_devices_table`,
`add_plan_to_users_table`). Their objects exist in the database; only the
ledger rows are missing.

**2. Three migrations exist under both names but at different versions.**

| Migration | Repo version | Hosted version |
|---|---|---|
| `refine_username_suggestions` | 20260826072000 | 20260826075218 |
| `set_active_body_goal_rpc` | 20260830055341 | 20260830074411 |
| `add_nutrition_other_free_text` | 20260831064500 | 20260831064841 |

**Deployment gate this creates.** The new migration's version is later than the
hosted latest, so it is correctly ordered. But a plain `supabase db push` would
first try to replay the eleven unrecorded `202608140000xx`–`202608160000xx`
migrations, which create objects that already exist. That would fail, and if
forced could damage existing data. **The ledger must be repaired first** — the
eleven marked applied, and the three version mismatches resolved — before this
migration can be deployed by the normal flow. Recording it here as a mandatory
rollout gate; it does not block local implementation, and no repair was
attempted in this pass.
- Some broad architecture/setup strategy wording is stale relative to the active
  root/product contract; runtime source and current root architecture remain truth.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| V1 set is exactly four canonical IDs | Approved | Frozen TNYX-141 boundary | Owner |
| V1 recommendation eligibility is age >= 19 | Approved | No pediatric policy or fabricated default | Owner |
| Persist only `custom_value` within versioned JSON | Approved | Runtime recommendation remains current canonical truth | Owner |
| Unknown V1 data is opaque and merge-preserved | Approved | Forward-compatible read-modify-write | Owner |
| Future schema is unsupported/read-only | Approved | An old client must never downgrade future data | Owner |
| Hosted apply waits for separate authorization and ledger reconciliation | Approved | Current migration ledger is mismatched | Owner |

## 4. Architecture Design

### Chosen Approach

- Domain owns `AdditionalNutrientGoalSet`, `AdditionalNutrientGoal`, policy types,
  capability state, recommendation derivation and effective-value resolution.
- Data owns a V1 persistence envelope/codec. Raw maps never enter UI contracts.
- Core-target `upsert` omits the new column, preserving new-client state when an
  old/core-only writer updates the existing row.
- A dedicated repository operation re-reads and merge-updates only additional
  goals, preserving unknown V1 content and refusing future schema rewrites.
- App composition supplies canonical Calories and DOB-derived age to the feature.

### Ownership and Data Flow

```text
Additional Goals UI -> typed domain policy -> NutritionTargetsRepository
  -> V1 persistence codec/envelope -> Supabase/PostgREST

Profile DOB + canonical target Calories -> runtime recommendations only
```

### Alternative Rejected

Loose `Map<String, dynamic>` through domain/UI, per-nutrient columns, a child
table, persisted recommendation values, and duplicating age/calorie truth were
rejected because they violate the frozen contract.

### Failure and Accessibility States

Unavailable recommendations are explicit and non-actionable; saved custom values
remain visible. Save failures keep the editor retryable. Rows retain semantic
labels, standard navigation affordances, and existing touch/keyboard behavior.

## 5. Implementation Plan

- [x] Add typed goal/recommendation contracts and pure policy tests.
- [x] Add V1 persistence codec and repository preservation tests.
- [x] Create one canonical additive local migration.
- [x] Add the nested route and feature-owned goals screen.
- [x] Add widget and route-level persistence/preservation tests.
- [~] Prove old-client semantics through local PostgREST — **not executable
  here**; strongest available repository-level proof provided instead (see
  Compatibility proof).
- [x] Run focused and package-level validation plus self-review.
- [ ] Commit, push, open reviewed Draft PR, and attach exact evidence to Linear.

### Compatibility proof — why it is a gateway-payload test

Docker is not installed, the Supabase CLI is not on PATH, and `npx supabase`
requires a network download, so a live PostgREST integration test cannot run in
this environment. Rather than fake it with a mapper-only assertion, the proof
pins the half of the contract that lives in this repository: the exact payload
sent to PostgREST.

That is a real guarantee because PostgREST's upsert compiles to
`INSERT ... ON CONFLICT (user_id) DO UPDATE SET <payload columns>`. A column
absent from the payload is never written; one present with an explicit null is
written as null. So two assertions decide the preservation behaviour:

- the core-five upsert payload **omits** `additional_nutrient_goals` entirely,
  so an old-client-shaped write cannot clear it;
- the goals-only write payload contains **only** `user_id` and
  `additional_nutrient_goals`, so it cannot disturb the core five.

Both are asserted, along with a re-read-before-merge test proving concurrent
unknown data is not lost. The remaining half is documented PostgreSQL
semantics, and is listed as a deployment-gate verification item to confirm once
the hosted migration is authorized.

## 6. Quality Review

### Validation Run

This PR changes a repository interface, so affected packages are **not**
inferred from production imports — `NutritionTargetsRepository` is also
implemented by test doubles in packages that never import the new code. The
full workspace is analyzed and tested, matching CI.

```text
dart format   (all changed source and test files)          PASS
git diff --check origin/main...HEAD                        PASS

flutter analyze  -- all 16 packages                        PASS (0 failures)
  shared · core · app · wear · account_setup · auth · coaching · home
  nutrition · onboarding · profile · progress · settings · splash
  welcome · workout

flutter test  -- all 14 test-bearing packages              PASS (0 failures)
  onboarding      450        auth            159
  nutrition       278        profile          59
  app             269        progress         51
  settings        192        account_setup    38
  core            177        shared           36
  workout          14        splash           12
  wear              9        home              1
                                              -----
                                        total 1745
```

`apps/features/nutrition` went 133 → 278 (+145) and `apps/app` 267 → 269 (+2,
the profile-error route composition). Every other package's total is unchanged
from baseline, which is the point: the interface change had to be absorbed by
their test doubles without altering their behaviour.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence or follow-up |
|---|---|---|---|---|
| F1 | Blocking | Fixed | The V1 codec did not compile. `custom_value` was read into an `Object?` and the guard `if (raw != null && raw is! num) throw` does not promote, so `raw?.toDouble()` failed to resolve. Restructured into an explicit null / `is num` / else-throw chain. | `additional_nutrient_goals_v1_codec.dart` |
| F2 | Blocking | Fixed | Same file carried an unused `tio_shared` import. Confirmed safe to drop: `storageValue` is an enum field, not an extension getter, so it resolves without the import. | `additional_nutrient_goals_v1_codec.dart` |
| F3 | High | Fixed | The new route was missing from `shellChromePolicyForPath`, so it fell through to `noBottomBar` and would have rendered shell chrome over a full-screen settings page. Added, and the existing policy test extended to cover all three nutrition sub-routes rather than two. | `router.dart`, `nutrition_settings_route_test.dart` |
| F4 | Medium | Fixed | The row overflowed by 18px at 390dp: "Recommended" beside a label like "Saturated Fat" does not fit the core settings row's label/annotation pair. Moved the state caption under the amount in the value column, which also keeps both states visible. | `additional_nutrient_goals_page.dart` |
| F5 | Medium | Fixed | Thousands grouping was initially applied by a single formatter used for both prose and the editor's text field, so a custom value of 1500 would have rendered as "1,500" and then failed `double.tryParse` on save. Split into a grouped formatter for prose and an ungrouped one for anything parsed back. | `additional_nutrient_goals_page.dart` |
| F6 | Blocking | Fixed | **Caught by CI, not by local validation.** Affected packages were chosen from production imports, but `NutritionTargetsRepository` is also implemented by five test doubles in `tio_feature_onboarding`, so adding a method to the interface broke analysis there. The fakes now implement it — throwing `UnsupportedError`, since onboarding never configures these goals and a silent no-op would hide a real future mistake; the delegating fake forwards instead. Validation is now full-workspace. | five files under `apps/features/onboarding/test/domain/` |

### Manual review findings (Draft PR #202, at head `7b8e449c`)

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| R1 | P1 | Fixed | `_editableNumber()` rounded every non-integer to one decimal before refilling the editor, so a stored `0.04` reopened as `0` and pressing Save silently overwrote it; `0.45` became `0.5`. The domain accepts any finite nonnegative double, so this was silent data loss on a no-op interaction. | The editable field now uses `toString()` for non-integers — the shortest exactly round-tripping form — while prose guidance keeps a separate readable rounding. Regression covers 0.04, 0.45, 1.25, 12.345 and 0.001 through reopen-and-save. |
| R2 | P1 | Fixed | The row summary dropped `comparison` and rendered sodium's recommendation as a bare `2000 mg`, presenting the forbidden boundary as the goal itself. | Summary formatting carries the comparator: `< 2000 mg`. Applied for custom values too, since the comparison belongs to the nutrient's policy rather than to where the number came from. Row-level regressions added for the recommended state, the custom state, and a non-strict nutrient as a negative control. Editor guidance still reads "less than 2,000 mg/day". |
| R3 | P2 | Fixed | The codec correctly decoded a future `schema_version` as `unsupported()`, but the page rendered that empty typed set as four tappable `Not set` rows — so a user with newer-client data would only discover the incompatibility as a generic save failure. | When `!goals.isWritable` the page shows an explicit read-only notice and renders no rows at all, so no edit can be started and the payload is never rewritten. Regressions assert the notice appears, no `Not set` text appears, no nutrient row exists, and nothing is written. |
| R4 | Minor | Fixed | Invalid-number copy said "or more than zero" even though an explicit zero is a valid goal. | Now reads "Enter zero or a higher number of &lt;unit&gt;." Pinned by a test that also asserts the old wording is gone. |
| R6 | P1 | Fixed | The Recommended state was unreachable from scratch. With a derivable recommendation and no goal yet, the editor offered only the custom input and Save, so `Not set -> Recommended` was impossible — a new user had to invent a Custom override first, even though key-present + `custom_value: null` is the contract's enabled-Recommended state. `Use Recommended` now appears whenever the goal is not already on the recommendation, covering both opting in and reverting; both persist `custom_value: null`. Still gated on the recommendation being derivable, so nothing became enableable when it is not. | `additional_nutrient_goals_page.dart` |
| R7 | P2 | Fixed | Unavailable guidance claimed every recommendation needs Calories *and* a date of birth. Only the two percentage rules read Calories; sodium and Vitamin D are fixed amounts gated on age alone, so those users were told to fix an input their nutrient never uses. Guidance is now driven by `AdditionalNutrientRecommendationPolicy.blockersFor()`, which reports only the prerequisites that nutrient actually has, and distinguishes missing date of birth, age below the minimum, missing Calories, and both. Age below the minimum is stated as eligibility rather than as something to correct. | policy + `additional_nutrient_goals_page.dart` |
| R8 | Medium | Fixed | **A false PASS in my own evidence.** Earlier rounds recorded `git diff --check PASS`, but I had only ever run it against the working tree, which passes trivially once the offending lines are committed. Run correctly against the branch's whole contribution (`git diff --check origin/main...HEAD`) it exited 2: two files carried a trailing blank line at EOF, inherited from the first checkpoint commit. Files fixed and the evidence now names the exact command so it cannot be satisfied by a weaker check. | two domain model files |
| R5 | Medium | Fixed | **Found while fixing R3/R4, in the test helper rather than the product.** `pumpPage`'s `dateOfBirth: dateOfBirth ?? adultDob` could not distinguish "not specified" from "explicitly absent", so passing `null` silently produced an adult date of birth — meaning the existing "override survives the recommendation going away" test was passing for the wrong reason. Replaced with an explicit `withoutDateOfBirth` flag. | `additional_nutrient_goals_page_test.dart` |

### Codex review findings (Draft PR #202, at head `dfb0ad4e`)

Ten unresolved threads were fetched fresh from GitHub and triaged. Classifying
each one before fixing anything matters here: three of the ten did not describe
a live defect, and fixing them anyway would have churned working code.

| ID | Severity | Classification | Status | Finding | Resolution |
|---|---|---|---|---|---|
| C1 | P1 | Valid | Fixed | **Concurrent lost update.** `encodeUpdated` replaced the whole goal set, removing every authorized nutrient absent from `updated`. Confirmed by direct inspection, not by relaying the bot: a screen loads with no goals, another client adds Sodium, the user enables Vitamin D, and Sodium is silently deleted. Re-reading first does not help — the caller's snapshot still says "absent" for Sodium. | Converted to a per-nutrient delta end to end: `NutritionTargetsRepository.updateAdditionalNutrientGoal(NutrientId, AdditionalNutrientGoal?)` and `AdditionalNutrientGoalsV1Codec.encodeGoalDelta`. Only the edited key is written; every other entry, authorized or not, is carried through from the freshly decoded envelope. Both repository implementations, the page callback and the router composition follow. |
| C2 | P1 | Valid | Fixed | **Edit eligibility lived in the widget.** The frozen rule about what an unavailable recommendation permits was expressed as layout conditions inside the editor, so any second surface offering these actions would have re-derived it and drifted. | Extracted to `AdditionalNutrientGoalEditCapability.forGoal()` in the domain, exposing `canSetCustomValue`, `canUseRecommendation`, `canTurnOff` and `isValuePreserved`. The editor now renders the capability rather than deciding it. |
| C3 | P1 | Valid | Fixed | **Canonical editor surface bypassed.** `showTioEditorSheet` configures the modal route only; the builder returned a raw `Column`, skipping `TioEditorSheet` and with it viewInsets padding, the scrollable body, the pinned action region and SafeArea. On a compact phone with the keyboard raised, Save could sit below the fold — the exact defect that component exists to prevent. | Rebuilt as `TioEditorSheet` slots: `title`, `supportingText`, `content`, `actions`, with `canDismiss: !_isSaving` so a drag cannot discard an in-flight write. |
| C4 | P2 | Valid | Fixed | **Profile load errors read as a missing date of birth.** `ref.watch(profileDataProvider).valueOrNull` collapsed error and absent into the same `null`. A transient network error would render four permanently "Unavailable" nutrients and, under the frozen eligibility rule, block editing — with nothing on screen explaining why or offering a retry. | The route now handles the profile's loading and error states explicitly, reusing `_NutritionLoadFailure` with a retry that invalidates the profile provider. Two route-level regressions distinguish the failed load from a genuinely absent date of birth. |
| C5 | P2 | Valid | Fixed | **Tiny nonzero goals rendered as zero.** The precision-widening loop stopped at six decimals, so a stored `0.0000001` displayed as `0 g` — identical to the explicit zero that means something entirely different in this feature. | Widening now runs to `toStringAsFixed`'s documented 20-digit limit and then falls back to `double.toString()`'s shortest round-trippable form. Unfamiliar for a value that small, but honest. |
| C6 | P2 | Valid | Fixed | **Locale decimal separator rejected.** Comma-decimal keyboards send `22,5`; the input formatter stripped the comma (turning it into `225`) and the parser never normalised it. | The formatter admits `,` and `_saveCustom` normalises it to the canonical dot before parsing. A regression asserts the typed comma is not silently dropped, which is the more dangerous half. |
| C7 | P2 | Stale duplicate | Replied, resolved | "Enable a new goal directly on Recommended." Already fixed as **R6** in the previous pass; the thread is marked outdated by GitHub and was written against superseded code. | No code change. |
| C8 | P2 | Stale duplicate | Replied, resolved | "State nutrient-specific prerequisites." Already fixed as **R7**; thread marked outdated. | No code change. |
| C9 | P1 | Already fixed | Replied, resolved | "Do not record a failing diff check as PASS." Correct when written, and already self-reported and fixed as **R8** at `dfb0ad4e`. | Re-verified: `git diff --check origin/main...HEAD` exits 0 at `d5021d85`. |
| C10 | P1 | **Deployment gate** | **Left unresolved deliberately** | **Migration must be applied before this client ships.** `readRow` selects `additional_nutrient_goals`; on an unmigrated database PostgREST fails the whole request rather than returning null, and that same `readRow` backs the Nutrition Targets and Macros routes — so all three screens would break, not just the new one. Confirmed by direct inspection. | Not a code defect and not fixable in code. It is a rollout ordering constraint, and hosted migration is outside this task's authorization. The thread stays open as `DEPLOYMENT BLOCKER — NOT YET RESOLVED` so it cannot be lost. See the migration-ledger reconciliation above: a plain `supabase db push` would replay 11 unrecorded migrations against existing objects, so **ledger repair is part of this gate**. |

Nine regression tests were added for C1 alone, covering the required scenarios:
Sodium survives a local Vitamin D enable and a local Vitamin D disable; a local
Sodium edit and a local Sodium removal each touch only Sodium; unknown nutrient
keys, unknown top-level fields and unknown fields inside entries all survive; an
unsupported future schema stays fail-closed; and the core-five write still omits
the column entirely. The stale-full-set scenario is proved gone by asserting the
stale snapshot's `contains(sodium) == false` and that Sodium survives anyway.

### Final manual review findings (Draft PR #202, at head `030af057`)

Recorded separately from Codex C1–C10 above, because these came from manual
re-review of the *fixes* made in that pass. Two of the three found that an
earlier fix was necessary but not sufficient — worth stating plainly, since
"we already addressed that" was the wrong conclusion both times.

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| M1 | **P1 merge blocker** | Fixed | **The per-nutrient delta did not make the write atomic.** C1 fixed the stale-snapshot deletion, but the read-modify-write race underneath survived: clients A and B can both read envelope E0, A adds Vitamin D, B adds Sodium, and each writes the whole `additional_nutrient_goals` value back — whichever upsert lands last silently erases the other. The C1 regressions only covered the case where the competing write was already visible *before* the re-read, so they could not catch this. | Optimistic compare-and-swap against the row's existing `updated_at`, which an existing BEFORE UPDATE trigger already refreshes. Each attempt re-reads with its version, applies one delta, and updates only `WHERE user_id = ? AND updated_at = ?`; a swap that matches no row means another writer won, so the attempt re-reads and rebuilds the delta on what actually landed. Retries bounded at four. The missing-row race is handled by INSERT, not upsert — two blind upserts race identically — and a `23505` on the `user_id` primary key is treated as "someone created it, merge onto theirs" while unrelated PostgREST failures are rethrown. No schema change and no RPC; the gateway gains three primitives (versioned read, conditional swap, insert-if-absent) and PostgREST mechanics stay out of domain and UI. |
| M2 | P2 | Fixed | **A delta's key and its goal could disagree.** `goal.validate()` only proves the goal's own nutrient is authorized, not that it equals the separate `nutrientId` argument, so `encodeGoalDelta(decoded, sodium, goal(vitaminD, 18))` stored 18 under the Sodium key. The in-memory owner had the *opposite* failure mode, because `withGoal` follows `goal.nutrientId` — it would have written Vitamin D. Divergent behaviour on the same bad call is worse than either outcome alone. | `AdditionalNutrientGoalsV1Codec.requireGoalIdentity` enforces `goal == null \|\| goal.nutrientId == nutrientId`, called from the codec and from both repositories. The Supabase repository checks before any I/O, so a caller bug never reaches the gateway. |
| M3 | P2 | Fixed | **`canDismiss` did not block route dismissal.** It governs the `TioEditorSheet` handle only; `showModalBottomSheet` leaves the route back- and barrier-dismissible, so a back press could close the editor after the write had started — directly contradicting the comment claiming an in-flight write could not be discarded. | Wrapped in `PopScope<Object?>(canPop: !_isSaving)` while retaining `canDismiss`, matching the established usage on the app's other editor sheets. Layout, keyboard-safe insets, pinned actions and save behaviour are unchanged. |

**Mutation-verified, because these tests are the whole evidence.** Reverting
the compare-and-swap to the previous read-then-upsert fails 8 tests, including
both same-predecessor races. Forcing `canPop: true` fails the in-flight
back-press test. Without that check two of them would have been vacuous, and
two genuinely were until it was run:

- The table double stamped its seeded row with a hand-written version string
  that collided with its own first generated version, so a stale
  compare-and-swap passed. The double now stamps seeded rows from the same
  counter as every later write.
- The first back-press test used `tester.binding.handlePopRoute()`, which never
  reached the route — it passed with the guard removed. `Navigator.maybePop` is
  the path `PopScope` actually gates. A follow-on trap: `maybePop` returns
  `true` for `doNotPop` as well, because it reports that the pop was *handled*,
  so only the sheet's presence afterwards distinguishes a refused pop — and one
  pump only *starts* a dismissal animation, leaving the sheet still mounted.

**Required concurrency coverage**, all against a double that models one row per
user, a version stamp refreshed on every write, `23505` on a duplicate primary
key, and a version-predicate UPDATE that matches no row:

- same predecessor, A adds Vitamin D and B adds Sodium — both survive
- the same race reversed
- a concurrent disable does not resurrect the disabled nutrient
- compare-and-swap conflicts are retried (asserted on the operation sequence,
  not inferred from the final value)
- bounded retry exhaustion fails without overwriting the latest data
- a missing row is created by insert, never by upsert
- losing the row-creation race merges instead of clobbering
- an unrelated insert failure is not mistaken for a lost race
- unknown nutrient keys, unknown top-level fields and unknown fields inside
  known entries all survive a retry
- a schema that turns unsupported mid-retry still fails closed
- core-five writes remain independent in both directions

### Owner UX decision — recorded as frozen

When a recommendation is unavailable and the nutrient is **not** configured: no
`Turn on`, no key created, no arbitrary custom value accepted; the state is
explained and the nutrient stays unconfigured. When an already-configured goal
later becomes underivable: the stored custom override is preserved and still
displayed, `Turn off` remains available, and `Use Recommended` stays hidden
until a recommendation can be derived again. This closes the dead end
previously recorded as an open question.

### Contract deviation recorded for review

The pre-existing test `additional nutrient goals are not exposed here` asserted
that the literal string "Additional Nutrient Goals" must not appear on the
Nutrition Targets page. TNYX-141 section 18 requires exactly that entry to be
added there. The test's underlying intent — that individual nutrient rows must
not appear beside the core five — is preserved and still asserted; the string
assertion was inverted to match the new contract, and a navigation test was
added. Flagging it because it is a deliberate change to an existing guard
rather than an incidental test update.

*(The previously open unavailable-recommendation question is now resolved —
see "Owner UX decision" above.)*

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-141-additional-nutrient-goals-v1.md
supabase/migrations/20260902041627_add_nutrition_additional_nutrient_goals.sql

apps/core/lib/src/routing/routes/app_routes.dart

apps/features/nutrition/lib/src/domain/models/additional_nutrient_goal.dart
apps/features/nutrition/lib/src/domain/models/nutrient_recommendation.dart
apps/features/nutrition/lib/src/domain/models/nutrition_targets_data.dart
apps/features/nutrition/lib/src/domain/models/models.dart
apps/features/nutrition/lib/src/domain/repositories/nutrition_targets_repository.dart
apps/features/nutrition/lib/src/domain/usecases/additional_nutrient_recommendation_policy.dart
apps/features/nutrition/lib/src/domain/usecases/nutrition_target_editor.dart
apps/features/nutrition/lib/src/domain/usecases/usecases.dart
apps/features/nutrition/lib/src/data/additional_nutrient_goals_v1_codec.dart
apps/features/nutrition/lib/src/data/in_memory_nutrition_targets_repository.dart
apps/features/nutrition/lib/src/data/repositories/supabase_nutrition_targets_repository.dart
apps/features/nutrition/lib/src/data/data.dart
apps/features/nutrition/lib/src/presentation/pages/additional_nutrient_goals_page.dart
apps/features/nutrition/lib/src/presentation/pages/nutrition_targets_settings_page.dart
apps/features/nutrition/lib/src/presentation/pages/pages.dart

apps/features/nutrition/test/domain/additional_nutrient_recommendation_policy_test.dart
apps/features/nutrition/test/domain/additional_nutrient_goal_set_test.dart
apps/features/nutrition/test/data/additional_nutrient_goals_v1_codec_test.dart
apps/features/nutrition/test/data/additional_nutrient_goals_persistence_test.dart
apps/features/nutrition/test/presentation/additional_nutrient_goals_page_test.dart
apps/features/nutrition/test/presentation/nutrition_targets_settings_page_test.dart

apps/app/lib/app/router.dart
apps/app/test/app/nutrition_settings_route_test.dart
```

### Actual Behavior

Settings → Nutrition & Diet → Nutrition Targets now carries an ADDITIONAL
section linking to a nested Additional Nutrient Goals screen. That screen lists
exactly saturated fat, trans fat, sodium and vitamin D. Each row reads Not set,
the effective amount with a Recommended or Custom caption, or Unavailable.
Tapping a row opens an editor offering a custom override, Use Recommended, and
turn off; sodium's guidance states the strict "less than 2,000 mg/day"
boundary. Recommendations are derived at runtime from canonical Calories and
Profile date of birth and are never stored. Core-five targets are unchanged in
value, provenance and write path.

### Known Limitations

- **Hosted Supabase is unmigrated, and this is a hard release gate, not a
  graceful degradation.** An earlier draft of this note claimed the screen
  would read an absent column as "no goals configured". That was wrong, and
  Codex finding C10 caught it: PostgREST fails the entire request when a
  selected column does not exist, and the same `readRow` backs the Nutrition
  Targets and Macros routes — so shipping this client against the current
  production schema would break three screens, not degrade one. The migration
  must be applied and the ledger repaired before any client rollout.
- Old-client preservation is proven at the request-payload boundary rather than
  against a live PostgREST instance, because the local Supabase stack cannot
  run in this environment.
- A stored custom value whose recommendation is underivable can be viewed and
  turned off, but not edited, until the recommendation becomes derivable again.
  That is the frozen owner decision, not an accident.

### Final Status

`AWAITING REVIEW` — implementation, review resolution and validation complete
through the final manual re-review (M1-M3). PR #202 remains Draft. Two gates
remain and neither is a code change: owner physical-device acceptance, and
hosted migration authorization with ledger repair (Codex finding C10, still
open by design). Next gate is a final manual substantive re-review.
