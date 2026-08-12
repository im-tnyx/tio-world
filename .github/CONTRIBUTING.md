# Contributing

The canonical contributor guide for **tio-world** lives at:

- [../CONTRIBUTING.md](../CONTRIBUTING.md)

Use this GitHub-facing file as a pointer only.

Before opening a pull request, read:

- [../README.md](../README.md)
- [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
- [../docs/MODULE_OWNERSHIP.md](../docs/MODULE_OWNERSHIP.md)
- [../docs/WATCH_STRATEGY.md](../docs/WATCH_STRATEGY.md)
- [../docs/ROADMAP.md](../docs/ROADMAP.md)

For day-to-day work, follow these defaults:

- Flutter phone app work belongs in `apps/app`.
- Shared Dart logic belongs in `apps/shared`; reusable Flutter UI belongs in `apps/core`.
- Flutter Wear OS app work belongs in `apps/wear`.
- Apple Watch app work belongs in `apps/watchos`.
- Backend and AI work belongs in `backend/*`.
- Keep changes small, scoped, and validated.
- Do not commit secrets, `.env` files, APK/AAB/IPA files, build outputs, or local caches.

If a doc does not exist yet, create or update it in the same PR that changes the architecture or workflow.
