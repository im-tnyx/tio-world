# GitHub #564 — Routine shared-submit + Detail Edit-row UI parity

**Status:** In progress — first bounded Flutter-only sub-slice
**Primary owner:** Workout feature (`apps/features/workout`)
**Affected platforms:** Flutter Android/iOS phone UI; app-shell routes unchanged

## Owner Approval and Scope Boundary
**Trigger:** Already approved #564 owner-visible corrections.
**Approval status:** Approved for same Create/Edit screen, top Save→Update placement, and Routine Detail Exercises-row action.
**Approval evidence:** Owner 2026-10-15/16 issue #564 decisions and 2026-10-16 explicit `Go` after review.
**Approved product/UI boundaries of THIS sub-slice:** Reuse existing `RoutineComposerScreen` in create/edit modes. Put existing Edit Update action in same top-right app-bar position as Create Save, preserving guards and keys; remove only Edit's duplicate bottom submit. Move existing owner-verified Detail Edit action from app bar to right side of Exercises heading, for nonempty AND historical ready-empty Routines. Preserve counts beneath, preview UI and existing route/refetch.
**Explicit non-changes:** No Routine Name edit yet (currently separate metadata `rename` vs composition-save RPC and cannot falsely claim atomic joint Update). Do not route Routine 3-dot Edit to an editor missing requested editable Name; the Rename-only popup is scheduled for replacement in the follow-up after data-integrity gate. No Delete/Move/thumbnail/Play, backend/SQL/RLS, credentials, Core tokens/geometry, app-shell, wearable or unrelated layout changes.

## Active Handoff
**Planning owner:** Tio-world owner + GitHub #564 / Linear TNYX-81
**Implementation owner:** Current GitHub-connected session; no parallel PR/open implementation branch found on fresh audit.
**Review owner:** Independent Codex bot after CI.
**Implementation ownership state:** Active
**Ownership transition:** New, independent first slice after merged #566; no existing open PR.
**Repository state last verified:** `main@5aec6ef1a90c3cc6afefc66e71f70c54af1b5c1b` matches owner-provided local `main`; GitHub API audit.
**Branch:** `tnyx/issue-564-routine-composer-header-parity`
**HEAD SHA:** Initial parent `5aec6ef1`; refresh exact branch HEAD after commits.
**Observed working-tree state:** Owner reports local clean `main...origin/main`; connector cannot read their Windows worktree. Connected GitHub branch created at verified base.
**Observed uncommitted/dirty files:** None observed in remote branch; local state not independently inspected by connector.
**PR / tracker:** GitHub #564; Linear TNYX-81 (Backlog; blocked by TNYX-78/TNYX-80), GitHub #526 destructive action separate.
**Current implementation state:** Scoped task brief; code changes and tests pending.
**Relevant execution surface:** `routine_composer_screen.dart`, `routine_detail_page.dart`, focused feature widget tests and canonical Routine screen doc.
**Validation completed at SHA:** Baseline audit only; CI pending.
**Validation remaining:** Source test audit, changed-file diff, Flutter Analyze/full Tests at exact SHA, independent Codex review, owner device light/dark and compact-width QA.
**Current blocker:** Atomic name+composition Update requires independently approved owner-safe persistence contract; not part of this UI parity slice.
**Open review finding IDs:** None at start.
**Next exact action:** Implement top Save/Update parity and Detail Exercises-row Edit/empty-ready access; add focused widget assertions, update canonical status, open Draft PR and validate.

## Evidence and Architecture
- Root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README, ADR-0015, canonical `docs/screens/routine-library.md`, W4 handoff, issue #564 and Linear TNYX-81 inspected.
- Shared `RoutineComposerScreen` already exists; Create top `Save`, Edit bottom `Update`. Reuse it, do not create duplicate composer/controller or change form internals in this slice.
- Detail currently renders top app-bar Edit only in ready state; ready-empty uses a different body branch, so move to shared ready-list header and preserve the empty message on index 1.
- Current `RoutineRepository.rename` and `RoutineCompositionRepository.save` are distinct; composition RPC only updates revision/sets. Two client writes are not a safe all-or-nothing replacement. Leave Name editing for explicitly reviewed backend slice.
- `TioAppBar` / `TextButton` reuse existing Core/Material primitives. Routine owner checks, weight-unit availability, in-flight guard and confirmed-refetch semantics must be unchanged.

## Next separate sub-slice
Audit exact secure transactional name+composition semantics, obtain any required owner shape/security approval, expose the saved editable Name in Edit and a safe joint Update, then rewire Program Detail and expanded Library Routine 3-dot directly to the full editor and remove Rename sheet. Routine Delete is independently gated by #526.
