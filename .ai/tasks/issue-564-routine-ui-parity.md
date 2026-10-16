# GitHub #564 — Routine shared-submit + Detail Edit-row UI parity

**Status:** In progress — first bounded Flutter-only sub-slice
**Primary owner:** Workout feature (`apps/features/workout`)
**Affected platforms:** Flutter Android/iOS phone UI; app-shell routes unchanged

## Owner Approval and Scope Boundary
**Trigger:** Already approved #564 owner-visible corrections.
**Approval status:** Approved for same Create/Edit screen, top Save→Update placement, and Routine Detail Exercises-row action.
**Approval evidence:** Owner 2026-10-15/16 #564 decisions, explicit `Go`, and 2026-10-16 clarification: both Create/Edit headers show leading X (replacing Cancel) and left-aligned title; Edit Routine Name must be editable in the shared composer.
**Approved product/UI boundaries of THIS sub-slice:** Reuse existing `RoutineComposerScreen` in create/edit modes. Put existing Edit Update action in same top-right app-bar position as Create Save, preserving guards and keys; remove only Edit's duplicate bottom submit. Use Core `TioAppBar.leading` with accessible X Close instead of left Cancel text and a start-aligned title in both modes; preserve the same cancel, auth and in-flight protections. Move existing owner-verified Detail Edit action from app bar to right side of Exercises heading, for nonempty AND historical ready-empty Routines. Preserve counts beneath, preview UI and existing route/refetch.
**Explicit non-changes:** No Routine Name edit yet (currently separate metadata `rename` vs composition-save RPC and cannot falsely claim atomic joint Update). Do not route Routine 3-dot Edit to an editor missing requested editable Name; the Rename-only popup is scheduled for replacement in the follow-up after data-integrity gate. No Delete/Move/thumbnail/Play, backend/SQL/RLS, credentials, Core tokens/geometry, app-shell, wearable or unrelated layout changes.

## Active Handoff
**Planning owner:** Tio-world owner + GitHub #564 / Linear TNYX-81
**Implementation owner:** Current GitHub-connected session; no parallel PR/open implementation branch found on fresh audit.
**Review owner:** Independent Codex bot after CI.
**Implementation ownership state:** Active — Draft PR #570; no concurrent source owner.
**Ownership transition:** New, independent first slice after merged #566; no existing open PR.
**Repository state last verified:** `main@5aec6ef1a90c3cc6afefc66e71f70c54af1b5c1b` matches owner-provided local `main`; GitHub API audit.
**Branch:** `tnyx/issue-564-routine-composer-header-parity`
**HEAD SHA:** Previous owner-approved header/code checkpoint `2b1ed2339f2387368a70213b34c4e776f6b0172b`, Flutter CI #38852397756 SUCCESS and Codex reported no new major issues at that exact code revision. New Edit SET badge-parity source/test commits `2911abf5` / `424e060e` and canonical doc `dcf5d417` follow, so *their* exact-head CI and Codex re-review are pending. Re-read PR HEAD after this task update.
**Observed working-tree state:** Owner reports local clean `main...origin/main`; connector cannot read their Windows worktree. Connected GitHub branch created at verified base.
**Observed uncommitted/dirty files:** None observed in remote branch; local state not independently inspected by connector.
**PR / tracker:** Draft [PR #570](https://github.com/im-tnyx/tio-world/pull/570); GitHub #564; Linear TNYX-81 (Backlog; blocked by TNYX-78/TNYX-80); GitHub #526 destructive action separate.
**Current implementation state:** Shared composer top-right Save/Update, leading accessible X (replacing Cancel text), Core start-aligned 18sp title in both modes, Detail Exercises-row Edit including ready-empty. Owner identified intentional inconsistency: Create SET number filled Core `surfaceVariant` badge, Edit/PREVIOUS unboxed blue number. Added exact shared `RoutineSetInputRow` background parity (Edit retains blue foreground/PREVIOUS), dark/light 38dp/radius widget regression, and canonical doc clarification. Existing Set data/controller/validation untouched. No backend or editable Routine Name Update; later transactional data-integrity slice required. Latest changes need CI/review.
**Relevant execution surface:** `routine_composer_screen.dart`, `routine_detail_page.dart`, focused feature widget tests and canonical Routine screen doc.
**Validation completed at SHA:** Baseline source/diff audit verified. Earlier test-fixture Analyze failures (missing cancel, invalid const callback, const lint) were corrected. Codex first review at `433587f7` found three remediated historical findings (P1 test cast, P2 handoff and canonical status). Later implementation HEAD `2b1ed233` Flutter CI #38852397756 SUCCESS; Codex reviewed it and reported no new major issues. **This later SET-badge change requires its own exact-head CI/re-review; historical threads still need evidence-based disposition.**
**Validation remaining:** Exact-head Flutter Analyze/full Tests and attribution checks after Edit SET badge parity; Codex re-review of latest change and previous three thread dispositions; owner device light/dark and compact-width QA. No local SDK/worktree run in this GitHub connector session.
**Current blocker:** Owner reconfirmed editable saved Routine Name in Edit; current revision-guarded composition save RPC does not include Name, and `RoutineRepository.rename` is a separate uncoordinated write. Do NOT add an editable Name input in this UI-only PR that cannot be safely persisted with Sets. Next bounded backend/security slice should design a single owner-scoped revision/idempotency-guarded transaction handling name-only and combined Name+Sets, plus unknown outcome and client compatibility tests; exact RPC policy/shape needs its own review before implementation.
**Open review finding IDs:** `PRRT_kwDOTOXwB86tEEfy` (handoff P2), `PRRT_kwDOTOXwB86tEEgC` (canonical status P2), `PRRT_kwDOTOXwB86tEEgJ` (remaining cast P1). Changes landed, not yet re-reviewed or resolved.
**Next exact action:** Verify current PR HEAD/CI after filled Edit SET badge correction; request Codex review of corrected HEAD, reconcile prior three historical threads based on exact evidence, and keep Draft pending owner phone QA and explicit `Go merge`. Next independent gate is transactional editable Name+composition Update followed by full Routine 3-dot Edit; Delete remains separate.

## Evidence and Architecture
- Root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README, ADR-0015, canonical `docs/screens/routine-library.md`, W4 handoff, issue #564 and Linear TNYX-81 inspected.
- Shared `RoutineComposerScreen` already exists; Create top `Save`, Edit bottom `Update`. Reuse it, do not create duplicate composer/controller or change form internals in this slice.
- Detail currently renders top app-bar Edit only in ready state; ready-empty uses a different body branch, so move to shared ready-list header and preserve the empty message on index 1.
- Current `RoutineRepository.rename` and `RoutineCompositionRepository.save` are distinct; composition RPC only updates revision/sets. Two client writes are not a safe all-or-nothing replacement. Leave Name editing for explicitly reviewed backend slice.
- `TioAppBar` / `TextButton` reuse existing Core/Material primitives. Routine owner checks, weight-unit availability, in-flight guard and confirmed-refetch semantics must be unchanged.

## Next separate sub-slice
Audit exact secure transactional name+composition semantics, obtain any required owner shape/security approval, expose the saved editable Name in Edit and a safe joint Update, then rewire Program Detail and expanded Library Routine 3-dot directly to the full editor and remove Rename sheet. Routine Delete is independently gated by #526.
