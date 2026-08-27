# Auth Phone-first Test Alignment

**Status:** TEST FIX PASS / FLUTTER CI PASS / ANDROID CI PASS  
**Parent:** #118  
**Base:** PR #131 @ `d4e323ce7ef22cd2958756236f34f411bc87473d`  
**Branch:** `agent/auth-phone-first-test-alignment`

## Context

Repository-wide Flutter CI exposed inherited Auth presentation test failures while validating Issue #23. The failing Auth files were unchanged by the units refactor, so this work is intentionally isolated from Issue #23.

## Demonstrated stale assumptions

1. `auth_field_visual_parity_test.dart` mounted `LoginPage` and `EmailSignupPage` with Phone-first defaults, then immediately looked for Email + Password fields.
2. `login_page_test.dart` expected global text `Email` to be absent in Email mode even though the Email field itself correctly renders an `Email` label.
3. Once the parity test rendered the intended Email fields, it exposed stale hardcoded stroke widths (`1.2` / `1.8`) while canonical `TioInput` ownership is `TioInputTokens.outlineWidth` / `focusedOutlineWidth` (`0.75` / `1.25`).

## Fix

- mount Login and Signup explicitly with `AuthEntryMode.email` for Email-field visual parity assertions
- remove the invalid global `Email` text absence assertion from the mode-switch test
- assert canonical `TioInputTokens` stroke roles instead of obsolete physical `TioStroke` widths
- no production Auth source changes
- no Supabase/config/data changes

Validated test-fix source head:

`ba9f42887e2200f7a8a0fb8b6a3b81bc49dc7e31`

Later tracker-only commits do not change application/test source.

## Validation

Validation-only Draft PR #135 targeted `main` only to trigger existing CI while PR #134 remains stacked on PR #131. PR #135 was closed without merge after evidence was recorded.

Confirmed on source head `ba9f42887e2200f7a8a0fb8b6a3b81bc49dc7e31`:

- [x] repository-wide Flutter analyze PASS
- [x] repository-wide Dart analyze PASS
- [x] repository-wide serialized Flutter tests PASS
- [x] repository-wide Dart tests PASS
- [x] previously failing Login mode-switch test PASS
- [x] previously failing Auth field visual-parity test PASS
- [x] Android phone debug APK PASS
- [x] Android Wear debug APK PASS
- [x] final evidence recorded on parent #118 and PR #134

## Scope

Test-only alignment. Production Phone-first Auth behavior and canonical design-system input geometry remain unchanged.

Keep PR #134 Draft/open/unmerged. Do not mark PR #131 or downstream stacked PRs Ready/merged without explicit owner authorization.
