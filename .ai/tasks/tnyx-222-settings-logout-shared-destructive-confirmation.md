# TNYX-222 — Settings logout shared destructive confirmation

**Status:** In progress
**Primary owner:** Implementation
**Affected platforms:** Flutter phone app / Core UI

## Owner Approval and Scope Boundary

**Trigger:** Existing approved product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner explicitly said `go`, then `GO YOU ARE WORKING IN TIO-WORLD FOLLOW AGENT.MD` for the audited logout-card slice tracked by GitHub #173 / Linear TNYX-222.
**Approved product/UI/data-shape boundaries:** Keep a backwards-compatible standard/destructive confirmation intent at the shared presenter boundary, route Settings logout through the shared presenter with destructive intent, preserve current copy and logout behavior.
**Explicit non-changes:** No confirmation-surface/background convergence, no global card semantic change, no `TioGroupCard` / `TioSelectableCard` consolidation, no product-flow behavior change, no auth/session/routing/backend/Supabase/data change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Pending final review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository base last verified:** `main` at `17383476fdb8844b592041e730a764bd132f602c`
**Branch:** `tnyx/tnyx-222-settings-logout-shared-destructive-confirmation-intent`
**HEAD SHA before this handoff sync:** `bac4a26a776860002838a1f458cf85016481f684`
**Observed working-tree state:** Connector-only session; local working tree unavailable.
**Observed uncommitted/dirty files:** Not observable in connector-only session.
**PR / tracker:** GitHub PR #279 / GitHub #173 / Linear TNYX-222
**Current implementation state:** Architecture correction and Settings migration are implemented; exact-head Flutter CI is analyze-clean but failing in the Flutter test phase. The remaining work is bounded validation/test repair plus documentation/review alignment.
**Relevant execution surface:** Core shared confirmation presenter/tests, Settings logout/tests, and stale consumer tests that referenced the removed public confirmation-card type.
**Validation completed at SHA:** At `bac4a26a776860002838a1f458cf85016481f684`, Flutter CI run `35230326956` (rerun included) passed Flutter/Dart analyze and failed only in `Test Flutter packages` (job `105241166575`).
**Validation remaining:** Identify the exact failing Flutter test from repository/CI evidence, apply the smallest behavior-based test repair if needed, then obtain exact-head CI evidence and final review.
**Current blocker:** CI job log retrieval through the connector has not yielded usable decoded failure text in this session; do not guess a source change from stale default-branch search results.
**Open review finding IDs:** None currently recorded as blocking.
**Next exact action:** Inspect branch-specific candidate test(s) and CI evidence; repair only a verified stale assertion without restoring `TioConfirmationCard` or changing product behavior.

## Global UI / Design-System Guardrail

Follow root `AGENTS.md`, `apps/features/AGENTS.md`, and `apps/core/lib/src/theme/README.md`. Preserve existing confirmation surface/background geometry in this slice. The approved visible delta is only the Settings logout confirmation moving from its local dialog to the existing shared bottom-sheet family with destructive action semantics.

## 1. Discovery

### User Outcome

Settings logout uses the governed shared confirmation presenter instead of a feature-local raw `AlertDialog`, while retaining destructive action semantics and the existing logout contract.

### Success Criteria

- explicit `TioConfirmationIntent.standard/destructive` at the presenter boundary, with `standard` default;
- existing shared-confirmation callers stay standard unless they opt in;
- presenter composes confirmation UI from base `TioCard` + semantic `TioButton` variants;
- no public `TioConfirmationCard` contract remains;
- Settings logout uses destructive shared confirmation;
- cancel calls logout zero times; confirm calls logout exactly once;
- copy and logout/session/navigation behavior remain unchanged;
- exact-head validation is green before leaving Draft.

### Scope

Core confirmation presenter intent/composition; Settings logout migration; focused Core/Settings/consumer tests; Core public component docs; PR/task alignment.

### Non-Goals

No `surfaceRaised` convergence; no broad card/sheet consolidation; no product-flow redesign; no auth/backend/data work.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md` was re-read on the active branch before continuing this slice.
- TNYX-223 architecture audit classified `TioCard` as the base visual primitive and the generic confirmation presenter/result contract as the reusable boundary.
- `TioConfirmationIntent` now lives at the presenter boundary.
- `showTioConfirmationBottomSheet` composes directly from `TioCard` + `TioButton`; the public `TioConfirmationCard` export/file/test were removed.
- Settings logout uses the shared presenter with destructive intent and preserves the existing callback/session behavior.
- Earlier stale consumer type assertions were migrated away from `TioConfirmationCard` in app/onboarding tests.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| `standard` is default intent | Locked | Backwards-compatible for existing consumers | Owner-approved audit |
| `destructive` maps confirm to `TioButton.destructive` | Locked | Reuses governed semantic action | Owner-approved audit |
| public `TioConfirmationCard` is removed | Locked | TNYX-223 found the standalone public boundary unnecessary; generic behavior belongs to presenter/result contract | TNYX-223 audit |
| presenter composes `TioCard` + `TioButton` directly | Locked | Keeps Core primitives generic and avoids workflow-shaped component proliferation | TNYX-223 audit |
| `surfaceRaised` convergence excluded | Locked | Separate visible surface contract in #173 | Owner-approved audit |

## 4. Architecture Design

### Chosen Approach

Keep `TioConfirmationIntent` on `showTioConfirmationBottomSheet`, render the confirmation content internally from the base `TioCard` plus semantic `TioButton` variants, and let Settings await the presenter's boolean result before invoking its existing logout callback.

### Ownership and Data Flow

```text
SettingsPage logout row
→ showTioConfirmationBottomSheet(intent: destructive)
→ internal TioCard + TioButton composition
→ bool result
→ existing onLogoutPressed callback
```

### Alternative Rejected

Restoring/expanding a public `TioConfirmationCard`, keeping a local `AlertDialog`, or creating a Settings-specific confirmation widget are rejected for this slice. The generic presenter owns the reusable interaction/result contract while base Core primitives own visual/action semantics.

### Failure and Accessibility States

Cancel/dismiss must not call logout. Existing shared sheet safe-area/dismiss behavior remains authoritative. No auth failure handling changes in this slice.

## 5. Implementation Plan

- [x] Add `TioConfirmationIntent.standard/destructive` with default `standard` at presenter boundary.
- [x] Compose confirmation content internally from `TioCard` + semantic `TioButton` variants.
- [x] Remove the public `TioConfirmationCard` export/file/test boundary.
- [x] Migrate Settings logout to await shared presenter result and call logout only on `true`.
- [x] Update focused Core and Settings tests.
- [x] Migrate known stale app/onboarding assertions away from the removed public type where verified.
- [ ] Resolve the current exact-head Flutter test failure using branch-specific evidence.
- [ ] Align Core public component documentation safely using complete-file retrieval only.
- [ ] Align PR body and final validation evidence.
- [ ] Run final Codex-style review; keep Draft until no blocking findings and exact-head validation is green.

## 6. Quality Review

### Validation Run

```text
Connector-only validation evidence:
- Flutter CI #2631 failed during analyze on a stale app-level `TioConfirmationCard` assertion; repaired in commit 3552c3ba0398ee680d5d45ab78496c2a2ba62e79.
- Flutter CI #2632 passed app/core analysis and then exposed stale onboarding type assertions.
- `onboarding_root_exit_test.dart` assertions were migrated in commit e698ad95d2b53a8f94b9492caf0504b7510a5c3c.
- Current exact-head evidence before this handoff sync: head bac4a26a776860002838a1f458cf85016481f684, run 35230326956. Flutter analyze PASS, Dart analyze PASS, Flutter tests FAIL. The connector has not exposed usable decoded failure text yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| CI-1 | P1 validation blocker | Open | Exact-head Flutter test phase is failing; PR must remain Draft until the verified failure is repaired and rerun is green | `bac4a26a776860002838a1f458cf85016481f684` | Run `35230326956`, job `105241166575` |

### Process Deviation

A prior connector-only attempt to update `apps/core/lib/src/theme/README.md` used incomplete/truncated retrieved content and accidentally created commit `f718b3552c7dbe709a1719fe44020050fb1dc8ae`. The mistake was detected immediately and the branch ref was force-moved back to the prior good commit. That force ref update did not have explicit owner approval and is therefore recorded as a governance deviation. The bad commit is not part of the current branch. No further large-file write may be made unless the complete file content is verifiably retrieved (blob or gap-free line chunks).

## 7. Final Handoff

### Changed Files

Implementation is present on PR #279; the exact final changed-file list will be recorded after the final compare audit.

### Actual Behavior

Settings logout now uses the shared confirmation presenter with destructive action semantics. Generic confirmation presentation uses presenter-level intent and internal base-primitives composition rather than a workflow-shaped public confirmation-card component.

### Known Limitations

The reusable confirmation surface keeps its existing elevated-card background/shadow geometry; broader surface convergence remains out of scope. Connector-only work cannot report local working-tree state.

### Final Status

`IMPLEMENTATION / VALIDATION — PR remains Draft; do not merge.`
