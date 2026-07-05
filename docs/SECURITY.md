# Security

`tio-world` is a health and fitness product. Treat privacy, safety, and trust as product requirements.

## Public Repository Rule

This repository is public. Assume anything committed here can be seen by other people.

Before every commit, check:

```bash
git status -sb
git diff --stat
git diff --check
```

## Never Commit

Do not commit:

- `.env` files
- signing files
- private certificates
- local machine paths
- production logs
- real user exports
- health records
- local database dumps
- APK, AAB, IPA, or archive artifacts
- screenshots containing personal information

## Environment Files

Keep local environment files out of Git.

Allowed pattern:

```text
.env.example
```

Not allowed:

```text
.env
.env.local
.env.production
```

## Client Safety

Mobile and watch apps should only contain values safe for client distribution.

Server-only operations should stay in backend code.

## Health Data

Health and fitness data can be sensitive.

Rules:

- collect only what the feature needs
- show clear user intent for connected services
- avoid logging personal health details
- keep screenshots clean before sharing in issues or PRs
- avoid putting real user data in test fixtures

## Authentication

Auth flows should avoid leaking implementation details into UI.

Recommended direction:

```text
UI
  ↓
Auth controller
  ↓
Auth repository
  ↓
Backend or auth provider
```

## Watch Security

Watch apps should store minimum local data.

Recommended watch local state:

- current workout session
- current set input
- rest timer state
- pending sync metadata

Avoid storing long-term history on watch unless required.

## Review Checklist

Before merging security-sensitive work:

- [ ] No local environment files are included.
- [ ] No real user data is included.
- [ ] No build artifacts are included.
- [ ] Logs are clean.
- [ ] Screenshots are clean.
- [ ] Data access is behind repository/API boundaries.
- [ ] Backend-only behavior is not implemented in client code.
