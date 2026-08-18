# Professional Core Theme & Token System

**Status:** In progress — architecture corrected before further production edits  
**Primary owner:** `apps/core/lib/src/theme`  
**Consumers:** every Flutter screen/component in `apps/app`, `apps/features/*`, and core UI  
**Reference architecture:** `im-tnyx/Tio-hub` core theme centralization, adapted for Flutter  
**Related issue:** #6  
**Working branch:** `codex/design-system-token-consolidation`  
**Draft PR:** #22

---

## 1. Goal

Build `apps/core/lib/src/theme/` into the single professional design-system source of truth for Tio.

The finished app must not invent fixed visual values independently inside component, feature, screen, or widget files. Every fixed visual value must be governed from core theme/token ownership so the repository can answer questions such as:

```text
Where is 20dp used?
Which components depend on 16dp?
What is the blast radius of changing a fixed size?
Which token owns a border width, icon size, radius, opacity, or duration?
```

The desired dependency direction is:

```text
Primitive foundation tokens
        ↓
Foundation / semantic / typography / effects roles
        ↓
Component tokens
        ↓
Reusable core components
        ↓
Feature screens/widgets
```

There is **no feature composition token layer** in the final architecture.

The migration is **pixel-preserving by default**. Token ownership may change without changing the rendered value. A visual value changes only through a separate explicit product/design decision.

---

## 2. Non-Negotiable Rules

### 2.1 One primitive source of truth for fixed visual values

Every fixed visual numeric value must have exactly one primitive owner in core.

Examples include:

- spacing and gaps;
- width, height, min/max size;
- icon/image presentation size;
- radius;
- border/stroke width;
- fixed padding/insets;
- typography size, line height, letter spacing where represented as fixed design values;
- opacity/state alpha;
- animation duration;
- reusable elevation/shadow measurements;
- reusable breakpoints, ratios, or visual factors.

Component tokens, semantic tokens, screens, and widgets may **reference or alias** primitive values. They must not redefine the same numeric value independently.

Bad:

```dart
class TioButtonTokens {
  static const height = 46.0;
  static const horizontalPadding = 20.0;
}
```

Target:

```dart
class TioSize {
  static const dp20 = 20.0;
  static const dp46 = 46.0;
}

class TioButtonTokens {
  static const height = TioSize.dp46;
  static const horizontalPadding = TioSize.dp20;
}
```

The exact class/file names may be refined during implementation, but this ownership invariant is mandatory.

### 2.2 Primitive numeric names are allowed only at the primitive layer

Previous guidance that rejected every numeric token name was too broad.

At the primitive layer, numeric names are intentional because the primitive represents the physical value itself:

```text
TioSize.dp0
TioSize.dp1
TioSize.dp2
TioSize.dp4
TioSize.dp6
TioSize.dp8
TioSize.dp10
TioSize.dp12
TioSize.dp14
TioSize.dp16
TioSize.dp18
TioSize.dp20
...
```

Do **not** pre-create every integer up to an arbitrary maximum. The primitive registry should contain every approved fixed value actually evidenced by production UI, plus values intentionally added by an explicit design decision.

Numeric naming is **not allowed** as the public semantic/component role:

```text
TioButtonTokens.size46       ❌
TioInputTokens.radius14      ❌
TioSpacing.space8            ❌
TioRadius.radius20           ❌

TioButtonTokens.height       ✅
TioInputTokens.radius        ✅
TioSpacing.small             ✅
TioRadius.large              ✅
```

### 2.3 Component tokens are aliases/contracts, not numeric stores

Component tokens express component meaning:

```text
TioButtonTokens.height
TioButtonTokens.horizontalPadding
TioInputTokens.minHeight
TioNavigationTokens.iconSize
```

Their fixed numeric values must resolve to primitive or lower-level governed tokens.

A component token file must not become a second dimensions catalog.

### 2.4 No feature-owned design-token catalogs

Final production architecture must not introduce parallel feature token systems such as:

```text
WelcomeTokens
WelcomeLayoutTokens
WelcomeColorTokens
WelcomeTypographyTokens
WelcomeMotionTokens
AuthTokens
OnboardingTokens
HomeTokens
```

Feature screens/widgets consume the core design system.

For a truly one-off fixed layout value that does not deserve a reusable semantic/component role, the feature may consume an approved core primitive directly rather than creating a feature token catalog.

Example:

```dart
SizedBox(width: TioSize.dp60)
```

This keeps the physical value centralized and searchable without creating another token ownership layer.

### 2.5 No random visual literals in production UI

Final production UI code must not contain unexplained raw visual literals for:

- spacing, padding, gaps;
- radius and shape;
- fixed width/height/min-size;
- icon/image presentation size;
- border/stroke width;
- opacity/state alpha;
- typography size, weight, line height, letter spacing;
- animation duration/easing contracts;
- reusable colors;
- elevation/shadow;
- recurring layout dimensions;
- reusable breakpoints or responsive factors.

Moving `20.0` from a widget into `_radius = 20.0` does not solve ownership.

### 2.6 Existing primitive/token first

Before adding any fixed value or role:

1. search the primitive registry;
2. search existing foundation/semantic/component roles;
3. identify the visual role;
4. reuse the exact existing primitive if the physical value already exists;
5. reuse an existing semantic/component role when semantics also match;
6. add a new primitive only when the exact fixed value is not already governed;
7. add a new role only when the role itself is justified.

### 2.7 Do not normalize values silently

If current UI uses `20dp` and the nearest semantic radius is `24dp`, do not replace `20 → 24` merely to fit a scale.

Instead:

1. preserve `20` as a primitive value;
2. classify its role;
3. alias it appropriately or consume the primitive directly;
4. change pixels only through a separate design decision.

### 2.8 Static vs dynamic ownership

Static primitives and static role contracts belong to token classes.

Dynamic/theme-resolved values belong to `ThemeData`, `ThemeExtension`, or one canonical `BuildContext` extension.

Do not maintain multiple equivalent access APIs for the same value.

---

## 3. Allowed Non-Design Literals

The no-hardcode rule applies to visual design decisions, not every number in Dart.

Examples that may remain inline when truly program/data logic:

- loop indexes;
- zero/one used as mathematical identity;
- enum/data values;
- validation limits;
- dates and IDs;
- business calculations;
- collection indexes;
- runtime-derived sizes such as `availableWidth` where the result is not a fixed design decision.

A fixed visual ratio, breakpoint, gradient stop, animation interval, or reusable calculation is governed if it represents a design contract.

---

## 4. Current Theme Audit

Current core structure already has the right high-level category direction:

```text
apps/core/lib/src/theme/
├── context/
├── tokens/
│   ├── foundation/
│   ├── semantic/
│   ├── typography/
│   ├── effects/
│   ├── components/
│   └── domain/
├── theme.dart
├── tio_theme.dart
└── tio_theme_config.dart
```

This broadly matches the centralized ownership principle verified in `Tio-hub`, where foundation, semantic, typography, effects, component, and domain contracts live under core theme rather than inside feature modules.

### 4.1 Current foundation is incomplete

Currently verified foundation files include:

```text
tio_palette.dart
tio_spacing.dart
tio_radius.dart
```

Current spacing/radius roles include:

```text
TioSpacing
  extraSmall = 4
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

These currently own raw values directly. Under the corrected architecture they should resolve through primitive values where appropriate.

### 4.2 Raw numeric values already exist inside component token files

Examples currently verified:

```text
TioButtonTokens
  height                      = 46
  minimumWidth                = 0
  horizontalPadding           = 20
  loadingIndicatorSize        = 18
  loadingIndicatorStrokeWidth = 2
  outlineWidth                = 1
  focusedOutlineWidth         = 2

TioInputTokens
  radius                       = 14
  minHeight                    = 52
  mobileFieldHeight            = 56
  mobileVerifiedIconSize       = 22
  usernameIconSize             = 20
  usernameCheckingIndicatorSize = 16
  usernameSupportingGap        = 6
  usernameSuggestionRadius     = 20
  ...
```

These are migration debt. Component tokens should retain their semantic names but their physical values must be moved to canonical primitives/lower roles.

### 4.3 Duplicate access layers

Historical/static wrappers and facades must still be audited and consolidated deliberately.

Target principle:

- primitive/static role tokens = direct token classes;
- dynamic theme values = one canonical context API;
- `TioTheme` = theme composition/configuration, not a second static token facade.

### 4.4 Existing visual drift must not be hidden

Known examples such as Material Card radius `20` vs reusable card radius `16` are real contract differences until proven stale.

Do not collapse distinct pixels merely to simplify the registry.

The primitive layer can contain both values while semantic/component ownership is audited.

---

## 5. Target Professional Theme Architecture

```text
apps/core/lib/src/theme/
├── theme.dart
├── tio_theme.dart
├── tio_theme_config.dart
│
├── context/
│   ├── context.dart
│   └── tio_theme_context.dart
│
├── tokens/
│   ├── tio_tokens.dart
│   │
│   ├── primitive/
│   │   ├── primitive.dart
│   │   ├── tio_size.dart              # canonical fixed geometry values
│   │   ├── tio_opacity.dart           # canonical alpha values
│   │   ├── tio_duration.dart          # canonical fixed durations
│   │   └── additional primitive families only when evidenced
│   │
│   ├── foundation/
│   │   ├── foundation.dart
│   │   ├── tio_palette.dart
│   │   ├── tio_spacing.dart
│   │   ├── tio_radius.dart
│   │   ├── tio_icon_size.dart
│   │   └── tio_stroke.dart
│   │
│   ├── semantic/
│   │   ├── semantic.dart
│   │   └── tio_colors.dart
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
└── builders/                          # optional, only if ThemeData composition benefits
    ├── builders.dart
    ├── tio_button_theme_builder.dart
    ├── tio_input_theme_builder.dart
    ├── tio_card_theme_builder.dart
    └── tio_navigation_theme_builder.dart
```

### Dependency rule

```text
Primitive physical values
        ↓
Foundation/semantic/type/effect roles
        ↓
Component contracts
        ↓
Reusable core components
        ↓
Features
```

Dependencies must not point upward or sideways into feature-owned token catalogs.

### No file explosion

Create a primitive/token family only when evidence justifies it.

However, unlike the earlier blueprint, `TioSize` or an equivalent canonical fixed-geometry primitive is now **required**, because current component files already prove that raw geometry is duplicated across owners.

---

## 6. Primitive Foundation Standard

### 6.1 Geometry

All approved fixed geometry values must resolve to one canonical registry such as `TioSize`.

Example shape:

```dart
abstract final class TioSize {
  static const dp0 = 0.0;
  static const dp1 = 1.0;
  static const dp2 = 2.0;
  static const dp4 = 4.0;
  static const dp6 = 6.0;
  static const dp8 = 8.0;
  static const dp10 = 10.0;
  static const dp12 = 12.0;
  static const dp14 = 14.0;
  static const dp16 = 16.0;
  static const dp18 = 18.0;
  static const dp20 = 20.0;
  static const dp22 = 22.0;
  static const dp24 = 24.0;
}
```

This example is illustrative, not a license to add unused values.

A repository search for `TioSize.dp20` should make the dependency surface of physical `20dp` discoverable.

### 6.2 Spacing/radius/icon/stroke roles

Role tokens alias primitives:

```dart
TioSpacing.small = TioSize.dp8;
TioRadius.large = TioSize.dp16;
TioIconSize.medium = TioSize.dp20;
TioStroke.medium = TioSize.dp2;
```

### 6.3 Component geometry

Component contracts alias primitive or semantic geometry:

```dart
TioButtonTokens.height = TioSize.dp46;
TioButtonTokens.contentGap = TioSpacing.small;
TioButtonTokens.loadingIndicatorSize = TioSize.dp18;
```

No raw `46.0`, `18.0`, etc. remain in the component file.

### 6.4 Other primitive families

The same one-source rule applies to other fixed visual scalar values.

Examples:

```text
opacity → TioOpacity or equivalent
fixed duration → TioDuration / governed motion primitive
typography physical scale → governed typography primitives/roles
palette colors → TioPalette
```

Do not force unrelated concepts into `TioSize` just because they are numeric.

---

## 7. Token Ownership Rules

### Primitive token

Owns the physical value, not product meaning.

Examples:

```text
dp20
alpha38
milliseconds200
```

### Foundation role

Names a reusable geometric role and aliases primitives.

Examples:

```text
spacing.small
radius.large
iconSize.medium
stroke.thin
```

### Semantic token

Expresses product/theme meaning.

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

Expresses reusable component meaning and composes lower-level tokens.

Examples:

```text
TioButtonTokens.height
TioInputTokens.minHeight
TioAvatarTokens.largeSize
TioNavigationTokens.bottomBarHeight
```

### Feature code

Features consume core tokens/components.

They do not own a parallel design-token taxonomy.

For one-off layout geometry, prefer a direct governed primitive over a feature token wrapper when no reusable semantic role exists.

---

## 8. Naming Standard

### Primitive layer

Numeric physical names are acceptable and expected:

```text
dp0
dp1
dp2
dp20
```

### Semantic/component layer

Names describe intent:

```text
extraSmall
screenHorizontalPadding
contentGap
loadingIndicatorSize
selectedBorderWidth
```

Avoid semantic APIs named only by number:

```text
size20
radius20
space10
value08
```

---

## 9. Theme API Standard

### Static

Prefer direct canonical classes:

```dart
TioSize.dp20
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
Theme.of(context).textTheme
```

### Avoid duplicate APIs

Do not keep equivalent wrappers such as:

```dart
TioTheme.spacing.large
TioSpacingLocals.large
context.spaceLarge
TioComponentLocals.buttonHeight
```

when they merely mirror the canonical source.

---

## 10. Typography Standard

Typography must also avoid raw visual numbers scattered through feature/component files.

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

If the current product requires additional exact typography values:

1. inventory occurrences;
2. preserve current pixels;
3. add the physical typography scale/role in core;
4. expose a semantic typography role;
5. consume that role from features.

Do not solve a unique Welcome headline by creating `WelcomeTypographyTokens`.

---

## 11. Color Standard

Use centralized core ownership in this order:

1. `context.tioColors` semantic roles;
2. `Theme.of(context).colorScheme` where Material semantic roles are appropriate;
3. domain semantic colors;
4. component-specific state colors that resolve from core theme roles;
5. palette primitives only when intentionally required.

Do not create `WelcomeColorTokens`, `AuthColorTokens`, or equivalent feature color catalogs.

If a missing media-overlay semantic is real, add a reusable/intentional core semantic role after evidence rather than hiding the raw color inside a feature.

---

## 12. Motion Standard

Use governed core motion contracts for durations and reduced-motion behavior.

Raw animation timings must not be introduced in screen/widget files.

Shared easing and interval contracts belong in core effects/motion ownership.

For one-off choreography values, use governed core primitive/effect contracts rather than `WelcomeMotionTokens` or another feature motion catalog.

---

## 13. Responsive Layout Standard

Runtime-derived measurements may stay runtime-derived:

```dart
final available = MediaQuery.sizeOf(context).width;
```

Fixed design breakpoints, max widths, ratios, and factors are governed values.

If a fixed value is unique to one screen and no reusable semantic role is justified, consume a canonical core primitive directly. Do not create a feature token layer merely to rename it.

---

## 14. `locals/` Consolidation Plan

Keep one canonical dynamic context API where Flutter needs theme-resolved access.

Audit/remove duplicate static wrappers only after zero-reference verification.

Migration rule:

- static aliases → direct canonical token class;
- dynamic aliases → canonical `TioThemeContext` getter;
- preserve public exports intentionally;
- do not copy Jetpack Compose `CompositionLocal` mechanics into Flutter merely because `Tio-hub` uses them.

`Tio-hub` is the ownership reference, not a framework-mechanics template.

---

## 15. Completed Work Before Architecture Correction

### Slice 1 — component alias consolidation

Previous work aliased several component roles to spacing/radius roles and passed CI #399.

### Slice 2 — Avatar source-of-truth

Runtime contract remained:

```text
small      = 36
large      = 100
extraLarge = 160
```

CI #401 passed.

### Slice 3 — initial Welcome private-token migration

Earlier work removed `WelcomeDimens`/`WelcomeColors` from live usage but later introduced `welcome_visual_tokens.dart` with feature-owned layout/motion/typography/color contracts.

Under this corrected architecture, that is **transitional debt, not the final pattern**.

Do not replicate it into Auth, Onboarding, Home, or other features.

---

## 16. Implementation Slices From This Point

### Slice A — Primitive Foundation + Core Ownership Baseline

Do this before further feature migration.

- [ ] inventory every raw fixed visual scalar in `apps/core/lib/src/theme/tokens/**`;
- [ ] create canonical primitive geometry registry (`TioSize` or final agreed equivalent);
- [ ] populate it only with evidenced fixed values currently in production UI;
- [ ] add governed primitive families for opacity/duration only where needed;
- [ ] migrate `TioSpacing` and `TioRadius` raw values to primitive aliases;
- [ ] add `TioIconSize` / `TioStroke` when evidence supports reusable roles;
- [ ] migrate raw geometry out of `TioButtonTokens`;
- [ ] migrate raw geometry out of `TioInputTokens`;
- [ ] audit every remaining component token class for raw fixed numbers;
- [ ] inventory every file under old/static `theme/locals` APIs and every consumer;
- [ ] consolidate dynamic access into one canonical context extension;
- [ ] migrate duplicate static facade consumers;
- [ ] audit `TioTheme` raw visual values;
- [ ] preserve distinct values such as card radius `20` vs `16` until design ownership is resolved;
- [ ] update token contract tests;
- [ ] full CI.

### Slice B — Welcome Cleanup as First Consumer

- [ ] inventory every value currently in `welcome_visual_tokens.dart`;
- [ ] classify each as primitive geometry, semantic color, typography, motion/effect, reusable component role, or runtime/program logic;
- [ ] move/alias governed physical values into core primitives/roles;
- [ ] migrate Welcome screen/widgets to core tokens/components;
- [ ] remove `WelcomeLayoutTokens` final-state dependency;
- [ ] remove `WelcomeTypographyTokens` final-state dependency;
- [ ] remove `WelcomeColorTokens` final-state dependency;
- [ ] remove `WelcomeMotionTokens` final-state dependency;
- [ ] remove `WelcomeBackdropTokens` final-state dependency where values are fixed visual contracts;
- [ ] do not replace them with another feature token file;
- [ ] preserve pixels/behavior;
- [ ] focused Welcome regression tests + full CI.

### Slice C — Core UI Components & Shell

Audit:

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

- [ ] no raw fixed visual numbers inside component token files except justified non-design logic;
- [ ] component roles alias primitive/foundation/semantic contracts;
- [ ] no duplicate physical value ownership;
- [ ] theme state layers use semantic/component contracts;
- [ ] tests lock important ownership relationships.

### Slice D — Auth + Account Setup

- [ ] screen/widget inventory first;
- [ ] migrate colors;
- [ ] migrate typography;
- [ ] migrate spacing/radius;
- [ ] migrate icon/component sizes;
- [ ] migrate state opacity/strokes/motion;
- [ ] no feature token catalog;
- [ ] preserve pixels and behavior;
- [ ] focused package CI.

### Slice E — Product Onboarding

Same ownership rules. Do not mix business-flow changes into theme migration.

### Slice F — Home + Profile + Settings

Same ownership rules. No feature design-token catalogs.

### Slice G — Workout + Nutrition + Progress + Remaining Phone UI

Proceed package-by-package with bounded diffs.

### Slice H — App-Level Composition & Final Enforcement

- [ ] app shell/composition raw visual audit;
- [ ] final primitive registry audit;
- [ ] confirm no duplicate raw fixed geometry in semantic/component/feature layers;
- [ ] confirm no feature-owned token catalogs remain;
- [ ] final export cleanup;
- [ ] dead token cleanup;
- [ ] docs update;
- [ ] static audit strategy;
- [ ] full workspace CI;
- [ ] final PR diff review;
- [ ] compact/light/dark/high-contrast/reduced-motion validation where applicable.

---

## 17. Per-File Audit Template

For every UI/token file, record:

```text
File:
Owner:
Raw fixed visual values:
Existing primitive matches:
Existing semantic/component role matches:
New primitive values required:
New roles required:
Runtime/program literals allowed:
Pixel changes required: NO by default
Tests impacted:
Result:
```

No implementation edit should begin before classification is clear for the slice.

---

## 18. Per-Screen Acceptance Checklist

For every active screen/widget:

- [ ] no raw fixed visual geometry;
- [ ] colors use core semantic/theme/component roles;
- [ ] typography uses core semantic roles;
- [ ] spacing uses governed core roles/primitives;
- [ ] radius/shape uses governed core roles/primitives;
- [ ] icon/image presentation size is governed;
- [ ] fixed component dimensions are governed;
- [ ] borders/strokes are governed;
- [ ] opacity/state layers are governed;
- [ ] motion is governed and supports reduced motion;
- [ ] fixed responsive factors/breakpoints are governed;
- [ ] no feature-owned design-token catalog;
- [ ] no duplicate physical value source;
- [ ] no accidental pixel change;
- [ ] analyze/tests pass.

---

## 19. Test Strategy

### Primitive contract tests

Lock important canonical values that are already product contracts.

### Alias contract tests

Verify ownership relationships such as:

```text
TioSpacing.small == TioSize.dp8
TioRadius.large == TioSize.dp16
TioButtonTokens.contentGap == TioSpacing.small
TioButtonTokens.height == canonical primitive
```

### Component tests

Validate computed presentation contracts rather than implementation details.

### Screen regression tests

Preserve layout/contrast/semantics behavior during ownership migration.

### Static audit

A regex-only numeric ban is insufficient because business/math literals are legitimate.

Static/review checks should specifically target UI constructors and token files for raw fixed visual scalars and feature-token catalogs.

---

## 20. Searchability Requirement

The design system must make physical values discoverable.

Example expectation:

```text
search: TioSize.dp20
```

should reveal every role/component/screen that directly depends on the canonical `20dp` primitive.

A raw repository search for `20.0` should not be required to understand design-system ownership.

This searchability requirement is a first-class acceptance criterion.

---

## 21. Commit Discipline

Each commit should express one ownership responsibility.

Good examples:

```text
refactor(theme): add canonical size primitives
refactor(theme): alias spacing and radius to primitives
refactor(theme): migrate button geometry to primitives
refactor(theme): migrate input geometry to primitives
refactor(welcome): remove feature token catalog
refactor(auth): consume core theme contracts
```

Avoid giant commits that touch unrelated features simultaneously.

---

## 22. Hard Boundaries

This task must not modify:

- Auth identity/session architecture;
- Account Setup flow behavior;
- Product Onboarding sequencing/business rules;
- Supabase schema/data behavior;
- navigation behavior unrelated to styling;
- persistence/domain calculations.

Any such discovery becomes a separate task/issue unless a compile-only adaptation is unavoidable.

---

## 23. Quality Gates

A slice is complete only when:

1. inventory/classification is recorded;
2. every fixed visual scalar has one primitive source of truth;
3. semantic/component tokens do not redefine raw physical values;
4. features do not create parallel token catalogs;
5. no accidental visual value changes are introduced;
6. obsolete duplicate APIs have zero references before deletion;
7. focused tests pass;
8. Flutter/Dart analyze passes;
9. full workspace tests pass for merge-boundary slices;
10. task file is updated with actual evidence;
11. PR diff is reviewed for scope creep;
12. token searchability is verified for representative physical values.

---

## 24. Current Evidence

```text
CI #399 — PASS — Slice 1 source head 24c4dbd
CI #401 — PASS — Slice 2 head 18e8d89
CI #404 — superseded/cancelled after later task-head commits; analyze stages had passed before cancellation
```

Repository evidence also confirms:

```text
Tio-hub centralizes token categories under core theme.
Tio-world currently has raw physical values inside component token files.
Tio-world currently has a transitional Welcome feature token catalog.
```

Draft PR #22 remains the working review surface. Issue #6 stays open until the agreed design-system scope is complete.

---

## 25. Next Action

**Do not continue repo-wide feature migration yet.**

The next implementation slice is now:

```text
Slice A — Primitive Foundation + Core Ownership Baseline
```

First establish the canonical primitive registry and remove raw physical-value ownership from semantic/component layers. Then clean Welcome as the first consumer and continue feature-by-feature.

---

## 26. Final Status

`PARTIAL — architecture corrected; implementation must now migrate existing component/feature token debt to the canonical core primitive model before further rollout.`
