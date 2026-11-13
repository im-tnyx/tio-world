# W10-C — RPE Tracking Visibility in Save-only Log Workout

**Status:** Validated / merged 2026-11-13 per the checked-in main audit; PR #755 is merged. The pre-merge review snapshot below is historical. Device acceptance is not independently verified here.
**Primary owner:** `apps/features/workout`
**Affected platforms:** Flutter Android and iOS phone

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice and visible Workout Settings / Log Workout change.
**Approval status:** Approved by product owner 2026-11-13 in Tio-world project chat.
**Approval evidence:** "W10-C RPE Tracking ... Default OFF, device-local account-scoped switch; ON ... existing per-Set RPE header/picker ... OFF ... hide but saved RPE data must not disappear ... 320dp responsive, failure/retry ... single-owner ... review-gated PR ... no Supabase change or merge."
**Approved boundaries:** Add one RPE Tracking switch to existing Workout Settings. Missing/malformed preference OFF; store boolean via existing owner-scoped SharedPreferencesAsync repository. Only the Save-only `Log Workout` draft's working RPE header and picker respond to the switch (even at 320dp). Hide is presentation-only, never clears draft, saved RPE or historical values. Settings changes apply live through the existing controller. Read failure stays retryable and must not block workout.
**Explicit non-changes:** No Supabase migration/RPC/RLS/schema/deploy; no cloud sync for the preference, new RPE calculation/scale, legacy online W7B session RPE writes, W8 Completed Workout History Edit, Routine templates, RIR, sound/notification/other Settings, redesign, watch, or PR merge.

## Historical Pre-Merge Handoff

**Planning owner:** Tio-world owner / Linear TNYX-87 / GitHub #48
**Implementation owner:** ChatGPT (sole source writer on focused branch; no second implementation agent)
**Previous agent:** Not applicable — new W10-C child slice.
**Last commit agent:** ChatGPT
**Last commit SHA:** `7d0cb61100de864277a6bbe965d8f539c87a8821` (latest source/test checkpoint before this handoff-only update).
**Review owner:** Independent GitHub reviewer `i-the`; COMMENTED review on earlier head `44243773`, no APPROVED review on current source head. Re-review requested for exact-head findings.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable.
**Repository state last verified:** Remote GitHub main@5ac411c3f9f636192afc2faa0db70bc1813c4101 on 2026-11-13; remote connector only, local Windows checkout `G:\\projects\\Tio-World` not accessible.
**Branch:** `tnyx/w10c-rpe-tracking`
**HEAD SHA:** `7d0cb61100de864277a6bbe965d8f539c87a8821` (verified source/test HEAD before this documentation commit; recheck branch HEAD and CI after update).
**Observed working-tree state:** Local working tree unavailable; no claim of clean checkout.
**Observed uncommitted/dirty files:** Unavailable.
**PR / tracker:** [PR #755](https://github.com/im-tnyx/tio-world/pull/755) OPEN, unmerged; [GitHub #48](https://github.com/im-tnyx/tio-world/issues/48) OPEN; [Linear TNYX-87](https://linear.app/tnyx/issue/TNYX-87) Backlog for broad W10. This approved child does not complete the epic.
**Current implementation state:** Source and focused tests committed; review-gated PR open. Exact source-head CI green; final independent review pending.
**Relevant execution surface:** `WorkoutRuntimeSettingsRepository`, `SharedPreferencesWorkoutRuntimeSettingsRepository`, `WorkoutRuntimeSettingsController`, `WorkoutSettingsPage`, Save-only draft preview in `ActiveWorkoutPage`, existing `WorkoutExerciseCard`, `WorkoutSetInputRow`, `showWorkoutRpeSheet`.
**Validation completed at SHA:** GitHub Actions at source HEAD `7d0cb61100de864277a6bbe965d8f539c87a8821`: Flutter CI #4561 SUCCESS, Android Native CI #626 SUCCESS, Docs Hygiene CI #689 SUCCESS. No local Flutter/Dart commands run by this agent; physical device QA not independently verified. Owner reports emulator UI looks correct.
**Validation remaining:** Recheck CI on documentation-update HEAD; independent final review and disposition of two P2 threads; physical phone QA remains unverified.
**Current blocker:** None for approved child implementation; final release/device QA and independent review remain gates.
**Open review finding IDs:** `PRRT_kwDOTOXwB863AzaA` (320dp width, corrected, unresolved); `PRRT_kwDOTOXwB863BZ3g` (fresh-empty Settings build lifecycle, corrected, outdated/unresolved). Do not resolve without independent disposition.
**Next exact action:** Obtain independent exact-head review, verify post-documentation CI, disposition P2 threads after reviewer verification; no merge.

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
- [x] Add focused tests for preference, retry, visibility, responsive layout, route navigation and picker theme; source-head Flutter CI passed. Physical viewport acceptance remains owner/device QA.
- [x] Reconcile `docs/screens/workout-settings.md` and `docs/screens/active-workout.md`.
- [x] Source-head Flutter, Android Native and Docs Hygiene CI green on `7d0cb611`; PR #755 opened. Independent final review and post-handoff HEAD CI remain pending; no merge.

## Quality Review and Final Handoff

**Validation run:** Source HEAD `7d0cb611`: Flutter CI, Android Native CI, Docs Hygiene CI completed successfully via GitHub Actions. No local/device run claimed. Documentation commit triggers a new HEAD requiring check refresh.
**Review source:** PR #755 Codex P2 threads and `i-the` COMMENTED review at `44243773`; no current-head APPROVED review claimed.
**Final status:** IN REVIEW — implementation/test changes present and source-head CI green; final independent approval and thread disposition pending.

## P2 review remediation — 320dp RPE readability

- Original 320dp RPE-on preview left numeric input fields only about 31dp because PREVIOUS is a 64dp dash placeholder; this was a valid independent P2.
- At phone width <360dp, **only when RPE is ON in Save-only Log Workout**, hide that unavailable PREVIOUS placeholder in both the header and Set rows. This frees width for readable numeric KG/REPS/TIME fields and leaves RPE interactive. At >=360dp and with RPE OFF, preserve existing layout. Routine builders, legacy online Workout and History Edit remain untouched.
- Regression verifies RPE visible, PREVIOUS not rendered, KG and REPS numeric inputs >=60dp at 320dp, and no Flutter exception. New exact-head CI and reviewer disposition pending; no merge.

## Owner-approved W10-C follow-up — Log Workout Settings navigation & RPE option contrast

- **Owner request:** On Log Workout, tapping existing Settings should open Workout Settings; the selected text in the existing RPE bottom sheet must remain readable in the currently selected highlight.
- The feature-owned `ActiveWorkoutPage` accepts an optional `onSettingsPressed` callback, forwarded to both Save-only and legacy Settings buttons. App-owned `shell_route.dart` pushes the existing `AppRoutes.workoutSettings` route; no new page, no nested router, no auth or storage changes. Back returns to the same Workout/draft; changing RPE Tracking updates the current preview through the existing controller listener.
- The RPE slider's selected number now uses semantic `colors.onPrimary` over its semantic `colors.primary` circular fill rather than hard-coded white; unselected numbers keep `colors.textPrimary`. No RPE scale/picker-selection behavior or layout redesign.
- Added feature widget tests for both Settings callback paths, app route navigation/back preserving the Routine-seeded draft and reflecting RPE toggle, and per-theme selected/unselected text foreground checks for Light, Dark and Tio Dark. All tests are **authored, not PASS until exact-head CI runs**.
- No Supabase changes, no merge, no PR duplication. All changes remain on PR #755 review-gated branch.

## CI-driven navigation lifecycle remediation

- New app-router regression initially failed on exact head `78b5504a51b486a56bced48829e957345cd9e8c6`: the test checked `router.routeInformationProvider` for a nested imperative push, which retains the branch root URL by existing go_router behavior; it now checks `GoRouterState.of(WorkoutSettingsPage)` directly.
- The same CI surfaced a **real** `setState() called during build` problem when Settings initialization notified the shared runtime settings controller while the live Save-only preview was still listening beneath the pushed route. The preview now filters unrelated Rest-setting notifications by the actual RPE visibility boolean and defers a genuine RPE-triggered rebuild until after the frame if the framework is currently in its persistent build phase. On controller replacement it re-seeds the observed visibility; disposed previews do not set state.
- No new settings owner/router or data persistence. Re-run exact-head Flutter/Android CI; do not claim PASS yet, do not merge. Original 320dp P2 remains independent-review pending.

## Additional Codex P2 — fresh empty Log Workout Settings

- Automated reviewer requested a **fresh empty Log Workout** regression with **Default Rest still unloaded** before opening Settings, distinct from the Routine-seeded navigation test. The underlying build-phase `setState` fix is at `07be6ce3adc1c5a787cca9a164df0a9d6b9b4879`.
- Added app-router widget regression: `/workout/active?preview=1` starts an empty owner-bound local draft; assert runtime default-rest preference `isReady=false`; tap Settings; assert canonical Workout Settings route, successful default load and no framework exception; Back returns to the exact same empty draft ID with no extra save. No Supabase, no merge.
- Exact-head CI and independent reviewer verification still required.

## Live review reconciliation — 2026-11-13

- Remote PR #755 was verified OPEN and unmerged on source HEAD `7d0cb61100de864277a6bbe965d8f539c87a8821`; 20 changed files before this handoff-only commit. GitHub reports mergeable=true, which does not constitute owner merge authorization.
- Exact source-head GitHub Actions: Flutter CI run `43399859212` SUCCESS; Android Native CI run `43399859115` SUCCESS; Docs Hygiene CI run `43399859117` SUCCESS. Recheck checks on any newer commit before claiming exact-current-head green.
- Two Codex P2 review threads remain unresolved: 320dp input widths (not outdated) and fresh-empty Settings `setState` during build (outdated after fix). Existing source fixes and focused regressions are documented above. Independent reviewer `i-the` commented on earlier head and has not approved the latest source head. Do not self-approve or resolve reviewer threads without verification.
- Product owner reports emulator UI appears correct. This is user-reported emulator acceptance, not independent physical-device validation.
- This update is documentation/handoff reconciliation only; no production UI, Flutter source, Supabase, or merge changes. No local Windows checkout inspected. Follow the one-owner rule for any later source correction.
