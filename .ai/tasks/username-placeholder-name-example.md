# Username Placeholder Name Example

**Status:** In progress  
**Primary owner:** Flutter mobile / Core UI  
**Affected platforms:** Flutter Android and iOS

## Global UI / Design-System Guardrail

The core theme guidance, design-system consolidation task, and feature-package
rules were read before this UI copy change. The existing public
`TioUsernameInputField` component remains the only implementation surface.
No geometry, color, typography, spacing, radius, motion, validation, or
persistence contract is changed.

## 1. Discovery

### User Outcome

The Username field must not show the person-specific placeholder
`e.g. santosh_99`. It should use a neutral, name-style example.

### Success Criteria

- The default Username placeholder is `e.g. your.name`.
- The public-handle validation and availability flow remain unchanged.
- A focused widget test locks the default copy.

### Scope

- `TioUsernameInputField` default placeholder copy and its focused test.

### Non-Goals

- Do not auto-fill a username from a person's name.
- Do not change username uniqueness, character policy, server checks, routing,
  account persistence, or screen layout.

## 2. Codebase Exploration

### Verified Evidence

- `apps/core/lib/src/ui/components/inputs/tio_username_input_field.dart`
  owns the reusable default hint and currently defines `e.g. santosh_99`.
- `UsernameStep` uses this component without overriding `hintText`, so the
  Account Setup flow renders the core default.
- The input's existing policy allows lowercase letters, numbers, dots, and
  underscores; `your.name` is a valid illustrative handle.
- `apps/core/test/ui/components/tio_username_input_field_test.dart` provides
  the focused component widget-test suite.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use `e.g. your.name` as the default hint | Approved | Neutral name-style copy satisfies the request without claiming a real name is uniquely claimable | Product owner |

## 4. Architecture Design

### Chosen Approach

Change the default parameter of the existing core component and add a focused
rendering assertion. No data flow changes are required.

### Ownership and Data Flow

```text
UsernameStep -> TioUsernameInputField default hint -> TextField decoration
```

### Alternative Rejected

Auto-generating a username from an account name is rejected: usernames are
globally unique and server-verified, while a name alone is not a safe claim.

### Failure and Accessibility States

The hint remains an illustrative placeholder only; existing labels,
validation feedback, and availability states remain unchanged.

## 5. Implementation Plan

- [x] Replace the personal sample with the neutral name-style example.
- [x] Add a focused widget assertion.
- [ ] Run formatting and the focused core test.

## 6. Quality Review

### Validation Run

```text
git diff --check
PASS (no whitespace errors; Git reported only local LF-to-CRLF conversion warnings)

G:\dev\flutter-sdk\bin\dart.bat format apps\core\lib\src\ui\components\inputs\tio_username_input_field.dart apps\core\test\ui\components\tio_username_input_field_test.dart
PASS

G:\dev\flutter-sdk\bin\flutter.bat test test\ui\components\tio_username_input_field_test.dart --reporter expanded
INCOMPLETE: started twice in bounded foreground windows; neither runner returned a final test result before the command-yield limit.
```

### Review Findings and Resolution

- `.ai/tasks/username-placeholder-name-example.md`
- `apps/core/lib/src/ui/components/inputs/tio_username_input_field.dart`
- `apps/core/test/ui/components/tio_username_input_field_test.dart`

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

The default placeholder is now `e.g. your.name`; explicit caller-provided
`hintText` values remain supported.

### Known Limitations

The default hint is not an account-name-to-username generator.

### Final Status

`PARTIAL` — focused test result is pending.
