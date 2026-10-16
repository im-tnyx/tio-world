# GitHub #538 — Routine Set Type bottom-sheet color parity

**Status:** In progress, source implementation pending CI
**Primary owner:** Workout feature presentation (this branch only)
**Affected platforms:** Flutter Android/iOS phone Routine Create/Edit
**GitHub:** #538; follow-up to merged PR #570
**Linear:** TNYX-81 (parent W4 remains Backlog / blocked by TNYX-78 and TNYX-80)

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI change already owner-approved in 2026-10-16 conversation, with explicit `Go` after read-only audit.
**Approved outcome:** Set Type selection bottom sheets display the *same* Normal/Warm Up/Failure/Drop semantic badge colors as Set rows for both Create and Edit.
**In scope:** feature-owned reusable Set badge presentation; replace plain/missing leading indicators in both selection sheets; preserve contextual Normal numbering, existing selection check and accessibility, and add focused widget regression tests.
**Explicit non-changes:** Set data model, UUID, controller behavior, save/update/auth, rep-range/rest/delete semantics, Core token contracts, shared domain, Supabase SQL/RPC/RLS/deploy, app routing, Watch, AI, exercise cards, other bottom sheets.

## Active Handoff

**Implementation owner:** This GitHub-connected session; only branch `tnyx/issue-538-set-type-sheet-color-parity`.
**Review owner:** Independent GitHub/Codex review required after source, and owner device QA.
**Base source:** `main@42af17a67e84f744ed07cfbc5e66d1fe19f67b41` (merged #570 at `7f05def9`, merged #573 at `42af17a6`).
**Current observed state:** GitHub API source only; Windows worktree and local Flutter SDK unavailable in this session. No claim of local `git status`, `melos`, device rendering or hosted Supabase verification.
**Tracked drift:** #538 text and old #538/#539 stacked PR handoff reflect 2026-10-13 pre-#551 state; present source on main already has durable `RoutineSetType` and sheets. `docs/screens/routine-library.md` still describes merged #570 as Draft. Reconcile only touched documentation relevant to this slice.

## Discovery and Source Evidence

- `create_routine_page.dart::_selectSetType` displays plain leading `1/W/F/D` text, with `1` even when a prospective Normal number is higher.
- `edit_routine_page.dart::_selectSetType` displays no leading type indicator; Edit retains separate `Rest & set details`.
- `routine_set_input_row.dart::_fields` uses `surfaceVariant` 38dp filled, `TioInputTokens.radius` and `textPrimary/primary, warning, danger, info` semantic foreground with >=4.5:1 fallback.
- `routine_set_input_row_test.dart` already protects filled badge geometry and contrast; Create/ Edit page tests cover sheet selection but not its visual semantic parity.
- Reuse `TioEditorSheet` and `showTioEditorSheet` from Core. No new global token/component needed: sheet type visuals are Workout-owned.

## Architecture Decision

Extract the identical existing 38dp Set badge rendering and contrast computation into a small Workout presentation widget consumed by the inline Set row and both Set Type sheet option leading slots. Render leading badges as `ExcludeSemantics` so ListTile labels remain the accessible names. Keep existing option keys, checkmarks, guards and result handling. A candidate Normal badge uses the count of Normal Sets before the selected Set plus one, matching the on-row numbering that would result from conversion.

**Rejected:** independently duplicating semantic switch/contrast logic in Create and Edit, introducing new Core color tokens, or consolidating entire bottom sheets while Edit's extra advanced action differs.

## Validation / Merge Gate

- [ ] Test bottom-sheet label and indicator for all four types, both Create/Edit and selected-state check.
- [ ] Confirm 38dp shape/color/contrast and contextual Normal number in compact light/dark/high-contrast, and no unwanted row visual diff.
- [ ] Preserve Set identity and on-type change, Remove Set and Edit advanced-details paths.
- [ ] GitHub exact-head Analyze Flutter/Dart and Flutter/Dart tests, CI failures investigated.
- [ ] Independent review of exact final head and open threads, parent ancestry/changed-file audit, physical-device owner QA before explicit `Go merge`.

**No merge or deployment authorized by implementation Go.**
