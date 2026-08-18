# Professional Core Theme & Token System

**Status:** In progress — architecture blueprint frozen before further production edits  
**Primary owner:** `apps/core/lib/src/theme`  
**Consumers:** every Flutter screen/component in `apps/app`, `apps/features/*`, and core UI  
**Related issue:** #6  
**Working branch:** `codex/design-system-token-consolidation`  
**Draft PR:** #22

---

## 1. Goal

Build `apps/core/lib/src/theme/` into the single professional design-system foundation for Tio.

The finished app must not style screens by inventing random colors, sizes, spacing, radius, icon dimensions, typography, opacity, borders, motion, or reusable layout values inside screen/widget files.

The desired dependency direction is:

```text
Core foundation tokens
        ↓
Semantic/theme tokens
        ↓
Component tokens
        ↓
Reusable core components
        ↓
Feature composition tokens (only when genuinely feature-specific)
        ↓
Screens/widgets
```

The migration is **pixel-preserving by default**. Token ownership may change without changing the rendered value. A visual value changes only through a separate explicit product/design decision.

---

## 2. Non-Negotiable Rules

### 2.1 No random visual literals in production UI

Final production screen/widget code must not contain unexplained hardcoded design values for:

- spacing, padding, gaps;
- radius and shape;
- fixed component width/height/min-size;
- icon/image presentation size;
- border/stroke width;
- opacity/state alpha;
- typography size, weight, line height, letter spacing;
- animation duration/easing;
- reusable colors;
- elevation/shadow;
- recurring layout dimensions;
- reusable breakpoints or responsive factors.

Moving `20.0` from a widget into `_radius = 20.0` does **not** make it a professional token. The value must have an intentional owner and semantic name.

### 2.2 Existing token first

Before adding any token:

1. search the current core theme/token system;
2. identify the visual role;
3. verify whether an existing token has the same semantic role and exact value;
4. reuse it if yes;
5. add a new token only when ownership is justified by actual usage evidence.

### 2.3 No numeric token catalog

Do not create APIs such as:

```text
size4
size20
radius20
value56
space10
```

solely to hide literals.

Names describe **roles**, not numbers.

### 2.4 Do not normalize values silently

If a current screen uses `20dp` and the nearest shared radius is `24dp`, do not replace `20 → 24` merely to fit the scale. Preserve 20 until an explicit visual decision approves the change.

### 2.5 Static vs dynamic ownership

Static values belong to token classes.

Dynamic/theme-resolved values belong to `ThemeData`, `ThemeExtension`, or one canonical `BuildContext` extension.

Do not maintain multiple equivalent access APIs for the same value.

---

## 3. Allowed Non-Design Literals

The no-hardcode rule applies to **visual design decisions**, not every number in Dart.

Examples that may remain inline when they are truly program/data logic:

- loop indexes;
- zero/one used as mathematical identity;
- enum/data values;
- validation limits;
- dates and IDs;
- business calculations;
- collection indexes;
- runtime-derived sizes such as `availableWidth`, where the result is not a reusable design constant.

If a responsive ratio, breakpoint, or calculation is reused or expresses a design contract, it must receive a named token/contract.

---

## 4. Current Theme Audit

Current root:

```text
apps/core/lib/src/theme/
├── locals/
├── tokens/
├── theme.dart
├── tio_theme.dart
└── tio_theme_config.dart
```

Current token categories already provide a good base:

```text
tokens/
├── foundation/
├── semantic/
├── typography/
├── effects/
├── components/
└── domain/
```

### 4.1 Foundation currently verified

```text
TioSpacing
  small      = 8
  medium     = 12
  large      = 16
  extraLarge = 24

TioRadius
  small      = 8
  medium     = 12
  large      = 16
  extraLarge = 24
  full       = 999
```

A repeated `4dp` spacing rhythm is evidenced by live UI and is eligible for a semantic smallest spacing role such as:

```dart
TioSpacing.extraSmall = 4.0;
```

This is an evidence-backed scale addition, not an arbitrary numeric token.

### 4.2 Duplicate API layers found

The current `locals/` directory contains multiple wrappers that alias existing tokens, for example:

- `TioSpacingLocals` → `TioSpacing`;
- `TioRadiusLocals` → `TioRadius`;
- `TioComponentLocals` → component tokens;
- `TioDomainLocals` → domain tokens;
- `TioMotionLocals` → motion tokens;
- `TioTypographyLocals.of(context)` → `Theme.of(context).textTheme`;
- `TioShadowsLocals.of(context)` → the shadow extension.

Repository search has not shown live consumers for several of these static wrapper classes. They are **candidate duplicate APIs**, not automatic deletion targets. Exact references must be verified before removal.

`TioThemeContext` is different: `context.tioColors` and `context.tioMotion` have real consumers and represent useful dynamic theme access.

### 4.3 `TioTheme` also contains duplicate/static facades

Current `TioTheme` exposes:

```text
TioTheme.spacing
TioTheme.radius
TioTheme.motion
```

which proxy token classes through additional wrapper objects.

Known consumers exist for at least `TioTheme.spacing` and `TioTheme.radius` in core UI components. These must be migrated deliberately before facade removal.

Target rule:

- `TioTheme` = theme composition/configuration;
- static tokens = `TioSpacing`, `TioRadius`, component token classes, etc.;
- dynamic access = one canonical `BuildContext` extension.

### 4.4 Raw values inside `TioTheme`

The theme builder itself currently contains visual literals that require ownership audit, including examples such as:

- Material card radius `20`;
- input radius `14`;
- navigation label top padding `2`.

Some already have matching or related component contracts (`TioInputTokens.radius = 14`, card tokens, navigation tokens). Do not assume equivalence where semantics differ. Audit the resulting Material component and custom component contracts before aliasing.

### 4.5 Existing drift that must not be hidden

A raw Material `CardTheme` radius of `20` exists while the current reusable `TioCardTokens.radius` is `16`.

This is a real design-contract drift. The token task must determine whether:

- Material Card and `TioCard` intentionally use different shapes; or
- one of them is stale.

Do **not** silently change either pixel value during architecture cleanup.

---

## 5. Target Professional Theme Architecture

The target should remain understandable to a Flutter engineer without requiring a project-specific token map.

```text
apps/core/lib/src/theme/
├── theme.dart                         # public theme barrel only
├── tio_theme.dart                     # Tio Theme widget / ThemeData composition
├── tio_theme_config.dart              # user/system theme configuration
│
├── context/
│   ├── context.dart                   # context barrel
│   └── tio_theme_context.dart         # canonical dynamic theme getters
│
├── tokens/
│   ├── tio_tokens.dart                # token barrel
│   │
│   ├── foundation/
│   │   ├── foundation.dart
│   │   ├── tio_palette.dart
│   │   ├── tio_spacing.dart
│   │   ├── tio_radius.dart
│   │   ├── tio_icon_size.dart         # only if audit proves a reusable icon scale
│   │   ├── tio_stroke.dart            # only if audit proves reusable stroke roles
│   │   └── tio_opacity.dart           # only if audit proves stable reusable roles
│   │
│   ├── semantic/
│   │   ├── semantic.dart
│   │   ├── tio_colors.dart
│   │   └── role/state color contracts
│   │
│   ├── typography/
│   │   ├── typography.dart
│   │   └── tio_typography.dart
│   │
│   ├── effects/
│   │   ├── effects.dart
│   │   ├── tio_motion.dart
│   │   ├── tio_motion_scheme.dart
│   │   └── tio_shadows.dart
│   │
│   ├── components/
│   │   ├── components.dart
│   │   ├── tio_avatar_tokens.dart
│   │   ├── tio_button_tokens.dart
│   │   ├── tio_card_tokens.dart
│   │   ├── tio_input_tokens.dart
│   │   ├── tio_navigation_tokens.dart
│   │   ├── tio_sheet_tokens.dart
│   │   └── additional reusable component contracts only when justified
│   │
│   └── domain/
│       ├── domain.dart
│       └── tio_domain_colors.dart
│
└── builders/                          # add only if TioTheme split improves clarity
    ├── builders.dart
    ├── tio_button_theme_builder.dart
    ├── tio_input_theme_builder.dart
    ├── tio_card_theme_builder.dart
    └── tio_navigation_theme_builder.dart
```

### Important: target tree is a responsibility map, not permission for file explosion

A proposed file is created only when audit evidence justifies it.

For example, do not create `tio_icon_size.dart`, `tio_stroke.dart`, or `builders/` merely because they appear in this blueprint. First prove that centralization removes real duplication and creates a stable semantic contract.

---

## 6. `locals/` Consolidation Plan

Goal: eliminate parallel token facades while preserving useful dynamic theme access.

### Keep concept

A canonical context extension is useful:

```dart
context.tioColors
context.tioMotion
context.tioShadows
context.tioTextTheme // if adopted
```

### Remove/merge candidates after consumer audit

```text
TioSpacingLocals
TioRadiusLocals
TioComponentLocals
TioDomainLocals
TioMotionLocals
TioTypographyLocals
TioShadowsLocals
TioColorLocals.localTioColors
TioTheme.spacing
TioTheme.radius
TioTheme.motion
```

Migration rule:

- static aliases → direct token class;
- dynamic extension aliases → canonical `TioThemeContext` getter;
- remove a wrapper only after repo search shows zero consumers.

Do not break public `tio_core/core.dart` exports accidentally. Export changes require explicit API audit.

---

## 7. Token Ownership Rules

### Foundation token

Use when a stable low-level scale is reused across unrelated components/screens.

Examples:

```text
spacing rhythm
radius scale
widely reused icon-size scale
widely reused stroke roles
widely reused opacity/state primitives
```

Foundation values must not encode a feature name.

### Semantic token

Use when the value expresses product meaning rather than geometry.

Examples:

```text
textPrimary
textSecondary
surfaceRaised
success
warning
danger
workout
nutrition
progress
coach
```

### Component token

Use when the dimension/state belongs to a reusable component.

Examples:

```text
TioButtonTokens.height
TioInputTokens.minHeight
TioAvatarTokens.largeSize
TioNavigationTokens.bottomBarHeight
```

Do not push these into a generic dimensions class.

### Feature composition token

Use only when a visual contract is intentionally owned by one feature composition and is not reusable elsewhere.

Example:

```dart
class WelcomeLayoutTokens {
  const WelcomeLayoutTokens._();

  static const featurePanelRadius = 20.0;
}
```

A feature token file must be narrow and role-based. It must not become another `WelcomeDimens` catch-all bag duplicating core spacing/radius scales.

---

## 8. Naming Standard

Good:

```text
extraSmall
screenHorizontalPadding
featurePanelRadius
contentGap
loadingIndicatorSize
selectedBorderWidth
heroImageHeightFactor
featureDividerHeight
```

Bad:

```text
size20
space10
radius20
value08
customSize
bigPadding
small2
```

Token names describe intent and owner.

---

## 9. Theme API Standard

### Static

Prefer:

```dart
TioSpacing.large
TioRadius.small
TioButtonTokens.height
TioNavigationTokens.iconSize
```

### Dynamic

Prefer one canonical extension:

```dart
context.tioColors
context.tioMotion
context.tioShadows
Theme.of(context).textTheme // or context.tioTextTheme if one canonical helper is adopted
```

### Avoid final state

```dart
TioTheme.spacing.large
TioSpacingLocals.large
context.spaceLarge
TioComponentLocals.buttonHeight
```

when these merely duplicate the canonical token API.

---

## 10. Typography Standard

Screen code should first use semantic `TextTheme` roles:

```text
displayLarge
headlineMedium
titleLarge
titleMedium
bodyLarge
bodyMedium
labelLarge
labelSmall
```

If a valid reusable typography role is missing:

1. inventory all occurrences;
2. determine whether it is shared product typography or feature-specific display treatment;
3. add a semantic typography contract only with evidence;
4. preserve existing pixels during migration.

Do not create a global font token merely because one Welcome headline currently uses `42`.

A feature-specific hero style may remain feature-owned if it is genuinely unique, but its styling still belongs in an intentional feature style/token contract—not inline `TextStyle` literals in the screen.

---

## 11. Color Standard

Use in this order:

1. `context.tioColors` semantic roles;
2. `Theme.of(context).colorScheme` where Material semantic roles are appropriate;
3. domain semantic colors;
4. component-specific state colors;
5. feature composition color token only when a real feature-specific visual contract exists.

Do not create arbitrary global colors such as `gold`, `white70`, or `overlay94` unless product semantics/reuse justify them.

Media-overlay text may legitimately require a feature composition role, but the role must be named by intent.

---

## 12. Motion Standard

Use `TioMotionScheme`/`context.tioMotion` for durations and reduced-motion behavior.

Raw animation timing inside screens is not allowed in the final state unless it is runtime-derived and not a reusable design contract.

Easing curves and interval contracts must be audited similarly. Shared motion belongs in core effects; feature-specific choreography may use a feature motion contract that respects reduced motion.

---

## 13. Responsive Layout Standard

Do not tokenise every runtime size calculation.

Allowed:

```dart
final available = MediaQuery.sizeOf(context).width;
```

Governed when reusable/design-defined:

```text
compact breakpoint
content max width
hero image height factor
sheet max width
navigation transition breakpoint
```

Responsive contracts must be named by behavior, not numeric value.

---

## 14. Completed Work Before Architecture Freeze

### Slice 1 — component alias consolidation

Implemented exact semantic aliases:

```text
Button contentGap 8   → TioSpacing.small
Button radius 999     → TioRadius.full
Card padding 16       → TioSpacing.large
Card radius 16        → TioRadius.large
Card radiusItem 8     → TioRadius.small
Navigation radius 16  → TioRadius.large
Sheet padding 24      → TioSpacing.extraLarge
```

CI #399 passed full workspace analyze/tests on source head `24c4dbd`.

### Slice 2 — Avatar source-of-truth

Runtime contract remains:

```text
small      = 36
large      = 100
extraLarge = 160
```

Stale Profile documentation/test wording was aligned to runtime without a visual change. CI #401 passed full workspace analyze/tests on head `18e8d89`.

### Slice 3 — initial Welcome private-token migration

`WelcomeDimens`/`WelcomeColors` were removed from live usage and exact existing spacing/radius values were migrated where clear.

This initial source commit introduced temporary local constants for `4` and `20`; under the newly approved professional architecture those constants are **not final** and must be migrated to governed roles before Welcome is considered complete.

---

## 15. Implementation Slices From This Point

### Slice A — Core Theme Architecture Baseline

Purpose: make core theme ownership clean before migrating more screens.

- [ ] add evidence-backed `TioSpacing.extraSmall = 4`;
- [ ] update spacing contract tests;
- [ ] inventory every file under `theme/locals` and every consumer;
- [ ] consolidate dynamic access into one canonical context extension;
- [ ] migrate consumers of duplicate static `Locals` wrappers;
- [ ] migrate `TioTheme.spacing/radius/motion` consumers to canonical APIs;
- [ ] remove wrappers only after zero-reference verification;
- [ ] audit `TioTheme` raw visual values;
- [ ] map each ThemeData visual value to a component/foundation token or document intentional distinct ownership;
- [ ] decide Material Card radius `20` vs reusable card radius `16` without changing pixels silently;
- [ ] extract ThemeData component builders only if it materially improves responsibility and testability;
- [ ] keep public exports coherent;
- [ ] full CI.

### Slice B — Welcome As First Professional Consumer

- [ ] create narrow Welcome composition/style contracts for truly feature-specific values;
- [ ] replace temporary `4dp` locals with `TioSpacing.extraSmall`;
- [ ] replace panel radius `20` with role-based Welcome composition token;
- [ ] audit remaining Welcome spacing/radius/dimensions;
- [ ] audit hero typography;
- [ ] audit feature-tile typography;
- [ ] audit icon/image presentation sizes;
- [ ] audit divider width/height;
- [ ] audit panel opacity/border;
- [ ] audit backdrop gradient opacity/stops/height factor;
- [ ] audit animation offset/easing/interval;
- [ ] keep only role-based feature-specific tokens that cannot live in core;
- [ ] remove orphan Welcome legal wrapper/state after exact reference audit;
- [ ] ensure Welcome screens/widgets contain no unexplained visual literals;
- [ ] focused Welcome regression tests + full CI.

### Slice C — Core UI Components & Shell

Audit all core reusable components before feature migrations:

```text
buttons
cards
inputs
avatars
sheets
navigation
screen headers/layout helpers
shell top/bottom navigation
```

For each:

- [ ] no duplicate raw component constants;
- [ ] component-specific geometry owned by component token;
- [ ] shared geometry aliases foundation tokens where semantics match;
- [ ] theme state layers use semantic/component tokens;
- [ ] tests lock important token contracts.

### Slice D — Auth + Account Setup

- [ ] screen/widget inventory first;
- [ ] migrate colors;
- [ ] migrate typography;
- [ ] migrate spacing/radius;
- [ ] migrate icon/component sizes;
- [ ] migrate state opacity/strokes/motion;
- [ ] preserve pixels and behavior;
- [ ] focused package CI.

### Slice E — Product Onboarding

Same audit discipline. Do not mix onboarding business-flow changes into theme migration.

### Slice F — Home + Profile + Settings

Same audit discipline. Keep feature behavior untouched.

### Slice G — Workout + Nutrition + Progress + Remaining Phone UI

Proceed package-by-package, with one bounded diff at a time.

### Slice H — App-Level Composition & Final Enforcement

- [ ] app shell/composition raw visual audit;
- [ ] final export cleanup;
- [ ] final dead token cleanup;
- [ ] docs update;
- [ ] targeted static audit strategy;
- [ ] full workspace CI;
- [ ] final PR diff review;
- [ ] compact/light/dark/high-contrast/reduced-motion validation where applicable.

---

## 16. Per-File Audit Template

For every UI file, record:

```text
File:
Owner:
Current raw visual values:
Existing token matches:
Missing semantic roles:
Feature-only values:
Pixel changes required: NO by default
Tests impacted:
Result:
```

No implementation edit should begin before this classification is clear for the slice.

---

## 17. Per-Screen Acceptance Checklist

For every active screen/widget:

- [ ] colors use semantic/theme/component roles;
- [ ] typography uses semantic or deliberate feature style roles;
- [ ] spacing uses shared or role-based tokens;
- [ ] radius/shape uses shared/component/feature role tokens;
- [ ] icon/image presentation size is governed;
- [ ] fixed component dimensions are governed;
- [ ] borders/strokes are governed;
- [ ] opacity/state layers are governed;
- [ ] motion uses governed contracts and reduced-motion support;
- [ ] reusable responsive factors/breakpoints are governed;
- [ ] no feature token duplicates a core scale;
- [ ] no arbitrary `sizeN`/`radiusN` token names;
- [ ] no accidental pixel change;
- [ ] analyze/tests pass.

---

## 18. Test Strategy

### Token contract tests

Lock important ownership relationships, for example:

```text
component alias == foundation semantic role
semantic avatar size == documented runtime size
new spacing scale values remain stable
```

### Component tests

Validate important computed presentation contracts instead of testing implementation details.

### Screen regression tests

For UI-touching migrations, preserve existing key layout/contrast/semantics behavior.

### Static audit

A regex-only hardcoded-number ban is insufficient because business/math literals are legitimate.

Use a combination of:

- token ownership conventions;
- targeted repository searches;
- focused lint/static checks where reliable;
- code review checklist;
- contract/widget tests;
- documented exceptions.

---

## 19. Commit Discipline

Each commit should express one design-system responsibility.

Good examples:

```text
refactor(theme): consolidate context token access
refactor(theme): remove duplicate static locals
refactor(theme): align material component theme tokens
refactor(welcome): migrate layout values to governed tokens
refactor(auth): consume core theme contracts
```

Avoid giant commits that simultaneously touch unrelated features.

---

## 20. Hard Boundaries

This task must not modify:

- Auth identity/session architecture;
- Account Setup flow behavior;
- Product Onboarding sequencing/business rules;
- Supabase schema/data behavior;
- navigation behavior unrelated to styling;
- persistence/domain calculations.

Any such discovery becomes a separate task/issue unless a compile-only adaptation is unavoidable.

---

## 21. Quality Gates

A slice is complete only when:

1. inventory/classification is recorded;
2. ownership is clear;
3. no accidental visual value changes are introduced;
4. obsolete duplicate APIs have zero references before deletion;
5. focused tests pass;
6. Flutter/Dart analyze passes;
7. full workspace tests pass for merge-boundary slices;
8. task file is updated with actual evidence;
9. PR diff is reviewed for scope creep.

---

## 22. Current Evidence

```text
CI #399 — PASS — Slice 1 source head 24c4dbd
CI #401 — PASS — Slice 2 head 18e8d89
CI #404 — superseded/cancelled after later task-head commits; analyze stages had passed before cancellation
```

Draft PR #22 remains the working review surface. Issue #6 stays open until the agreed design-system scope is complete.

---

## 23. Next Action

**Do not start the repo-wide screen migration yet.**

The next implementation slice is:

```text
Slice A — Core Theme Architecture Baseline
```

Start with the `apps/core/lib/src/theme` ownership cleanup and contract tests. Once the core API is stable and CI is green, migrate Welcome as the first full consumer, then continue feature-by-feature.

---

## 24. Final Status

`PARTIAL — professional architecture blueprint complete; implementation must now follow this task file slice-by-slice.`
