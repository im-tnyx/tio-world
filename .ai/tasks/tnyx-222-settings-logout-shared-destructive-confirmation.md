# TNYX-222 — Settings logout shared destructive confirmation

**Status:** Validated — merged
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
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository base last verified:** `main` at `17383476fdb8844b592041e730a764bd132f602c`
**Branch:** `tnyx/tnyx-222-settings-logout-shared-destructive-confirmation-intent` (not deleted; owner did not request branch deletion)
**Final PR HEAD:** `3cd33b3c612b70dff4a429afc4ce631c720e15ec`
**Merge commit:** `ecfab7530f48af08587a34048f722fd31f4119fe` — squash-merged into `main` 2026-09-18T05:06:02Z
**Observed working-tree state:** Local clone available this session (`G:\projects\Tio-World`). Local `main` fast-forwarded to `ecfab753` post-merge; working tree clean.
**PR / tracker:** GitHub PR #279 (Merged) / GitHub #173 (stays open — other consumers remain, see Non-Goals) / Linear TNYX-222 (Done)
**Current implementation state:** Merged into `main`. All acceptance criteria verified against merged source: `TioConfirmationIntent.standard/destructive` exists with `standard` default; destructive confirm uses `TioButton.destructive`; cancel uses `TioButton.secondary`; presenter composes `TioCard` + `TioButton` directly; `TioConfirmationCard` fully removed (no file, no references repo-wide); Settings logout calls `showTioConfirmationBottomSheet(intent: destructive)` and invokes `onLogoutPressed` only on `true`; no auth/session/backend/Supabase files touched; confirmation surface unchanged (`TioCardVariant.elevated`); Core docs match runtime.
**Validation remaining:** None for this slice.
**Current blocker:** None.
**Open review finding IDs:** None open.

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
- [x] Obtain exact-head green CI (Flutter CI #2642, run `35265780486`, on `ecd1098b`).
- [x] Fix stale `TioButtonVariant.destructive` doc comment in `tio_button.dart` still describing the removed `TioConfirmationCard` routing (DOC-2).
- [x] Refresh PR body with final validation evidence.
- [x] Run final Codex-style review; no blocking findings at exact HEAD `09660677`; exact-head CI green.
- [x] Move PR #279 to Ready for Review and Linear TNYX-222 to In Review.
- [x] Merge PR #279 (squash) into `main` on explicit owner instruction.
- [x] Sync local `main` per `docs/POST_MERGE_SYNC.md`.
- [x] Verify acceptance criteria against merged `main` source and move Linear TNYX-222 to Done.

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

Flutter CI run 35244080308 at dfebe6e70322b955a7e2e823a95bff9c687b0b4f (local audit, this session):
- `melos exec` FAILED in package `tio_feature_settings`, exit code 1 (228 passed, 1 failed).
- Failing test: `apps/features/settings/test/presentation/settings_page_test.dart` — "Settings logout uses shared confirmation and supports cancel", line 192.
- Root cause: the assertion `expect(find.text('Log Out'), findsNWidgets(2))` counted every "Log Out" `Text` in the widget tree, not only the ones inside the confirmation bottom sheet. With the sheet open, three matches exist: the `SettingsPage` logout row title (still present in the tree behind the modal barrier), the sheet title, and the destructive confirm button — not two. This is a test-assertion gap introduced by this PR's own new test, not a production regression.
- Fix: scoped the assertion to `find.descendant(of: find.byType(BottomSheet), matching: find.text('Log Out'))`, so it verifies exactly the sheet title + confirm button regardless of what is present behind the modal.
- Local validation (`G:\projects\Tio-World`, Flutter SDK at `G:\dev\flutter-sdk`):
  - `flutter test test/presentation/settings_page_test.dart --no-pub` from `apps/features/settings`: 7/7 passed.
  - `flutter test --no-pub` (full package): 229/229 passed.
  - `flutter analyze --no-pub`: No issues found.
- Fix committed only to `apps/features/settings/test/presentation/settings_page_test.dart`; no production code changed.

Flutter CI #2642, run `35265780486`, on exact HEAD `ecd1098b4f0358ffecfb6b1f164db8890e218f2f`: SUCCESS.
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS
CI-1 is resolved for this HEAD.

Final-review pass at `ecd1098b` (this session, read-only diff audit against `main`, all 11 changed files inspected):
- Confirmed: `TioConfirmationIntent.standard` default, `destructive` → `TioButton.destructive`, cancel → `TioButton.secondary`, presenter composes `TioCard` + `TioButton` directly, no public `TioConfirmationCard` remains, Settings logout calls `showTioConfirmationBottomSheet(intent: destructive)` and invokes `onLogoutPressed` only on `true`, no auth/session/routing/backend/Supabase files touched, no confirmation-surface/background convergence (still `TioCardVariant.elevated`), all 11 changed files fall within the approved TNYX-222 scope, onboarding/app consumer tests already assert copy/behavior rather than the removed type.
- Found DOC-2: `apps/core/lib/src/ui/components/buttons/tio_button.dart` enum doc comment on `TioButtonVariant` still said "`TioConfirmationCard` still routes confirm through [primary]" — stale, since this PR removes `TioConfirmationCard` and destructive confirm already routes through `TioButton.destructive` via the shared presenter. Corrected to describe the current presenter/variant relationship. Comment-only; no button behavior, styling, tokens, geometry, or API changed.
- Local validation for the DOC-2 fix: `git diff --check` clean; `flutter analyze --no-pub` in `apps/core` → No issues found. No test rerun claimed beyond this, since no test-observable behavior changed.

Flutter CI #2643, run `35308007688`, on exact HEAD `0966067798dbfc326423e963373332100b1716eb`: SUCCESS.
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS

Final Codex-style re-check at exact HEAD `09660677` (this session):
- `git merge-base --is-ancestor origin/main HEAD`: OK.
- `git diff --name-only origin/main...HEAD`: 12 files, all within approved TNYX-222 scope (task brief, Core confirmation presenter/button/card files and their tests, Settings logout + test, onboarding/app consumer test corrections).
- `git diff --check origin/main...HEAD`: clean.
- PR #279: `mergeable=MERGEABLE`, `mergeStateStatus=CLEAN`.
- Unresolved GitHub review threads: 0 (`reviewThreads` query returned an empty list).
- No P0/P1/P2 findings remain open.

Docs-only task-brief handoff commit `3cd33b3c` also validated: `git diff --check` clean; Flutter CI (run `35308686756`) SUCCESS on this exact HEAD — this is the HEAD that was merged.

Merge (owner-approved, this session):
- Pre-merge revalidation: PR #279 open/not Draft, HEAD exactly `3cd33b3c`, `MERGEABLE`/`CLEAN`, exact-head CI green (run `35308686756`), 0 unresolved review threads, 0 blocking reviews, Linear still `In Review`, diff unchanged since final review — all 8 checks passed.
- Merged via `gh pr merge 279 --squash --match-head-commit 3cd33b3c...` (expected-head protection). Result: PR #279 `state=MERGED`, merge commit `ecfab7530f48af08587a34048f722fd31f4119fe`.
- Verified `origin/main` moved `17383476..ecfab753` and local `main` fast-forwarded to match.
- Post-merge acceptance-criteria re-check against merged `main` source (grep-verified): intent enum + `standard` default, `destructive`/`secondary` button mapping, `TioConfirmationCard` fully absent repo-wide, Settings logout wiring, empty diff for auth/backend paths — all satisfied.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| DOC-1 | P1 | Resolved | Core README documented removed public `TioConfirmationCard` | README now documents `showTioConfirmationBottomSheet`, `TioConfirmationIntent`, internal `TioCard` + `TioButton` composition |
| TEST-1 | P2 | Resolved | App consumer test pinned a global `TioCard` count instead of confirmation behavior | Removed card-count assertion; retained action/result assertions |
| TEST-2 | P3 | Resolved | Settings confirm test depended on `find.text('Log Out').last` ordering | Targets destructive `FilledButton` directly |
| CI-1 | P1 validation blocker | Resolved | Exact-head Flutter CI must pass before PR leaves Draft | Flutter CI #2642 (run `35265780486`) passed all four steps on `ecd1098b` |
| DOC-2 | P3 | Resolved | `tio_button.dart` `TioButtonVariant` doc comment still described destructive confirm routing through the removed `TioConfirmationCard`/`primary` | Comment corrected to describe the current presenter/`TioButton.destructive` relationship; no behavior/API change; Flutter CI #2643 (run `35308007688`) green on `09660677` |

### Process Deviation

A prior connector-only attempt to update `apps/core/lib/src/theme/README.md` used incomplete/truncated retrieved content and accidentally created commit `f718b3552c7dbe709a1719fe44020050fb1dc8ae`. The mistake was detected immediately and the branch ref was force-moved back to the prior good commit. That force ref update did not have explicit owner approval and remains recorded as a governance deviation. The bad commit is not part of the current branch. The successful README correction in this review used complete blob retrieval before writing.

## 7. Final Handoff

### Actual Behavior

Settings logout uses the shared confirmation presenter with destructive action semantics. Generic confirmation presentation uses presenter-level intent and internal base-primitives composition rather than a workflow-shaped public confirmation-card component.

### Known Limitations

The reusable confirmation surface keeps its existing elevated-card background/shadow geometry; broader surface convergence remains out of scope. GitHub #173 remains open — its own checklist still lists `surfaceRaised` convergence, onboarding/Body Goal/Nutrition Meal Category confirmation adoption verification, and any other destructive-confirmation convergence as separate future slices, each requiring its own fresh audit and owner approval. This task does not start any of them.

### Final Status

`MERGED — PR #279 squash-merged into main as ecfab7530f48af08587a34048f722fd31f4119fe (final head 3cd33b3c). Exact-head Flutter CI (run 35308686756) was green before merge. Linear TNYX-222 is Done. GitHub #173 stays open (other consumers remain). No further action on this slice; the next #173 slice requires its own fresh audit and explicit owner approval.`
