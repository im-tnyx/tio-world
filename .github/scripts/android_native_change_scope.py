"""Select Android APK builds from a PR diff; unknown changes build both."""

import os
import re
import subprocess


def select_targets(paths: list[bytes]) -> tuple[bool, bool]:
    if not paths:
        return True, True

    phone = False
    wear = False
    for path in paths:
        if path.startswith((b"apps/app/", b"apps/features/")):
            phone = True
        elif path.startswith(b"apps/wear/"):
            wear = True
        else:
            return True, True
    return phone, wear


def main() -> None:
    if os.environ.get("GITHUB_EVENT_NAME") == "workflow_dispatch":
        phone, wear = True, True
    else:
        base = os.environ["PR_BASE_SHA"]
        head = os.environ["PR_HEAD_SHA"]
        if not all(re.fullmatch(r"[0-9a-f]{40}", sha) for sha in (base, head)):
            raise ValueError("Expected full PR base and head commit SHAs")
        changed = subprocess.check_output(
            ["git", "diff", "--name-only", "--no-renames", "-z", f"{base}...{head}"]
        )
        phone, wear = select_targets([path for path in changed.split(b"\0") if path])

    result = f"phone={str(phone).lower()}\nwear={str(wear).lower()}\n"
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(result)
    print(f"Android build selection: {result.strip().replace(chr(10), ', ')}")


if __name__ == "__main__":
    main()
