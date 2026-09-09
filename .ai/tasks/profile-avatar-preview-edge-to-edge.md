# GitHub #210 — Profile Photo preview edge-to-edge horizontally

## 1. Baseline

```text
base            d3eac22c4910c5b35a496b2c73f7d2de817edd25
branch          fix/profile-avatar-preview-edge-to-edge
issue           https://github.com/im-tnyx/tio-world/issues/210
surface         apps/features/profile/lib/src/presentation/pages/
                avatar_preview_page.dart
```

## 2. The defect, measured

`AvatarPreviewPage` sizes its square from the width its box reports, and that
box sat inside a `SafeArea` applying horizontal insets. On a device that
reports them the photo came out narrower than the screen it was meant to fill.

Measured against the base, with synthetic horizontal `viewPadding`:

```text
viewport  side inset   left   right   square
360       0             0.0   360.0   360.0
360       24           24.0   336.0   312.0
320       0             0.0   320.0   320.0
320       24           24.0   296.0   272.0
```

`TioAvatarShape.square` and `BoxFit.cover` add no side padding of their own.
The body's safe area was the whole of it.

Confirmed still present on the exact base before any change: nothing landed
between the issue and this branch that addressed it, and no other open PR
touches these files.

## 3. Owner-approved behaviour

```text
portrait preview        edge to edge horizontally
top / bottom insets     preserved
1:1 square              preserved
TioAvatar / BoxFit      unchanged
Back / Replace /
Download / Delete       unchanged
missing or failed photo same square bounds
```

## 4. Implementation scope

One widget, two arguments:

```dart
SafeArea(left: false, right: false, …)
```

Top and bottom stay on, and that is not a compromise — it costs the square
nothing. Measured:

```text
bottom inset   body height   body width   square
0              700           360          360
34             666           360          360
```

In portrait the remaining height still exceeds the width, and the width is
what `min` picks. Top is already spent by the app bar; bottom is real
protection for the home indicator, and the body still stops above it.

## 5. Non-goals

```text
remove-image confirmation sheet   not touched — a separate design-system
                                  slice, agreed with the owner, because it
                                  is shared by three screens across two
                                  packages and hand-rolls its actions
Profile redesign                  none
media / storage / backend         none
routing                           none — apps/app is untouched
```

## 6. Test matrix

`apps/features/profile/test/presentation/avatar_preview_bounds_test.dart`,
asserting measured bounds rather than widget presence:

```text
360 wide, 24dp side insets     left == 0, right == 360, width == 360
320 wide, 24dp side insets     left == 0, right == 320, width == 320
both widths                    still square, TioAvatar matches the bounds
no insets                      unchanged at 360
34dp bottom inset              body stops above it; square still 360
initials fallback              same bounds
photo that cannot decode       same bounds, no exception
actions                        all three present; Back reports its tap
```

Mutation-verified: restoring the horizontal inset fails five of these.

## 7. Validation

```text
flutter analyze  profile / core / app       No issues found
flutter test     profile 68 · core 267 · app 305    all passed
git diff --check origin/main...HEAD         clean
Flutter CI on fe65e016                      success
```

## 8. Ownership and handoff

The page belongs to the Profile feature; the change is layout only and adds
no Core surface. `TioAvatar` is unchanged, so no design-system contract moves
with it.

Handoff after merge: the remove-image confirmation sheet still hand-rolls its
two actions and its close affordance instead of using `TioConfirmationCard`
and `TioButton`, which is the path `showTioConfirmationBottomSheet` already
takes. That is queued as its own slice with its own UI review, because it is
shared by `avatar_preview_page`, `profile_page` and `profile_settings_page`.

## 9. Status

**Merge is owner-gated.** Nothing here is merged.
