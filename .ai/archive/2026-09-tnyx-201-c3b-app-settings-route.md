# TNYX-201 C3b — App Settings Hub Route Registration Extraction

**Status:** Validated
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app
**Tracker:** GitHub #392; parent #357 / #260; Linear TNYX-201
**Completed:** 2026-09-26

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** After C3a merge/archive and the fresh next-slice audit, the owner instructed “Go” on 2026-09-26.
**Approved product/UI/data-shape boundaries:** Move only `AppRoutes.appSettings` registration from root `router.dart` into the existing app-owned `routing/routes/settings_routes.dart`, preserving current state/callback/navigation behavior.
**Explicit non-changes:** No Measurement Units, Profile, Profile Avatar, Profile Settings, Nutrition, Wellness, Body or Account route move; no UI, controller/repository ownership, persistence, API, Supabase, schema or navigation redesign.

## Active Handoff

**Planning owner:** current C3b planning/reconciliation session
**Implementation owner:** None active; bounded source implementation is complete
**Review owner:** None; exact-head review completed before merge
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main@4237244867892815dcc4cabb419706a652a00168` after PR #393 squash merge
**Branch:** source `tnyx/tnyx-201-c3b-app-settings-route`; archive `tnyx/tnyx-201-c3b-archive`
**HEAD SHA:** exact reviewed final head `258861d8f1b5eb47bcdf672c943fc760fdf94749`; merged as `4237244867892815dcc4cabb419706a652a00168`
**Observed working-tree state:** Connector/API execution only; no local working tree claimed
**Observed uncommitted/dirty files:** Not applicable / not observable from connector execution
**PR / tracker:** GitHub #392 / #357 / #260; Linear TNYX-201
**Current implementation state:** App Settings hub registration moved verbatim into existing `settings_routes.dart`; root duplicate removed
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/settings_routes.dart`
**Validation completed at SHA:** `258861d8f1b5eb47bcdf672c943fc760fdf94749` — Flutter CI #2808 full PASS; Commit attribution guard PASS; Attribution guard runner PASS; Codex found no major issues; 0 unresolved threads
**Validation remaining:** None for C3b. Archive reconciliation is docs-only.
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** None for C3b. PR #393 is merged and this brief is archived; no next source slice is authorized by this archive.

## 1. Discovery

### User Outcome

Continue router modularization without moving mixed feature workflow/presentation behavior into routing modules.

### Success Criteria

- `AppRoutes.appSettings` is registered by `settings_routes.dart`.
- Root router no longer directly registers the App Settings hub.
- App Mode, Theme, Calendar and Measurement Units navigation behavior remains identical.
- One root `goRouterProvider` / `GoRouter(...)` remains.
- No visible or persistence behavior changes.

### Scope

Only the App Settings hub route registration.

### Non-Goals

Measurement Units; Profile/Profile Avatar/Profile Settings; Nutrition; Wellness; Body; Account; controller/repository ownership; UI; persistence/API/Supabase/schema.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, #260, #357, TNYX-201, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, `docs/ARCHITECTURE.md`, `docs/MODULE_OWNERSHIP.md`, current `router.dart`, current `settings_routes.dart`.
- Current base: `main@ff1a37086cf98d9ce08a14b6e5514e199f91d7e1`.
- `router.dart`: 1252 lines; one root `GoRouter(...)`; one `goRouterProvider`.
- Existing `settings_routes.dart` already owns Settings root, App Mode, Calendar and Theme registration.
- Profile route block is intentionally deferred because it mixes completion reminder, avatar presentation and avatar persistence workflow.
- Measurement Units is intentionally deferred because its route currently includes Profile-backed loading and persistence composition.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Extract whole Profile block next | Rejected | Mixed feature workflow/presentation/persistence; #260/#357 require classification first | C3b audit |
| Move Measurement Units with App Settings | Rejected | It carries load/save composition beyond the stable hub route boundary | C3b audit |
| Move only App Settings hub | Chosen | Stable Settings-owned route composition with existing dependencies already present in `settings_routes.dart` | C3b audit |

## 4. Architecture Design

### Chosen Approach

Extend `buildSettingsRoutes(...)` with the existing App Settings hub `GoRoute`. Keep root `router.dart` as the sole `GoRouter` owner and continue injecting app-owned controllers/state through the builder.

### Ownership and Data Flow

`router.dart` -> `buildSettingsRoutes(...)` -> Settings feature pages/callbacks

### Alternative Rejected

A broad Profile/Settings/Measurement Units extraction was rejected because it would hide unresolved feature ownership and loading/persistence responsibilities inside a route module.

### Failure and Accessibility States

No failure/accessibility behavior changes. Existing App Settings behavior is moved verbatim.

## 5. Implementation Plan

- [x] add existing App Settings route registration to `settings_routes.dart`
- [x] remove only the duplicate root App Settings route block
- [x] audit imports and route references
- [x] verify one-router authority
- [x] run exact-head CI
- [x] independent review
- [x] final exact-head docs-only validation and tracker reconciliation

## 6. Quality Review

### Validation Run

Source/review checkpoint `c66d433fce7661d6270d6cb4712aafa229dc7301`:

- Flutter CI #2807 / run `36243812138`: PASS
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS
- Commit attribution guard: PASS
- Attribution guard runner: PASS
- fresh Codex review: no major issues
- unresolved review threads: 0
- route move audit: App Settings block textually identical apart from indentation
- changed paths: exactly 4 C3b-owned paths
- trailing whitespace/conflict markers: 0
- root `GoRouter(...)`: 1; route-module `GoRouter(...)`: 0
- non-required GHAS failed before analysis because the configured Copilot model returned `400 The requested model is not supported`; no code-scanning finding was produced

Initial CI #2806 failed only because `calendar_preferences.dart` became an unused root import after the route move. Narrow fix `c66d433f` removed only that stale import and the corrected exact-head run passed.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c3b-app-settings-route.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/settings_routes.dart`

### Actual Behavior

App Settings still reads current App Mode, Theme and Calendar preference state and navigates to the same App Mode, Measurement Units and Calendar destinations. Only registration ownership moved to the existing Settings route module. Measurement Units/Profile/Nutrition/Wellness/Body/Account blocks remain root-owned and untouched.

### Known Limitations

Profile and Measurement Units mixed ownership/composition remain intentionally deferred.

### Final Status

`VALIDATED — MERGED VIA PR #393 (42372448)`


## Final Merge Validation

- exact final reviewed head: `258861d8f1b5eb47bcdf672c943fc760fdf94749`
- Flutter CI #2808 / run `36244381925`: full PASS
- Commit attribution guard: PASS
- Attribution guard runner: PASS
- final Codex review: no major issues
- unresolved review threads: 0
- non-required GHAS: failed before analysis because configured Copilot model returned `400 The requested model is not supported`; no code-scanning finding was produced
- PR #393 squash-merged on 2026-09-26 as `4237244867892815dcc4cabb419706a652a00168`
- GitHub #392 closed as completed

## Archive Handoff

C3b is complete. App Settings hub route registration is now Settings-route-module owned while Measurement Units/Profile/Nutrition/Wellness/Body/Account mixed blocks remain intentionally untouched. A future source slice requires a fresh current-main audit and explicit owner authorization.
