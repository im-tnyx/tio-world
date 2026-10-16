# #526/#564/#569 — Routine 3-dot Core bottom sheet (UI capability slice)

**Status:** In Review — Flutter exact-head CI PASS, independent review and owner device QA pending.
**Primary owner:** Workout feature presentation.
**Affected platforms:** Flutter Android/iOS phone, Program Detail Routine card. No Watch/Supabase changes.

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI/UX change; owner explicitly approved on 2026-10-16: replace the Routine 3-dot anchored popup card with a bottom sheet whose intended options are **Edit Routine, Move Routine and Delete Routine**, while following AGENTS.md. This supersedes the older #524/#526/#564 instruction to preserve an anchored popup. The earlier *Program* 3-dot bottom sheet stays distinct.

**This first bounded implementation:** Replace the Routine card's existing `TioAnchoredPopup` with feature-owned composition of the **existing Core TioSheet, TioGroupCard and TioSettingsNavigationRow**, matching the established Program action sheet pattern. Keep Edit Routine fully functional via its current callback. Add optional Move/Delete **callback slots** to this Routine action surface; show a row only when the owning feature supplies a real callable capability. Do not insert enabled or disabled placeholder rows. Users will see only Edit until the separately gated secure Move and Delete integration is completed.

**Out of scope for this PR:** Actual Move RPC/destination picker and authenticated Move service (#569; still missing), owner-scoped Delete Flutter RPC + auth-cycle/unknown-outcome controller and confirmation (#526; deployed DB contract exists but mobile adapter does not), Create lifetime-limit error (#554), Routine Detail and composer visuals, Library row rights, Program overflow, Workout Start, Notes/Rest, Storage and any DB migration. These will require separate bounded follow-up. No fake buttons.

## Active Handoff

**Planning owner:** GitHub #526/#564/#569; Linear TNYX-81.
**Implementation owner:** This GitHub-connected assistant session, one owner for this UI-only branch.
**Review owner:** Unassigned; independent review requested at PR handoff, not yet received.
**Implementation ownership state:** Handoff pending — implementation owner has supplied the reviewed source/test scope; separate reviewer must inspect before merge.
**Repository state last verified:** Remote GitHub `main@b6f8c6359beca26e6199d2b55c9ae108bc91720d`, no open PRs before branching, backend SQL #578 merged and two migrations owner-deployed/hosted-verified. Windows `G:\\projects\\Tio-World` cannot be inspected or changed by this cloud session (owner last showed clean synced main after db push).
**Branch:** `tnyx/issue-526-routine-actions-bottom-sheet` created from exact verified main.
**Observed working-tree state:** GitHub remote API only; no local working-tree claim.
**PR / tracker:** [Draft PR #581](https://github.com/im-tnyx/tio-world/pull/581), GitHub #526/#564/#569; Linear TNYX-81 remains Backlog with TNYX-78/TNYX-80 blockers.
**Current blocker:** Independent PR review, owner device QA and later real Move/Delete capabilities before showing all three live. Initial head `26360070` Flutter Analyze found invalid const runtime color; implementation commit `9163a521` fixed it. Exact-head `8f45b0bc` CI all PASS: Analyze/Dart, app-workout, nutrition-onboarding, core-wear, aggregated check and both attribution checks.
**Next exact action:** Review current PR #581 exact-head diff as a separate reviewer; resolve concrete findings under implementation-owner handoff; confirm Android light/dark and 320dp physical UI before owner `Go merge`. Do not merge or mark broad #526/#569 complete.

## Discovery / Runtime Evidence

- `apps/features/workout/lib/src/presentation/library/routines/routine_metadata_card.dart` currently exposes a 48dp Routine 3-dot and one real Edit callback through `TioAnchoredPopup`.
- `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart` already composes its Program actions in `showModalBottomSheet` with `TioSheet + TioGroupCard + TioSettingsNavigationRow`.
- `apps/features/workout/lib/src/presentation/library/programs/program_detail_page.dart` supplies real onEdit when current Program Routines are loaded; `inline_program_routines.dart` is read-only and intentionally has no Edit callback.
- `RoutineRepository` has list/create/rename only; hosted Delete RPC `delete_user_workout_routine(uuid,uuid,bigint)` is deployed but Flutter wiring/confirmation is unimplemented.
- `#569` Move is not yet server-capable; cannot simply update `program_id` in a client.
- Root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README, design-system handoff, .ai workflow and issue scopes audited. ADR-0015 preserves Program ownership.

## Architecture and Choices

The card is a presentation-only action dispatcher; it must **not** know Supabase, program UUID ownership, RPC details or Move/Delete business logic. Use optional `VoidCallback?` (Edit, Move, Delete); only render genuinely supplied capabilities. Close the sheet **before** invoking a selected callback. Avoid duplicating the existing Program bottom sheet component and do not create new Core tokens/components without demonstrated reuse.

**Alternative rejected:** Display all three rows immediately with noop/disabled callbacks or directly call SQL from the UI. Both would mislead users or break least privilege.

## Quality / Merge Gate

- [x] Source implements modal in place of anchored popup; title uses selected Routine name and existing Edit callback is preserved. Runtime validation remains pending.
- [x] Source and widget tests assert optional Move/Delete row gating, independent action dispatch, and backdrop dismissal; test execution pending.
- [x] Feature/app widget tests assert Program Detail capability gate and Library read-only behavior; full app-workout CI PASS at `8f45b0bc`.
- [x] Source preserves 48dp trigger, writes narrow/dark widget assertions; device and CI validation pending.
- [x] Exact-head Flutter app-workout test, other shards, aggregate, analyze and attribution CI all PASS at `8f45b0bc`; GitHub compare confirms 12 commits ahead, 0 behind, exactly 7 scoped files.
- [ ] Independent code review and Android physical light/dark/compact QA before merge (not completed).
- [ ] PR moves to **Ready for review** after this handoff and CI recheck; do not merge until separate owner approval, independent review and device gates. No production DDL.

## Final Handoff

**Changed files:** `routine_metadata_card.dart`, `program_detail_page_test.dart`, `workout_exercises_route_test.dart`, `docs/screens/programs.md`, `docs/screens/routine-library.md`, this handoff and task index.
**Validation:** Initial `26360070` Analyze failure identified as a locally introduced invalid `const`; fixed in `9163a521`. Verified complete checks PASS for exact source-head `8f45b0bc`: Flutter Analyze+Dart, app-workout, core-wear, nutrition-onboarding, aggregated Analyze and test, commit attribution and attribution runner. API compare `main@b6f8c635...8f45b0bc` ahead 12 / behind 0, 7 scoped paths. This handoff-only commit requires its own HEAD recheck before merge.
**Known limitations:** Move/Delete callbacks not yet wired to live services, so three-option finished UI is not shipped by this initial surface-only slice.
**Final status:** REVIEW — UI-only slice implemented/tested; independent review/device and product capability follow-ups remain.
