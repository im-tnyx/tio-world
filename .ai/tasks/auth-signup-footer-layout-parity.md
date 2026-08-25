# Auth signup footer layout parity

Status: In Progress

## Problem

Manual QA found that the Login screen keeps its account-switch footer visually fixed at the bottom with the expected viewport height, while the Sign Up screen footer sits differently and changes the perceived bottom spacing/height.

Fresh source audit found the layout contract drift:

- Login uses `Scaffold(resizeToAvoidBottomInset: false)`; Sign Up used the default resizing behavior.
- Login uses `SafeArea(maintainBottomViewPadding: true)`; Sign Up used the default behavior.
- Login footer has only top spacing; Sign Up added an extra `TioSpacing.lg` bottom padding.

## Scope

- Align Sign Up viewport/keyboard/footer layout behavior with the existing accepted Login screen contract.
- Keep Sign Up copy and destination unchanged: `Already have an account? Log In`.
- Add focused regression coverage for the Sign Up layout contract.

## Out of scope

- Auth business logic or provider behavior.
- Password/email validation policy.
- Login screen redesign.
- Product Onboarding data/schema/flow changes.
- Splash branding.

## Acceptance

1. Sign Up uses the same scaffold resize behavior as Login.
2. Sign Up preserves bottom safe-area padding like Login.
3. Sign Up account-switch footer uses the same bottom-spacing contract as Login.
4. Existing Sign Up authentication behavior remains green.
5. Full Flutter/Dart + Android phone/Wear CI passes on the accepted runtime SHA.
6. PR #50 remains Draft/open/unmerged.
