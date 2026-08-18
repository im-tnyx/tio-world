# Core Reusable Field System

**Status:** Planned  
**Issue:** #24  
**Scope:** `apps/core/lib/src/ui/components/inputs/**`, input component tokens/tests, and focused feature consumers  
**Blocked by:** current design-system Slice A reaching a clean validated boundary

## Outcome

Create a future-safe reusable field family in `tio_core` so current and future screens consume governed editable, multiline, selection, username, mobile and numeric field components instead of rebuilding `TextField` / `TextFormField` visuals and behavior locally.

This is an architecture/reuse migration. **Current UI must remain visually unchanged.**

## Verified Current State

- `TioInput` already exists as the generic editable-field foundation.
- Current `TioInputTokens.radius = TioSize.dp14` and `minHeight = TioSize.dp52`.
- Several current Settings/Workout local field surfaces use an exact `16dp` radius contract.
- The initial migration must therefore preserve both evidenced 14dp and 16dp field appearances. Do not normalize one into the other.
- Onboarding `NameScreen` already consumes `TioInput`.
- `AccountSettingsPage` duplicates username availability/debounce/status/suggestion behavior even though `TioUsernameInputField` already exists.
- `TioMobileNumberField` already exists and should be the single mobile-number field across current and future onboarding/settings/account surfaces where the same behavior is required.
- Equipment notes, Special Event and Health Concerns repeat multiline input composition.
- Profile/Account Settings contain tappable field-shaped values (DOB, gender, height, weight, etc.). These are selection/action fields and should not be implemented as fake editable text fields.
- Auth and some other screens still use direct Flutter text fields because the current `TioInput` API does not expose every evidenced capability required by those consumers.

## Architecture Contract

```text
Flutter TextField / TextFormField
        ↓
core reusable field implementations only
        ↓
shared field frame / governed appearance contracts
        ↓
TioInput
├── standard
├── roundedSurface
├── multiline
└── compactNumber

Specialized reusable fields
├── TioUsernameInputField
├── TioMobileNumberField
└── TioSelectionField
```

Names may be refined during implementation, but public variants/components must describe capability or reusable appearance. Do not use feature names such as `settings`, `profile`, `auth`, or `onboarding` in core component variants.

## Design Principles

### 1. Visual difference → appearance/variant

Reusable differences in radius, fill, border, padding, density, line count, or field presentation belong to a reusable appearance/variant contract.

Examples:

```text
current standard TioInput visual (14dp) → standard appearance
current repeated 16dp rounded surface   → roundedSurface appearance
repeated textarea composition           → multiline behavior/constructor
compact sets/reps style                  → compactNumber
```

Do not call the 16dp contract `capsule`; it is a rounded rectangle, not a pill/full-radius capsule.

### 2. Reusable domain behavior → specialized field

```text
username normalization + availability + suggestions → TioUsernameInputField
mobile/country/verification behavior                 → TioMobileNumberField
picker/action value surface                          → TioSelectionField
```

Do not create `TioNameInput`, `TioProfileInput`, `TioSettingsInput`, etc.

### 3. Selection is not text editing

`TioSelectionField` (or final equivalent name) should render the same governed field family where appropriate but expose tappable semantics:

- label
- value
- leading/trailing widgets
- enabled/disabled state
- selected/error state where evidenced
- `onTap`
- optional helper/error text
- appropriate accessibility button/selection semantics

Use it for DOB/gender/height/weight/unit/picker-style values where users select rather than type.

### 4. Shared field frame

If editable and selection fields require the same border/fill/radius/status surface, extract a shared internal field-frame implementation rather than duplicating decoration code. Keep it internal unless a real public consumer requires it.

## Visual Preservation Rules

- Preserve current colors exactly.
- Preserve typography exactly.
- Preserve current field heights/padding exactly.
- Preserve focus/error/disabled/verified/available states exactly.
- Preserve current selection/picker behavior exactly.
- Preserve current 14dp and 16dp radius contracts separately during the first migration.
- Do **not** perform 14dp↔16dp normalization in this task unless separately approved.
- Do not introduce feature-specific core styling.

## Generic `TioInput` API Audit

Add capabilities only when an evidenced consumer requires them.

Candidate missing capabilities:

- [ ] `validator`
- [ ] `autovalidateMode`
- [ ] `inputFormatters`
- [ ] `autofillHints`
- [ ] `textCapitalization`
- [ ] `scrollPadding`
- [ ] `prefixText`
- [ ] `suffixText`
- [ ] multiline line-count behavior
- [ ] leading/trailing widgets and focus interactions
- [ ] enabled/readOnly/obscure behavior parity
- [ ] submitted/focus/controller lifecycle parity

Do not add speculative parameters with no current or near-term consumer.

## Implementation Checklist

### F1 — Full field inventory

- [ ] Inventory every feature `TextField` and `TextFormField` usage on the current branch.
- [ ] Inventory every `TioInput`, `TioUsernameInputField`, and `TioMobileNumberField` consumer.
- [ ] Classify each direct field as generic editable, multiline, compact numeric, specialized username/mobile, selection/action, inline one-off, or obsolete/dead screen.
- [ ] Record exact current visual/state contracts before migration.

### F2 — Base reusable field foundation

- [ ] Keep `TioInput` as the generic editable engine.
- [ ] Complete only evidenced missing API capabilities.
- [ ] Model current 14dp standard appearance explicitly.
- [ ] Model repeated current 16dp rounded-surface appearance explicitly.
- [ ] Add reusable multiline constructor/variant without changing current textarea visuals.
- [ ] Preserve existing compact-number behavior.
- [ ] Extract shared internal frame/decoration logic if editable and selection fields duplicate the same surface.
- [ ] Add focused widget and token contract tests.

### F3 — Username reuse

- [ ] Keep username behavior centralized in `TioUsernameInputField`.
- [ ] Reuse it in Account Setup / onboarding username flows where behavior matches.
- [ ] Replace Account Settings duplicated username debounce/availability/suggestions implementation.
- [ ] Reuse in future profile-edit username surfaces where behavior matches.
- [ ] Preserve current availability/error/suggestion behavior and persistence callbacks.
- [ ] Delete duplicate screen-local username logic after zero-reference verification.

### F4 — Mobile reuse

- [ ] Keep `TioMobileNumberField` as the single reusable mobile-number composition where country/verification behavior matches.
- [ ] Audit onboarding/account/settings mobile consumers for one consistent API.
- [ ] Preserve verification state and callbacks.
- [ ] Do not duplicate phone formatting/verification UI in screens.

### F5 — Multiline reuse

- [ ] Migrate Equipment additional info.
- [ ] Migrate Special Event.
- [ ] Migrate Workout Health Concerns.
- [ ] Audit other repeated note/description/health textareas.
- [ ] Preserve each screen's current min/max lines and exact visual appearance.

### F6 — Selection/action field

- [ ] Add `TioSelectionField` or final equivalent reusable component.
- [ ] Support governed rounded field appearance without editable text semantics.
- [ ] Migrate repeated DOB/gender/height/weight/unit/picker action rows where contracts match.
- [ ] Keep domain picker logic outside the generic field component.
- [ ] Preserve selection state, trailing indicators and tap behavior.

### F7 — Generic form migration

- [ ] Migrate current canonical Auth email/password/reset fields only after required generic API support exists.
- [ ] Migrate Profile/Account editable rounded fields where the reusable appearance matches exactly.
- [ ] Migrate Step Target numeric dialog after formatter/suffix support is available.
- [ ] Preserve existing feature keys/semantics needed by tests.

### F8 — Exceptions and cleanup

- [ ] Keep raw feature `TextField` / `TextFormField` only for documented cases where promoting the behavior would make core API worse.
- [ ] Document every remaining exception.
- [ ] Delete obsolete screen-local input helpers after zero-reference verification.
- [ ] Delete duplicated InputDecoration/token logic after canonical migration.
- [ ] Do not leave permanent compatibility wrappers with no consumers.

### F9 — Future-screen contract

- [ ] Document that new screens should use the reusable field family by default.
- [ ] Generic text entry → `TioInput`.
- [ ] Repeated textarea → multiline reusable contract.
- [ ] Username → `TioUsernameInputField`.
- [ ] Mobile → `TioMobileNumberField`.
- [ ] Picker/action value → `TioSelectionField`.
- [ ] New specialized field only when reusable behavior—not just a different label—is evidenced.

### F10 — Validation

- [ ] Core field widget tests pass.
- [ ] Username/mobile specialized tests pass.
- [ ] Feature migration tests pass.
- [ ] Repository-wide direct-field audit completed.
- [ ] Flutter analyze/tests pass.
- [ ] Dart analyze/tests pass.
- [ ] Required GitHub CI passes on the final cleanup head.

## Non-Goals

- No field visual redesign.
- No global radius normalization.
- No new product validation rules unrelated to existing behavior.
- No feature-specific input component/token bags in core.
- No redesign of username/mobile verification flows.
- Do not combine this migration into the current design-system Slice A boundary.
