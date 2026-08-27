# Google Connect Email Match Guard

Issue: #141
Parent: #118
Hosted smoke: #125
Stack base: Draft PR #134 / `agent/auth-phone-first-test-alignment`
Branch: `agent/auth-google-link-email-match`

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

This confirms the existing UUID-preservation guard is insufficient by itself.

## Implementation

- [x] Reuse `canonicalEmailIdentity` for both Tio and Google Email comparison.
- [x] Require a verified Tio Email before a new Google link.
- [x] Block mismatched Google Email before token exchange/linking.
- [x] Preserve explicit Google account chooser.
- [x] Preserve existing Google-linked idempotence.
- [x] Preserve post-link Google identity evidence and UUID check.
- [x] Add mismatch and Gmail canonical-equivalence tests.
- [ ] Repository-wide Flutter/Dart analyze/tests green.
- [ ] Phone + Wear Android debug builds green.
- [ ] Hosted mismatch retest proves no identity attaches.

## Scope boundary

No production identity cleanup, Email-change UX, implicit merge, or Supabase schema/data mutation in this source slice.

## PR state rule

Implementation PR remains Draft/open/unmerged. Do not mark Ready or merge without explicit owner authorization.
