# Workout Superset Composition, Execution, and Scrolling

**Status:** Review — the initial one P1 and three P2 findings were fixed at `728a126a`; independent review at `dcdc151b` found two additional P2 Active Workout membership issues, fixed at `e6567a84`. Exact-head CI and another independent review are pending. Device acceptance remains outstanding.
**Primary owner:** `apps/features/workout` with `supabase/` for Routine persistence
**Affected platforms:** Flutter phone app; Supabase Postgres source/tests

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product feature; product-visible Routine and Log Workout UI; Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner response `PLEASE IMPLEMENT THIS PLAN` to the complete Superset architecture and implementation plan. Earlier owner choices accept unequal ordinal rounds, shared Normal/Warm-up pair with Warm-up winning mixed rounds, group-block Routine reorder, and freezing active membership after the first completed/skipped set.
**Approved product/UI/data-shape boundaries:** Superset group identity with 2–3 Routine exercise members; one group-owned rest pair; nullable Routine exercise membership; Create/Edit grouping and block reorder; Save-only workout round timer; snapshot/history preservation; default-OFF owner-scoped Smart Superset Scrolling. The approved relational design uses a Routine Superset parent record and a nullable `superset_id` on Routine exercises. Rest wheel limits reuse the existing OFF or 5-second increments through 600-second behavior.
**Explicit non-changes:** No hosted migration apply, deployment, Linear/GitHub issue-status updates, merge, new protected backend, legacy online-session execution changes, Wear OS/watchOS implementation, separate countdown engine, individual rest-value rewrite, or broad redesign. Owner explicitly authorized committing/pushing this branch and opening PR #756; it is currently open and marked ready for review.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Previous agent:** Not applicable
**Last commit agent:** Codex
**Last implementation commit SHA:** `e6567a840728c4e4b573b16071c5e0ce3e622c88` (Active Workout membership fixes and regression tests)
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Git root `G:/projects/Tio-World`; branch `tnyx/workout-superset`; pushed remediation `HEAD` is `e6567a840728c4e4b573b16071c5e0ce3e622c88`.
**Branch:** `tnyx/workout-superset`; review remediation stays on PR #756 with Codex as single implementation owner.
**HEAD / PR state:** PR [#756](https://github.com/im-tnyx/tio-world/pull/756) remains open at pushed remediation head `e6567a840728c4e4b573b16071c5e0ce3e622c88`. All major CI workflows and the Superset SQL matrix passed at reviewed predecessor `5382c15b` (database run `43460417479`). The independent Codex review requested in [PR comment](https://github.com/im-tnyx/tio-world/pull/756#issuecomment-6859964782) reviewed `dcdc151b` and identified two additional P2 findings. At `dcdc151b`, Android, Flutter, Supabase Database, docs hygiene, and attribution jobs passed; `e6567a84` CI and review are pending.
**Observed working-tree state:** Six review findings are fixed: Routine detail group transfer, unrelated rest retention, Create/Edit and Active Workout middle-member ungroup, group-order reconciliation, and incoming member progress eligibility. The first remediation's five focused suites passed 124/124 and full Workout suite passed 1545/1545. After the two new fixes, focused Active Workout suites passed 97/97, full Workout suite passed 1548/1548, and Workout analysis passed locally.
**PR / tracker:** The open PR targets `main`; no Linear or GitHub issue status was changed. At the last tracker snapshot, Linear TNYX-87 was Backlog and blocked by TNYX-78, Linear TNYX-81 was Backlog and blocked by TNYX-78/TNYX-80, and GitHub #48 remained open. Older CI had Flutter and Android Phone failures while the Superset SQL test was not yet in the workflow; `03286872` fixed those Flutter errors and `e777721f` registered the pgTAP test. At `4518b97a`, Flutter, Android Native, docs hygiene, and attribution pass. The SQL file executed all custom assertions without SQL errors but `run_pgtap.sh` rejected the missing TAP plan/output. PR #755 is merged at `b2c3f5d0c280d4c213bbcc2b5ec782dfc633e901`, the current `main` base observed for this branch.
**Current implementation state:** Routine grouping/RPC persistence, Save-only shared round timer and recovery, snapshot/History Edit preservation, default-OFF Smart Scrolling, and the requested selector UI are implemented. The selector title stays pinned while its exercise list scrolls; group markers use the group color, selection uses a check, separators use the 0.5-width stroke, and the sheet omits the “already in Superset” subtitle. A single exercise cannot form a group. Log Workout shows a larger colored round dot before the Superset label without a vertical line before the exercise title. Local Flutter validation passes; Flutter and Android CI pass at pushed head `4518b97a`. After assertion split `0977be11`, the SQL test ran through all custom assertions but the pgTAP runner failed because no TAP plan/output was emitted; the current change adds a 17-test plan and TAP outputs. Local database replay failed before this feature's migration, and no hosted migration was applied.
**Relevant execution surface:** `apps/features/workout` Routine composition, encrypted Active Workout draft, Save-only session DTOs, settings and History Edit; `supabase/migrations` and `supabase/tests/database` for owner-secured persistence/validators.
**Validation completed at SHA:** At source commit `03286872fce921939e567a3ac4474a6402af4415`, `flutter analyze` and all `1542` Workout tests passed; `apps/core` `flutter analyze` and all `370` Core tests passed; `apps/app` `flutter build apk --debug` passed. Focused pinned-header, Smart Scrolling, and Create/Edit reorder tests also passed in the full Workout suite. At pushed head `4518b97a2a15c8c3c0459d1a2ac0e26f99d05ad4`, GitHub Flutter CI run `43458108910`, Android Native CI run `43458108984`, and Docs Hygiene CI run `43458108660` passed. Supabase Database CI run `43458108769` passed SQL execution through the Superset assertions but failed the `run_pgtap.sh` wrapper because the file emitted no TAP plan line. SDK: `G:\dev\flutter-sdk` Flutter `3.44.6` / Dart 3.12.2; CI pins Flutter 3.47.9. Local `supabase db reset --local --no-seed`, using `G:\dev\supabase-cli\v2.121.0\supabase.exe`, stopped at pre-existing `20260824070233_cleanup_legacy_canonical_mirrors.sql` (`LOCK TABLE can only be used in transaction blocks`) before either Superset migration. No hosted migration was run.
**Validation remaining:** Verify final exact-head CI, reconcile the next independent Codex review, and resolve the five inline threads only after verification. Device acceptance remains outstanding.
**Current blocker:** Final-head CI and independent review are pending. Local Supabase replay remains blocked by the pre-existing migration failure above; hosted schema state is not verified.
**Open review finding IDs:** Initial Codex review `5894749819` (P2 group-order reconciliation); inline comments `4566042707` (P2 unrelated Rest Timer cancellation), `4566042719` (P1 Start Routine group loss), `4566042726` (P2 Routine middle-member ungroup). Second review `5895353248` added inline comments `4566503452` (P2 Active Workout middle-member ungroup) and `4566503464` (P2 progressed incoming member). All source fixes are pushed; resolve the five inline threads only after final-head verification.
**Next exact action:** Inspect final exact-head checks and the next independent review. Keep PR #756 open and do not merge or apply hosted migrations.

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
- [x] Routine Create/Edit menu, eligible selector, empty/capacity state, ungroup/remove/replace semantics and whole-block reorder — source and focused tests passed in the Workout suite.
- [x] Draft serialization/recovery, group transfer and active shared round timer; visible controls and scroll orchestration — source and focused tests passed in the Workout suite.
- [x] Save snapshot-v2 and SQL validator updates; History Edit preserves/dissolves valid groups with no performed-set column — source and focused tests added; DB/Dart checks pending.
- [x] Smart Scrolling preference and progression after member completion and rest finish/skip — source and focused tests added; tests and device review pending.
- [x] Reconcile `docs/screens/workout.md`, `docs/screens/workout-settings.md`, and `.ai/tasks/README.md`; archive merged W8C/W10-B/W10-C handoffs without treating pre-merge states as current.

## 6. Quality Review

### Validation Run

```text
`G:\dev\flutter-sdk\bin\flutter.bat analyze` in `apps/features/workout` and `apps/core` — PASS. `flutter test` in `apps/features/workout` — PASS (1542 tests); in `apps/core` — PASS (370 tests). `flutter build apk --debug` in `apps/app` — PASS. At pushed head `4518b97a`, GitHub Flutter CI run `43458108910`, Android Native CI run `43458108984`, Docs Hygiene CI run `43458108660`, and commit attribution — PASS. Supabase Database CI run `43458108769` executed the full SQL file without assertion errors, then failed its wrapper because no TAP plan/output was present. The earlier combined assertion at head `e777721f` was split in commit `0977be11`; the current test update adds `plan(17)` and TAP output for each assertion. `git diff --check` passed before the current edit. Local Supabase reset — BLOCKED before the feature migration by pre-existing `20260824070233_cleanup_legacy_canonical_mirrors.sql` (`LOCK TABLE can only be used in transaction blocks`); no local feature pgTAP replay reached. No hosted migration was run.
```

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Routine groups and selector | Composition model, RPC, Create/Edit, `routine_superset_member_sheet.dart` | Full Workout suite passed (1542); empty state, capacity, selection, group color/check affordance, pinned title and independently scrolling list are covered. At `4518b97a`, all 17 custom SQL assertions completed without SQL errors after splitting the save and count checks; the TAP wrapper then failed because the file emitted no plan/output. The current change converts those helpers to pgTAP output. | Flutter `03286872`; DB workflow `4518b97a` | pgTAP output fix awaits CI; local replay stops before feature migration; no device review |
| Shared round timer | Active draft/controller/card | Full Workout suite passed, including unequal rounds, mixed types, skip/unlog, recovery, timer edits, and final-rest suppression | `03286872`, Flutter 3.44.6 | Real background/device behavior until manual QA |
| Snapshot/history compatibility | DTOs, SQL validators, History Edit | Full Workout suite passed. The complete SQL file ran through snapshot/history assertions without SQL errors at `4518b97a`; only the missing TAP plan/output wrapper check failed. Local replay also stops before the feature migration. | Flutter `03286872`; DB workflow `4518b97a` | Hosted validator/schema not verified |
| Smart scrolling | Settings controller/repository and Active Workout | Full Workout suite passed; focused ON/retry behavior included | `03286872`, Flutter 3.44.6 | Device accessibility review |
| Visual/accessibility | Superset sheet and Workout cards | Pinned-header/list-scroll widget coverage passed; 320dp, light/dark, physical labels/touch targets and device review remain outstanding | `03286872`, Flutter 3.44.6 | Physical-device QA not claimed |

### Review Provenance

**Review source / link:** Local implementation review at `03286872`; PR [#756](https://github.com/im-tnyx/tio-world/pull/756) is open and ready for review. Exact-head Flutter, Android, Docs Hygiene, and attribution checks passed at `4518b97a`; Supabase Database CI reached the test but rejected missing TAP plan/output. The current follow-up fixes the runner contract.
**Reviewer / relation to implementer:** Codex implementation owner
**Diff or commit SHA actually reviewed:** `03286872fce921939e567a3ac4474a6402af4415`.
**Review result and finding IDs/dispositions:** Fixed previous CI compile errors (`RoutineCompositionGateway.readSupersets` adapter and Edit Routine entry lookup), corrected Smart Scrolling to defer only for actual editable-text focus, and fixed Create/Edit reorder indices already adjusted by `SliverReorderableList`. Added the requested pinned picker header, group-color markers, compact row spacing, check selection affordance, and single-member prevention. Existing findings about independent Settings retry, pending Smart Scroll route readiness, and numeric payload schema version remain addressed in source and locally tested.
**Independent review?** No
**Limitations and unmet required gates:** The combined three-member assertion was fixed by separating the RPC save and subsequent member count; CI then executed the full SQL test without SQL errors but rejected its missing TAP plan/output. The current follow-up emits a 17-test pgTAP plan and assertion rows. Local migration replay still stops at the pre-existing migration noted above. Independent review and physical-device QA remain pending. Hosted Supabase migration/security advisor not run.

## 7. Final Handoff

### Changed Files

The source fix commit changes 20 files across `apps/core/` and `apps/features/workout/`, including the pinned-header sheet, Superset member selector, Routine controllers, Active Workout UI, tests, and `pubspec.lock`. The follow-up changes `.github/workflows/supabase-db-ci.yml` to run `workout_superset_composition.test.sql`; assertion evaluation is sequential, and the current test update emits TAP results for its 17 assertions. The task handoff is reconciled with the current CI result. The broader feature PR also includes `apps/app/test/`, `supabase/migrations/`, `supabase/tests/database/`, `.ai/`, and `docs/screens/`.

### Actual Behavior

Routine Create/Edit supports 2–3 member Supersets with group-block reorder and shared Normal/Warm-up rest settings. The selector keeps its title pinned while the exercise list scrolls, uses distinct group colors and a check affordance, and prevents single-member groups. Save-only Log Workout copies group metadata into its encrypted draft, advances a shared round timer by logged/skipped set completion, and preserves metadata through v2 Save snapshots and History Edit. Smart Superset Scrolling is device-local, owner-scoped, default OFF, and defers around editable focus and workout modals. Local Flutter analysis/tests and Android debug build passed at `03286872`; Flutter and Android CI pass at `4518b97a`. Supabase Database CI executed the SQL file but failed the TAP wrapper for missing plan/output; the current follow-up fixes that, and device acceptance remains pending.

### Known Limitations

No Linear/GitHub issue-status updates or hosted database changes. Branch `tnyx/workout-superset` and PR #756 are open; PR is ready for review. Hosted Supabase truth remains unverified.

### Final Status

`REVIEW` — local Flutter analysis/tests and Android debug build pass, as do exact-head Flutter, Android, Docs Hygiene, and attribution checks. Supabase Database CI ran the assertions but failed the TAP wrapper because the test emitted no plan/output; the current uncommitted update adds `plan(17)` and TAP-returning helpers. Local replay, independent review, and device acceptance remain outstanding. No migration is hosted-applied.
