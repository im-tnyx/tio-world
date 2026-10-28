# Exercise catalog expansion and localized instructions

**Status:** Validated
**Primary owner:** Current implementation agent
**Affected platforms:** Flutter phone catalog data boundary and shared pure-Dart Exercise read model

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task / feature slice
**Approval status:** Approved
**Approval evidence:** User request on 2026-10-28 to add localized exercise instructions for the future About Exercise surface and include the newly added records from `G:\exercises\Final update\exercises_data.json`.
**Approved product/UI/data-shape boundaries:** Extend the existing bundled catalog with the owner-source `localizedTitles` and `localizedInstructions` fields, add the 17 source rows absent from the current catalog, and expose the content through the existing canonical `Exercise` read model and Workout parser.
**Explicit non-changes:** No Exercise Detail/About UI or route, no visual redesign, no Supabase schema/data/RLS/grants, no remote API, no new translations beyond the source-provided `en` content, no media URL policy change, and no external tracker mutation.

## Active Handoff

**Planning owner:** Current implementation agent
**Implementation owner:** Current implementation agent
**Review owner:** Self-review; independent review unavailable in this turn
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-10-28
**Branch:** `main`
**HEAD SHA:** `d46c628be163b5f8bcd7311d9574272be5258416` (working tree changes are uncommitted)
**Observed working-tree state:** Existing unrelated untracked `.ai/tasks/issue-567-d3c-deployment-readiness-gate.md` preserved
**Observed uncommitted/dirty files:** `.ai/tasks/issue-567-d3c-deployment-readiness-gate.md` (unrelated, pre-existing)
**PR / tracker:** Linear `TNYX-262` (W3B — Exercise detail) is `Backlog`; this slice prepares its catalog contract but does not implement W3B UI.
**Current implementation state:** Bounded implementation complete and locally validated; no commit, push, PR, or tracker mutation performed
**Relevant execution surface:** `apps/shared/lib/src/workout/`, `apps/features/workout/assets/exercises/`, `apps/features/workout/lib/src/data/exercises/`, focused tests, and exercise catalog docs
**Validation completed at SHA:** `d46c628be163b5f8bcd7311d9574272be5258416` plus the current uncommitted working tree
**Validation remaining:** Independent review, CI, and full monorepo suite are not run
**Current blocker:** None for this bounded local slice
**Open review finding IDs:** None
**Next exact action:** Owner review; implement Linear `TNYX-262` About/Exercise Detail UI only as a separately approved slice.

## 1. Discovery

### User Outcome

The future About Exercise surface can read localized titles and step-by-step instructions from the same canonical bundled catalog, while the latest owner-added exercises are available to the existing Exercises capability.

### Success Criteria

- The bundled catalog contains all `118` owner-source exercise IDs with no duplicates.
- Existing `101` rows preserve their consumed metadata and media exactly; the `17` new rows are added through the same schema.
- `localizedTitles` and `localizedInstructions` are validated at the catalog boundary and mapped into canonical `Exercise` values.
- The catalog remains offline/bundled and `schemaVersion` stays `1`; `catalogVersion` increments for the content contract change.
- No About/Exercise Detail UI, route, persistence, or backend behavior changes.

### Scope

- Extend the pure-Dart `Exercise` contract with immutable localized title/instruction maps.
- Extend `ExerciseCatalogRowDto` validation and mapping with precise `localizedTitles.*` / `localizedInstructions.*` diagnostics.
- Regenerate `apps/features/workout/assets/exercises/exercise_catalog.json` from the explicitly named owner source using only approved catalog fields.
- Update focused parser/asset/shared tests and canonical exercise catalog documentation.

### Non-Goals

- Implementing Linear `TNYX-262` Exercise Detail/About UI or navigation.
- Generating Hindi or other translations not present in the owner source.
- Adding provider/source/standards/goal/tracking metadata to the shipped catalog.
- Changing Supabase, user-created Exercise persistence, media hosting, or Watch behavior.

## 2. Codebase Exploration

### Verified Evidence

- `G:\exercises\Final update\exercises_data.json` contains `118` unique rows; every row has non-empty `localizedTitles` and `localizedInstructions`, currently with `en` content.
- Before implementation, `apps/features/workout/assets/exercises/exercise_catalog.json` contained `101` unique rows at `catalogVersion: 3`; all `101` consumed source fields/media matched the owner source exactly. The implementation now projects all `118` owner rows at `catalogVersion: 4`.
- The current DTO/parser intentionally ignores `localizedTitles` and `localizedInstructions`, and the asset guard currently forbids those keys.
- Linear `TNYX-262` is `Backlog` and explicitly scopes instructions on the shared Exercise detail surface; W3A catalog/data issues are `Done`.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep source locale shape as maps keyed by locale | Made | Preserves the owner source and allows future locale fallback without a second catalog model | Owner/agent |
| Ship only source-provided `en` content | Made | No translation source or approval was provided for additional locales | Owner/agent |
| Keep `schemaVersion` 1 and bump `catalogVersion` | Made | Fields are additive and the existing decoder supports forward-compatible row keys | Agent |
| Do not implement About UI in this slice | Made | Linear TNYX-262 remains a separate Backlog implementation slice | Owner/agent |

## 4. Architecture Design

### Chosen Approach

Keep one catalog file and one canonical `Exercise` model. The Workout row DTO validates the owner-source localization maps and maps them into immutable pure-Dart fields. Widgets and future About UI consume `Exercise`; they do not read JSON directly.

### Ownership and Data Flow

```text
owner source JSON → bundled catalog asset → document decoder → row DTO/parser
→ canonical Exercise localized content → future About/Exercise Detail consumer
```

### Alternative Rejected

- Keeping localization only in presentation or a second detail-specific model: rejected because it would duplicate catalog truth and block reuse by future phone/watch consumers.
- Adding generated or invented translations: rejected because the owner source currently supplies only `en` content.

### Failure and Accessibility States

Malformed locale keys, localized titles, or instruction steps fail the whole catalog with row/field diagnostics. Missing localized content remains a parser error for bundled rows; the future detail surface can still use the canonical display title only for user-created Exercises, which are outside this bundled catalog contract.

## 5. Implementation Plan

- [x] Add immutable localized title/instruction fields to `Exercise` and focused shared tests.
- [x] Add DTO validation/mapping and focused parser tests.
- [x] Regenerate the bundled catalog with all `118` source rows and localization fields; bump `catalogVersion`.
- [x] Update the production asset guard and canonical catalog docs.
- [x] Run focused validation and record exact results.

## 6. Quality Review

### Validation Run

```text
Read-only source/catalog parity: PASS (118 source rows, 118 catalog rows, 118 unique IDs, 0 missing IDs, 0 projection mismatches, 4 approved canonical exerciseType values preserved)
Localization coverage: PASS (118 `en` localized titles and 118 `en` localized instruction arrays)
apps/shared focused analyze: PASS (`dart.exe analyze` on changed shared source/tests)
apps/shared focused test: PASS (`dart.bat test test/workout/exercise_test.dart`; 22 tests passed)
apps/features/workout focused analyze: PASS (`flutter.bat analyze`; no issues found)
apps/features/workout focused tests: PASS (`flutter.bat test test/data/exercises/exercise_catalog_parser_test.dart test/data/exercises/asset_bundle_exercise_catalog_source_test.dart`; 49 tests passed)
git diff --check: PASS
Full monorepo `melos analyze` / `melos test`: NOT RUN
Independent review, CI, and device QA: NOT RUN
```

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| All owner rows are bundled once | catalog asset | 118 source rows, 118 catalog rows, 118 unique IDs, 0 missing IDs | Windows local checkout | Source may change after this snapshot |
| Localization is typed and validated | shared Exercise + Workout DTO/parser | Focused parser, asset-guard, and shared tests passed; 118 `en` title/instruction entries present | Windows local checkout | Future locale fallback/UI remains separate |
| Existing media and metadata are preserved | catalog asset | Projection parity passed with 0 mismatches; only four previously approved canonical `exerciseType` values retained | Windows local checkout | None known |

### Review Provenance

**Review source / link:** self-review
**Reviewer / relation to implementer:** Same agent
**Diff or commit SHA actually reviewed:** `d46c628be163b5f8bcd7311d9574272be5258416` plus current uncommitted diff
**Review result and finding IDs/dispositions:** Self-review completed; no findings identified
**Independent review?** No (self-review)
**Limitations and unmet required gates:** Linear `TNYX-262` UI implementation, independent review, CI, and device proof are outside this slice.

## 7. Final Handoff

### Changed Files

- `apps/features/workout/assets/exercises/exercise_catalog.json`
- `apps/features/workout/lib/src/data/exercises/exercise_catalog_row_dto.dart`
- `apps/features/workout/test/data/exercises/asset_bundle_exercise_catalog_source_test.dart`
- `apps/features/workout/test/data/exercises/exercise_catalog_parser_test.dart`
- `apps/shared/lib/src/workout/exercise.dart`
- `apps/shared/test/workout/exercise_test.dart`
- `docs/architecture/MODULE_OWNERSHIP.md`
- `docs/screens/exercise-search.md`
- `.ai/tasks/exercise-catalog-localization-expansion.md`

The pre-existing unrelated `.ai/tasks/issue-567-d3c-deployment-readiness-gate.md` was preserved and is not part of this change.

### Actual Behavior

The bundled catalog now contains 118 owner-source exercises (17 newly added rows), including immutable `localizedTitles` and `localizedInstructions` content on the canonical `Exercise` model. The catalog remains offline/bundled, keeps `schemaVersion: 1`, and is now `catalogVersion: 4`. The future About/Exercise Detail UI and route remain out of scope.

### Known Limitations

The About/Exercise Detail surface remains unimplemented and tracked separately by Linear `TNYX-262`.

### Final Status

`REVIEW` — bounded local implementation and focused validation pass; independent review, CI, and full monorepo validation remain pending.
