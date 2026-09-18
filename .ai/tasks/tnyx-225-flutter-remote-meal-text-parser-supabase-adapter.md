# TNYX-225 — N5D-7 Flutter Remote MealTextParseRepository Supabase Adapter

**Status:** Review fixes implemented — exact-head CI/re-review pending
**Primary owner:** `apps/features/nutrition/lib/src/data/repositories`, `apps/app/lib/app/network_providers.dart`
**Affected platforms:** Flutter phone app (`apps/app`), Nutrition feature package (`apps/features/nutrition`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner explicitly authorized TNYX-225 implementation in-session via `AskUserQuestion` ("हाँ, authorize करता हूँ") after full state reconstruction (clean `main` at `7f2dbed9107b0f7af8fd825db2d95045abc3675c` matching `origin/main`) and an explicit scope summary (what will be built, why, what changes, what does not change) was presented per `.ai/FEATURE_DEVELOPMENT.md` Owner Approval Gate.
**Approved product/UI/data-shape boundaries:** A new `SupabaseMealTextParseRepository` data-layer adapter implementing the existing `MealTextParseRepository` contract, an injectable Supabase Functions gateway seam, focused tests, and `apps/app` composition wiring only. No UI, no schema/RLS/RPC, no Edge Function changes.
**Explicit non-changes:** No Supabase deployment. No Edge Function (`nutrition-meal-text-parse`) source changes. No Add Food UI activation. No Meal Editor UI changes. No TNYX-226 start. No `services/api` start. No provider credentials/DTOs in Flutter. No fake/in-memory production fallback repository.

## Active Handoff

**Planning owner:** Existing TNYX-225 plan retained
**Implementation owner:** ChatGPT (owner-authorized review-fix pass)
**Review owner:** Fresh reviewer pass after exact-head CI
**Implementation ownership state:** Review fixes implemented
**Ownership transition:** Owner explicitly instructed `@GitHub @Linear @Supabase sahi kare` after the fresh PR review; implementation ownership transferred only for the bounded G1/G2/G3 fix pass plus adjacent strict-schema hardening.
**Repository state last verified:** `main` clean at `7f2dbed9107b0f7af8fd825db2d95045abc3675c` == `origin/main`, before branch creation
**Branch:** `tnyx/tnyx-225-n5d-7-flutter-remote-mealtextparserepository-supabase`
**HEAD SHA:** recorded at push time in the PR/handoff report
**Observed working-tree state:** Clean at task start; only this task's files changed since
**Observed uncommitted/dirty files:** None pre-existing; `flutter pub get` incidentally rewrote `apps/features/nutrition/pubspec.lock` dependency-classification metadata (transitive → direct, no version change) each run — reverted with `git checkout` after every validation pass so it never enters the diff
**PR / tracker:** Linear TNYX-225 (moved Backlog → In Progress); PR created as draft after push, referencing TNYX-225 and GitHub #269
**Current implementation state:** G1/G2/G3 review fixes implemented; strict nested nutrition schema-version validation also tightened inside the approved decoder scope
**Relevant execution surface:** `MealTextParseController` → `MealTextParseRepository` → `SupabaseMealTextParseRepository` → bounded `MealTextParseFunctionGateway` → `SupabaseClient.functions.invoke('nutrition-meal-text-parse', ...)`
**Validation completed at SHA:** original implementation validation is recorded below; post-fix exact-head CI must be re-verified after push
**Validation remaining:** Exact-head Flutter CI/re-review; live authenticated Supabase invocation remains blocked on a later explicit deployment gate because the function is NOT DEPLOYED
**Current blocker:** Review findings must be re-verified and resolved on the new exact head before Ready for Review
**Open review finding IDs:** TNYX-225-G1, TNYX-225-G2, TNYX-225-G3 — fixes included in this pass, thread resolution pending fresh verification
**Next exact action:** Wait for exact-head Flutter CI, re-review the fixes, then resolve review threads only if the new head confirms them

## Global UI / Design-System Guardrail

Not applicable. This task adds no Flutter UI, widgets, or visual code. No screen/design/token file is touched.

## 1. Discovery

### User Outcome

Give the Nutrition feature a production-capable data adapter that turns normalized natural-language meal text into a reviewable `MealLoggingDraft` by calling the already-merged, provider-neutral `nutrition-meal-text-parse` Supabase Edge Function contract — without yet wiring it into any UI. TNYX-226 (out of scope here) will later decide how/when Add Food UI consumes this capability.

### Success Criteria

- `SupabaseMealTextParseRepository` implements `MealTextParseRepository.parseMealText(String text)` exactly.
- Calls `nutrition-meal-text-parse` via `SupabaseClient.functions.invoke` with the exact request contract (`schemaVersion: 1`, `mealText`) and a bounded client-side abort signal.
- Decodes the merged response contract strictly and defensively, including optional `mealName` typing and nested nutrition snapshot schema version; every malformed/unexpected shape fails closed to `MealTextParseFailureReason.unavailable` rather than leaking a raw exception, transport detail, or provider payload.
- `unrecognized`/`incomplete`/`unavailable` server outcomes map to the matching typed `MealTextParseFailure` reason.
- A successful decode produces a `MealLoggingDraft` with `captureSource: MealLogCaptureSource.text`.
- `apps/app` composition provider selects the Supabase adapter when a Supabase client exists and resolves to `null` otherwise (no fake/in-memory fallback).
- Focused repository tests and app composition tests pass; `melos`/package-level `flutter analyze` is clean for the touched packages.

### Scope

In scope:

- `apps/features/nutrition/lib/src/data/repositories/supabase_meal_text_parse_repository.dart` (new)
- `apps/features/nutrition/lib/src/data/data.dart` (export)
- `apps/features/nutrition/test/data/supabase_meal_text_parse_repository_test.dart` (new)
- `apps/app/lib/app/network_providers.dart` (`mealTextParseRepositoryProvider`)
- `apps/app/test/app/network_providers_test.dart` (provider-selection coverage)
- `.ai/tasks/tnyx-225-flutter-remote-meal-text-parser-supabase-adapter.md` (this brief)

### Non-Goals

- Add Food natural-language UI activation.
- Meal Editor UI changes.
- Any Supabase schema/RLS/RPC/migration or Edge Function source change.
- Supabase deployment of any kind.
- TNYX-226 (consumption of this capability by UI).
- `services/api`.
- Provider (Gemini/FatSecret/Edamam) credentials, DTOs, or field names anywhere in Flutter.
- Dependency upgrades (kept on the already-locked `supabase_flutter: ^2.8.0` / resolved `functions_client 2.7.1`).

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `apps/features/nutrition/lib/src/domain/repositories/meal_text_parse_repository.dart` — `MealTextParseRepository`, `MealTextParseFailure`, `MealTextParseFailureReason` (`unrecognized`, `incomplete`, `unavailable`).
  - `apps/features/nutrition/lib/src/meal_logging/meal_text_parse_controller.dart` — confirmed the controller already owns trim/blank-guard, duplicate-submission suppression, retry, and catch-all sanitization to `unavailable`; confirmed it rejects a "successful" draft whose `captureSource != MealLogCaptureSource.text`.
  - `apps/shared/lib/src/nutrition/meal_logging_draft.dart`, `meal_logging_draft_item.dart`, `meal_log_capture_source.dart`, `nutrition_snapshot.dart`, `nutrient_id.dart` — exact constructors/validation and the 12 canonical nutrient keys (`energy`, `protein`, `carbohydrate`, `fat`, `fiber`, `saturated_fat`, `trans_fat`, `added_sugar`, `sodium`, `calcium`, `phosphorus`, `vitamin_d`); confirmed unknown nutrient keys are silently ignored (not remapped) by `NutrientId.fromStorageValue`.
  - `supabase/functions/nutrition-meal-text-parse/contract.ts` and `handler.ts` (read-only, not modified) — confirmed the exact merged wire contract: top-level `{schemaVersion, outcome, mealName?, items?}`, item shape `{displayName, quantity, servingUnit, nutritionSnapshot}`, and that the Edge Function always responds HTTP 200 for all four outcomes (`success`/`unrecognized`/`incomplete`/`unavailable`); only `400`/`401`/`405` (invalid request / unauthorized / method not allowed) are non-2xx.
  - locked `functions_client 2.7.1` package source/types — confirmed transport exception shapes and request-cancellation support that must remain sanitized at the repository boundary.
  - `apps/app/lib/app/network_providers.dart` — confirmed the established `Provider<T?>((ref) { supabaseClient != null ? Supabase... : null })` idiom already used by `userProfileRepositoryProvider`, `profileAccountRepositoryProvider`, `appOnboardingDraftRepositoryProvider` for capabilities with no safe offline fallback.
- Existing pattern to follow: `apps/features/nutrition/lib/src/data/repositories/supabase_meal_categories_repository.dart` — constructor-injected `SupabaseClient` plus an optional injectable gateway seam defaulting to a concrete Supabase-backed gateway, enabling hand-written fakes in tests (no mocktail/mockito anywhere in this repo).
- Tests or validation already present: `apps/features/nutrition/test/meal_logging/meal_text_parse_controller_test.dart` already covers the controller side against a hand-rolled `_RecordingRepository`; no prior Supabase-backed test existed for the parser repository before this task.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Provider returns `MealTextParseRepository?` (null when no Supabase client), not an in-memory/fake fallback | Made | Parsing has no safe offline capability; a fake production parser would silently fabricate meal data | Task brief (explicit instruction) |
| Introduce `MealTextParseFunctionGateway` seam around `functions.invoke` | Made | Matches existing repo convention (`MealCategoriesTableGateway`) for testability without a live Supabase project | Codebase pattern |
| All server outcome/shape decoding failures map to `unavailable` except the three named outcomes | Made | Matches merged server contract's four `ParseOutcome` values and the "never leak raw transport/provider detail" requirement | Task brief + `contract.ts` |

## 4. Architecture Design

### Chosen Approach

```text
MealTextParseController
  -> MealTextParseRepository (existing interface, unchanged)
  -> SupabaseMealTextParseRepository (new)
  -> MealTextParseFunctionGateway (new injectable seam)
  -> SupabaseMealTextParseFunctionGateway (new, wraps SupabaseClient.functions.invoke)
  -> strict response decoding (outcome switch + defensive item/snapshot decoding)
  -> MealLoggingDraft (existing shared domain type)
```

### Ownership and Data Flow

```text
UI (not built yet, TNYX-226) -> MealTextParseController (existing) -> MealTextParseRepository (existing contract)
  -> SupabaseMealTextParseRepository (new) -> MealTextParseFunctionGateway (new seam) -> Supabase Edge Function
```

### Alternative Rejected

A plain callable/typedef gateway (as used by `SupabaseGoogleLoginAdmissionChecker`) was considered instead of an `abstract interface class` gateway, but the interface-class seam was chosen to match the more common repository-adjacent gateway convention (`MealCategoriesTableGateway`) and to keep the default concrete implementation (`SupabaseMealTextParseFunctionGateway`) separately swappable/testable.

### Failure and Accessibility States

Not applicable (no UI). Data-layer failure states: `MealTextParseFailureReason.unrecognized` / `.incomplete` / `.unavailable`, all consumed by the existing, unmodified `MealTextParseController`.

## 5. Implementation Plan

- [x] Add `SupabaseMealTextParseRepository` + `MealTextParseFunctionGateway` + `SupabaseMealTextParseFunctionGateway`.
- [x] Export from `apps/features/nutrition/lib/src/data/data.dart`.
- [x] Add focused repository tests (22 cases after review fixes, including bounded abort, malformed present `mealName`, and unsupported nested snapshot schema version).
- [x] Add `mealTextParseRepositoryProvider` to `apps/app/lib/app/network_providers.dart` (Supabase-or-null, no fallback).
- [x] Extend `apps/app/test/app/network_providers_test.dart` with default/no-Supabase/Supabase-available coverage.
- [x] Run focused + full validation for both touched packages.

## 6. Quality Review

### Validation Run

Original implementation validation at `f99534fc4a4e3f9b7f844e0a4e7012ae60d05941`:

```text
cd apps/features/nutrition
flutter pub get
flutter test test/data/supabase_meal_text_parse_repository_test.dart   -> All 19 tests passed
flutter analyze                                                        -> No issues found
flutter test                                                           -> All 853 tests passed

cd apps/app
flutter pub get
flutter analyze                                                        -> No issues found
flutter test test/app/network_providers_test.dart                     -> All 10 tests passed
flutter test                                                           -> All 320 tests passed

git diff --check origin/main...HEAD
git diff --name-status origin/main...HEAD
git rev-list --left-right --count origin/main...HEAD
```

Note: the original local validation environment reported incidental `apps/features/nutrition/pubspec.lock` dependency-classification drift with no version/hash change; that lockfile was kept out of the task diff.

Post-review-fix validation in this connector session cannot run the local Flutter toolchain. The new exact head must therefore rely on GitHub Flutter CI before review threads are resolved or the PR moves out of Draft.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-225-G1 | P2 | Fixed in source; re-review pending | Client function invocation lacked a bounded abort signal | `f99534f` | 50s client budget now drives `abortSignal`; abort/transport errors still collapse to `unavailable`; focused regression added |
| TNYX-225-G2 | P2 | Fixed in source; re-review pending | Present non-string `mealName` was silently treated as absent | `f99534f` | Present malformed values now fail closed to `unavailable`; regression added |
| TNYX-225-G3 | P3 | Fixed in task brief; re-review pending | Machine-specific absolute package-cache path was committed | `f99534f` | Replaced with portable locked-package source wording |
| TNYX-225-G4 | P2 | Fixed proactively; re-review pending | Nested `NutritionSnapshot` accepted unsupported integer schema versions | fix pass | Decoder now requires nutrition snapshot schema version 1; regression added |

## 7. Final Handoff

### Changed Files

- `apps/features/nutrition/lib/src/data/repositories/supabase_meal_text_parse_repository.dart` (new)
- `apps/features/nutrition/lib/src/data/data.dart`
- `apps/features/nutrition/test/data/supabase_meal_text_parse_repository_test.dart` (new)
- `apps/app/lib/app/network_providers.dart`
- `apps/app/test/app/network_providers_test.dart`
- `.ai/tasks/tnyx-225-flutter-remote-meal-text-parser-supabase-adapter.md` (new)

### Actual Behavior

`SupabaseMealTextParseRepository` calls the merged `nutrition-meal-text-parse` contract with a bounded 50s client abort budget, decodes strictly (including optional `mealName` typing and nested nutrition schema version), and never lets a raw transport/provider detail escape the `MealTextParseFailure` boundary. `apps/app` composition selects it only when a Supabase client is available and otherwise exposes `null` — there is no fake/in-memory production parser. No UI, schema, RLS, RPC, or Edge Function file was touched.

### Known Limitations

- Live authenticated integration against the deployed Edge Function has not run and cannot run: `nutrition-meal-text-parse` is currently NOT DEPLOYED. This is an explicit, separate deployment gate, not a defect in this slice.
- TNYX-226 (Add Food UI consumption of this capability) is intentionally untouched.

### Final Status

`REVIEW FIXES APPLIED — EXACT-HEAD CI / RE-REVIEW PENDING`
