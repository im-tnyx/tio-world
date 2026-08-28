# Auth signup footer layout parity

Status: Complete / Frozen

## Problem

Manual QA found two presentation drifts between Login and Sign Up:

- Sign Up account-switch footer did not share Login's stable viewport/bottom-safe-area contract.
- Auth input fields did not share one visual/floating-label behavior contract; Login Password was hint-only while Sign Up had a different field geometry and icon treatment.

## Implemented scope

- Sign Up now uses `Scaffold(resizeToAvoidBottomInset: false)` and `SafeArea(maintainBottomViewPadding: true)` like Login.
- Sign Up account-switch footer uses the same bottom-spacing contract as Login.
- Login and Sign Up Email/Password fields use the same accepted outline geometry, padding, typography and floating-label behavior.
- Screen-specific semantics remain separate:
  - Login Password uses floating label `Password` and no signup-policy guidance.
  - Sign Up Password uses floating label `Password` and retains `At least 6 characters` guidance.
- Existing validation, auth/provider behavior, routing and Product Onboarding data/schema are unchanged.
- Regression coverage locks footer behavior plus shared field geometry/floating-label contract without forcing identical screen-specific copy.

## Accepted runtime/source-test checkpoint

```text
e4f8125d674392158cbc461c64c73d5051522a9d
Flutter CI #2031 / run 32864846288 ✅
Android Native CI #443 / run 32864846300 ✅
```

Flutter analyze, Dart analyze, Flutter tests, Dart tests, phone Android debug APK and Wear Android debug APK all passed on the accepted SHA.

## Merge guard

PR #50 remains Draft/open/unmerged. Ready/Merge still requires explicit owner authorization.
