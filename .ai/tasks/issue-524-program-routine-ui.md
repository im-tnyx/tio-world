# GitHub #524 — Program-owned Routine UI corrections

**Status:** In progress / manual review queued
**Owner approval:** 2026-10-11 user approved user-visible Routine UI corrections and explicitly moved Program Detail's single Routine-create + to its top app bar, removed redundant Routines heading, requested separate Routine cards, and asked for saved Routine rows under expanded Library Programs. Subsequent 2026-10-11 instruction explicitly authorized proceeding through **manual review** because Codex bot review usage is unavailable. These approvals do **not** authorize merge.
**Trackers:** [GitHub #524](https://github.com/im-tnyx/tio-world/issues/524) / umbrella [#475](https://github.com/im-tnyx/tio-world/issues/475); [Linear TNYX-267](https://linear.app/tnyx/issue/TNYX-267) Backlog, blocked by TNYX-266/TNYX-81; [TNYX-81](https://linear.app/tnyx/issue/TNYX-81) Backlog, blocked by TNYX-78/TNYX-80. Do not change parent statuses/blockers.
**Implementation owner:** this connected GitHub implementation session only for #524. **Review owner:** manual read-only final-diff review (do not misrepresent self-review as independent bot/human approval).
**Base SHA:** `main@12999565d72915e0653116d6060d93e1e9cb10f5`, owner last reported clean local main after PR #522. Remote main confirmed exact before branch creation; no local Windows worktree access, so local status/test runs cannot be claimed.
**Working branch:** `tnyx/issue-524-program-routine-ui`.
**Docs PR #523:** unrelated docs-only branch currently OPEN; never merge its stale work or scope into #524.

## Observed source baseline
- `program_detail_page.dart`: redundant body `Routines` header and plus; empty CTA; one `TioGroupCard` wraps multiple `TioSettingsNavigationRow`.
- `programs_surface.dart`: `_collapsedPrograms` toggles chevron but emits no Routine children and no owner-filtered reads.
- `library_page.dart` / app shell: selected Program navigation launches `ProgramDetailPage` without awaited completion and refresh; `routineRepositoryProvider` already exists.
- Reuse `TioAppBar.actions`, `TioCard`, existing `ProgramRoutinesController` for owner-scoped read state, `TioSettingsNavigationRow`, `TioButton`/Core tokens. Preserve current library Program-header geometry and callback ownership.

## Approved changes
1. Program Detail: single top-app-bar Add Routine +, no additional heading or extra empty CTA, each Routine in its own TioCard; keep left icon as thumbnail fallback. Owner's later reference specifies future card anatomy **thumbnail | name | Play | Routine 3-dot**. The available **3-dot → Edit-only** action invokes the existing Rename Routine editor. No fake Play, Change Picture or Delete controls.
2. Library: expanded Program renders persisted owner-filtered Routines beneath that Program, collapse hides, reopen refreshes; asynchronous owner read/error/retry/no provider fail-closed; after returning from Detail refresh the shown rows without new truth.
3. Focused widget/controller/navigation tests: multiple Programs, two distinct Routine cards, single action, compact width, dark mode, empty/loading/failure, collapse/re-expand, create-return refresh, provider null, no cross-owner data.
4. Canonical screens docs for new runtime behavior.

## Additional owner screenshot clarification (2026-10-11)

The owner expressly requested Routine card images on the left, Play on the right, and a 3-dot Routine menu intended to contain Edit / Change Picture / Delete. [GitHub #524](https://github.com/im-tnyx/tio-world/issues/524) now records the complete approved *visual target*. The real data/action capabilities not present in this slice are tracked in [GitHub #526](https://github.com/im-tnyx/tio-world/issues/526): user-private persisted Routine image, eligible Active Workout Start, and safe authenticated cascade-aware Delete. No authorization for new SQL/Storage/API or fake controls follows from a visual reference. Existing Edit-only menu + icon fallback is a truthful partial step in #525, not completion of #526.

## Exclusions
No W4B editor/ExercisePicker/Sets, no default My Program Library top-bar quick create, no Program delete/media/TrainingPlan/Favorites/Folders, no Supabase schema/RLS/RPC/production data write, no full W4/W6B blocker removal, no merge/release/branch deletion.

## Gates
Read root and feature AGENTS, relevant ADR/docs, Core theme/component README, issue/Linear dependencies; audit exact changed-file scope; Flutter analyze/test + attribution guard on exact PR source head, read-only manual review, any findings fixed in this branch. Codex quota limitation not a review PASS; never claim independent human sign-off. STOP before explicit separate owner `Go merge`.
