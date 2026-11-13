# W10-C — RPE Tracking Visibility in Save-only Log Workout

**Status:** In progress
**Primary owner:** `apps/features/workout`
**Affected platforms:** Flutter Android and iOS phone

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice and visible Workout Settings / Log Workout change.
**Approval status:** Approved by product owner 2026-11-13 in Tio-world project chat.
**Approval evidence:** "W10-C RPE Tracking ... Default OFF, device-local account-scoped switch; ON ... existing per-Set RPE header/picker ... OFF ... hide but saved RPE data must not disappear ... 320dp responsive, failure/retry ... single-owner ... review-gated PR ... no Supabase change or merge."
**Approved boundaries:** Add one RPE Tracking switch to existing Workout Settings. Missing/malformed preference OFF; store boolean via existing owner-scoped SharedPreferencesAsync repository. Only the Save-only `Log Workout` draft's working RPE header and picker respond to the switch (even at 320dp). Hide is presentation-only, never clears draft, saved RPE or historical values. Settings changes apply live through the existing controller. Read failure stays retryable and must not block workout.
**Explicit non-changes:** No Supabase migration/RPC/RLS/schema/deploy; no cloud sync for the preference, new RPE calculation/scale, legacy online W7B session RPE writes, W8 Completed Workout History Edit, Routine templates, RIR, sound/notification/other Settings, redesign, watch, or PR merge.

## Active Handoff

**Planning owner:** Tio-world owner / Linear TNYX-87 / GitHub #48
**Implementation owner:** ChatGPT (sole source writer on focused branch; no second implementation agent)
**Previous agent:** Not applicable — new W10-C child slice.
**Last commit agent:** ChatGPT
**Last commit SHA:** `ff3ff87e5b7cb6477a79cc9867f9b9ea414aea7b` (source/test checkpoint, docs follow-up pending).
**Review owner:** Independent GitHub reviewer `i-the` requested after PR; review not yet performed.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable.
**Repository state last verified:** Remote GitHub main@5ac411c3f9f636192afc2faa0db70bc1813c4101 on 2026-11-13; remote connector only, local Windows checkout `G:\\projects\\Tio-World` not accessible.
**Branch:** `tnyx/w10c-rpe-tracking`
**HEAD SHA:** `ff3ff87e5b7cb6477a79cc9867f9b9ea414aea7b` (latest source/test head before docs-only follow-up).
**Observed working-tree state:** Local working tree unavailable; no claim of clean checkout.
**Observed uncommitted/dirty files:** Unavailable.
**PR / tracker:** No W10-C PR yet; [GitHub #48](https://github.com/im-tnyx/tio-world/issues/48), [Linear TNYX-87](https://linear.app/tnyx/issue/TNYX-87) Backlog/blocked by TNYX-78 for broad W10. This approved child does not change epic status.
**Current implementation state:** Source and focused tests authored in branch; PR review and CI still pending.
**Relevant execution surface:** `WorkoutRuntimeSettingsRepository`, `SharedPreferencesWorkoutRuntimeSettingsRepository`, `WorkoutRuntimeSettingsController`, `WorkoutSettingsPage`, Save-only draft preview in `ActiveWorkoutPage`, existing `WorkoutExerciseCard`, `WorkoutSetInputRow`, `showWorkoutRpeSheet`.
**Validation completed at SHA:** Source/planning metadata audit only. No local Flutter/Dart command run; toolchain unavailable in ChatGPT environment.
**Validation remaining:** Focused controller/repository/widget/routing regressions, current-head Flutter/analyzer/Android/Docs CI, independent PR review, physical phone acceptance.
**Current blocker:** None for approved child implementation; final release/device QA and independent review remain gates.
**Open review finding IDs:** None yet (PR not created).
**Next exact action:** Implement existing-controller-backed boolean and Save-only draft column visibility, then focused tests, reviewed PR, no merge.

## Discovery — verified evidence

- Core Theme `apps/core/lib/src/theme/README.md` and feature `apps/features/AGENTS.md` read. Reuse `TioSettingsValueRow`, `TioGroupCard`, `Switch.adaptive`; do not invent a new design system component.
- W10-A/W10-B use owner-scoped device-local repository/controller with independently loaded optional settings.
- `ActiveWorkoutPage` Save-only preview presently uses `MediaQuery.width >= 360` for RPE column and already calls `ActiveWorkoutDraftController.setRpe` via `showWorkoutRpeSheet`. Its encrypted draft recovery and existing Save DTO map set RPE into `routine_snapshot.exercises[*].prescribed_sets[*].performed_rpe` without new schema.
- Legacy online `_SessionState` has `onRpePressed:null` and no performed RPE persistence; do not change this older session in W10-C. Edit Workout / Workout overall-RPE UI are different capabilities.
- Supabase `tio-world` project `oykupyiitspujzpwwvuj` healthy ap-south-1; public Workout sessions table RLS on, existing JSONB snapshot and overall workout RPE. Metadata check only: no private data read.
- Current `docs/screens/workout-settings.md` and old W10-B handoff say PR #754 is in review, but GitHub verified W10-B merged @main 5ac411c3. Reconcile the directly touched screen spec, preserve older handoff as historical.
- GitHub #48 describes RPE persistence as an unapproved **account-synced candidate**, not an implemented contract; owner's latest explicit approval selects device-local owner-scoped for W10-C.

## Architecture & decisions

`WorkoutSettingsPage` switch → existing owner-bound `WorkoutRuntimeSettingsController` → existing `WorkoutRuntimeSettingsRepository` → same `SharedPreferencesWorkoutRuntimeSettingsRepository` owner-id key. `ActiveWorkoutPage` Save-only preview listens to controller changes and renders existing RPE column/picker if loaded and ON, even at 320dp. Separate independent load/retry fails closed OFF, never blocks Add Exercise/Save, and never erases RPE data. Avoid a copied local boolean in app routing and avoid editing Supabase code.

## Implementation Plan

- [x] Add repository/controller local RPE boolean, independent load/retry and safe save; update existing repository fakes.
- [x] Add RPE Tracking switch with separate read failure/Retry UI on existing Workout Settings page.
- [x] Connect only Save-only Log Workout preview to live preference, remove width-based visibility veto, reuse existing RPE controls; preserve legacy session behavior.
- [ ] Add focused tests: OFF/ON, persistence/restart/account isolation, malformed/failure/retry, live toggle, existing draft RPE retains/reappears, 320dp/390dp accessibility and no overflow.
- [x] Reconcile `docs/screens/workout-settings.md` and `docs/screens/active-workout.md`.
- [ ] Exact-head CI, independent GitHub review-gated PR; no merge.

## Quality Review and Final Handoff

**Validation run:** Not yet. Exact-head CI and reviewer findings must be recorded after actual results.
**Review source:** Pending independent GitHub PR; no approval claimed.
**Final status:** REVIEW — pending implementation/tests and independent review.
