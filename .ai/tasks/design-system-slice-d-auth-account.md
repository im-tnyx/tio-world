# Design System Slice D — Auth + Account Setup

**Status:** In progress  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Migrate Auth and Account Setup production UI to governed core design-system ownership without changing authentication behavior, account-setup flow, or rendered UI.

## Mandatory Visual Freeze

```text
pixels before == pixels after
```

No screen design, layout, spacing, color appearance, typography appearance, radius, icon/image sizing, motion, gradient, component geometry, legal placement, or interaction visual may change without separate explicit owner/design approval.

## Preconditions

- [x] Slice A source/runtime boundary validated by Flutter CI #624.
- [x] Slice B Welcome validated by Flutter CI #646.
- [x] Slice C Core Components validated; final source boundary passed Flutter CI #710.
- [x] Feature UI agents are instructed to read `apps/core/lib/src/theme/README.md` before internal token files.
- [x] Core component-token admission gate forbids feature/screen/workflow token bags.

## Scope

- `apps/features/auth/**` presentation UI;
- Account Setup presentation UI on the current branch;
- narrowly required existing core design-system contracts only when real evidence shows a missing reusable owner;
- focused Auth/Account Setup tests and static audits.

## Hard Boundaries

- no auth/session architecture changes;
- no provider/sign-in behavior changes;
- no Firebase/Supabase/auth backend behavior changes;
- no Account Setup sequencing/business-rule changes;
- no navigation/routing behavior changes except purely mechanical import/token ownership changes when unavoidable;
- no legal placement move/removal/addition unless separately approved;
- no feature token/color/layout/theme catalog;
- no `AuthTokens`, `AccountSetupTokens`, screen-specific core token classes, or equivalent replacement bags;
- do not implement the separate reusable-field Issue #24 unless this slice is explicitly expanded later.

## Ownership Rules

Use this order for every fixed visual value:

```text
Existing reusable core component
        ↓
Existing runtime semantic role / TextTheme
        ↓
Existing reusable component contract
        ↓
Existing exact governed primitive
        ↓
Only then consider a narrowly evidenced reusable core extension
```

Behavior/domain/program values stay outside the design-token system.

Examples:

```text
provider/auth flow state            → behavior, not token
form validation limits              → behavior, not token
animation interval/flex/gradient stop → local composition when not reusable semantics
screen-specific visual token bag    → forbidden
```

## Checklist

### D1 — Inventory and classification

- [ ] Inventory Auth/Account Setup screens/widgets and current visual helper/token/theme files.
- [ ] Inventory raw fixed colors, typography, geometry, strokes, opacity/alpha, motion, shadows and component sizes.
- [ ] Inventory direct Flutter `TextField`/button/card/dialog usage only to classify current ownership; do not redesign field architecture here.
- [ ] Classify behavior/domain/composition literals separately from product-visible fixed visual values.
- [ ] Record exact current rendered values before mutations.

### D2 — Ownership plan

- [ ] Map each visual value to existing core semantic/component/primitive ownership first.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md` to colors/alpha/gradients/shadows/state layers.
- [ ] Identify feature-local token/theme/color/layout catalogs for removal.
- [ ] Reject any proposed core token class that fails the component-token admission gate.
- [ ] Preserve one-off composition data locally rather than inventing a feature token bag.

### D3 — Implementation

- [ ] Migrate Auth/Account Setup consumers in bounded batches.
- [ ] Prefer existing reusable core components where the visual/behavior contract already matches exactly.
- [ ] Preserve provider buttons, fields, legal copy/placement, loading states and interaction visuals exactly.
- [ ] Delete obsolete feature visual/token helpers only after zero-reference verification.

### D4 — Validation

- [ ] Run existing focused Auth/Account Setup widget tests.
- [ ] Run static zero-reference / forbidden-token / compatibility-alias audit.
- [ ] Verify no auth/provider/session/account-setup behavior changed.
- [ ] Verify no unapproved visible UI change occurred.
- [ ] Run analyze and required Flutter CI.
- [ ] Record final evidence, mark Slice D `Validated`, and unblock Slice E.

## Completion Lifecycle

1. Inventory
2. Classification
3. Planned ownership
4. Implementation
5. Focused tests
6. Static audit
7. Pixel/UI regression check
8. Analyze
9. Required CI
10. Update evidence
11. Mark `Validated`
12. Unblock Slice E

## Exit Criteria

- Auth/Account Setup consume canonical core design-system ownership;
- no feature token/color/layout/theme catalog remains;
- no screen/workflow-specific token class is introduced in core;
- behavior, routing, provider/auth state and account-setup flow remain unchanged;
- no visible UI change occurred without separate approval;
- focused tests/analyze/required CI pass.
