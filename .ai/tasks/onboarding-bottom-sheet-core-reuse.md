# Onboarding Core Bottom-Sheet Reuse

**Status:** In progress  
**Primary owner:** `apps/core` + `apps/features/onboarding` + `apps/features/account_setup`  
**Affected platforms:** Flutter Android and iOS

## 1. Discovery

### User Outcome

Every modal presented by Product Onboarding should consume a reusable core UI
sheet contract instead of owning its own bottom-sheet surface.

### Success Criteria

- informational onboarding sheets use one core presenter and surface;
- the onboarding exit confirmation uses a core confirmation-sheet presenter;
- Mobile Account Setup uses the same core information-sheet presenter;
- specialized height, weight, and date picker sheets remain their existing
  core-owned components;
- product copy, callbacks, and domain decisions remain feature-owned.

### Scope

- add focused reusable information and confirmation bottom-sheet presenters in
  `apps/core`;
- migrate all four current `showModalBottomSheet` call sites in Product
  Onboarding;
- migrate Account Setup Mobile information content to the information presenter;
- add focused core and feature regressions, and document public core APIs.

### Non-Goals

- no changes to onboarding routes, persistence, validation, or account/mobile
  verification behavior;
- no redesign of picker sheet interaction or measurement logic;
- no Supabase, backend, or auth-provider change.

## 2. Codebase Exploration

### Verified Evidence

- Product Onboarding has four modal call sites: exit confirmation, data
  collection, goal-pace information, and pace warning.
- Only the exit sheet already consumes core `TioConfirmationCard`; its modal
  presenter remains feature-owned.
- Data collection and both goal-pace sheets rebuild their own modal surfaces.
- Account Setup Mobile uses core `TioSheet` but owns its modal invocation and
  action composition.
- `TioSheet`, `TioConfirmationCard`, and `TioButton` are public core
  components. Height, weight, and date pickers are already core sheet
  implementations.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Make information sheets a reusable core contract | Approved | Three onboarding contexts plus Account Setup need the same modal pattern | Product owner |
| Make confirmation modal presentation a core contract | Approved | Product Onboarding must not retain a local bottom-sheet shell | Product owner |
| Keep specialized pickers separate | Approved | They are already core-owned and have distinct input/result behavior | Engineering |

## 4. Architecture Design

### Chosen Approach

Add `showTioInformationBottomSheet` and `showTioConfirmationBottomSheet` to
core. They own modal setup, safe area, shared surface, close/dismiss action,
and core buttons. Feature call sites provide only product copy, optional icon,
alignment, and callbacks.

### Ownership and Data Flow

```text
Onboarding / Account Setup action
  -> core bottom-sheet presenter
     -> TioSheet or TioConfirmationCard + TioButton
        -> feature callback / Navigator result
```

### Alternative Rejected

Keeping a separate local helper per screen was rejected because it allows
surface, padding, close control, and dismissal behavior to drift. Replacing
specialized core pickers with a generic information sheet was rejected because
their input and result contracts differ.

### Failure and Accessibility States

Core presenters keep standard modal back/outside dismissal and expose explicit
close or primary actions. Feature-owned callbacks continue to control
confirmation outcomes.

## 5. Implementation Plan

- [x] Add/export core information and confirmation sheet presenters.
- [x] Migrate onboarding data-collection, goal-pace info, pace warning, and
  exit confirmation call sites.
- [x] Migrate Account Setup Mobile information sheet.
- [x] Add core and feature regression coverage.
- [x] Format the changed Dart files.
- [ ] Run focused tests.

## 6. Quality Review

### Validation Run

- Dart formatting parsed and formatted the changed Dart files, but the local
  telemetry session timestamp could not be written outside the repository.
- `flutter test test/ui/components/tio_information_bottom_sheet_test.dart`
  produced no output after 60 seconds in this environment and was stopped; it
  is not counted as passing validation.
- `git diff --check` passed.

### Review Findings and Resolution

No direct `showModalBottomSheet` call remains under Product Onboarding.
Focused test execution remains blocked by the local Flutter runner stall.

## 7. Final Handoff

### Changed Files

Core sheet presenters, their exports/documentation, the Onboarding migrations,
and Account Setup Mobile migration are in the working tree.

### Actual Behavior

The updated UI has not been installed and visually checked on the emulator in
this environment.

### Known Limitations

Pending validation.

### Final Status

`PARTIAL`
