#!/usr/bin/env python3
"""Validate and materialize client-safe Supabase defines for manual iOS QA."""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlsplit


class ConfigurationError(ValueError):
    """Raised when a requested QA build has invalid runtime configuration."""


_SUPABASE_HOST = re.compile(r"^[a-z0-9][a-z0-9-]*\.supabase\.co$", re.IGNORECASE)
_PUBLISHABLE_KEY = re.compile(r"^sb_publishable_[A-Za-z0-9_-]+$")


def _is_service_role_jwt(value: str) -> bool:
    parts = value.split(".")
    if len(parts) != 3:
        return False
    try:
        payload = parts[1] + "=" * (-len(parts[1]) % 4)
        decoded = json.loads(base64.urlsafe_b64decode(payload.encode("ascii")))
    except (ValueError, UnicodeError, json.JSONDecodeError):
        return False
    return isinstance(decoded, dict) and decoded.get("role") == "service_role"


def resolve_runtime_config(
    mode: str,
    supabase_url: str = "",
    publishable_key: str = "",
) -> dict[str, str] | None:
    """Return compile-time defines for QA mode, or None for UI-only mode."""
    if mode == "ui_only":
        return None
    if mode != "qa_login":
        raise ConfigurationError("Unsupported iOS build mode.")

    url = supabase_url.strip()
    key = publishable_key.strip()
    if not url or not key:
        raise ConfigurationError("QA Supabase configuration is missing.")

    try:
        parsed = urlsplit(url)
        port = parsed.port
    except ValueError as error:
        raise ConfigurationError(
            "QA Supabase URL must be an HTTPS project endpoint."
        ) from error
    if (
        parsed.scheme != "https"
        or not parsed.hostname
        or not _SUPABASE_HOST.fullmatch(parsed.hostname)
        or parsed.username is not None
        or parsed.password is not None
        or port not in (None, 443)
        or parsed.path not in ("", "/")
        or parsed.query
        or parsed.fragment
    ):
        raise ConfigurationError("QA Supabase URL must be an HTTPS project endpoint.")

    if _is_service_role_jwt(key) or key.lower().startswith(
        ("sb_secret_", "sb_service_role_", "service_role", "service-role")
    ):
        raise ConfigurationError("Privileged Supabase keys are not allowed.")
    if not _PUBLISHABLE_KEY.fullmatch(key):
        raise ConfigurationError("QA key must be a Supabase publishable key.")

    return {
        "SUPABASE_URL": url,
        "SUPABASE_PUBLISHABLE_KEY": key,
    }


def write_runtime_config(
    mode: str,
    output_path: Path,
    supabase_url: str = "",
    publishable_key: str = "",
) -> None:
    config = resolve_runtime_config(mode, supabase_url, publishable_key)
    if config is None:
        output_path.unlink(missing_ok=True)
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor = os.open(
        output_path,
        os.O_WRONLY | os.O_CREAT | os.O_EXCL,
        0o600,
    )
    try:
        if hasattr(os, "fchmod"):
            os.fchmod(file_descriptor, 0o600)
        with os.fdopen(file_descriptor, "w", encoding="utf-8") as runtime_file:
            runtime_file.write(json.dumps(config, separators=(",", ":")))
    except Exception:
        output_path.unlink(missing_ok=True)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("ui_only", "qa_login"), default="ui_only")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    try:
        write_runtime_config(
            args.mode,
            args.output,
            os.environ.get("TIO_IOS_QA_SUPABASE_URL", ""),
            os.environ.get("TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY", ""),
        )
    except ConfigurationError as error:
        print(str(error), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
