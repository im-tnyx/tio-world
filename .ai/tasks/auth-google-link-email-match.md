# Google Connect Email Match Guard

Issue: #141
Parent: #118
Hosted smoke: #125
Implementation PR: #144
Stack base: Draft PR #138 / `agent/auth-email-confirmation-return`
Branch: `agent/auth-google-link-email-match-latest`

## Status

**SOURCE + COMBINED REPOSITORY CI PASS / HOSTED MISMATCH RETEST PENDING**

Exact combined application/test source validated:

`c04cdfabf9ee193feca4891a62c81509fc1a1c97`

## Product rule

Google Connect is an identity-link action, not an Email-change action.

```text
verified Tio Email = A
selected Google Email = A
→ allow

verified Tio Email = A
selected Google Email = B
→ block before Supabase link
```

Email change remains a separate future flow.

## Discovery evidence

Sanitized read-only production audit at discovery:

```text
users with Email + Google identities = 2
same canonical Email = 1
different canonical Email = 1
mismatched case Auth UUIDs = 1
mismatched case public roots = 1
identities on mismatched account = 2
```

This confirms the existing UUID-preservation guard is insufficient by itself. No production identity was changed by this implementation or validation work.

## Implementation

- [x] Reuse `canonicalEmailIdentity` for both Tio and Google Email comparison.
- [x] Require a verified Tio Email before a new Google link.
- [x] Block mismatched Google Email before token exchange/linking.
- [x] Preserve explicit Google account chooser.
- [x] Preserve existing Google-linked idempotence.
- [x] Preserve post-link Google identity evidence and UUID check.
- [x] Add mismatch and Gmail canonical-equivalence tests.
- [x] Combined repository-wide Flutter/Dart analyze/tests green on latest #138 stack.
- [x] Combined Phone + Wear Android debug builds green.
- [ ] Hosted mismatch retest proves no new mismatched identity attaches.

## Validation

Isolated guard checkpoint `9277712bf4caf50d9177a885ed090d1f6b7fac0b`:

- Flutter CI #2092 / run `33063500232`: SUCCESS
- Android Native CI #504 / run `33063500233`: SUCCESS

Latest combined #138 + #141 source `c04cdfabf9ee193feca4891a62c81509fc1a1c97` via validation-only PR #145:

- Flutter CI #2093 / run `33064273360`: SUCCESS
  - Flutter analyze PASS
  - Dart analyze PASS
  - serialized Flutter tests PASS
  - Dart tests PASS
- Android Native CI #505 / run `33064273338`: SUCCESS
  - Phone Android debug APK PASS
  - Wear Android debug APK PASS

## Scope boundary

No production identity cleanup, Email-change UX, implicit merge, or Supabase schema/data mutation in this source slice.

## PR state rule

PR #144 remains Draft/open/unmerged. Do not mark Ready or merge without explicit owner authorization. Validation-only PR #145 closes without merge after evidence sync.
