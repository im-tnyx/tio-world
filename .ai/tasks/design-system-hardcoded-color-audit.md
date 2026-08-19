# Design System Hardcoded Color Audit

**Status:** Planned / audit in progress  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Draft PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`  
**Scope:** Flutter production UI in `apps/core`, `apps/app`, `apps/features/*`, and `apps/wear`

---

## 1. Goal

Remove accidental hardcoded visual colors from production UI and route every intentional product color through the centralized Tio core design-system ownership model.

This is an ownership/refactor task, **not a recolor or screen redesign task**.

### Mandatory visual-freeze rule

No screen design, layout, styling, color appearance, typography appearance, spacing, radius, icon sizing, component geometry, motion behavior, or other visible UI contract may change without a **separate explicit owner/design confirmation**.

During this task:

- preserve the exact currently rendered color/value by default;
- do not improve, modernize, normalize, restyle, simplify, or "fix" a screen visually while migrating ownership;
- do not change a color merely because another semantic token looks close;
- do not change contrast/layout/style unless the owner separately approves that visual change;
- if a genuine UI/design defect is discovered, record it as a separate decision/task instead of silently changing it here.

A token migration that changes the visible screen without separate confirmation fails this task even when the new implementation appears cleaner.

---

## 2. Corrected Color Ownership Architecture

Color ownership follows the same centralized architecture as the parent token task:

```text
TioPalette / core color primitives
        ↓
Semantic theme colors (`TioColors` / ColorScheme mapping)
        ↓
Domain and reusable component color roles
        ↓
Reusable core components
        ↓
Feature screens/widgets
```

There is **no feature composition color-token layer** in the final architecture.

Do not create or preserve final-state parallel feature color systems such as:

```text
WelcomeColorTokens
AuthColorTokens
OnboardingColorTokens
HomeColorTokens
ProfileColorTokens
SettingsColorTokens
```

Features consume core-owned color contracts.

If an exact existing visual color is genuinely unique to one current screen and no semantic role yet exists, first register/classify it in the centralized core color ownership model while preserving its exact value. Do not solve the problem by creating another feature-private color catalog.

---

## 3. Migration Order

```text
Audit raw color usage
        ↓
Record exact rendered value and role
        ↓
Classify centralized owner
        ↓
Reuse exact existing semantic/domain/component role when valid
        ↓
Add missing core-owned primitive/role only when required
        ↓
Migrate call site value-preservingly
        ↓
Remove obsolete feature/private color helpers
        ↓
Validate no pixel/color drift
```

Numeric/color equality alone does not prove semantic equivalence, but the exact physical/color value must still have governed core ownership.

---

## 4. What Counts As A Hardcoded Color Candidate

Audit all production UI occurrences of:

- `Colors.white`, `Colors.black`, `Colors.white70`, `Colors.transparent`, etc.;
- `Color(0x...)`, `Color.fromARGB`, `Color.fromRGBO`;
- raw `MaterialColor` shades;
- literal foreground/background/border/divider/icon colors;
- raw gradient colors;
- raw shadow colors;
- raw system chrome colors when part of the visual contract;
- `withOpacity(...)` / `withValues(alpha: ...)` where alpha expresses a fixed visual decision;
- feature-private color helper/token classes;
- component token files that still store raw color primitives independently.

Not every occurrence is automatically wrong. Every occurrence must be classified before editing.

---

## 5. Allowed Framework / Implementation Exceptions

A direct framework color may remain only when audit proves it is a framework/protocol implementation requirement rather than an app design decision.

Possible examples after explicit review:

- transparent Material host when its visible color intentionally comes entirely from a child/background;
- transparent system bars required for edge-to-edge behavior;
- painter/mask implementation values that are not user-visible styling;
- tests intentionally asserting exact rendered output.

Every remaining exception must be documented. Do not use the exception category to keep app styling outside centralized ownership.

---

## 6. Color Ownership Priority

For product-visible colors, classify in this order:

1. `context.tioColors` semantic role;
2. Material `ColorScheme` where its semantic role exactly fits;
3. `TioDomainColors` or equivalent centralized domain role;
4. reusable core component color/state role;
5. new centralized core semantic/domain/component role when none exists;
6. documented framework/implementation exception only when it is not product styling.

There is no feature-color fallback.

Bad final state:

```dart
WelcomeColorTokens.onMediaPrimary
AuthColors.errorBorder
ProfileVisualColors.photoScrim
```

Target direction:

```dart
context.tioColors.onMediaPrimary
context.tioColors.error
TioDomainColors.workout
TioDialogTokens.destructiveContainerColor
```

Exact final class ownership is determined by semantic audit, but it remains under `apps/core` design-system ownership.

---

## 7. Palette vs Semantic Roles

The physical color value and the public meaning are separate responsibilities.

Conceptually:

```text
TioPalette exact color value
        ↓
TioColors semantic role
        ↓
component/domain role if needed
        ↓
UI
```

Do not expose encoded color names as feature-facing design APIs.

Good role names:

```text
textPrimary
textSecondary
onMediaPrimary
onMediaSecondary
surfaceRaised
outlineStrong
danger
success
selectedStateLayer
```

Avoid public semantic names such as:

```text
white
white70
black87
colorFF123456
myGray
lightBlack
```

---

## 8. Alpha / Opacity Rules

A base color and alpha are separate fixed visual decisions.

Example:

```dart
Colors.white.withValues(alpha: 0.70)
```

must be classified into governed ownership for both the base color and the alpha/state role.

Do not create feature alpha bags such as:

```text
WelcomeOpacity
AuthOpacity
ProfileOverlayOpacity
```

Fixed alpha values follow the parent task's primitive/semantic ownership rules. Reusable state meaning should have a core semantic/component role. One-off exact fixed visual alpha still uses centralized governed ownership rather than a feature token catalog.

---

## 9. Welcome Transitional Debt

Welcome is the first cleanup consumer, but it must not own a final design system.

Current feature-owned Welcome color/media roles are transitional debt under the corrected parent architecture.

Audit at least:

- black Scaffold/media background;
- white hero headline;
- white/secondary media supporting text;
- top-bar foreground;
- transparent Material/system bars;
- feature panel surface/border;
- feature icon tint;
- CTA/login foregrounds;
- backdrop scrim/gradient colors;
- gradient alpha/stops where fixed visual contracts are involved.

Image-backed media text must not be incorrectly mapped to `onSurface` merely to remove a literal. If `onMediaPrimary` / `onMediaSecondary` are required semantic roles, own them centrally in core while preserving their exact current values.

Do **not** create or keep `WelcomeColorTokens` as the fallback.

---

## 10. Per-File Audit Record

For every affected file record:

```text
File:
Raw color expression:
Exact current rendered value:
Rendered role:
Theme dependent?:
Existing exact core semantic/domain/component role?:
Missing core primitive/role required?:
Framework exception?:
Replacement:
Visible UI/color change approved?: NO by default
Separate approval reference if YES:
Tests impacted:
Result:
```

No production edit should begin until this classification is clear for the bounded slice.

---

## 11. Migration Slices

### Color Slice 0 — Core Color Ownership Baseline

- [ ] inventory `TioPalette` exact physical colors;
- [ ] inventory `TioColors` light/dark/OLED/high-contrast roles;
- [ ] inventory Material `ColorScheme` mapping;
- [ ] inventory domain colors;
- [ ] inventory reusable component colors/state layers;
- [ ] find duplicate raw physical colors in core token/component files;
- [ ] establish one centralized owner for every approved fixed product color;
- [ ] establish governed opacity/state ownership where required;
- [ ] add contract tests for important ownership relationships;
- [ ] make no visible UI change.

### Color Slice 1 — Welcome Cleanup

- [ ] complete per-expression audit;
- [ ] preserve current hero/media contrast exactly;
- [ ] migrate exact roles to centralized core ownership;
- [ ] move missing media/scrim semantics into core when required;
- [ ] remove final-state dependency on Welcome color token/helper catalogs;
- [ ] do not replace them with another Welcome visual token file;
- [ ] verify light/dark/accessibility behavior without redesign;
- [ ] focused Welcome tests + full CI.

### Color Slice 2 — Core Reusable Components / Shell

Audit:

```text
dialogs
buttons
cards
inputs
avatars
sheets
navigation/shell
legal/components
shadows/gradients/state layers
```

For each:

- [ ] no duplicate raw product color ownership;
- [ ] component roles compose centralized primitive/semantic roles;
- [ ] preserve exact current rendered values;
- [ ] no visual redesign.

### Color Slice 3 — Auth + Account Setup

- [ ] Login/Signup/provider actions;
- [ ] Username/Mobile;
- [ ] errors/status/disabled/loading visuals;
- [ ] no Auth feature color catalog;
- [ ] no auth behavior change;
- [ ] no unapproved UI change.

### Color Slice 4 — Product Onboarding

- [ ] dialogs;
- [ ] progress chrome;
- [ ] profile steps;
- [ ] workout/nutrition target screens;
- [ ] congratulations/review states;
- [ ] no Onboarding feature color catalog;
- [ ] no onboarding flow/business-rule change;
- [ ] no unapproved UI change.

### Color Slice 5 — Home + Profile + Settings

- [ ] Home/shell-owned surfaces;
- [ ] Profile/Profile Photo;
- [ ] Settings/theme selection UI;
- [ ] entitlement presentation where present;
- [ ] no feature color catalogs;
- [ ] preserve exact UI.

### Color Slice 6 — Workout + Nutrition + Progress + Remaining Phone UI

Proceed package-by-package with bounded diffs. Core design-system ownership remains the only visual token source.

### Color Slice 7 — Wear

Wear may have different semantic/interaction needs, but those still require centralized Wear/core-governed ownership rather than per-screen color bags. Do not force phone roles when semantics genuinely differ, and do not redesign watch UI during ownership migration.

### Color Slice 8 — Final Repository-Wide Gate

- [ ] search production Flutter paths for `Colors.`;
- [ ] search raw `Color(0x...)` / ARGB/RGBO constructors;
- [ ] search raw gradient/shadow colors;
- [ ] search hardcoded alpha/state layers;
- [ ] search feature-local `*Color*Tokens`, `*Colors`, visual-theme bags;
- [ ] classify every remaining hit as governed core role or documented framework exception;
- [ ] verify no feature-owned design-token/color catalog remains;
- [ ] verify no visible UI changed without separate approval;
- [ ] full workspace CI;
- [ ] light/dark/OLED/high-contrast checks where applicable;
- [ ] update parent task, Issue #6 and PR #22 evidence.

---

## 12. Relationship To Parent Size/Token Migration

This task inherits all rules from `.ai/tasks/design-system-token-consolidation.md`.

```text
Audit → classify exact value → centralized owner → preserve pixels → migrate → validate
```

Color work may be performed in the same bounded feature slice as geometry/typography ownership when that keeps review coherent, but it must not become an excuse for screen redesign.

---

## 13. Tests / Quality Gates

For each color slice:

- centralized token/semantic contract tests where appropriate;
- widget tests for important foreground/background/state contracts;
- accessibility/contrast tests where already supported;
- light + dark verification;
- OLED/high-contrast verification where applicable;
- before/after rendered value or screenshot comparison where practical;
- no unintended pixel/color changes;
- explicit separate approval reference for every intentional visible change;
- Flutter/Dart analyze and relevant tests green.

---

## 14. Hard Boundaries

This task must not alter without a separate approved task/decision:

- screen design or visual composition;
- colors as perceived by the user;
- spacing/layout/geometry;
- typography appearance;
- icons/assets;
- animation choreography;
- business logic;
- auth/session identity;
- Account Setup behavior;
- onboarding sequencing;
- Supabase data/schema;
- navigation logic;
- entitlement logic.

When cleanup exposes a UI/design opportunity, document it separately and leave current rendering unchanged until explicit confirmation is received.

---

## 15. Completion Definition

This child task is complete only when:

1. every production hardcoded-color candidate is migrated to centralized core ownership or documented as a genuine framework/implementation exception;
2. no feature-owned design-token/color catalog remains;
3. no duplicate raw product color source remains outside the canonical ownership model;
4. every bounded migration preserves the pre-existing rendered UI unless a separate explicit visual approval is linked;
5. parent task, Issue #6 and Draft PR #22 are synchronized with the same architecture;
6. full workspace CI and final repository-wide search evidence are green/recorded.

`DONE` does not mean the UI was redesigned. It means ownership was corrected without unapproved visual drift.
