# #526/#564/#569 — Routine 3-dot Core bottom sheet (UI capability slice)

**Status:** In progress — GitHub-connected implementation, review/CI pending.
**Primary owner:** Workout feature presentation.
**Affected platforms:** Flutter Android/iOS phone, Program Detail Routine card. No Watch/Supabase changes.

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI/UX change; owner explicitly approved on 2026-10-16: replace the Routine 3-dot anchored popup card with a bottom sheet whose intended options are **Edit Routine, Move Routine and Delete Routine**, while following AGENTS.md. This supersedes the older #524/#526/#564 instruction to preserve an anchored popup. The earlier *Program* 3-dot bottom sheet stays distinct.

**This first bounded implementation:** Replace the Routine card's existing `TioAnchoredPopup` with feature-owned composition of the **existing Core TioSheet, TioGroupCard and TioSettingsNavigationRow**, matching the established Program action sheet pattern. Keep Edit Routine fully functional via its current callback. Add optional Move/Delete **callback slots** to this Routine action surface; show a row only when the owning feature supplies a real callable capability. Do not insert enabled or disabled placeholder rows. Users will see only Edit until the separately gated secure Move and Delete integration is completed.

**Out of scope for this PR:** Actual Move RPC/destination picker and authenticated Move service (#569; still missing), owner-scoped Delete Flutter RPC + auth-cycle/unknown-outcome controller and confirmation (#526; deployed DB contract exists but mobile adapter does not), Create lifetime-limit error (#554), Routine Detail and composer visuals, Library row rights, Program overflow, Workout Start, Notes/Rest, Storage and any DB migration. These will require separate bounded follow-up. No fake buttons.

## Active Handoff

**Planning owner:** GitHub #526/#564/#569; Linear TNYX-81.
**Implementation owner:** This GitHub-connected assistant session, one owner for this UI-only branch.
**Review owner:** Not yet assigned; exact-head independent review required.
**Implementation ownership state:** Active.
**Repository state last verified:** Remote GitHub `main@b6f8c6359beca26e6199d2b55c9ae108bc91720d`, no open PRs before branching, backend SQL #578 merged and two migrations owner-deployed/hosted-verified. Windows `G:\\projects\\Tio-World` cannot be inspected or changed by this cloud session (owner last showed clean synced main after db push).
**Branch:** `tnyx/issue-526-routine-actions-bottom-sheet` created from exact verified main.
**Observed working-tree state:** GitHub remote API only; no local working-tree claim.
**PR / tracker:** GitHub #526/#564/#569; Linear TNYX-81 remains Backlog with TNYX-78/TNYX-80 blockers.
**Current blocker:** Flutter CI/device QA and separate real Move/Delete capabilities before showing all three live.
**Next exact action:** Implement UI-only sheet + tests, create Draft PR, inspect exact-head CI and independent review before merge.

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

- [ ] Verify modal replaces anchored popup; title is selected Routine name and Edit callback opens existing canonical composer.
- [ ] Optional Move/Delete rows only appear when real callbacks are provided; confirm callbacks can dispatch independently; cancel/backdrop never calls any callback.
- [ ] Confirm Program Detail card and Library read-only lack false actions.
- [ ] Verify 48dp overflow trigger, light/dark, 320dp viewport, labels/semantics, unchanged card layout.
- [ ] Focused Flutter tests, analyze, exact-head CI, diff/security review, owner device QA; no green claim without actual evidence.
- [ ] PR remains Draft; do not merge until owner approval and validation gates. No production DDL.

## Final Handoff

**Changed files:** To record at PR review.
**Validation:** Pending.
**Known limitations:** Move/Delete callbacks not yet wired to live services, so three-option finished UI is not shipped by this initial surface-only slice.
**Final status:** PARTIAL — in progress.
