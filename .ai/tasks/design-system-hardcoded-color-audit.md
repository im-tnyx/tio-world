# Design System Hardcoded Color Audit

**Status:** Planned / audit in progress  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working branch:** `codex/design-system-token-consolidation`  
**Scope:** Flutter production UI in `apps/core`, `apps/app`, `apps/features/*`, and `apps/wear`

## 1. Goal

Remove accidental hardcoded visual colors from production UI and route every intentional color through the professional Tio theme/design-system ownership model.

This is not a recolor/redesign task. Existing rendered colors are preserved unless a separate visual decision explicitly approves a change.

The migration order is:

```text
Audit raw color usage
        ↓
Classify visual intent
        ↓
Reuse existing semantic/theme role when exact
        ↓
Add a justified semantic/component/feature color role only if missing
        ↓
Migrate call sites value-preservingly
        ↓
Remove obsolete private color helpers
        ↓
Validate light/dark/OLED/high-contrast + tests
```

## 2. What Counts As A Hardcoded Color Candidate

Audit all production UI occurrences of:

- `Colors.white`, `Colors.black`, `Colors.white70`, `Colors.transparent`, etc.;
- `Color(0x...)`, `Color.fromARGB`, `Color.fromRGBO`;
- raw `MaterialColor` shades such as `Colors.red.shade...`;
- literal foreground/background/border/divider/icon colors;
- raw gradient colors;
- raw shadow colors;
- raw system chrome colors when they are part of the product visual contract;
- `withOpacity(...)` / `withValues(alpha: ...)` where the alpha itself expresses a reusable visual/state role;
- feature-private color helper classes that duplicate `TioColors`, `ColorScheme`, domain colors, or component state roles.

Not every occurrence is automatically wrong. Every occurrence must be classified first.

## 3. Allowed / Intentional Cases

A direct framework color may remain only when the audit proves it is a framework/protocol requirement rather than an app design choice.

Examples that may be legitimate after explicit review:

- `Colors.transparent` for a Material host whose visual color intentionally comes entirely from its child/background;
- transparent system bars when edge-to-edge behavior explicitly requires transparency;
- painter/mask implementation values where color is not user-visible styling;
- test expectations that intentionally assert the exact rendered contract.

Even these cases should be documented in the slice audit instead of silently ignored.

## 4. Color Ownership Priority

Use this order:

1. `context.tioColors` semantic roles;
2. Material `ColorScheme` roles when the Material semantic is correct;
3. `TioDomainColors` for workout/nutrition/progress/coach/recovery domain identity;
4. reusable component token/state color contracts;
5. narrow feature composition color roles only for genuine feature-specific visuals;
6. framework color constant only when intentionally exempt.

Never add a global token only because a literal exists.

## 5. Naming Rules

Good semantic names:

```text
textPrimary
textSecondary
onMediaPrimary
onMediaSecondary
surfaceRaised
outlineStrong
danger
success
featurePanelSurface
heroScrim
selectedStateLayer
```

Bad names:

```text
white
white70
black87
colorFF123456
overlay94
myGray
lightBlack
```

Names describe role and ownership, not the encoded color.

## 6. Alpha / Opacity Rules

A hardcoded base color and a hardcoded alpha are separate design decisions.

Example:

```dart
Colors.white.withValues(alpha: 0.70)
```

must be classified as:

```text
base semantic role + state/composition alpha role
```

Do not create `opacity70` merely to hide the number. If the alpha is reusable, give it semantic ownership such as a muted-content/state-layer role. If it is feature-specific, keep it in a narrowly named feature visual contract.

## 7. Initial Repository Evidence

Early repository search confirms direct framework color usage is not limited to Welcome.

Known candidate areas include:

- Welcome screen/top bar;
- Splash;
- Auth login/signup;
- Product Onboarding dialogs/screens;
- Settings/Profile;
- core dialogs/components;
- Wear UI.

This list is evidence to perform a full audit, not permission to bulk-replace values.

## 8. Welcome First-Consumer Color Audit

Welcome is the first full feature consumer of the professional theme architecture.

Audit at least:

- black Scaffold/background;
- white hero headline;
- white/white70 supporting text;
- top-bar white foreground;
- transparent Material/system bars;
- feature panel surface/border;
- feature icon tint;
- CTA/login foregrounds;
- backdrop black scrim/gradient;
- all gradient colors/stops/alpha values.

### Welcome classification rule

The hero is image-backed, so `onSurface` is not automatically the correct semantic for white copy over media.

If core lacks a reusable media-overlay semantic role, first determine whether `onMediaPrimary` / `onMediaSecondary` is reused elsewhere. Only then add it to core semantic colors. If it is unique to Welcome, use a narrow Welcome visual contract and preserve exact pixels.

Do not map white media text to an unrelated theme token just to remove `Colors.white`.

## 9. Per-File Audit Record

For every affected file record:

```text
File:
Raw color expression:
Rendered role:
Theme dependent?:
Existing exact semantic token?:
Owner: core semantic / domain / component / feature / framework exception
Replacement:
Pixel/color change?: NO by default
Tests impacted:
Result:
```

## 10. Migration Slices

### Color Slice 0 — Core semantic color contract audit

- [ ] inventory existing `TioColors` roles in light/dark/OLED/high-contrast;
- [ ] inventory `ColorScheme` mapping;
- [ ] inventory domain colors;
- [ ] identify duplicate/ambiguous semantic roles;
- [ ] decide whether media-overlay foreground/scrim roles belong in core;
- [ ] add no colors without cross-screen evidence.

### Color Slice 1 — Welcome

- [ ] complete per-expression audit;
- [ ] preserve current hero/image contrast;
- [ ] migrate exact semantic matches;
- [ ] create only justified feature/core roles;
- [ ] remove obsolete Welcome color helpers;
- [ ] verify light/dark and accessibility contrast behavior;
- [ ] run focused Welcome tests + full CI.

### Color Slice 2 — Core reusable components / shell

- [ ] dialogs;
- [ ] buttons;
- [ ] cards;
- [ ] inputs;
- [ ] avatars;
- [ ] sheets;
- [ ] navigation/shell;
- [ ] legal/components;
- [ ] shadows/gradients/state layers.

Core components must be clean before feature packages depend on their color contracts.

### Color Slice 3 — Auth + Account Setup

- [ ] login;
- [ ] email signup;
- [ ] provider actions;
- [ ] Account Setup Username/Mobile;
- [ ] errors/status/disabled/loading visuals.

No auth behavior changes.

### Color Slice 4 — Product Onboarding

- [ ] dialogs;
- [ ] progress chrome;
- [ ] profile steps;
- [ ] workout/nutrition target screens;
- [ ] congratulations/review states.

No onboarding flow/business-rule changes.

### Color Slice 5 — Home + Profile + Settings

- [ ] Home/shell-owned surfaces;
- [ ] Profile/Profile Photo;
- [ ] Settings and theme selection UI;
- [ ] plan/entitlement presentation where present.

### Color Slice 6 — Workout + Nutrition + Progress + remaining phone features

Proceed package-by-package with bounded commits.

### Color Slice 7 — Wear

Audit watch-specific visuals separately. Do not force phone semantic roles where watch interaction/contrast needs genuinely differ.

### Color Slice 8 — Final repo-wide hardcoded-color gate

- [ ] search all production Flutter paths for `Colors.`;
- [ ] search for raw `Color(0x...)` / ARGB/RGBO constructors;
- [ ] search raw gradient/shadow colors;
- [ ] search hardcoded alpha/state layers;
- [ ] classify every remaining hit as governed role or documented exception;
- [ ] verify there are no obsolete private color bags;
- [ ] run full workspace CI;
- [ ] perform light/dark/OLED/high-contrast checks where applicable;
- [ ] update parent design-system task and Issue #6 evidence.

## 11. Relationship To Size/Token Migration

Color migration follows the same professional rule as spacing/radius/size migration:

```text
Audit first → classify → choose owner → preserve pixels → migrate → validate
```

When a screen is already being audited for spacing/size/typography, its colors may be migrated in the same **feature-bounded slice** if that keeps the diff coherent and reviewable.

Do not create one giant repository-wide color replacement commit.

The final Color Slice 8 remains mandatory even after feature-by-feature migration; it catches leftovers and documents intentional exceptions.

## 12. Tests / Quality Gates

For each color slice:

- semantic token contract tests where appropriate;
- widget tests for important foreground/background/state contracts;
- contrast/accessibility tests where already supported;
- light + dark verification;
- OLED/high-contrast verification for affected semantic roles;
- no unintended screenshot/pixel color changes;
- Flutter/Dart analyze and relevant tests green.

## 13. Hard Boundaries

This task must not alter:

- business logic;
- auth/session identity;
- Account Setup behavior;
- onboarding sequencing;
- Supabase data/schema;
- navigation logic;
- entitlement logic.

If a hardcoded color exposes a separate UX/product bug, record it separately rather than silently redesigning during token migration.

## 14. Completion Definition

This child task is complete only when every production hardcoded-color candidate is either:

1. migrated to an intentional theme/token role; or
2. explicitly documented as a justified framework/implementation exception.

`DONE` requires full workspace CI and final repository-wide search evidence.
