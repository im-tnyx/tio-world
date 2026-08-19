# Design System Slice H — Final Enforcement

**Status:** Ready  
**Current phase:** Final inventory  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Complete repository-wide enforcement of the centralized design-system ownership model and prove that no duplicate physical visual ownership, feature token catalogs, transitional compatibility debt, or unapproved visual drift remain.

## Mandatory Visual Freeze

No cleanup in this slice may redesign or restyle any screen. Any discovered visual improvement/defect becomes a separate approved decision/task.

## Preconditions

- [x] Slices A–G are `Validated`.
- [x] Slice G Splash migration passed Flutter CI #845.
- [x] Slice G final Wear/remaining-UI implementation head `1a031d76ab7155e2879320437dff448031cf6b0c` passed Flutter CI #846.

## Compatibility Debt Exit Rule

Compatibility aliases, facades, fallback accessors, legacy token names, and temporary duplicate APIs may exist only to keep incremental migration safe. They are **not valid final-state architecture**.

Examples include, where still present:

- legacy `TioSpacing.extraSmall/small/medium/large/extraLarge` aliases;
- legacy `TioRadius.small/medium/large/extraLarge` aliases;
- `TioMotionTokens` compatibility facade;
- `TioDialogTokens.otpShadowColor` compatibility alias after runtime shadow migration;
- static radius getters under `context/`;
- `TioTheme.colors(context)` transitional access;
- any other compatibility export introduced during Slices A–G.

A compatibility API may be deleted only when all of the following are true:

1. every production/test consumer has migrated to the canonical replacement;
2. repository-wide search proves zero legitimate references remain;
3. exports/barrels and compatibility-specific tests are removed or updated;
4. no public package still relies on the compatibility symbol;
5. focused tests and Flutter/Dart analyze pass after deletion;
6. required workspace CI is green.

Final enforcement must perform the deletion. Do not leave compatibility aliases/facades behind merely because they are harmless or deprecated.

## Checklist

- [ ] Audit app shell/composition and all remaining production UI for raw fixed visual literals.
- [ ] Audit canonical primitive registries for evidence-only values and dead entries.
- [ ] Confirm foundation/semantic/typography/effects/component roles do not redefine physical values independently.
- [ ] Confirm no `WelcomeTokens`, `AuthTokens`, `OnboardingTokens`, `HomeTokens`, `ProfileTokens`, or equivalent feature token/color/layout/theme catalogs remain.
- [ ] Confirm no screen-specific token bags were hidden under core component tokens.
- [ ] Confirm dynamic access is canonical (`context.tioColors`, `context.tioMotion`, `context.tioShadows`, semantic `TextTheme`) and static tokens are accessed directly.
- [ ] Inventory every transitional compatibility alias/facade/accessor/export introduced or retained during Slices A–G.
- [ ] Migrate every remaining compatibility consumer to the canonical API.
- [ ] Prove zero legitimate references for every compatibility symbol before removal.
- [ ] Delete zero-reference compatibility aliases/facades/accessors/exports and update/remove compatibility-only tests.
- [ ] Re-run repository search after deletion to prove the old symbols are gone.
- [ ] Audit colors using `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [ ] Verify representative primitive searchability such as `TioSize.dp20`.
- [ ] Run static searches for UI constructors/raw values and classify legitimate business/runtime literals.
- [ ] Run focused tests across touched packages.
- [ ] Run Flutter/Dart analyze.
- [ ] Run full workspace CI.
- [ ] Validate representative compact/light/dark/OLED/high-contrast/reduced-motion states where applicable.
- [ ] Review final PR #22 diff for scope creep and visible UI drift.
- [ ] Update parent task, Issue #6, PR #22 and child task statuses with verified evidence only.

## Repository-Wide Definition of Done

- every fixed product-visible physical value has one canonical core owner;
- primitive registries contain evidenced/approved values only;
- semantic/component contracts alias governed ownership;
- no feature-owned token/color/theme catalog remains;
- no duplicate equivalent dynamic/static theme access API remains;
- no transitional compatibility alias/facade/accessor/export remains after its consumers are migrated;
- repository-wide search proves retired compatibility symbols have zero legitimate references;
- no unexplained production visual literal remains after classification;
- no visible UI change occurred without separate explicit approval;
- tests, analyze and full CI pass;
- Issue #6 and PR #22 accurately reflect the validated final state.

## Completion Lifecycle

1. Final inventory
2. Static/repository audit
3. Canonical consumer migration
4. Zero-reference compatibility audit
5. Delete compatibility aliases/facades/accessors/exports
6. Re-run zero-reference search
7. Focused tests
8. Pixel/UI regression validation
9. Analyze
10. Full CI
11. Final PR review
12. Update evidence
13. Mark Slice H and parent task `Validated`
14. Close Issue #6 only when the full agreed scope is actually complete
