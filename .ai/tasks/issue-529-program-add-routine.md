# GitHub #529 — Program-scoped Add Routine entry points

**Status:** In progress
**Primary owner:** Workout feature + app composition
**Affected platforms:** Flutter mobile (Android/iOS)

## Owner Approval and Scope Boundary
**Trigger:** Approved Program-visible UI/navigation feature slice
**Approval status:** Approved
**Approval evidence:** Owner on 2026-10-15: "Agar program par routine nahi h to add routine rahega is kaam ko start kare go follow agent.md" and "And program ke 3dot se add routine and delate program bhi rahega edit program rename bhi rahega bottom sheet se".
**Approved boundaries:** Expanded Library Program with authoritative zero Routines exposes functional Add Routine. Program 3-dot remains Tio bottom sheet; preserve Edit Program→Rename, add real Program-scoped Add Routine. Delete Program is approved target behavior but its destructive persistence/RLS/cascade/history contract is a separate gated slice, not authorized as a fake action or direct client DELETE.
**Explicit non-changes:** No SQL/RLS/grants, Program Delete implementation, new Routine create repository/editor, new Program ownership or default My Program behavior, new Core UI contracts, new backend or existing nonempty Program geometry.

## Active Handoff
**Planning owner:** Connected repository review
**Implementation owner:** This GitHub-connected #529 implementation branch; one owner for this slice
**Review owner:** Independent reviewer pending
**Implementation ownership state:** Active
**Ownership transition:** Not applicable; no #529 active branch or PR found on preflight
**Repository state last verified:** GitHub API main = `4090e3a143fcfc309a3020e73823bc30ec40c282`
**Branch:** `tnyx/issue-529-inline-add-routine`
**HEAD SHA:** `4090e3a143fcfc309a3020e73823bc30ec40c282` (before implementation)
**Observed working-tree state:** GitHub API-only; no local checked-out working tree or `git status` available
**Observed uncommitted/dirty files:** Unknown locally, isolated new remote branch
**PR / tracker:** GitHub #529 / #475, Linear TNYX-267 and TNYX-81
**Current implementation state:** Not yet committed
**Relevant execution surface:** `InlineProgramRoutines` → `ProgramsSurface` → `LibraryPage` → app shell's ProgramDetail/Create route
**Validation completed at SHA:** Source/planning review only, no Flutter checks yet
**Validation remaining:** Widget/app-route tests, exact-head CI, diff audit, security/API re-check and review
**Current blocker:** Direct Program Delete unavailable (ProgramRepository.list/create/rename only; authenticated DELETE revoked).
**Open review finding IDs:** Delete deferred to independent bounded lifecycle design; no false Delete UI.
**Next exact action:** Add guarded Library Add Routine and Program 3-dot Add Routine reusing ProgramDetail/Create.

## 1. Discovery
### User Outcome
An empty expanded Program displays Add Routine instead of passive No routines yet; same Program's bottom sheet can rename or launch the real Create Routine.
### Success Criteria
- Action only on loaded, empty, owner-scoped Program and live Create capability
- Create routes to selected Program with existing session guards, atomic Create, no metadata-only write
- Cancel no write; confirmed/uncertain return refreshes selected Program without duplicate RPC
- Menu keeps Edit Program → Rename; missing capabilities fail closed
### Scope
Flutter Workout presentation, thin app-shell navigation, focused tests, canonical Programs doc.
### Non-Goals
Delete Program implementation, Program/Routine schema or RPC, top-level My Program, other Routine menus.

## 2. Codebase Exploration
- `InlineProgramRoutines`: currently renders Text('No routines yet'); owning Program ID and repository already scoped.
- `ProgramsSurface._openProgramActions`: existing TioSheet with functional Edit Program → rename.
- `ProgramDetailPage`: sole Create + calls app-shell callback; reuses atomic `CreateRoutinePage` with auth/session and pending-commit protection.
- `shell_route.dart`: verified owner/login-cycle + capability checks surround Create; do not replicate or bypass.
- `ProgramRepository` has no delete contract; migration `20260929133232_harden_user_workout_program_privileges.sql` revoked authenticated DELETE.
- Linear TNYX-267 and TNYX-81 remain Backlog; broader dependencies not completed.
- Read root and features AGENTS, Core theme README, design-system task, ADR-0015, canonical screen docs, .ai workflow and PR templates.

## 3. Clarification
| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Add Routine is direct to existing Create flow for selected Program | Approved | No duplicate Routine identity or controller | Owner |
| Keep Edit Program real Rename | Approved | Existing durable action | Owner |
| Delete Program separately gated | Deferred | No destructive repository/RLS/grant/history contract | Security/product follow-up |

## 4. Architecture Design
### Chosen Approach
Pass a capability-gated Program create-entry callback from app shell to Library to ProgramsSurface and InlineProgramRoutines. Reuse the existing ProgramDetail screen as a guarded Create entry host and automatically open its canonical Create action once owner-scoped metadata is ready. Return to Library and refresh real persisted Routine reads. Do not write metadata from Library.
### Ownership and Data Flow
`Library Add/overflow → ProgramDetail (selected Program) → existing guarded shell callback → CreateRoutinePage → atomic owner-scoped RPC`.
### Alternative Rejected
Direct metadata-only Create, new Routine editor, direct Program DELETE, inert destructive menu, optimistic fake row.
### Failure and Accessibility States
Hide Add when repository or callback absent; no creation during loading/error; retries and empty state honest; pending unknown write guard maintained. Use TioButton/TioSettingsNavigationRow, accessible labels.

## 5. Implementation Plan
- [ ] Add callback propagation and empty-state Add button
- [ ] Add guarded Program 3-dot Add Routine; retain Edit Program rename
- [ ] Connect direct entry to existing Create route without new write path
- [ ] Add focused feature widget and app route tests
- [ ] Update canonical docs and audit PR/CI

## 6. Quality Review
### Validation Run
No Flutter SDK or worktree is accessible in this connector-only runtime. Remote GitHub Actions exact-head evidence required.
### Review Findings and Resolution
| ID | Severity | Status | Finding | Observed at SHA | Evidence |
|---|---|---|---|---|---|
| DEL-01 | P1 | Deferred | Program Delete absent and grants revoked; do not expose fake Delete | main@4090e3a | #529 / migration / W6B |

## 7. Final Handoff
### Changed Files
Pending implementation
### Actual Behavior
Pending implementation
### Known Limitations
Program Delete deliberately not part of this safe UI slice.
### Final Status
PARTIAL (in progress; not release-ready)
