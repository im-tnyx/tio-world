# TNYX-270 W3A2a — Exercise catalog content/source integration

**Status:** Validated
**Completion date:** 2026-09-25
**Primary owner:** `apps/features/workout` (catalog data/source boundary)
**Affected platforms:** Flutter consumers of the Workout feature package; no UI or routing change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-25 the owner explicitly authorized W3A2a implementation, Draft PR creation and a subsequent independent exact-head review. Ready for Review and the PR #339 squash merge were separately authorized the same day. The owner also attested that catalog/source rights and provenance evidence is retained externally and must not be committed to the repository.
**Approved product/UI/data-shape boundaries:** Workout-owned sanitized/versioned catalog asset; Workout pubspec asset registration; document decoder; injected `AssetBundle` production source composed with the W3A1 repository/parser; production-asset validation tests; focused task/Linear governance; Draft PR.
**Explicit non-changes (initial implementation scope; later lifecycle actions were separately authorized as recorded above):** no Exercises page, visible UI, controller/presentation state, route contract/router wiring, Library or Workout Home entry, Exercise Detail, Favorites, Custom Exercises, Folders, Supabase, standards, remote media, icons, branch deletion, Ready transition or merge. W3A2b remains separate.

### Content provenance governance

Catalog/source rights and provenance were owner-confirmed. Supporting evidence is retained externally by the owner and is not stored in the repository. This is an owner governance attestation, not an independently verified legal-compliance claim. W3A2a ships only the approved sanitized fields and excludes media, standards, icon assets, instructions and provider metadata.

### Protected owner work

The following existing untracked owner paths remain read-only and must not be staged except that `exercises_data.json` may be read as source material for the new sanitized Workout-owned asset:

```text
apps/core/assets/exercises/exercises_data.json
apps/core/assets/exercises/exercise_standard_ids.json
apps/core/assets/exercises/exercise_standards.json
apps/core/assets/ic_body_part/
apps/core/assets/ic_equipment/
apps/core/assets/musclemap/
```

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Exact-head self-review by the task agent (same agent as planning/implementation owner, so not independent); Codex (supplemental), whose Ready-triggered review raised R4/R5
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-25 after the PR #340 post-merge sync; GitHub `main`, `origin/main` and local `main` all at `359e24ffcc29c57a242c435351e5ac8c35c0ab7e`
**Branch:** `tnyx/tnyx-270-w3a2a-exercise-catalog-content-integration` (merged; retained, deletion separately gated)
**HEAD SHA:** merged PR head `8f18c6520ffbcf69c05e9873513f7832db901c39` on base `f5bf3c4f`; squash merge commit on `main` `a023730fa49303f2698dd9676b2c7adddf76759f` (GitHub-verified; merge tree identical to reviewed head)
**Observed working-tree state:** Not applicable (slice complete); protected owner asset directories remain untracked and untouched
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:** [PR #339](https://github.com/im-tnyx/tio-world/pull/339) merged 2026-09-25T07:17:54Z (squash). The GitHub integration moved Linear TNYX-270 to `Done`; it was manually reconciled back to `In Progress` because TNYX-270 is the W3A2 umbrella and W3A2b (TNYX-272, `Backlog`) remains open. Post-merge fixes landed through TNYX-273 / PR #340 (`359e24ff`, `Done`). Parent TNYX-261 stays `In Progress`.
**Current implementation state:** Validated. On `main`: The sanitized/versioned production asset, Workout pubspec registration, document decoder, typed source/document failures, injected `AssetBundle` source and production-path tests are implemented. Self-review findings R1/R2 from `8462ec7c` and R3 from `9399cb7c` are remediated and validated.
**Relevant execution surface:** `apps/features/workout/{assets,lib/src/data/exercises,lib/src/domain/exercises/exercise_catalog_repository.dart (doc only),test/data/exercises,pubspec.yaml}`
**Validation completed at SHA:** R3 doc-contract remediation (working tree on `9399cb7c`) on 2026-09-25 — Dart format PASS (3 files, 0 changed); Workout `flutter analyze` PASS; focused Exercise tests PASS (60); full Workout tests PASS (79); `git diff --check` PASS. Previously at source-remediation SHA `315f8176` — Dart format PASS; Workout `flutter analyze` PASS; focused Exercise tests PASS (60); full Workout tests PASS (79); exact registered production asset load/mapping and sanitization tests PASS; protected-source SHA-256 values unchanged from the provenance audit; commit-attribution guard PASS.
**Validation remaining:** None. Exact head `8f18c652`: Commit attribution guard SUCCESS (only required check), Attribution guard runner SUCCESS, Analyze and test SUCCESS.
**Current blocker:** None. The non-required `github-advanced-security` failure was the external TNYX-256 unsupported-model outage (`CAPIError 400`, no analysis): no real security finding, not a security pass.
**Open review finding IDs:** None (R1/R2/R3 resolved in PR #339; R4/R5 resolved by TNYX-273 / PR #340)
**Next exact action:** None for W3A2a (archived). W3A2b (TNYX-272) needs explicit owner approval to start; its UI contract and route intent are recorded in Linear.

## Global UI / Design-System Guardrail

No production UI or visual change is in scope.

## 1. Discovery

### User Outcome

Workout has one offline-capable production catalog source that loads a sanitized, versioned package asset and reuses the validated W3A1 row-to-domain path.

### Success Criteria

- The production asset contains only the approved W3A1-consumed fields inside schema/catalog version envelope `1`.
- `apps/features/workout` owns and registers the asset.
- An injected `AssetBundle` source loads and decodes the document, then delegates row validation/mapping to `DecodedRowsExerciseCatalogRepository` and `ExerciseCatalogParser`.
- Missing asset, invalid JSON/document, unsupported schema and invalid rows remain distinguishable.
- The exact production package asset loads and maps into a non-empty catalog of `CatalogExerciseRef` values.
- No media, provider URLs, YouTube IDs, standards, icons, instructions or legacy/provider metadata ship.

### Scope

```text
Workout package asset
→ AssetBundle source
→ ExerciseCatalogDocumentDecoder
→ DecodedRowsExerciseCatalogRepository
→ ExerciseCatalogParser
→ canonical ExerciseCatalog
```

### Non-Goals

See **Explicit non-changes**.

## 2. Codebase Exploration

### Verified Evidence

- `DecodedRowsExerciseCatalogRepository` already accepts an async `List<Object?>` reader and delegates to `ExerciseCatalogParser`.
- `ExerciseCatalogParser` and `ExerciseCatalogRowDto` already own consumed-row validation, duplicate-ref rejection and canonical mapping.
- The owner source is a bare array of 101 rows. All rows contain the approved consumed fields; source/media/instruction/standards/provider metadata must be removed from the production asset.
- `apps/features/workout/pubspec.yaml` currently has no asset registration.
- Current main is `f5bf3c4f`; no competing TNYX-270 branch or open PR exists.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use TNYX-270 without another child issue | Approved execution choice | TNYX-270 is already the W3A2 child; the prompt authorizes W3A2a and repo rules do not require another issue | Implementation |
| Source/licence evidence remains external | Owner-attested | Private commercial records must not be committed | Owner |
| Production asset is sanitized and versioned | Approved | Prevent provider/media leakage and establish an evolvable document boundary | Owner |
| Unknown top-level keys are ignored | Approved | Forward-compatible envelope while required/version fields fail closed | Owner |
| Reuse W3A1 row parser unchanged unless correctness requires otherwise | Approved | Avoid duplicate validation truth | Owner |

## 4. Architecture Design

### Chosen Approach

Add a pure `ExerciseCatalogDocumentDecoder` for JSON/envelope validation and an `AssetBundleExerciseCatalogSource` that wraps the existing decoded-row repository. Keep the asset key as one Workout-owned constant.

### Ownership and Data Flow

```text
apps/features/workout asset
→ injected AssetBundle
→ document decoder
→ decoded rows repository
→ W3A1 parser
→ canonical ExerciseCatalog
```

### Alternative Rejected

Registering the raw owner JSON under `apps/core` or reading it directly from widgets is rejected because Core does not own Workout content and it would ship unapproved fields/provider metadata while bypassing the W3A1 data boundary.

### Failure States

Distinct typed failures cover missing asset, invalid JSON/document and unsupported schema. Existing `InvalidExerciseCatalogException` remains the row/catalog failure.

## 5. Implementation Plan

- [x] Generate the sanitized versioned production asset under Workout ownership.
- [x] Register only that asset in the Workout package pubspec.
- [x] Add document/source exceptions and a pure document decoder.
- [x] Add injected `AssetBundle` source and compose it with the W3A1 repository/parser.
- [x] Add decoder/source/real-asset tests, including negative cases.
- [x] Audit protected assets, content leakage and W3A2a-only scope.
- [x] Validate, commit, push, create Draft PR (#339) and run exact-head self-review.

## 6. Quality Review

### Validation Run

```text
G:\dev\flutter-sdk\bin\dart.bat format <5 W3A2a Dart files>       PASS (5 files; final pass clean)
cd apps/features/workout && flutter analyze                        PASS (No issues found)
cd apps/features/workout && flutter test test/data/exercises test/domain/exercises
                                                                    PASS (60 tests)
cd apps/features/workout && flutter test                            PASS (79 tests)
production asset registration/load/document/parser/domain mapping   PASS
production asset safety: URLs/provider/YouTube/legacy metadata      PASS (all zero)
protected owner source hashes                                       UNCHANGED
git diff --cached --check                                           PASS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R1 | P1 | Resolved | Task brief approval/head/review wording was stale and self-contradictory | `8462ec7c` | Handoff now distinguishes authorized gates from completed state, delegates the self-referential current head to Git/PR, and records source-remediation SHA `315f8176` plus the publication blocker |
| R2 | P2 | Resolved | Catching `Object` mislabeled unexpected bundle/programming failures as a missing asset and discarded stack context | `8462ec7c` | Catch narrowed to `FlutterError`, stack retained, unexpected-failure propagation test added; focused/full tests and analyze pass |
| R3 | P3 | Resolved | W3A1 docs still called the asset source/document envelope a "later asset slice", and the `ExerciseCatalogRepository.load()` contract omitted the source/document failures the production source now throws | `9399cb7c` | Comment-only update to the decoded-rows repository, parser and repository contract docs; no behavior change; analyze and focused/full tests rerun |
| R4 | P2 | Resolved | Canonical docs still called the catalog asset path/loader/schema deferred and unshippable | `8f18c652` | Codex thread posted after Ready and still unresolved when PR #339 was merged: the merge gate checked the head but not the review-thread count. Fixed by TNYX-273 / PR #340 (`359e24ff`); thread resolved after that merge |
| R5 | P2 | Resolved | Every `FlutterError` was mapped to `MissingExerciseCatalogAssetException` | `8f18c652` | Same merge-gate miss. Fixed by TNYX-273 / PR #340: missing only for Flutter's exact not-found diagnostics for this key; other `FlutterError` → `ExerciseCatalogAssetLoadException`; thread resolved after merge |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-270-w3a2a-exercise-catalog-content-integration.md`
- `apps/features/workout/assets/exercises/exercise_catalog.json`
- `apps/features/workout/lib/src/data/exercises/`
- `apps/features/workout/lib/src/domain/exercises/exercise_catalog_repository.dart` (doc contract only)
- `apps/features/workout/pubspec.yaml`
- `apps/features/workout/test/data/exercises/`

### Actual Behavior

Workout can load its registered offline package asset through an injected `AssetBundle`, validate the version envelope, reuse W3A1 row validation/mapping and return the canonical non-empty `ExerciseCatalog`. Source/document/schema/row failures remain distinct.

### Known Limitations

W3A2a adds no visible UI or route. W3A2b remains separately gated.

### Final Outcome

- The sanitized, versioned catalog (`schemaVersion` 1, `catalogVersion` 1) ships as a Workout-owned package asset. It contains only approved text fields and no media, instructions, standards, icons or provider metadata.
- Flow: injected `AssetBundle` → document decoder → existing W3A1 parser/repository → canonical `ExerciseCatalog`. There is no second parser, and widgets do not read JSON.
- Owner source assets under `apps/core/assets/` were read only and are untouched. Catalog rights are owner-attested, with evidence retained outside the repository (no independent legal verification).
- Process lesson: a merge gate must require both the expected head and 0 unresolved review threads, and must wait for the Ready-triggered Codex review.

### Final Status

`Validated` — merged via PR #339 (`a023730f`), with post-merge fixes via PR #340 (`359e24ff`). Archived 2026-09-25. TNYX-270 remains `In Progress` until W3A2b (TNYX-272) is complete.
