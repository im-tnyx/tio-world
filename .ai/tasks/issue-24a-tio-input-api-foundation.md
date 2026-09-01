# GitHub #24-A — TioInput API Foundation

**Status:** Ready for review
**Primary owner:** `apps/core` reusable field components
**Affected platforms:** Flutter phone UI

## Owner Approval and Scope Boundary

**Approval status:** Approved as a bounded core-foundation slice after the #24 fresh audit returned PASS.
**Approved boundaries:** Add only the six currently evidenced optional `TioInput` parameters, with focused core tests and public design-system documentation.
**Explicit non-changes:** No consumer migration of any kind. No `TioSelectionField`, no multiline widget, no username race fix, no mobile refactor, no `TioUsernameInputField` / `TioMobileNumberField` change, no 14dp/16dp unification, no new token ownership, no #183 Phase-2C, no #173, no schema, Supabase, domain, repository, route or App Mode change.

## Active Handoff

**Implementation owner:** Claude (Claude Code). Recorded before source mutation; the earlier Phase-2B remediation was Codex-owned. Automated GitHub code review remains Codex-owned.
**Branch:** `claude/issue-24-tio-input-api-foundation`
**Base:** `main` @ `c2c6762b9b326b0897e267ca5aef30ff41cc31a0`
**Current state:** Implemented, validated locally, ready to publish as a Draft PR.
**Validation remaining:** Exact-head repository Flutter CI, then review.

## 1. Discovery

### User Outcome

Give the reusable field foundation the capabilities its future consumers actually need, without migrating any consumer yet.

### Why only six

The #24 fresh audit compared the issue's candidate-capability list against the real `TioInput` API. Most of that list already shipped: `leading`, `trailing`, `enabled`, `readOnly`, `obscureText`, `onSubmitted`, `maxLines`, `minLines`, `focusNode`, `controller`, `maxLength`, `textAlign`, `contentPadding`, `keyboardType` and `textInputAction` are all present today.

Six capabilities were genuinely missing **and** have current consumers:

| Capability | Evidenced by |
|---|---|
| `validator` | Auth email/password/reset (3 raw `TextFormField`s) |
| `autofillHints` | `forgot_password_page.dart` |
| `inputFormatters` | Nutrition ×3, `account_settings_page.dart`, onboarding |
| `textCapitalization` | 3 workout multiline screens |
| `prefixText` / `suffixText` | Nutrition targets/macros (`suffixText: unit`) |

Two candidates were deliberately **excluded**: `autovalidateMode` and `scrollPadding` have **zero** current consumers repository-wide. Adding them would be speculative API surface, which `apps/core/lib/src/theme/README.md` forbids.

### Non-Goals

Any consumer migration; unifying the 14dp and 16dp field families; adding validation, formatting or unit policy to core.

## 2. Codebase Exploration

### Verified Evidence

- `TioInput` already builds a **`TextFormField`** (`tio_input.dart`), so `validator` forwards natively. No widget-family change was needed, and none was made — that outcome was the gate for proceeding at all.
- `TioInputTokens.radius = TioSize.dp14`, `minHeight = TioSize.dp52` — the generic contract, unchanged here.
- `TioUsernameInputField` and `TioMobileNumberField` both use `TioRadius.lg` (16dp); the mobile field is 56dp tall. Both are legitimate current core contracts, untouched by this slice.
- `TioInput` is already exported via `apps/core/lib/src/ui/components/inputs/inputs.dart`, so no barrel churn was required.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Expose exactly six parameters | Made | Each has a current consumer; the rest of #24's list already exists. |
| Exclude `autovalidateMode` and `scrollPadding` | Made | Zero current consumers; speculative surface is forbidden by the theme README. |
| Keep `prefixText`/`suffixText` as plain plumbing | Made | Core must not own unit or domain semantics. |
| Do not unify 14dp and 16dp | Made | Both are evidenced current contracts inside core itself. |
| Leave the validator/`errorText` styling asymmetry as-is | Made | See Known Limitations — fixing it is a larger change than this additive slice. |

## 4. Architecture

```text
Flutter TextFormField
        ↓
TioInput  (generic editable field, 14dp / 52dp)
        +
TioUsernameInputField / TioMobileNumberField  (specialised, 16dp — untouched)
```

No controller, repository, data-source or schema flow is involved. This is presentation-component work only.

## 5. Implementation

- [x] Add six optional parameters to both `TioInput` constructors, defaulting to today's behaviour.
- [x] Forward them to the `TextFormField` and its `InputDecoration`.
- [x] Add focused contract tests for each, plus regression assertions.
- [x] Document the new public capabilities and their limits.
- [x] Zero consumer migration.

## 6. Quality Review

### Validation Run

```text
dart format
  lib/src/ui/components/inputs/tio_input.dart
  test/ui/components/tio_input_test.dart
PASS

flutter analyze  # working directory: apps/core
PASS — No issues found

flutter test  # working directory: apps/core
  test/ui/components/tio_input_test.dart
PASS — 15 tests (4 pre-existing, 11 new)

flutter test  # working directory: apps/core
PASS — full core suite

git diff --check
PASS
```

### Test Coverage

Per capability: forwarded correctly when supplied, and today's behaviour preserved when omitted. `inputFormatters` is proven behaviourally — typing `a1b2c3` through a digits-only formatter yields `123` — rather than by asserting the property alone.

Regression assertions pin that this slice changes nothing rendered: 14dp radius and 52dp minimum height, `leading`/`trailing` still reaching the decoration, `compactNumber` still centred with a decimal keyboard, and **no default prefix, suffix, or validation behaviour**.

## 7. Final Handoff

### Changed Files

- `apps/core/lib/src/ui/components/inputs/tio_input.dart`
- `apps/core/test/ui/components/tio_input_test.dart`
- `apps/core/lib/src/theme/README.md`
- `.ai/tasks/issue-24a-tio-input-api-foundation.md`

### Actual Behavior

`TioInput` accepts six more optional capabilities. Every existing call site renders exactly as before, because each new parameter defaults to the behaviour already in effect.

### Known Limitations

**Validator errors do not carry error styling.** `hasError` is computed from `errorText` alone and drives the border, cursor and label colours. A validator-produced error renders its message through the decoration but leaves those colours in their normal state. Unifying the two would mean reading `FormFieldState` during build — a structural change deliberately kept out of an additive API slice. The first consumer needing both, most likely the Auth migration, should carry it.

**No `autovalidateMode`.** Validation runs only when an enclosing `Form` asks. That is intentional: exposing the callback must not introduce validation timing on its own.

### Follow-ups recorded, not done here

- The 16dp specialised-field family has no `TioInputTokens` entry and uses `TioRadius.lg` directly — a governance gap of the same shape as #189 (AppBar height token).
- `account_settings_page.dart` hand-rolls a username field that duplicates `TioUsernameInputField` and is **missing both of its race guards** (generation and stale-handle), so a slow in-flight availability response can overwrite a newer one.
- Multiline consumers form **two** intentionally different contracts, not one.
- The `TioSelectionField` requirement in #24 needs re-auditing now that `TioSettingsValueRow` ships.

### Final Status

`REVIEW`
