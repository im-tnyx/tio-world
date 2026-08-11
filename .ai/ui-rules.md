# UI Rules

Use the existing TNYX / tio-world design direction and keep UI platform-appropriate.

## Flutter Mobile Rules

- Use the shared design system from `apps/core` when available.
- Use semantic color, spacing, typography, radius, and motion tokens.
- Keep widgets dumb and state-driven.
- Do not put business logic in Flutter widgets.
- Do not hardcode feature-specific UI logic in app shell or root navigation.
- Keep pages readable, stable, responsive, and accessible.
- Text must fit inside its container on mobile viewports.

## Material 3 Expressive Direction

- Treat Material 3 Expressive as a product design direction implemented by `apps/core`, not as a feature-level styling shortcut.
- Use semantic color, typography, shape, spacing, motion, and accessibility tokens; do not duplicate expressive values in feature packages.
- Preserve visible touch feedback and honor high-contrast and reduced-motion preferences.
- Migrate shared components only after light, dark, accessibility, and interaction states are verified.
- Keep Wear OS compact and watch-first. It may reuse suitable tokens but must not inherit phone-scale layouts or motion.

## Watch UI Rules

Wear OS:

- Use Flutter with watch-optimized components.
- Prefer watch-optimized components.
- Keep flows short and glanceable.
- Support two compact lanes: workout controls plus nutrition quick actions such as food, water, and today's summary.
- Keep full nutrition diary and Meal Plan editing on phone.
- Avoid heavy charts, large images, and long forms.

Apple Watch:

- Use Swift + SwiftUI.
- Prefer native watchOS patterns.
- Keep interactions quick and battery-aware.

## Chrome Policy

Every mobile destination should define its expected shell behavior:

- `MainTabs`
- `NoBottomNav`
- `FullScreen`
- `BottomSheet`
- `Dialog`

The app shell must never contain feature-specific business logic.

## App Mode Tabs

Build the initial guided bottom navigation from `AppMode`, not from the current fixed tab list:

| App mode | Guided default tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

Workout Library is part of Workout, and Meal Plan is a future Nutrition flow; neither is a guided default tab. A later custom layout may promote an implemented route as a shortcut without changing ownership. Coach becomes eligible when Phase 7 begins.

Future Navigation & Tabs personalization keeps Home fixed first and allows three to six eligible selections. Screen sections and action prominence may adapt through a prepared surface model, but screens must not branch on raw tab indexes or duplicate start-workout/meal-log logic.

Do not add Profile to the main bottom navigation.

Profile opens from avatar/account entry.

Settings opens from the gear/settings entry.

## Reusable Avatar

Use the shared `TioAvatar` component from `apps/core` across shell, lists, cards, and Profile. Select semantic sizes—`compact`, `small`, `medium`, and `large`—rather than local pixel values. The component is circular by default and supports rounded Profile treatment, optional images, centralized fallback behavior, and caller-supplied semantics.

## Production Screen Checklist

Before a production screen is considered ready, define:

- UI owner
- Navigation owner
- Business logic owner
- Repository owner
- Shell/chrome policy
- Empty state
- Loading state
- Error state
- Demo or real data source
- Accessibility basics
