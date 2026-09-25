# TNYX-270 W3A2a — Exercise catalog content/source integration

**Status:** In progress
**Primary owner:** `apps/features/workout` (catalog data/source boundary)
**Affected platforms:** Flutter consumers of the Workout feature package; no UI or routing change

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** On 2026-09-25 the owner explicitly authorized W3A2a through a Draft PR and independently reviewed exact head. The owner also attested that catalog/source rights and provenance evidence is retained externally and must not be committed to the repository.
**Approved product/UI/data-shape boundaries:** Workout-owned sanitized/versioned catalog asset; Workout pubspec asset registration; document decoder; injected `AssetBundle` production source composed with the W3A1 repository/parser; production-asset validation tests; focused task/Linear governance; Draft PR.
**Explicit non-changes:** no Exercises page, visible UI, controller/presentation state, route contract/router wiring, Library or Workout Home entry, Exercise Detail, Favorites, Custom Exercises, Folders, Supabase, standards, remote media, icons, branch deletion, Ready transition or merge. W3A2b remains separate.

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
**Review owner:** Independent exact-head reviewer after Draft PR creation; Codex supplemental only
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-25 after `git fetch --prune origin`; local `main` and `origin/main` both at `f5bf3c4f8aefd176bf393e0bdad8d98ab01abb45`
**Branch:** `tnyx/tnyx-270-w3a2a-exercise-catalog-content-integration`
**HEAD SHA:** `f5bf3c4f8aefd176bf393e0bdad8d98ab01abb45`
**Observed working-tree state:** clean tracked tree before this brief; protected owner asset directories untracked
**Observed uncommitted/dirty files:** protected owner asset directories listed above
**PR / tracker:** Linear TNYX-270 `In Progress`; TNYX-261 `In Progress`; TNYX-269 `Done`; no competing TNYX-270 branch/PR found
**Current implementation state:** Sanitized/versioned production asset, Workout pubspec registration, document decoder, typed source/document failures, injected `AssetBundle` source and production-path tests are implemented locally.
**Relevant execution surface:** `apps/features/workout/{assets,lib/src/data/exercises,test/data/exercises,pubspec.yaml}` and this task brief/index
**Validation completed at SHA:** uncommitted tracked tree on 2026-09-25 — Dart format PASS; Workout `flutter analyze` PASS; focused Exercise tests PASS (59); full Workout tests PASS (78); exact registered production asset load/mapping and sanitization tests PASS; protected-source SHA-256 values unchanged from the provenance audit.
**Validation remaining:** commit, branch attribution guard, push, CI and exact-head independent review
**Current blocker:** None within the approved W3A2a boundary
**Open review finding IDs:** None
**Next exact action:** Complete the staged scope audit, commit/push, open the Draft PR and run exact-head review.

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
- [ ] Validate, commit, push, create Draft PR and run exact-head independent review.

## 6. Quality Review

### Validation Run

```text
G:\dev\flutter-sdk\bin\dart.bat format <5 W3A2a Dart files>       PASS (5 files; final pass clean)
cd apps/features/workout && flutter analyze                        PASS (No issues found)
cd apps/features/workout && flutter test test/data/exercises test/domain/exercises
                                                                    PASS (59 tests)
cd apps/features/workout && flutter test                            PASS (78 tests)
production asset registration/load/document/parser/domain mapping   PASS
production asset safety: URLs/provider/YouTube/legacy metadata      PASS (all zero)
protected owner source hashes                                       UNCHANGED
git diff --cached --check                                           PASS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

Pending final exact-head list after commit.

### Actual Behavior

Workout can load its registered offline package asset through an injected `AssetBundle`, validate the version envelope, reuse W3A1 row validation/mapping and return the canonical non-empty `ExerciseCatalog`. Source/document/schema/row failures remain distinct.

### Known Limitations

W3A2a adds no visible UI or route. W3A2b remains separately gated.

### Final Status

`REVIEW`
