# Workout Superset Composition, Execution, and Scrolling

**Status:** Review — source implementation is complete; required validation is incomplete
**Primary owner:** `apps/features/workout` with `supabase/` for Routine persistence
**Affected platforms:** Flutter phone app; Supabase Postgres source/tests

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product feature; product-visible Routine and Log Workout UI; Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner response `PLEASE IMPLEMENT THIS PLAN` to the complete Superset architecture and implementation plan. Earlier owner choices accept unequal ordinal rounds, shared Normal/Warm-up pair with Warm-up winning mixed rounds, group-block Routine reorder, and freezing active membership after the first completed/skipped set.
**Approved product/UI/data-shape boundaries:** Superset group identity with 2–3 Routine exercise members; one group-owned rest pair; nullable Routine exercise membership; Create/Edit grouping and block reorder; Save-only workout round timer; snapshot/history preservation; default-OFF owner-scoped Smart Superset Scrolling. The approved relational design uses a Routine Superset parent record and a nullable `superset_id` on Routine exercises. Rest wheel limits reuse the existing OFF or 5-second increments through 600-second behavior.
**Explicit non-changes:** No hosted migration apply, deployment, Linear/GitHub updates, merge, new protected backend, legacy online-session execution changes, Wear OS/watchOS implementation, separate countdown engine, individual rest-value rewrite, or broad redesign. Owner subsequently authorized committing and pushing this task branch; no PR was requested.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Previous agent:** Not applicable
**Last commit agent:** Codex
**Last commit SHA:** `09772a91` (Superset implementation slice)
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Git root `G:/projects/Tio-World`; clean at `b2c3f5d0` before this brief; `git status` rechecked with `core.fsmonitor=false`.
**Branch:** `tnyx/workout-superset`, pushed and tracking `origin/tnyx/workout-superset` after the owner explicitly requested branch commit/push.
**HEAD SHA:** `e06758ff` at verified initial push; this closeout handoff update follows it.
**Observed working-tree state:** Superset implementation and task handoff commits were pushed; this final publication record is being committed and pushed separately. No PR was requested or created.
**Observed uncommitted/dirty files:** This new task brief only at creation.
**PR / tracker:** No Superset child issue or PR verified. Linear TNYX-87 is Backlog and blocked by TNYX-78. Linear TNYX-81 is Backlog and blocked by TNYX-78/TNYX-80. GitHub #48 remains open and its description says planning-only; its W10-C comments still describe pre-merge review status. The current PR #755 is closed/merged at `b2c3f5d0c280d4c213bbcc2b5ec782dfc633e901`, matching this checkout's `main` HEAD. The owner's explicit chat approval authorizes this Superset implementation; tracker records were not changed.
**Current implementation state:** Routine grouping, versioned RPC persistence, Save-only draft and shared round timer, snapshot/History Edit metadata preservation, local default-OFF Smart Scrolling, tests, additive migrations, and documentation reconciliation are committed and pushed. Flutter/Dart/pgTAP/CI validation is still outstanding; the local migration replay stopped at a pre-existing migration before reaching this slice, and nothing was applied to hosted Supabase.
**Relevant execution surface:** `apps/features/workout` Routine composition, encrypted Active Workout draft, Save-only session DTOs, settings and History Edit; `supabase/migrations` and `supabase/tests/database` for owner-secured persistence/validators.
**Validation completed at SHA:** On `tnyx/workout-superset`, `git diff --check` and `git diff --cached --check` passed; implementation commit is `09772a91`. Immediately before push, `origin/main` at `b2c3f5d0c280d4c213bbcc2b5ec782dfc633e901` was an ancestor, parent-to-head diff was task-scoped, and `git diff --check origin/main...HEAD` passed. Remote branch was verified at `e06758ffdd77c748e0823fd71f912aef3bc103c2`. `flutter`, `dart`, and `melos` are not resolvable in the current shell. `supabase db reset --local --no-seed` was attempted with `G:\dev\supabase-cli\v2.121.0\supabase.exe`; replay stopped at the existing `20260824070233_cleanup_legacy_canonical_mirrors.sql` migration with `LOCK TABLE can only be used in transaction blocks`, before either Superset migration. No pgTAP result is claimed.
**Validation remaining:** Focused Flutter/Dart checks, local migration replay and pgTAP, full repository CI, compact-width/theme/accessibility review, and independent source review. The local replay failure prevents meaningful Superset migration validation on this checkout.
**Current blocker:** Flutter/Dart/Melos validation is unavailable in this shell; local Supabase replay is blocked by the pre-existing migration failure above. Hosted schema state is not verified. No hosted migration or PR has been made.
**Open review finding IDs:** None recorded; independent source review remains outstanding.
**Next exact action:** Push this final handoff update to `tnyx/workout-superset`; run the remaining Flutter/Dart and pgTAP checks when their tools are available. Exact-head CI and independent review are still required before any merge.

## 1. Discovery

### User Outcome

Users can group two or three existing Routine or Save-only Log Workout exercises, retain the grouping through persistence/recovery/history, share one round-based Rest Timer, and optionally scroll between Superset sets.

### Success Criteria

- Routine Create/Edit can form, extend, ungroup, reorder, reload, and preserve Superset groups and each exercise's original prescriptions.
- Save-only Log Workout carries groups from Routine or ad-hoc grouping, has one shared timer per completed ordinal round, and safely restores after restart.
- Saved workout snapshots and History Edit preserve valid group metadata without changing performed-set indexes or legacy snapshots.
- Smart Superset Scrolling is local, owner-scoped, default OFF, retryable, and never changes logging data.

### Scope

1. Routine composition domain, atomic save/read adapter, migration/RLS and Create/Edit UI.
2. Save-only draft, shared round Rest Timer, grouping controls, snapshot Save and History Edit compatibility.
3. Workout Settings preference and focus/modal-safe Superset scrolling.
4. Reconcile canonical workout status docs and current task index where verified state is stale.

### Non-Goals

Hosted migration apply/push, real-user/device deployment, tracker writes, unrelated W4/W7/W10 closure, legacy online Active Workout grouping, Watch UI/sync, Superset merge between existing groups, new timer engine, and History grouping UI.

## 2. Codebase Exploration

### Verified Evidence

- `RoutineCompositionEntry` currently owns stable entry ID, Exercise ref and Set entries; snapshots/saves compare ordered entries.
- Routine exercise/set tables are normalized; current atomic RPC checks `auth.uid()`, revision/mutation identity, strict JSON allowlists, custom-exercise ownership and denies direct child writes.
- `RoutineRestTimerPreset` already models Normal/Warm-up; Failure/Drop use Normal; current wheel range is OFF or five-second increments to 600.
- Routine editors reorder individual entries and the options sheet supports Replace/Remove.
- `startFromRoutine()` copies ordered entries into the account-bound encrypted Save-only draft. The draft stores one current rest countdown tied to one exercise/set.
- Save-only DTO writes schema version 2 with `origin='ad_hoc'`; session SQL validators use strict allowlists. Performed sets use exercise/set indexes.
- History Edit reserializes the saved snapshot while existing add/remove/replace actions can change exercise arrays.
- Workout Settings preferences use owner-scoped `SharedPreferencesAsync`, independent load/retry, and safe OFF defaults.
- Live tracker status and current merged PR state conflict with old `.ai/tasks`/screen-document snapshots; exact mismatches are listed in this brief's handoff and will be corrected in canonical local docs.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Unequal set counts | Approved | Ordinal sets form rounds; exhausted members are omitted. | Owner |
| Mixed round timer type | Approved | Any active Warm-up selects Warm-up rest; otherwise Normal. Failure/Drop use Normal. | Owner |
| Routine reorder | Approved | A Superset remains a contiguous movable block. | Owner |
| Active membership change | Approved | Freeze while any group set is completed/skipped; rest edits apply to the next countdown. | Owner |
| Existing groups as selection candidates | Safe default | Do not merge groups; only ungrouped entries or members of the same group are candidates. | Codex |
| Group timer seed | Safe default | Seed from the initiating entry's existing pair; preserve all per-set rest values. | Codex |
| Active group removal after progress | Safe default | Prevent removal/ungroup while progress remains to protect round history; unlog group sets before editing membership. | Codex |

## 4. Architecture Design

### Chosen Approach

- A Routine group is a stable UUID plus a group-owned Normal/Warm-up rest pair. Membership is a nullable `superset_id` on Routine exercise entries; member order comes from contiguous Routine position.
- Add `user_workout_routine_supersets` with owner, routine, stable ID and the two rest values. Preserve current per-set/per-exercise values as the ungrouped state.
- Keep the existing JSONB RPC argument. Accept the new versioned envelope with ordered entries and a `supersets` collection; continue accepting legacy arrays for ungrouped Routines. Reject a legacy-array overwrite when the persisted Routine contains groups.
- Update existing atomic Create/Save/Update paths transactionally; enforce owner, same Routine, exactly 2–3 entries, one group per entry, contiguous member positions, allowed durations, revision and idempotency. RLS allows owner SELECT; writes remain RPC-only.
- In Active Workout, store group IDs/config once in draft/session structures. A shared countdown carries group ID and round index. Count logged or skipped member sets at the same ordinal; unlogging reopens the round and cancels its countdown. Suppress OFF and final-round rest.
- Add `superset_groups` to new schema-v2 Save-only snapshots and their strict validator. Keep v1 compatibility and treat absent group metadata as empty. History replacement preserves membership, additions are ungrouped, and removal dissolves groups below two members.
- Add independent owner-scoped `smart_superset_scrolling_enabled` preference, default OFF. The page observes committed draft state, de-duplicates targets, and defers scroll during input focus/modals.

### Ownership and Data Flow

```text
Routine UI -> Routine controller/domain aggregate -> Supabase composition repository/RPC
Routine -> ActiveWorkoutDraftController -> encrypted account-bound draft/recovery
Draft Save -> Workout snapshot DTO -> owner-authorized existing Save RPC/session snapshots
Workout Settings -> owner-scoped SharedPreferences repository -> Active Workout scroll observer
```

### Alternative Rejected

Storing the shared Normal/Warm-up pair on every exercise duplicates canonical group configuration and permits member timer drift. A parent group record is the smallest normalized owner for one stable group identity and one shared setting.

## 5. Implementation Plan

- [x] Routine group/domain model, versioned payload envelope, additive migration, RLS, RPC validation/idempotency, safe legacy writer guard — source implemented; SQL checks pending.
- [x] Routine Create/Edit menu, eligible selector, empty/capacity state, ungroup/remove/replace semantics and whole-block reorder — source and focused tests added; tests pending.
- [x] Draft serialization/recovery, group transfer and active shared round timer; visible controls and scroll orchestration — source and focused tests added; tests pending.
- [x] Save snapshot-v2 and SQL validator updates; History Edit preserves/dissolves valid groups with no performed-set column — source and focused tests added; DB/Dart checks pending.
- [x] Smart Scrolling preference and progression after member completion and rest finish/skip — source and focused tests added; tests and device review pending.
- [x] Reconcile `docs/screens/workout.md`, `docs/screens/workout-settings.md`, and `.ai/tasks/README.md`; archive merged W8C/W10-B/W10-C handoffs without treating pre-merge states as current.

## 6. Quality Review

### Validation Run

```text
`git diff --check` — PASS. `G:\dev\supabase-cli\v2.121.0\supabase.exe db reset --local --no-seed` — FAIL before the Superset migrations at pre-existing `20260824070233_cleanup_legacy_canonical_mirrors.sql` (`LOCK TABLE can only be used in transaction blocks`). The local reset did not complete and pgTAP was not run. Flutter/Dart/`melos` were not resolvable in the current shell. No hosted migration was run.
```

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Routine groups | Composition model, RPC, Create/Edit | Focused Dart and pgTAP cases added for membership, 2/3 capacity, legacy overwrite guard, RLS and group reload mapping; not run | Not run | Owner/tenant behavior until DB CI passes |
| Shared round timer | Active draft/controller/card | Focused controller/page cases added for unequal rounds, mixed types, skip/unlog, active timer recovery/edit and final-rest suppression; not run | Not run | Real background/device behavior until manual QA |
| Snapshot/history compatibility | DTOs, SQL validators, History Edit | Added grouped Save DTO and History Edit regression cases plus validator pgTAP cases; not run | Not run | Hosted validator/schema not verified |
| Smart scrolling | Settings controller/repository and Active Workout | Added preference isolation/retry/toggle and page observer coverage; not run | Not run | Device accessibility review |
| Visual/accessibility | Routine cards and Active Workout cards | Not run; 320dp, light/dark, labels/touch targets and manual-scroll review remain outstanding | Not run | Physical-device QA not claimed |

### Review Provenance

**Review source / link:** Manual working-tree inspection only; no PR exists for this slice.
**Reviewer / relation to implementer:** Codex implementation owner
**Diff or commit SHA actually reviewed:** Current uncommitted diff based on `b2c3f5d0`; no commit SHA exists.
**Review result and finding IDs/dispositions:** Two implementation review issues were corrected: independent Settings retry remains visible if Default Rest loading fails, and pending Smart Scroll no longer waits indefinitely for the Workout route to become current. Versioned routine payload validation now requires a numeric schema version.
**Independent review?** No
**Limitations and unmet required gates:** Feature tests/analyze, successful local migration replay/pgTAP, exact-head CI, independent review, and physical-device QA remain pending. Hosted Supabase migration/security advisor not run. The attempted local reset stopped at the pre-existing migration noted above.

## 7. Final Handoff

### Changed Files

Workout domain/controllers/repositories, routine and active-workout UI, Save/History DTOs, and focused tests under `apps/features/workout/`; app route fakes under `apps/app/test/`; additive migrations and pgTAP under `supabase/`; task brief/index and screen docs under `.ai/` and `docs/screens/`. Exact working-tree list is available from `git status`.

### Actual Behavior

Routine Create/Edit supports 2–3 member Supersets with group-block reorder and shared Normal/Warm-up rest settings. Save-only Log Workout copies group metadata into its encrypted draft, advances a shared round timer by logged/skipped set completion, and preserves group metadata through v2 Save snapshots and History Edit. Smart Superset Scrolling is device-local, owner-scoped, default OFF, and defers around focused fields and workout modals. These are source-level implementation claims only; runtime validation remains pending.

### Known Limitations

No external tracker updates or hosted changes. Branch creation was blocked because `.git` is sandbox read-only; source work remains uncommitted on `main`.

### Final Status

`REVIEW` — source implementation is present, but Flutter/Dart and Supabase validation could not be run in this environment; no migration is hosted-applied.
