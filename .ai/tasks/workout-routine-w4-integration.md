# W4 Routine Flutter PR consolidation / integration gate

**Status:** In progress / integration review. **Approval evidence:** On 2026-10-14 the owner requested a reduction from many Routine feature PRs, then explicitly said "Go" after the plan to consolidate seven stacked Flutter PRs into one without inventing new PRs. This is **not** approval to merge, deploy, expand the feature, change database schema, or rewrite history.

**Implementation/coordination owner:** current connected GitHub session on existing branch `tnyx/routine-set-boxed-fields-compact-add-set`. Ownership transition: existing W4B1/Create/Set/visual branch implementations are frozen for further edits; this consolidated integration branch owns all fixes to that combined Flutter implementation until handoff. **Independent review owner:** not yet assigned. **Planning:** Linear [TNYX-81](https://linear.app/tnyx/issue/TNYX-81/w4-programs-and-routines-canonical-content-composition-and-builders) remains Backlog, blocked by TNYX-78 and TNYX-80.

## Source and branch baseline
- Root `AGENTS.md`, `apps/features/AGENTS.md`, canonical `docs/screens/routine-library.md`, `docs/architecture/MODULE_OWNERSHIP.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md`, and existing implementation briefs examined. GitHub PR metadata/inline Codex threads, Linear TNYX-81 and actual combined remote diff reconciled.
- **Seven stacked Flutter Drafts:** #533 (W4B1 editor, main) → #537 (Create, #533) → #541 (Set Type/Rep Range, #537) → #544 (Create interaction and blank Reps, #541) → #546 (Detail/Edit grids, #544) → #549 (numeric limits, #546) → **#551** (owner-approved Core `TioButton.supporting` / `TioInput.boxedNumber` and Set visual, #549). Each parent is currently the preceding head; #551 already contains the accumulated Flutter source.
- **Exact remote baseline prior to integration:** `main@ee5ed4cc67bfb6c8d3eb867129578201b60703bc`; child #551 `fea690a8bd19b682ea0dee7076b750c5e6f96f61`; GitHub compare: **ahead 189 / behind 0 / merge-base=main, 55 changed files**. GitHub APIs confirm ancestry and changed-file list; local worktree, `git diff --check`, tests and Flutter SDK are not available here.
- **Do not mix Supabase migrations into Flutter PR:** #536 atomic Create RPC and #540 Set metadata/Range DB changes are independently owned main-based Drafts. Supabase live runtime is not automatically updated by this client branch. No migration is in the observed 55-file Flutter delta. DB roll-out and client compatibility gates remain separate.

## Integration-only scope and decisions
1. Retarget the **existing #551** (not a new PR) from `tnyx/routine-set-input-typing-limits` to `main` **while keeping Draft**. Update PR body/title to reflect *all* Flutter changes, upstream review finding links, broad security/DB gates, and accurate validation. This will make main-targeted Flutter CI eligible to run on the **real** integrated feature head, instead of creating synthetic temporary CI PRs.
2. **Do not close, force-push, merge or delete** #533/#537/#541/#544/#546/#549 solely to lower counts. Their code/review history stays accessible. After integration source is independently validated, original threads' findings are explicitly handled, and user reviews the handoff, mark them superseded and close unmerged one by one.
3. Fix only confirmed integration defects within existing approved scope, with focused tests. Preserve Core component ownership and no separate Workout-specific button/input helpers or feature token bags. No UI redesign beyond existing approval; no new database table/column/RPC.
4. All fixes on #551 branch are integration-owned; do not edit parent/source branches. Changes to authentication route cleanup require specific revocation and capability tests and security review. Do not suppress/skip existing full-suite CI checks.

## Existing release/review blockers
- **P1 data integrity** (inherited [#546](https://github.com/im-tnyx/tio-world/pull/546)): Advanced Set details changes to Reps/Weight leave existing inline controllers stale; later inline editing can silently overwrite saved draft values. Add widget regression for sheet → inline → Update preserving independent fields, including conversion.
- **P2 auth privacy** (#546): Create Exercise Options overlay may survive auth cycle revocation.
- **P2 explicit Rep Range Max** (#544): fixed Reps → Range must leave *new* Max blank and Save disabled until typed, not synthesize `8–8`.
- **P2 reorder accessibility** (#544): add keyboard/screen-reader custom move actions to Create Exercises without restoring visual arrows.
- **CI**: ancestor #537 stale `apps/app/test/app/workout_exercises_route_test.dart` integration test and previous synthetic-only analyzer fixture issues; Flutter Analyze/Tests must run at actual integration head.
- **Security/deploy**: owner-scoped repositories, auth/login-cycle revocation, Supabase #536/#540 protected RPC/columns not deployed, older client compatibility, independent review, device QA, and TNYX-81 dependencies.
- Codex usage limits or exhausted CI are not review approvals. A PR showing `mergeable:true` does not satisfy these gates.

## Checkpoints and exit criteria
- [x] Fresh GH/Linear/source/AGENTS audit (2026-10-14).
- [x] Verify seven Flutter branches all stack and #551 HEAD is ahead of main with no divergence; 55 changed files, no `supabase/` files.
- [ ] Retarget #551 to main Draft; read actual head and start/read Flutter CI.
- [ ] Repair blockers with focused tests and Core/Workout/app boundary review; all high-severity Codex threads accounted for.
- [ ] Flutter Analyze + focused Widget + full suite pass on **exact #551 head**; independent review; 320dp/light/dark/large-text/device QA.
- [ ] Dependency/security/DB deployment readiness and explicit merge decision. No automatic merge.
- [ ] When reconciled, safely close redundant superseded PRs without deleting branches and reflect final status in Linear.

**Validation recorded so far:** remote GitHub metadata/source/diff and review-thread read only. No local git/Flutter execution or successful GitHub CI at the new integration head has been claimed.


## Owner correction checkpoint — 2026-10-14 (single existing PR)

**Approval:** The owner requires shorter boxed fields, Reps/Rep Range Min/Max **at most three digits (0–999 typed; positive persisted)**, one canonical Exercises screen in both browse/selection, and Exercise artwork in Routine screens. The owner separately requires an Exercise AND Set but **optional unfilled Reps/KG** at Create Save; this last requirement is **not yet implemented** because the canonical Dart/hosted SQL contract rejects null Reps. Do not mistake the old `SetPrescription(reps:1)` internal draft placeholder for truthful persistence.

**Implemented on #551, no new PR:**
- Core `TioInput.boxedNumber` now has denser variant-only styling (44dp minimum InputDecoration constraints, smaller governed vertical padding); Core test reflects the approved geometry. Legacy Core inputs remain unchanged.
- Workout Reps/Range Min/Max input formatter rejects more than **3 whole digits**, including paste, without truncation; the Rest field retains its separate int32 cap and Weight retains 6+3 format. Unit/precision and schema int32 guard are not replaced.
- Deleted duplicate `RoutineExercisePickerPage` and removed its public export; Create/Edit route the **existing** `ExercisesPage` with a scoped selection callback and title `Add Exercise`. Normal browsing retains `Exercises` title, filters, search and Custom edit action. Selection reuses `ExercisesController`, the same list row/thumbnail, owner-scoped Custom source and fail-closed readiness; non-pointer browse does not accidentally select.
- Root navigation and widget tests now expect `ExercisesPage`, not the deleted picker. The existing `RoutineExercisePickerController` is **not** a UI screen; retained for canonical Exercise lookup and owner-verified Edit/Detail source resolution. No extra catalog or data storage.
- Create, Edit and Detail resolve artwork from canonical `Exercise.media` with `ExercisesController.thumbnailUrlFor` and reuse `ExerciseThumbnail` (existing text-only fallback). Nullable viewer media gender is supplied by app composition only when the session/profile is verified. No hard-coded image URL or independent network widget.

**Validation truth / known regressions:** Initial CI #38509724461 failed because a nested Riverpod catalog source override violated scope dependencies. Corrected by binding the existing `ExercisesController` to an explicit catalog source within `ExercisesPage` selection context instead of overriding a nested provider. Follow-up CI #38510341736 caught a nullable local controller expression, fixed. CI #38510586889 passed app route and Workout tests but failed a pre-refinement Core boxedNumber padding assertion, corrected in `apps/core/test/ui/components/tio_input_test.dart`. **A new exact-head run is needed before declaring these changes validated.** Never claim pass based on earlier #551 heads.

**Unimplemented backend blocker / owner decision needed:** For a genuinely blank Reps Set to save, shared `SetPrescription`, Create/Edit adapters, `reps NOT NULL`, existing Save RPC and atomic Create RPC (plus old-client compatibility) must all be coordinated. Also, #536 currently allows zero-Set Exercises whereas owner now requires at least one Set. GitHub #536 / #540 have read-only handoff comments; no SQL was edited/deployed. Current `repsMax != null` marks Range mode: when both Min/Max are blank, the schema cannot preserve Range selection without an explicit persisted mode. Decide/approve that representation before touching DB; do not silently degrade range to fixed or store invented 1/0 reps. Combined replay, RLS, idempotency, concurrency and old-client rollout gates remain mandatory.

**Disposition:** Keep #551 and #536/#540 Draft, no merge/production deployment/ancestor cleanup until exact-head CI, independent review, owner-approved nullable Set design, combined DB migration validation and phone QA. 
