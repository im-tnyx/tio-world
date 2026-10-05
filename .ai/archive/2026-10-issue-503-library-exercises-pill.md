# GitHub #503 — Library Exercises pill alignment

**Status:** Validated
**Completed:** 2026-10-05
**Merged PR:** #504
**Merge SHA:** `c98f771b51337a100d0d79fb7e9e2531343cbbd4`
**Reviewed head:** `6221433735049f14479eb44051eb7fbe8ac4f80d`
**Planning:** GitHub #475, Linear TNYX-264 / TNYX-83 / TNYX-267

## Outcome

PR #504 aligned the shipped Workout Library Exercises category with the owner-approved #475 interaction while keeping Exercise domain/persistence ownership unchanged.

Final shipped Library behavior:

```text
Library
[ Programs ] [ Exercises ]

tap Exercises
→ [ X ] [ Exercises selected ]

[ Create Exercise card ]

[ Exercises card ]
```

- The action surface uses separate standalone `TioCard` entries; `TioGroupCard` is not used.
- Library does not render Exercise rows.
- **Create Exercise** is capability-gated on the durable user-Exercise repository. When available it opens the feature-owned `CreateExercisePage` directly over Library, reusing the existing `CustomExercisesController` and `CustomExerciseEditorPage`.
- `ExercisesPage` is browse/search only and is absent from the Create Exercise back stack.
- Back and successful Save both return to the selected Exercises Library state.
- **Exercises** opens the canonical unified `/workout/exercises` collection containing catalog + user-created Exercises.
- User-created Exercises remain canonical `Exercise` items and use the presentation-only `Custom` tag.
- The stale Library Custom Exercises entry, `customOnly`, `startCreating`, `?create=true`, and app-shell create-query contracts were retired.
- Legacy `?custom=true` no longer creates a Custom-only product surface.
- Favorites/Folders remain capability-gated; when implemented, their Library entries join as separate standalone cards rather than grouped rows.

## Validation

Exact reviewed head `6221433735049f14479eb44051eb7fbe8ac4f80d`:

- Flutter CI `Analyze and test`: PASS.
- Flutter analyze: PASS.
- Dart analyze: PASS.
- Flutter tests: PASS.
- Dart tests: PASS.
- Commit attribution guard: PASS.
- Attribution guard runner: PASS.
- Codex exact-head review: no major issues.
- Unresolved review threads: 0.
- PR mergeable/clean before merge.
- GitHub Advanced Security failed before meaningful analysis with HTTP 402 monthly quota; no security pass and no vulnerability finding were claimed.

Post-merge verification:

- `main` = `c98f771b51337a100d0d79fb7e9e2531343cbbd4`.
- Merge commit signature: verified.
- GitHub #503 auto-closed as completed.
- GitHub #475 remains open.
- TNYX-264 remains In Progress for broader Custom Exercise work.
- TNYX-83 and TNYX-267 remain Backlog.

## Deferred / Separate Work

This slice intentionally did not implement:

- Programs directly on Library / Program-owned Routine UI. Current separate Programs screen remains a known mismatch against #475 and is tracked under TNYX-81 / TNYX-267.
- Your Plan.
- Favorites/Folders behavior.
- Program detail / Routine creation / default My Program.
- Custom Exercise editor field redesign.
- Supabase/schema/RLS/Storage changes.
- Supabase PR summary-bot work.

## Canonical References

- [Library](../../docs/screens/library.md)
- [Exercises and Exercise Picker](../../docs/screens/exercise-search.md)
- [ADR-0015 — Program-owned Routine and Program source boundary](../../docs/adr/0015-program-owned-routine-and-program-source-boundary.md)
- GitHub #475
- Linear TNYX-264 / TNYX-83 / TNYX-267
