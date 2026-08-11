# ADR-0004: Material 3 Expressive Through Core

- **Status:** Accepted
- **Date:** 2026-08-11

## Context

Tio needs a consistent premium mobile experience without allowing each feature to invent colors, spacing, shape, motion, or interaction behavior. Flutter already enables baseline Material 3, but a product direction must not depend on an assumed separate or stable Flutter Material 3 Expressive API.

## Decision

- Use Material 3 Expressive as a product direction, implemented incrementally through `apps/core` semantic color, typography, shape, spacing, motion, accessibility tokens, and reusable components.
- Keep feature packages focused on feature composition and state. They consume `apps/core` contracts rather than duplicating expressive values.
- Require light/dark, pressed/focus/disabled, high-contrast, reduced-motion, and screen-reader review when a shared component is migrated.
- Keep Wear OS watch-first and compact. It may share suitable tokens but does not inherit phone-sized layouts or motion.

## Consequences

### Positive

- The visual system can evolve centrally while feature code stays focused on product behavior.
- Accessibility and interaction quality are evaluated as component behavior, not left to individual screens.
- Reusable components such as the target `TioAvatar` receive one semantic API across shell, cards, lists, and Profile.

### Constraints

- Baseline Material 3 being enabled does not mean the Expressive migration is complete.
- The current theme disables splash and highlight feedback, so visible-touch-feedback requirements remain an implementation and validation item before a component is called complete.
- No feature package should hardcode repeated design values or declare a private visual system.

## Related

- [UI/UX System](../UX_UI_SYSTEM.md)
- [Architecture](../ARCHITECTURE.md)
- [Material 3 Expressive task](../../.ai/tasks/material-3-expressive.md)
- [Active Decision D-008](../../.ai/DECISIONS.md)
