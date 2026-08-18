# Design System Slice H — Final Enforcement

**Status:** Blocked by Slice G  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Complete repository-wide enforcement of the centralized design-system ownership model and prove that no duplicate physical visual ownership, feature token catalogs, or unapproved visual drift remain.

## Mandatory Visual Freeze

No cleanup in this slice may redesign or restyle any screen. Any discovered visual improvement/defect becomes a separate approved decision/task.

## Preconditions

- [ ] Slices A–G are `Validated`.

## Checklist

- [ ] Audit app shell/composition and all remaining production UI for raw fixed visual literals.
- [ ] Audit canonical primitive registries for evidence-only values and dead entries.
- [ ] Confirm foundation/semantic/typography/effects/component roles do not redefine physical values independently.
- [ ] Confirm no `WelcomeTokens`, `AuthTokens`, `OnboardingTokens`, `HomeTokens`, `ProfileTokens`, or equivalent feature token/color/layout/theme catalogs remain.
- [ ] Confirm no screen-specific token bags were hidden under core component tokens.
- [ ] Confirm dynamic access is canonical (`context.tioColors`, `context.tioMotion`, `context.tioShadows`, semantic `TextTheme`) and static tokens are accessed directly.
- [ ] Confirm transitional compatibility APIs have zero references before removal.
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
- no unexplained production visual literal remains after classification;
- no visible UI change occurred without separate explicit approval;
- tests, analyze and full CI pass;
- Issue #6 and PR #22 accurately reflect the validated final state.

## Completion Lifecycle

1. Final inventory
2. Static/repository audit
3. Ownership cleanup
4. Focused tests
5. Pixel/UI regression validation
6. Analyze
7. Full CI
8. Final PR review
9. Update evidence
10. Mark Slice H and parent task `Validated`
11. Close Issue #6 only when the full agreed scope is actually complete
