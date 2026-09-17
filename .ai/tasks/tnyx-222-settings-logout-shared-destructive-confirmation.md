# TNYX-222 — Settings logout shared destructive confirmation

**Status:** Validation / final review
**Primary owner:** Implementation
**Affected platforms:** Flutter phone app / Core UI

## Owner Approval and Scope Boundary

**Trigger:** Existing approved product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner explicitly said `go`, then `GO YOU ARE WORKING IN TIO-WORLD FOLLOW AGENT.MD`, and later `Go sahi Kar` for the audited TNYX-222 / GitHub #173 slice.
**Approved product/UI/data-shape boundaries:** Keep a backwards-compatible standard/destructive confirmation intent at the shared presenter boundary, route Settings logout through the shared presenter with destructive intent, preserve current copy and logout behavior, and repair validation/documentation gaps discovered in review.
**Explicit non-changes:** No confirmation-surface/background convergence, no global card semantic change, no `TioGroupCard` / `TioSelectableCard` consolidation, no product-flow behavior change, no auth/session/routing/backend/Supabase/data change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Pending final review
**Implementation ownership state:** Active through validation
**Ownership transition:** Not applicable
**Repository base last verified:** `main` at `17383476fdb8844b592041e730a764bd132f602c`
**Branch:** `tnyx/tnyx-222-settings-logout-shared-destructive-confirmation-intent`
**HEAD SHA before this handoff sync:** `bfef787d5286086b207917eb41f46dae8137e174`
**Observed working-tree state:** Connector-only session; local working tree unavailable. An isolated local clone attempt was blocked by container DNS/network access, so GitHub Actions remains validation source of truth.
**PR / tracker:** GitHub PR #279 / GitHub #173 / Linear TNYX-222
**Current implementation state:** Architecture correction, Settings migration, focused tests, and Core public documentation are implemented. Review-discovered brittle test targeting was tightened; exact-head CI is still required before leaving Draft.
**Validation remaining:** Exact-head Flutter CI green, then final Codex-style review and PR/Linear close-out.
**Current blocker:** Final exact-head CI result has not yet completed.
**Open review finding IDs:** CI-1 only until exact-head CI is green.

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
- Core public docs match runtime;
- exact-head validation is green before leaving Draft.

### Scope

Core confirmation presenter intent/composition; Settings logout migration; focused Core/Settings/consumer tests; Core public component docs; PR/task alignment.

### Non-Goals

No `surfaceRaised` convergence; no broad card/sheet consolidation; no product-flow redesign; no auth/backend/data work.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md` and current Linear TNYX-222 were reconciled before review fixes.
- TNYX-223 architecture audit classified `TioCard` as the base visual primitive and the generic confirmation presenter/result contract as the reusable boundary.
- `TioConfirmationIntent` lives at the `showTioConfirmationBottomSheet` presenter boundary.
- `showTioConfirmationBottomSheet` composes directly from `TioCard` + `TioButton`; the public `TioConfirmationCard` export/file/test boundary is removed.
- Settings logout awaits the shared presenter with destructive intent and invokes the existing logout callback only when the result is `true`.
- Consumer tests assert confirmation copy/actions/results instead of depending on the removed public card type.
- Core README now documents the presenter-level intent/result/composition contract and no longer lists `TioConfirmationCard` as public reusable UI.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| `standard` is default intent | Locked | Backwards-compatible for existing consumers | Owner-approved audit |
| `destructive` maps confirm to `TioButton.destructive` | Locked | Reuses governed semantic action | Owner-approved audit |
| public `TioConfirmationCard` is removed | Locked | Generic behavior belongs to presenter/result contract, not another workflow-shaped card | TNYX-223 audit |
| presenter composes `TioCard` + `TioButton` directly | Locked | Avoids one-off component proliferation | TNYX-223 audit |
| `surfaceRaised` convergence excluded | Locked | Separate visible surface contract in #173 | Owner-approved audit |

## 4. Architecture Design

```text
SettingsPage logout row
→ showTioConfirmationBottomSheet(intent: destructive)
→ internal TioCard + semantic TioButton composition
→ bool? result
→ existing onLogoutPressed callback only when result == true
```

Restoring a public `TioConfirmationCard`, retaining a local `AlertDialog`, or creating a Settings-specific confirmation widget remains out of scope and contrary to the audited ownership decision.

## 5. Implementation / Review Fixes

- [x] Add `TioConfirmationIntent.standard/destructive` with default `standard` at presenter boundary.
- [x] Compose confirmation content internally from `TioCard` + semantic `TioButton` variants.
- [x] Remove the public `TioConfirmationCard` export/file/test boundary.
- [x] Migrate Settings logout to await shared presenter result and call logout only on `true`.
- [x] Update focused Core and Settings tests.
- [x] Migrate stale app/onboarding assertions away from the removed public type.
- [x] Remove brittle app-level global `TioCard` count assertion and keep behavior/result assertions.
- [x] Target the Settings destructive confirm action through `FilledButton` semantics instead of `find.text(...).last` ordering.
- [x] Align Core public component documentation with the presenter-owned contract.
- [ ] Obtain exact-head green CI.
- [ ] Refresh PR body with final validation evidence.
- [ ] Run final Codex-style review; keep Draft until no blocking findings and exact-head validation is green.

## 6. Quality Review

### Validation History

```text
Flutter CI #2631: analyze failure from stale app-level TioConfirmationCard assertion; repaired.
Flutter CI #2632 and later runs: analyze clean, then additional stale/test-contract issues surfaced in Flutter tests.
Flutter CI #2637 at b6907799c27c236d10ced985d935dcd60d9bced2:
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: FAIL
- exact failing assertion text unavailable through connector logs.

Review repair commits after #2637:
- c2a4f4e1853a3f6965acf73ed3c2c514e7b85b90 — remove brittle app-level TioCard count assertion.
- aa18a0c7e5e08c2ce1e0c9c1f0f40ea0567852b5 — target Settings confirm button semantically.
- bfef787d5286086b207917eb41f46dae8137e174 — align Core README with current public confirmation contract.

Final exact-head CI after this task-brief sync is required before completion.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| DOC-1 | P1 | Resolved | Core README documented removed public `TioConfirmationCard` | README now documents `showTioConfirmationBottomSheet`, `TioConfirmationIntent`, internal `TioCard` + `TioButton` composition |
| TEST-1 | P2 | Resolved | App consumer test pinned a global `TioCard` count instead of confirmation behavior | Removed card-count assertion; retained action/result assertions |
| TEST-2 | P3 | Resolved | Settings confirm test depended on `find.text('Log Out').last` ordering | Targets destructive `FilledButton` directly |
| CI-1 | P1 validation blocker | Open | Exact-head Flutter CI must pass before PR leaves Draft | Await final GitHub Actions result |

### Process Deviation

A prior connector-only attempt to update `apps/core/lib/src/theme/README.md` used incomplete/truncated retrieved content and accidentally created commit `f718b3552c7dbe709a1719fe44020050fb1dc8ae`. The mistake was detected immediately and the branch ref was force-moved back to the prior good commit. That force ref update did not have explicit owner approval and remains recorded as a governance deviation. The bad commit is not part of the current branch. The successful README correction in this review used complete blob retrieval before writing.

## 7. Final Handoff

### Actual Behavior

Settings logout uses the shared confirmation presenter with destructive action semantics. Generic confirmation presentation uses presenter-level intent and internal base-primitives composition rather than a workflow-shaped public confirmation-card component.

### Known Limitations

The reusable confirmation surface keeps its existing elevated-card background/shadow geometry; broader surface convergence remains out of scope. Connector-only work cannot report local working-tree state.

### Final Status

`VALIDATION / FINAL REVIEW — PR remains Draft; do not merge until exact-head CI is green.`
