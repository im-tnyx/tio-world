# W10-B — Foreground Rest Timer Vibration

**Status:** In progress — approved by owner, implementation pending
**Primary owner:** `apps/features/workout`
**Affected platforms:** Flutter Android/iOS phones only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice and visible Workout Settings toggle
**Approval status:** Approved (owner's explicit 2026-11-13 instruction in Tio-world project conversation).
**Approved boundaries:** Rest Timer Vibration switch under Workout Settings, default OFF, device-local account-scoped persistence. Best-effort **single vibration per naturally expired rest** in foreground Active Workout. Both current Save-only draft and legacy online session countdown paths. Skip/OFF/Cancel/background must be silent. Reuse Flutter haptic platform API; no new countdown engine.
**Explicit non-changes:** No Supabase change, migration, RLS/RPC, push/cloud preference sync, background service, notification/lock-screen vibration, Wear OS/watchOS behavior, timer sound/volume, Superset, altered rest-countdown semantics, visual redesign, or merging without owner authorization.

## Active Handoff

**Planning owner:** #00 Tio-world / owner
**Implementation owner:** ChatGPT (sole writer of W10-B; not the W10-A owner)
**Previous agent:** Not applicable — new child slice
**Last commit agent:** Not applicable before first commit
**Last commit SHA:** Not yet committed
**Review owner:** Independent GitHub reviewer to be requested after PR
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub remote main `706bcdf4cba238e567b14cdbc2b48b0942abcf9a`, protected; no open PR. Local Windows checkout/worktree **unavailable** from ChatGPT; do not claim local status.
**Branch:** `tnyx/w10b-rest-vibration`
**HEAD SHA:** Base `706bcdf4cba238e567b14cdbc2b48b0942abcf9a`; update after commits
**Observed working-tree state:** Not observable from remote connector
**Observed uncommitted/dirty files:** Not observable
**PR / tracker:** Linear [TNYX-87](https://linear.app/tnyx/issue/TNYX-87); GitHub [#48](https://github.com/im-tnyx/tio-world/issues/48).
**Current implementation state:** Not yet written. W10-A was merged by [PR #753](https://github.com/im-tnyx/tio-world/pull/753) at `706bcdf4`; W10-A `.ai/tasks` and screen docs retain historical pre-merge status.
**Relevant execution surface:** `WorkoutRuntimeSettingsRepository`, `SharedPreferencesWorkoutRuntimeSettingsRepository`, `WorkoutRuntimeSettingsController`, `WorkoutSettingsPage`, `ActiveWorkoutDraftController`, `ActiveWorkoutController`, `ActiveWorkoutPage`, app auth-bound composition and focused tests.
**Validation completed at SHA:** Audit-only source/GitHub/Linear/Supabase metadata, no implementation tests run.
**Validation remaining:** Focused Flutter tests/analyze, exact-head CI, peer review, real Android/iOS phone acceptance.
**Current blocker:** W10 epic TNYX-87 formally blocked by TNYX-78. Owner approved W10-B child specifically; do not close epic or alter dependencies.
**Open review finding IDs:** None (no PR/review yet).
**Next exact action:** Implement bounded W10-B using existing owner-local storage and one-shot per-rest completion semantics; review-gated PR only.

## 1. Discovery

### User Outcome
A user can opt into one device vibration when their active rest naturally finishes while the phone app is foreground; all existing workout operations remain available if preference read or platform feedback fails.

### Success Criteria
- Default OFF. Device-local, authenticated owner-scoped preference persists across restarts, no Supabase writes. Auth cycle invalidates stale controller instances.
- Inactive/unset and malformed preferences fail safely OFF; transient read failure is retryable and never blocks Default Rest, Add Exercise or Save.
- The switch operates in the existing Workout/Hybrid Settings route; Nutrition still gated.
- One-shot natural expiry in **both** draft and legacy runtime; no alert on Skip, cancelled rest, explicit Rest OFF, +/- seconds causing cancellation, background expiry, restore already-expired timer, finished/discarded session or auth transition.
- No repeated buzz across ticks/rebuilds; fresh rest can alert again. Transition while visible and setting ON triggers at most one best-effort system haptic.
- Existing countdown, pause/resume, set entry and Rest Timer overrides unchanged.

## 2. Codebase Exploration

### Verified Evidence
- Source: `apps/features/workout/lib/src/domain/models/active_workout_draft.dart` stores UTC `ActiveWorkoutDraftRest.targetAtUtc` and stable exercise/set IDs. `active_workout_draft_controller.dart` creates/cancels rest on toggle and supports Skip / adjustRest.
- `active_workout_controller.dart` has in-memory `ActiveRestTimerState` and `updateElapsedDuration()` which clears expired rest without exposing a distinct completion event.
- `active_workout_page.dart` has `_StartWorkoutPreviewState` ticker, a controller-listening legacy screen, and Flutter lifecycle observation; separate no-duplicate feedback logic must handle both without creating a new countdown engine.
- W10-A `WorkoutRuntimeSettingsController` and owner-scoped `SharedPreferencesAsync` repository already handle Default Rest Time independently.
- Root `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, `.ai/FEATURE_DEVELOPMENT.md`, canonical ownership/docs and relevant tests inspected on verified main.
- Supabase project `oykupyiitspujzpwwvuj` is target metadata only; no schema change required.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Device-local account scope, default OFF | Approved | Explicit owner W10-B scope | Product owner |
| Foreground natural expiry only; background silent | Approved | No unreliable background notifications | Product owner |
| Both current countdown paths, one-shot | Approved | No duplicate/replayed feedback | Product owner |
| Keep Default Rest independently available on optional vibration read failure | Required engineering behavior | Haptic preference is nonessential | Architecture |
| Built-in `HapticFeedback.vibrate`, no plugin | Provisional scoped engineering choice | Existing Flutter platform API | Implementation owner |

## 4. Architecture Design

```text
WorkoutSettingsPage -> WorkoutRuntimeSettingsController -> WorkoutRuntimeSettingsRepository
                  -> owner-scoped SharedPreferencesAsync (boolean, default OFF)
Rest timer UTC deadline / explicit natural-expiry signal
                  -> one-shot foreground completion gate
                  -> best-effort Flutter HapticFeedback.vibrate
```

Keep completion cause in the owning Workout presentation/controller boundary. No other module owns vibration logic, and preference errors do not block rest countdowns.

## 5. Implementation Plan
- [ ] Preserve W10-A and extend Workout local preferences with separate haptic state/error/retry.
- [ ] One themed Settings switch, error handling and accessibility.
- [ ] Shared per-rest completion gate, draft + legacy runtime wiring and foreground suppression.
- [ ] Add focused controller/repository/widget/lifecycle tests; regression OFF/Skip/Adjust/Restore.
- [ ] Exact-head CI and independent review; no merge.

## 6. Quality Review

**Validation run:** NOT RUN; local Flutter/Dart SDK unavailable in ChatGPT environment. GitHub CI after PR required.

| Criterion | Proposed evidence | Outcome |
|---|---|---|
| Device-local default OFF and auth isolation | Repository/controller + provider tests | NOT RUN |
| One natural expiry vibration, no duplicates | Gate + both countdown tests | NOT RUN |
| Skip/OFF/Cancel/background/restore silent | Focused negative-path tests | NOT RUN |
| Default Rest and Save remain functional on haptic failure | Error independence tests | NOT RUN |
| Phone QA Android/iOS | Real-device acceptance | NOT RUN |

**Review source / link:** Pending independent GitHub PR.
**Independent review?** Not yet.
**Limitations and unmet required gates:** Device QA, exact-head CI and independent reviewer acceptance required.

## 7. Final Handoff

**Changed files:** Pending implementation.
**Known limitations:** Foreground-only phone feedback; OS may suppress haptics; no alarm or scheduled delivery guarantee.
**Final Status:** REVIEW pending implementation/testing and independent review.
