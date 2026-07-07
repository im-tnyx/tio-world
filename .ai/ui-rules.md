# UI Rules

Use the existing TNYX / tio-world design direction and keep UI platform-appropriate.

## Flutter Mobile Rules

- Use the shared design system from `packages/design_system` when available.
- Use semantic color, spacing, typography, radius, and motion tokens.
- Keep widgets dumb and state-driven.
- Do not put business logic in Flutter widgets.
- Do not hardcode feature-specific UI logic in app shell or root navigation.
- Keep pages readable, stable, responsive, and accessible.
- Text must fit inside its container on mobile viewports.

## Watch UI Rules

Wear OS:

- Use Flutter.
- Prefer watch-optimized components.
- Keep flows short and glanceable.
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

## Main Tabs

The main bottom navigation is:

- Home
- Workout
- Nutrition
- Coach
- Progress

Do not add Profile to the main bottom navigation.

Profile opens from avatar/account entry.

Settings opens from the gear/settings entry.

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
