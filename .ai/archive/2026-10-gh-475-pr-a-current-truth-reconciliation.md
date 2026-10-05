# GitHub #475 PR-A — Library current-truth reconciliation

**Status:** Validated  
**Completed:** 2026-10-05  
**Primary owner:** Workout Library planning/docs (`apps/features/workout`)  
**Affected platforms:** Planning/tracker reconciliation only; no runtime/UI/Supabase mutation

## Final Handoff

**Outcome:** Validated and merged.  
**Implementation PR:** GitHub #499, squash-merged to `main` as `3c46ab7f58d5f104bcf52afc328502e9f63d140d`.  
**Final reviewed PR head:** `3b11f096e5f907bcf0c729cf119a757d774a8002`.

Final exact-head evidence:

- scope: `4 ahead / 0 behind`, exactly two `.ai/tasks/**` documentation paths;
- Commit attribution guard: PASS;
- Attribution guard runner: PASS;
- Codex exact-head review: “Didn't find any major issues”;
- unresolved review threads: 0;
- PR mergeability before merge: `mergeable=true`, `mergeable_state=clean`;
- GHAS failed before meaningful analysis because the scanner model session exceeded monthly quota (HTTP 402); this is neither a security pass nor vulnerability evidence;
- local `git diff --check` and local post-merge sync were not run or claimed because the session had connector-only repository access.

Post-merge verification:

- `main` points exactly to `3c46ab7f58d5f104bcf52afc328502e9f63d140d`;
- the squash merge commit is signed/verified;
- GitHub #475 remains open for later bounded implementation;
- Linear TNYX-80 remains **In Progress**;
- Linear TNYX-83 and TNYX-267 remain **Backlog** because their W3/W4 dependency gates are still real.

## Durable Reconciliation

PR-A aligned GitHub #475 and tracker handoff with current source/canonical architecture:

- Library already exposes Programs, Exercises, Custom Exercises and Exercise search through shipped canonical routes.
- W3D3 Custom Exercises is shipped through #497/#498 and must not be described as unavailable.
- Programs collection/create is shipped, but Program rows remain display-only and Program detail is not yet a runtime capability.
- Direct Library Create Routine remains gated by a stable/idempotent default `My Program` identity independent of mutable display name.
- TNYX-267 W6B continues to depend on TNYX-81 W4; Library must not invent Program-detail/Routine-composition behavior to bypass that dependency.
- Standalone `Start Empty Workout` / Quick Start was removed from #475 target direction because canonical Workout start requires an explicitly selected saved Routine or scheduled PlannedWorkout/TrainingPlan context.
- Explore, Favorites, Folders and Your Plan remain capability-gated; no placeholder implementation is authorized.

## Tracker Correction

Fresh audit found TNYX-80 W3 incorrectly in Backlog even though W3A had shipped and TNYX-264 W3D was actively In Progress. PR-A reconciled the W3 parent to **In Progress** without claiming unfinished W3B/W3C/W3E acceptance complete.

TNYX-83 W6 and TNYX-267 W6B intentionally remain Backlog.

## Owner Sequencing

The dependency sequence remains:

1. default `My Program` identity foundation;
2. W4 Program detail read foundation;
3. Program-owned Routine create/edit/composition;
4. Library Programs composition;
5. Library `+` actions for capabilities that are actually available.

**Owner sequencing correction on 2026-10-05:** do not start that future sequence yet. First perform a fresh audit of the already-shipped Library / Programs / Exercises UI and fix/polish the existing UI in bounded tracker-backed slices. Resume future #475 capability work only after the current UI is satisfactory.

## Explicit Non-Changes

PR-A did not change:

- Flutter runtime or visible UI;
- routes;
- Program/Routine runtime behavior;
- Active Workout / WorkoutSession semantics;
- Supabase schema, RLS, grants or Storage;
- Explore, Favorites, Folders or Your Plan implementation.

## Canonical References

- GitHub #475
- `docs/screens/library.md`
- `docs/screens/programs.md`
- `docs/screens/workout.md`
- `docs/adr/0015-program-owned-routine-and-program-source-boundary.md`
- Linear TNYX-80, TNYX-81, TNYX-83, TNYX-267
