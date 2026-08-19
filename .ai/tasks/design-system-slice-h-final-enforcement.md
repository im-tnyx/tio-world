# Design System Slice H — Final Enforcement

**Status:** Validated  
**Current phase:** Complete  
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

Examples include:

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

## Checklist

- [x] Audit app shell/composition and all remaining production UI for raw fixed visual literals.
- [x] Audit canonical primitive registries for evidence-only values and dead entries.
- [x] Confirm foundation/semantic/typography/effects/component roles do not redefine physical values independently.
- [x] Confirm no `WelcomeTokens`, `AuthTokens`, `OnboardingTokens`, `HomeTokens`, `ProfileTokens`, or equivalent feature token/color/layout/theme catalogs remain.
- [x] Confirm no screen-specific token bags were hidden under core component tokens.
- [x] Confirm dynamic access is canonical (`context.tioColors`, `context.tioMotion`, `context.tioShadows`, semantic `TextTheme`) and static tokens are accessed directly.
- [x] Inventory every transitional compatibility alias/facade/accessor/export introduced or retained during Slices A–G.
- [x] Migrate every remaining compatibility consumer to the canonical API.
- [x] Prove zero legitimate references for every compatibility symbol before removal.
- [x] Delete zero-reference compatibility aliases/facades/accessors/exports and update/remove compatibility-only tests.
- [x] Re-run repository search after deletion to prove the old symbols are gone.
- [x] Audit colors using `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [x] Verify representative primitive searchability such as `TioSize.dp20`.
- [x] Run static searches for UI constructors/raw values and classify legitimate business/runtime literals.
- [x] Run focused tests across touched packages.
- [x] Run Flutter/Dart analyze.
- [x] Run full workspace CI.
- [x] Validate representative compact/light/dark/OLED/high-contrast/reduced-motion states where applicable.
- [x] Review final PR #22 diff for scope creep and visible UI drift.
- [x] Update parent task, Issue #6, PR #22 and child task statuses with verified evidence only.

## Final Validation Evidence

Final runtime/source validation head `9dfe2d746e5d126f3ade27923b66e241359dce64` passed **Flutter CI #865** end-to-end.

The CI gate verified:

- Flutter analyze across Flutter packages;
- Dart analyze for pure-Dart packages;
- full Flutter package test matrix;
- full Dart test matrix;
- `final_enforcement_visual_ownership_test.dart` — no unexplained production raw visual ownership;
- `final_enforcement_compatibility_test.dart` — zero Dart references to retired compatibility APIs;
- `final_enforcement_primitive_liveness_test.dart` — primitive registries contain production-backed values only;
- `final_enforcement_architecture_test.dart` — no feature-owned presentation design-system catalogs and retired compatibility structure remains absent;
- canonical color ownership across light/dark/OLED/high-contrast mappings;
- reduced-motion, compact-layout and accessibility regression coverage;
- feature-specific design-system ownership gates for Onboarding, Profile, Settings, Splash and Wear.

CI #864 had one enforcement-test self-reference false positive: the architecture test contained the retired `TioMotionTokens` symbol as assertion text, which the repository scanner then detected as a source reference. Commit `9dfe2d746e5d126f3ade27923b66e241359dce64` preserved the assertion semantics while splitting the source literal so the scanner measures actual retired API references. CI #865 then passed with `tio_core` at 100 tests and the complete workspace green.

Final PR scope review also identified two unrelated planned task documents for Issues #23 and #24. They were removed from the #6 branch in docs-only commits `e2d677643f251bc6d6706895698ba055aafaf411` and `6a1df021c262cba15f17d64b77962581e3253289`. These commits do not alter runtime or design-system source and keep PR #22 bounded to Issue #6.

## Repository-Wide Definition of Done

- [x] every fixed product-visible physical value has one canonical core owner;
- [x] primitive registries contain evidenced/approved values only;
- [x] semantic/component contracts alias governed ownership;
- [x] no feature-owned token/color/theme catalog remains;
- [x] no duplicate equivalent dynamic/static theme access API remains;
- [x] no transitional compatibility alias/facade/accessor/export remains after its consumers are migrated;
- [x] repository-wide enforcement proves retired compatibility symbols have zero legitimate references;
- [x] no unexplained production visual literal remains after classification;
- [x] no visible UI change was introduced outside separately approved decisions;
- [x] tests, analyze and full CI pass;
- [x] Issue #6 and PR #22 are ready to reflect the validated final state.

## Completion Lifecycle

1. Final inventory — complete
2. Static/repository audit — complete
3. Canonical consumer migration — complete
4. Zero-reference compatibility audit — complete
5. Compatibility deletion — complete
6. Re-run zero-reference search — complete
7. Focused tests — complete
8. UI/accessibility regression validation — complete
9. Analyze — complete
10. Full CI — complete via Flutter CI #865
11. Final PR scope review — complete
12. Evidence update — complete
13. Slice H / parent validation — complete
14. Issue #6 remains open until PR #22 is reviewed/merged; close only after the merged repository contains the validated final state.
