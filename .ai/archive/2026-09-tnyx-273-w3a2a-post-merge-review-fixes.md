# TNYX-273 W3A2a-F1 — Post-merge catalog integration review fixes

**Status:** Validated
**Completion date:** 2026-09-25
**Primary owner:** `apps/features/workout` (catalog data/source boundary) + canonical docs
**Affected platforms:** Flutter consumers of the Workout feature package; no UI or routing change

## Owner Approval and Scope Boundary

**Trigger:** None — review-finding fixes inside the already approved W3A2a scope
**Approval status:** Approved
**Approval evidence:** On 2026-09-25 the owner explicitly authorized this bounded follow-up for the two valid post-merge findings on PR #339, through Draft PR (#340). A later owner prompt on the same day authorized the Draft → Ready transition and the exact-head pre-merge gate; the PR #340 squash merge, post-merge reconciliation and brief archive were then separately authorized the same day.
**Approved product/UI/data-shape boundaries:** reconcile stale W3A2a docs; narrow missing-asset exception classification; exception-boundary tests; reply to PR #339 threads after the Draft PR exists.
**Explicit non-changes:** no W3A2b (TNYX-272), Exercises UI, route/router, Library, Workout Home, Supabase, catalog schema/content change, media, icons, standards, merge, PR #339 thread resolution before merge, brief archive or branch deletion.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Independent exact-head review by the task agent plus owner-account reviews; Codex (supplemental; usage-limited, no review)
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-25 after the post-merge sync; GitHub `main`, `origin/main` and local `main` all at `359e24ffcc29c57a242c435351e5ac8c35c0ab7e`
**Branch:** `tnyx/tnyx-273-w3a2a-f1-post-merge-catalog-integration-review-fixes` (merged; retained, deletion separately gated)
**HEAD SHA:** merged PR head `48ddbfa6d302012d262d5e2715b69b7ef4375649` on base `a023730f`; squash merge commit on `main` `359e24ffcc29c57a242c435351e5ac8c35c0ab7e` (GitHub-verified; merge tree identical to reviewed head)
**Observed working-tree state:** Not applicable (slice complete)
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:** [PR #340](https://github.com/im-tnyx/tio-world/pull/340) merged 2026-09-25T08:34:33Z (squash). Linear TNYX-273 `Done` (set by the GitHub integration on merge; moved to `In Review` manually at Ready). Parent TNYX-270 stays `In Progress`; TNYX-272 stays `Backlog`. The PR #339 R4/R5 threads were replied to and resolved after this merge.
**Current implementation state:** Validated. Canonical docs match the shipped W3A2a boundary, and source failures are distinguishable as missing asset, generic asset load failure, invalid document, unsupported schema and invalid rows.
**Relevant execution surface:** `apps/features/workout/lib/src/{data,domain}/exercises/`, `apps/features/workout/test/data/exercises/`, `docs/MODULE_OWNERSHIP.md`, `docs/screens/exercise-search.md`
**Validation completed at SHA:** exact-head CI PASS (Commit attribution guard, Attribution guard runner, Analyze and test) on fix commit `45e43df8`, on governance-only commits `2f02840a` and `48ddbfa6`, and on merged head `48ddbfa6`, with 0 unresolved review threads at merge. GHAS failed before analysis (`CAPIError: 400` unsupported model, TNYX-256 outage; no security pass claimed). Local, on the working tree before the fix commit (2026-09-25) — Dart format PASS (0 changed); Workout `flutter analyze` PASS; focused Exercise tests PASS (63); full Workout tests PASS (82); `git diff --check` PASS
**Validation remaining:** None.
**Current blocker:** None
**Open review finding IDs:** None (R4/R5/R6/R7 resolved; PR #339 threads resolved after merge)
**Next exact action:** None for W3A2a-F1 (archived). W3A2b (TNYX-272) needs explicit owner approval to start.

## Global UI / Design-System Guardrail

No production UI or visual change is in scope.

## 1. Discovery

### User Outcome

Canonical docs describe the shipped W3A2a catalog boundary truthfully, and the catalog source reports "missing asset" only when Flutter actually reported the asset as absent.

### Success Criteria

- R4: no canonical doc claims the asset path/loader/schema are deferred or unshippable; W3A2b/W6A/media/standards remain described as pending/out of scope.
- R5: non-missing `FlutterError` never becomes `MissingExerciseCatalogAssetException`; raw framework errors are wrapped in a typed source failure.

### Scope

Source PR #339 (merge `a023730f`) findings:

- **R4 (P2)** stale docs — `docs/MODULE_OWNERSHIP.md:41`, `docs/screens/exercise-search.md:65`.
- **R5 (P2)** `FlutterError` over-classification in `AssetBundleExerciseCatalogSource`.

### Non-Goals

W3A2b, UI/routing, Library, Supabase, catalog content/schema, media/icons/standards. ADR-0011 is a point-in-time decision record ("deferred to W3") and is not rewritten.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `asset_bundle_exercise_catalog_source.dart` catches every `FlutterError` as missing (current `main`). Flutter 3.44.6 `asset_bundle.dart`: `PlatformAssetBundle.load` throws `FlutterError.fromParts([ErrorSummary('Unable to load asset: "<key>".'), ErrorDescription('The asset does not exist or has empty data.')])` for absent/empty assets; `NetworkAssetBundle` (HTTP status) and `loadBuffer` failures reuse the same summary with a different description. No typed not-found exception exists.
- Existing pattern to follow: typed source exceptions in `exercise_catalog_source_exceptions.dart` with `assetKey`/`cause`/`stackTrace`.
- Tests or validation already present: decoder and source tests from W3A2a, including real registered package-asset tests.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Missing = exact Flutter not-found diagnostics for this key; other `FlutterError` → new `ExerciseCatalogAssetLoadException` | Made | Only supported runtime signal; wording drift degrades to generic load failure, never to a false "missing"; real `rootBundle` test detects drift | Agent |
| Non-`FlutterError` failures keep propagating unchanged | Made | Preserves W3A2a R2 decision: programming errors must not be relabelled | Agent |

## 4. Architecture Design

### Chosen Approach

`AssetBundle.loadString` → on `FlutterError`: missing-asset diagnostics → `MissingExerciseCatalogAssetException`; otherwise → `ExerciseCatalogAssetLoadException`. Decoder/parser boundaries unchanged.

### Ownership and Data Flow

```text
Workout asset → injected AssetBundle source → document decoder → W3A1 parser → ExerciseCatalog
```

### Alternative Rejected

- Single generic load exception for every `FlutterError`: drops the approved "missing catalog" distinction.
- Summary-only matching: also matches HTTP/buffer failures.

### Failure and Accessibility States

Source failures: missing asset, generic asset load failure, invalid document, unsupported schema, invalid rows.

## 5. Implementation Plan

- [x] R5: narrow classification, add `ExerciseCatalogAssetLoadException`, update repository contract doc.
- [x] R5 tests: real missing asset, non-missing `FlutterError`s, unchanged valid/malformed behavior.
- [x] R4: reconcile the two stale docs.
- [x] Validate, commit, push, Draft PR, reply to PR #339 threads.

## 6. Quality Review

### Validation Run

```text
dart format <touched Dart files>                                   PASS (0 changed)
cd apps/features/workout && flutter analyze                        PASS (No issues found)
cd apps/features/workout && flutter test test/data/exercises test/domain/exercises
                                                                    PASS (63 tests)
cd apps/features/workout && flutter test                            PASS (82 tests)
git diff --check                                                    PASS
asset / pubspec / apps/app / apps/core changes                      0 files
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R4 | P2 | Resolved | Canonical docs still describe the catalog asset path/loader/schema as deferred and unshippable | `8f18c652` (PR #339) | `MODULE_OWNERSHIP.md` and `exercise-search.md` now describe the shipped asset, registration, envelope decoder, AssetBundle source and W3A1 parser; W3A2b/W6A/media/standards stay pending or out of scope |
| R5 | P2 | Resolved | Every `FlutterError` mapped to `MissingExerciseCatalogAssetException` | `8f18c652` (PR #339) | Missing only for Flutter's exact not-found diagnostics for this key; other `FlutterError` → `ExerciseCatalogAssetLoadException`; real `rootBundle` missing-key test plus 3 non-missing tests |
| R6 | P2 | Resolved | Brief/Linear disagreed with the live Ready state (Ready listed as out of scope, CI listed as remaining, TNYX-273 `In Progress`) | `45e43df8` (PR #340 review) | Owner-authorized Ready recorded, CI evidence recorded, TNYX-273 moved to `In Review`; governance-only change |
| R7 | P3 | Resolved | Brief still listed exact-head CI as remaining after `2f02840a` passed it | `2f02840a` (PR #340 review) | Evidence now tied to the exact SHAs `45e43df8`/`2f02840a`; later brief-only heads defer to PR checks, so the line does not self-reference |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-273-w3a2a-post-merge-review-fixes.md`
- `apps/features/workout/lib/src/data/exercises/asset_bundle_exercise_catalog_source.dart`
- `apps/features/workout/lib/src/data/exercises/exercise_catalog_source_exceptions.dart`
- `apps/features/workout/lib/src/domain/exercises/exercise_catalog_repository.dart` (doc contract only)
- `apps/features/workout/test/data/exercises/asset_bundle_exercise_catalog_source_test.dart`
- `docs/MODULE_OWNERSHIP.md`
- `docs/screens/exercise-search.md`

### Actual Behavior

Source failures are distinguishable as missing asset, generic asset load failure, invalid document, unsupported schema and invalid rows. Non-`FlutterError` failures still propagate unchanged. Catalog content and the valid/malformed load behavior are unchanged.

### Known Limitations

Missing-asset detection depends on Flutter's diagnostic text because no typed not-found error exists. If that text drifts, failures degrade to `ExerciseCatalogAssetLoadException`, and the real-bundle test fails in CI.

### Final Status

`Validated` — merged via PR #340 (`359e24ff`). Archived 2026-09-25.
