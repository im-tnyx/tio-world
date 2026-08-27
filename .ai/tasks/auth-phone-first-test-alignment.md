# Auth Phone-first Test Alignment

**Status:** TEST FIX IMPLEMENTED / CI PENDING  
**Parent:** #118  
**Base:** PR #131 @ `d4e323ce7ef22cd2958756236f34f411bc87473d`  
**Branch:** `agent/auth-phone-first-test-alignment`

## Context

Repository-wide Flutter CI exposed two inherited Auth presentation test failures while validating Issue #23. Both failing files were byte-identical between PR #131 and the downstream units branch, so they are not Issue #23 regressions.

## Demonstrated stale assumptions

1. `auth_field_visual_parity_test.dart` mounted `LoginPage` and `EmailSignupPage` with their Phone-first defaults, then immediately looked for Email + Password fields.
2. `login_page_test.dart` expected global text `Email` to be absent in Email mode even though the Email field itself correctly renders an `Email` label.

## Fix

- mount Login and Signup explicitly with `AuthEntryMode.email` for Email-field visual parity assertions
- remove the invalid global `Email` text absence assertion from the mode-switch test
- no production Auth source changes
- no Supabase/config/data changes

## Validation

- [ ] Auth package analyze/test
- [ ] repository-wide Flutter/Dart analyze
- [ ] repository-wide serialized tests
- [ ] record evidence on parent/Auth PR

Keep any validation-only PR Draft and close it without merge after evidence is recorded. Do not mark PR #131 or downstream stacked PRs Ready/merged without explicit owner authorization.
