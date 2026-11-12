# Active Workout Screen

Document Status: Canonical Live Doc
Last Verified: 2026-11-12 (W10-A source branch; PR/CI handoff pending)
Owner: `apps/features/workout`
Truth Boundary: Authoritative for Active Workout ownership and intended behavior; source/merge state and device acceptance are recorded separately.

**Surface:** Nested Phone Workout execution flow
**Route:** `/workout/active`
**Primary owner:** `apps/features/workout`
**Status:** The Active Workout route and account-bound local Save-only draft are merged source. Home Play opens an empty ad-hoc draft. Routine Detail `Start Routine` and direct Routine-row Play from Program Detail/expanded Library seed this draft through one guarded flow. W10-A initializes newly added Exercises in the Save-only Log Workout draft from the device-local Default Rest Timer; PR/CI handoff is pending. No distributed release or device acceptance is claimed.

## Purpose

Let the user record a workout from either an empty ad-hoc start or an explicitly selected Routine. Routine Start preloads the Routine name, ordered Exercises, and planned Sets into the same Log Workout screen. The screen keeps planned prescriptions separate from performed values.

## Entry Rule

The Workout Home Play action starts an empty local draft. The Active Workout app-bar title remains `Log Workout` for all entry paths. `Start Routine` appears on Routine Detail, and an outlined Play action appears on owner/session-authorized Routine rows in Program Detail and expanded Library. Each Routine entry reads a current owner-verified composition and copies its title, ordered Exercises and planned Sets into the same local draft. The Routine name pre-fills the editable Save title. If another workout exists, the existing Resume / Start New / Cancel conflict flow applies. Resume keeps the current workout; Start New replaces it before seeding the selected Routine.

Routine Start does not create a W7B server session. Saved history continues to use the current Save-only `origin='ad_hoc'` contract; Routine provenance is not persisted by this slice. A reusable Program itself does not own a scheduled session.

## Target Content

- Session header: selected Routine/PlannedWorkout context, elapsed time, finish/discard action, and truthful save/sync status.
- Ordered exercise list from the selected plan.
- Per-exercise set input for values such as weight, performed reps and completion state. A planned reps range such as `8 - 12` appears in the single `REPS` field as a hint/reference; the actual field remains blank until the user enters reps, and the hint is never logged as performed data.
- Rest timer that is tied to an action only when the configured workout behavior supports it.
- Newly added Exercises receive the current device-local Default Rest Timer once. Their existing Rest Timer control stays editable; explicit OFF persists in the draft and skips subsequent countdowns for that Exercise.
- Exercise information from the selected catalog entry; changing the plan uses an explicit edit flow, not unscoped search.
- Finish review with incomplete-set handling before the session is saved to history.

## Data And State Boundaries

- Workout owns session state, validation, rest timing, completion rules, and repository events.
- A new workout start is held in the account-bound encrypted local draft until the user saves it; a local start alone is not a completed history event or authenticated Save E2E evidence.
- Back/close must offer resume, discard, or save-as-incomplete behavior when safe; it must never lose recorded user input silently.
- Keep loading, invalid/unavailable Routine, timer interruption, failed local save, pending sync, offline, and finish-confirmation states explicit.
- Active-session state is independent from the selected navigation layout. If Workout or Library is hidden/reordered, a persistent shell/Home Resume entry must still reach this canonical session.
- A mode/layout change during a live session preserves recorded input and cannot start a duplicate session. Any destructive discard remains an explicit Workout-owned confirmation.
- Default Rest Timer changes apply only to newly added Exercises. Existing active draft values are not rewritten, and the selected per-Exercise value is recovered through existing `restPreset`/`hasRestOverride` fields.

## Acceptance Criteria

- The selected Routine/PlannedWorkout context is visible and cannot change invisibly mid-workout.
- Set changes have accessible labels, validation feedback, and a clear saved/pending state.
- Finishing produces a Workout-owned history event that can later feed Workout Insights and Progress.
- Home Play remains an empty workout; Routine Detail Start preloads its selected Routine without a server session write.
- Planned rep ranges remain reference hints until actual performed reps are entered and the set is logged.
- Resume from Home, Workout, Library, or persistent chrome restores the same session and saved/pending state.

## Related

- [Workout](workout.md)
- [Program-owned Routines](routine-library.md)
- [Programs](programs.md)
- [Workout Insights](workout-insights.md)
