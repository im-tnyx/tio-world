## Codex Review Gate — 2026-10-15 exact reviewed HEAD
The independent Codex review completed on `f13b3a3635870a782a81ba6d1728466ffe79ca16` after Flutter CI #38788227679 SUCCESS. Four **open P2** issues (do not claim APPROVE):
- PRRT_kwDOTOXwB86s7LRF: one-flight direct Create launch shared across Program dotted and bottom-sheet entry points, including distinct Programs.
- PRRT_kwDOTOXwB86s7LRQ: remove stale handoff SHA and obsolete CI claims.
- PRRT_kwDOTOXwB86s7LRb: reject delayed Create if the initiating Library route is no longer current.
- PRRT_kwDOTOXwB86s7LRf: visible pending/unknown-outcome Create gate on the owning Program; disable Add while unconfirmed, preserve owner-only path to verification in existing Program Detail.
Scope of remediation: existing Flutter Program/Library route and feature UI, plus focused widget/route regression tests and task handoff. **No schema, RLS, delete, move, playback or unrelated visual work.** Revalidate at **new exact head** after fixes and request Codex re-review before merge. Repo source/current HEAD must be checked after every commit.

# GitHub #529 — Program-scoped Add Routine entry points

**Status:** In progress
**Primary owner:** Workout feature + app composition
**Affected platforms:** Flutter mobile (Android/iOS)

## Owner Approval and Scope Boundary
**Trigger:** Approved Program-visible UI/navigation feature slice
**Approval status:** Approved
**Approval evidence:** Owner on 2026-10-15: "Agar program par routine nahi h to add routine rahega is kaam ko start kare go follow agent.md" and "And program ke 3dot se add routine and delate program bhi rahega edit program rename bhi rahega bottom sheet se".
**Approved boundaries:** Expanded Library Program with authoritative zero Routines exposes functional **dotted-outline `+ Add new routine`** matching the owner-supplied 2026-10-15 reference, using Core tokens in a feature-local composition. Owner's further correction explicitly removes the additional 24dp start inset for **all expanded Program Routine content** (dotted card, persisted Routine cards and child loading/error states) so content uses only existing Library 16dp horizontal margins. Program 3-dot remains Tio bottom sheet; preserve Edit Program→Rename, add real Program-scoped Add Routine. Delete Program is approved target behavior but its destructive persistence/RLS/cascade/history contract is a separate gated slice, not authorized as a fake action or direct client DELETE.
**Explicit non-changes:** No SQL/RLS/grants, Program Delete implementation, new Routine create repository/editor, new Program ownership or default My Program behavior, new Core UI contracts, new backend, Routine card internal padding, or global Library/other category geometry. Newly approved Program header icon edge alignment may change only icon positioning inside unchanged 48dp touch targets.

## Active Handoff
**Planning owner:** Connected repository review
**Implementation owner:** This GitHub-connected #529 implementation branch; one owner for this slice
**Review owner:** Codex reviewed `f13b3a36` (4 P2); corrected HEAD awaits re-review.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable; no #529 active branch or PR found on preflight
**Repository state last verified:** GitHub API main = `4090e3a143fcfc309a3020e73823bc30ec40c282`
**Branch:** `tnyx/issue-529-inline-add-routine`
**HEAD SHA:** P2 remediation source checkpoint `ae48bffbdd473ff493c86010224a877d15b8c78d`, before this handoff update; verify exact final PR head before re-review.
**Observed working-tree state:** GitHub API-only; no local checked-out working tree or `git status` available
**Observed uncommitted/dirty files:** Unknown locally, isolated new remote branch
**PR / tracker:** [Draft PR #566](https://github.com/im-tnyx/tio-world/pull/566), GitHub #529 / #475, Delete gate [#567](https://github.com/im-tnyx/tio-world/issues/567), Linear TNYX-267 and TNYX-81
**Current implementation state:** Dotted empty Program and overflow actions open canonical Create directly. Codex P2 remediation now includes shared ProgramsSurface one-flight guard, modal dismissal before direct route, `ModalRoute.isCurrent` after owner read, disabled Add plus Program Detail verification affordance on uncertain Save, and reactive notifier-backed Library updates. Focused feature/route tests added; exact corrected-head CI pending.
**Relevant execution surface:** `InlineProgramRoutines` → `ProgramsSurface` → `LibraryPage` → app shell direct Create route; Program Detail's existing Create action shares the same guarded callback
**Validation completed at SHA:** Flutter Analyze/Tests CI #38788227679 SUCCESS at reviewed `f13b3a36` only. Codex review completed with 4 P2 on that same head, 0 resolved yet; fixes and *new-head* CI pending.
**Validation remaining:** Four P2 Codex remediations, focused new tests, exact corrected-head CI, reviewer re-review, diff/security QA and Android device visual QA.
**Current blocker:** Four Codex P2 findings unresolved on reviewed #566 head; new-head CI/re-review and owner device QA pending. Direct Program Delete belongs to separate #567.
**Open review finding IDs:** Delete deferred to independent bounded lifecycle design; no false Delete UI.
**Next exact action:** Verify new exact-head Flutter Analyze + Tests for Codex P2 fixes, resolve any concrete failures, inspect diff and request Codex re-review, reply/resolve only verified threads, then owner Android visual QA. No merge without explicit approval.

## 2026-10-15 Owner Alignment Refinement (active bounded slice)
Owner reports continued visible side space on Program header and Routine card edges and an overly heavy dotted Create-card stroke. Fresh Draft PR #566 source audit confirms Library itself has governed 16dp side padding; saved Routine and dotted card wrappers now have no extra horizontal inset. Program header chevron and overflow `IconButton` have 48dp interactive regions but center their 24dp glyphs, adding apparent left/right space. **Approved UI correction:** align leading glyph to start and trailing glyph to end within their existing >=48dp action regions. Do not globally alter Library padding or Routine internal card content. The feature-owned `_DottedOutline` stroke is currently `TioStroke.width2`; switch only its paint stroke to `TioStroke.width1` and preserve the rounded/dashed shape/theme color. Add geometry/widget assertions for Program header icon edges and Program/Routine/dotted card shared outer bounds, and validate current PR head via CI after commits. Root + feature AGENTS and Core theme README checked. Pre-edit branch head `38c4df88`. Applied `AlignmentDirectional.centerStart`/`centerEnd`, zero internal IconButton padding and exact 48dp constraints to the Program header chevron and overflow, and changed only dotted painter stroke to `TioStroke.width1`. Added widget assertions for glyph edge coordinates, action dimensions, and unchanged Library-side routine rows. Follow-up source commit `f78a7355` before docs/handoff updates; verify new exact PR head and new-run Flutter CI. Prior Flutter CI #38783537219 was for a superseded head. GitHub API cannot verify local worktree/device rendering. No DB or security change.

## 2026-10-15 P1 Review Finding NAV-01 — Direct Library Create Route
**Owner-reported reproduced from source:** Both Library empty-card and Program 3-dot Add launch `openProgram(program, launchCreate: true)`, which pushes `ProgramDetailPage` before its post-frame auto-Create pushes `CreateRoutinePage`. This visibly flashes a wrong intermediate screen and places an unwanted Program Detail route in the stack. **Owner-approved correction:** Library must navigate directly to canonical Create Routine; Cancel/Back must return directly to Library. Preserve selected `ProgramId`, protected atomic Create callback, owner/login-cycle checks, pending-gate lifecycle and authoritative Library refresh, without a duplicate create/persistence path.
**Source-verified minimal design:** Hoist the existing guarded `onCreateRoutine(suggestedName)` closure to one local `createRoutine` function in app shell, reused by Program Detail and the direct Library Create action. Resolve the suggested name via the already-exported `ProgramRoutinesController.load()` owner-scoped read, bail out on load failure/revoked session/unknown pending write; launch canonical `CreateRoutinePage` directly. Remove dead `ProgramDetailPage.launchCreateOnReady` trampoline and corresponding tests. Add app-level direct card/overflow Cancel + Save + preserved Program detail-path regression. No SQL/RLS/domain/Core/layout changes.
**Validation gate:** Review at exact new head + GitHub Flutter Analyze/Tests + device QA; keep Draft. Independent reviewer is still unassigned.

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
Pass a capability-gated Program create-entry callback from app shell to Library to ProgramsSurface and InlineProgramRoutines. Enter canonical `CreateRoutinePage` directly from Library using the existing guarded app-shell Create function; use a fresh owner-scoped `ProgramRoutinesController` read only for naming/capability checks. Do not push Program Detail as an invisible or briefly visible routing host. Program Detail remains a separate destination with the same Create callback. Return to Library and refresh persisted owner-scoped Routine reads. Do not write metadata from Library.
### Ownership and Data Flow
`Library Add/overflow → shared guarded shell Create callback → CreateRoutinePage (selected Program) → atomic owner-scoped RPC → Library refresh`.
### Alternative Rejected
Direct metadata-only Create, new Routine editor, direct Program DELETE, inert destructive menu, optimistic fake row.
### Failure and Accessibility States
Hide Add when repository or callback absent; no creation during loading/error; retries and empty state honest; pending unknown write guard maintained. Use TioButton/TioSettingsNavigationRow, accessible labels.

## 5. Implementation Plan
- [x] Add callback propagation and empty-state Add button
- [x] Add guarded Program 3-dot Add Routine; retain Edit Program rename
- [x] Connect direct entry to existing Create route without new write path
- [x] Add focused feature widget and app route tests
- [x] Canonical Program doc updated; CI succeeded on pre-review `f13b3a36`; P2-corrected head requires new CI/re-review

## 6. Quality Review
### Validation Run
Owner screenshot refinement: dotted card is a local Workout empty-state composition (single consumer), not a new generic Core component/token or physical copy of the screenshot. Focused light/dark/widget assertions added; verify again at new source HEAD. Earlier `cbc16bd5` Flutter CI #38779638889 SUCCESS before dotted visual change, **not evidence for current head**.
No Flutter SDK/worktree accessible in connector-only runtime. Earlier compile failures were resolved. Flutter CI #38788227679 succeeded on `f13b3a36`, then Codex returned 4 P2 findings. New P2 remediation head requires its own CI; previous PASS is **not** evidence for corrected head. Codex re-review and owner device QA pending.
### Review Findings and Resolution
| ID | Severity | Status | Finding | Observed at SHA | Evidence |
|---|---|---|---|---|---|
| DEL-01 | P1 | Deferred | Program Delete absent and grants revoked; do not expose fake Delete | main@4090e3a | #529 / migration / W6B |

## 7. Final Handoff
### Changed Files
App shell `shell_route.dart`; Workout `library_page.dart`, `programs_surface.dart`, `inline_program_routines.dart`, `program_detail_page.dart`; app and Workout tests; `docs/screens/programs.md`; task brief and index.
### Actual Behavior
Branch-only implementation: capability-gated selected-Program Add Routine, one direct Create route, no intermediate Program Detail, shared launch serialization, route-current cancellation, uncertain-write disabled UI and verification path, plus Edit Program Rename. Pre-review head CI passed; post-P2 exact-head CI pending. Not merged/released.
### Known Limitations
Program Delete deliberately not part of this safe UI slice; dedicated security/lifecycle issue #567. Hosted atomic Create RPC availability and mobile release remain separate gates.
### Final Status
PARTIAL (in progress; not release-ready)
