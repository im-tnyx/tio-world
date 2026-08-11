# UI/UX System

## Status And Scope

This is the target product design-system contract for the Flutter phone app and its Wear OS boundary. It supplements the [screen catalog](screens/README.md), which defines per-screen content and acceptance criteria.

It does not claim that the target components or behaviors are already implemented. Runtime source remains the behavior truth.

## Product Direction

The phone app adopts Material 3 Expressive as a product direction. `apps/core` delivers that direction through semantic tokens and reusable components, rather than feature packages copying visual values or depending on a separate Flutter API assumption.

The goal is a clear, energetic health-product UI that remains readable, calm, and accessible during high-attention moments such as logging a set, adding a meal, or reviewing progress.

## Current Runtime Boundary

The following facts are verified in the current Flutter source:

- `apps/core` enables baseline Material 3 and exposes theme, color, typography, spacing, radius, shadow, motion, and button-token foundations.
- The phone shell keeps five stable registered route branches, but its visible guided bottom navigation is derived from App Mode and contains three or four items.
- Material touch feedback is enabled globally; shared components must preserve visible pressed, hover, and focus state behavior.
- App Mode navigation uses token-driven Material 3 `NavigationBar`. High-contrast semantic colors, reduced-motion theme behavior, reusable `TioAvatar`, shared `TioButton` states, and Welcome semantic contrast are implemented. Pixel 9 light/dark and compact-width checks pass; OLED, keyboard/focus, and screen-reader validation remains open.

## Ownership

| Area | Owner | Rule |
| :--- | :--- | :--- |
| Semantic design tokens and reusable components | `apps/core` | Own colors, typography, shape, spacing, motion, states, shell chrome, and shared widgets. |
| App-level shell composition | `apps/app` | Compose routes and shell only; do not put feature business logic or private visual rules here. |
| Feature screen composition | `apps/features/*` | Use core tokens/components and own feature-specific content, state, and actions. |
| Shared domain contracts | `apps/shared` | Pure Dart only; never own Flutter widgets, visual tokens, or screen rendering. |
| Wear OS UI | `apps/wear` | Use watch-first layouts and suitable shared primitives without copying phone layouts. |

## Design Contracts

### Semantic Tokens

Feature packages use semantic tokens instead of repeated literal values. `apps/core` owns at least these token categories:

- color roles for primary action, surface, text, status, and Coach emphasis
- typography roles for hierarchy and supporting information
- spacing and layout rhythm
- shape and radius roles
- elevation/shadow roles
- motion duration and easing roles
- component dimensions and interaction states

When a needed token does not exist, add or evolve it in `apps/core` as part of a focused shared-component slice. Do not introduce feature-private copies of a global token.

### Component States

Every reusable interactive component must define and validate its default, pressed, focused, disabled, selected, loading, and error-relevant state where applicable. The component owner must preserve a visible touch response and a logical keyboard/focus order.

`TioButton` owns the shared primary, secondary, and ghost action treatments. Its token contract defines finite minimum sizing, content spacing, state-layer opacity, outline strength, disabled presentation, and loading-indicator dimensions. Loading disables the underlying action, announces progress through semantics, and uses a static indicator when reduced motion is active. Feature screens supply the label and business action; they do not rebuild loading or interaction-state behavior locally.

### Color And Contrast

Use semantic foreground/background pairs, not color values chosen ad hoc by a screen. `TioThemeConfig.highContrast` and system high-contrast preference select stronger semantic foreground, outline, and surface pairs. Every migrated component still requires light, dark, OLED, and high-contrast verification before completion.

### Motion

Motion should clarify state change, not decorate every surface. `TioThemeConfig.reducedMotion` and the system animation preference expose zero-duration `TioMotionScheme` values, disable route transitions, and propagate `MediaQuery.disableAnimations`. Feature packages consume the shared scheme and do not create independent motion timing scales.

## Shell And Navigation

Every phone destination declares one shell/chrome policy:

| Policy | Use |
| :--- | :--- |
| `MainTabs` | A primary App Mode destination. |
| `NoBottomNav` | A focused route, editor, drill-down, or account flow. |
| `FullScreen` | An immersive or interruptive flow. |
| `BottomSheet` | A temporary contextual action. |
| `Dialog` | A short confirmation or blocking decision. |

The implemented guided bottom navigation is derived from `AppMode`:

| App mode | Guided default tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

Profile and Settings are entry surfaces in the guided layout. Workout Library is a Workout route, and Meal Plan is a later Nutrition route. Coach becomes eligible only in Phase 7.

### Future Navigation Personalization

The final adaptive-navigation phase allows three to six selected destinations. Home is mandatory, first, and included in that count. A destination is selectable only when the current App Mode allows its domain, the feature is implemented, and the release stage exposes it.

Root destinations and promoted shortcuts remain distinct:

| Kind | Examples | Behavior |
| :--- | :--- | :--- |
| Root destination | Home, Workout, Nutrition, Progress, future You, Coach, future Social | Primary surface with stable route ownership and navigation state. |
| Promoted shortcut | Routine Library, Meal Plan | Opens the existing owner route; it does not create a new module, screen copy, or business workflow. |

On compact phones, six saved selections require an approved responsive treatment; some selections may live behind an accessible overflow/More control. Wider surfaces may show all eligible destinations through a suitable navigation rail or bar. The saved preference and feature reachability must remain stable across layouts.

## Adaptive Surface Composition

Screens do not branch on raw tab indexes. A prepared surface model combines App Mode, the selected navigation layout, feature availability, and user data state:

```text
AppMode + NavigationLayout + FeatureAvailability + UserDataState
  -> SurfaceComposition
```

Home is always present, but its sections and action prominence adapt:

- App Mode defines the allowed summary pool and onboarding/setup expectations.
- A selected root destination usually makes its Home preview compact.
- A hidden-but-eligible destination may receive a more prominent Home entry so the feature stays reachable.
- A promoted shortcut reduces duplicate hero treatment on its parent surface but does not remove required context.
- Important active or safety-relevant state is never hidden only because a tab was removed.

Every screen specification must separate stable purpose from App Mode variants, destination-placement variants, entry/chrome behavior, action context, and fallback reachability. Do not create a separate screen implementation for every mode/layout combination.

## Adaptive Action Entry Points

Feature commands remain canonical even when their entry point moves:

| Action | Owner | Possible entry surfaces |
| :--- | :--- | :--- |
| Start or resume selected workout | Workout | Home, Workout, Routine Library, persistent active-workout strip |
| Log meal or water | Nutrition | Home, Nutrition, Meal Diary |
| Log a planned meal | Nutrition | Meal Plan, Nutrition summary, contextual Home card |

`apps/core` may render generic primary, secondary, contextual, and persistent action slots. The owning feature decides action availability, validation, workflow state, and save behavior. Tab selection changes placement and emphasis; it does not create a second workout or meal-log implementation.

## Reusable Avatar

`apps/core` owns one `TioAvatar` component with semantic sizes `compact`, `small`, `medium`, and `large`. It is circular by default and supports a rounded Profile treatment, optional `ImageProvider`, initials/icon fallback, failed-image fallback, and caller-supplied semantics. Screens do not create their own avatar dimensions, clipping, fallback behavior, or image-loading rules.

## Screen Quality Baseline

Before a screen with real data is complete, define and verify:

- its module owner, navigation owner, controller/state owner, and repository boundary
- initial loading, empty, error, retry, and offline behavior
- semantic labels, logical focus order, readable text, and non-color-only status cues
- safe handling of health, nutrition, workout, recovery, profile, and photo data
- a responsive phone layout without clipped text or inaccessible primary actions

The detailed content and actions belong in the corresponding [screen specification](screens/README.md).

## Wear OS Boundary

Wear OS remains compact, glanceable, and action-first. Its two intended lanes are workout controls and nutrition quick actions. Full food search, diary editing, Meal Plan editing, image-heavy UI, long forms, and heavy analytics remain on phone.

## Related

- [ADR-0004: Material 3 Expressive Through Core](adr/0004-material-3-expressive-through-core.md)
- [ADR-0005: Adaptive Navigation And Action Entry](adr/0005-adaptive-navigation-and-action-entry.md)
- [Architecture](ARCHITECTURE.md)
- [Screen Catalog](screens/README.md)
- [Testing Guide](TESTING_GUIDE.md)
- [Adaptive navigation task](../.ai/tasks/adaptive-navigation-and-actions.md)
