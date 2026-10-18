from __future__ import annotations

import base64
import json
import os
import stat
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ios_qa_runtime_config import (  # noqa: E402
    ConfigurationError,
    resolve_runtime_config,
    write_runtime_config,
)


class RuntimeConfigTests(unittest.TestCase):
    @staticmethod
    def _workspace_temp_directory() -> tempfile.TemporaryDirectory[str]:
        repo_root = Path(__file__).resolve().parents[2]
        return tempfile.TemporaryDirectory(dir=repo_root)

    def test_ui_only_is_default_behavior_without_runtime_config(self) -> None:
        self.assertIsNone(resolve_runtime_config("ui_only"))

    def test_qa_login_accepts_https_supabase_project_and_publishable_key(self) -> None:
        self.assertEqual(
            resolve_runtime_config(
                "qa_login",
                "https://tio-qa-123.supabase.co",
                "sb_publishable_exampleKey_123",
            ),
            {
                "SUPABASE_URL": "https://tio-qa-123.supabase.co",
                "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_exampleKey_123",
            },
        )

    def test_qa_login_rejects_missing_and_partial_configuration(self) -> None:
        for url, key in (
            ("", ""),
            ("https://tio-qa.supabase.co", ""),
            ("", "sb_publishable_exampleKey"),
        ):
            with self.subTest(url=bool(url), key=bool(key)):
                with self.assertRaises(ConfigurationError):
                    resolve_runtime_config("qa_login", url, key)

    def test_qa_login_rejects_non_https_or_non_supabase_endpoints(self) -> None:
        for url in (
            "http://tio-qa.supabase.co",
            "https://tio-qa.supabase.co.attacker.example",
            "https://user@tio-qa.supabase.co",
            "https://tio-qa.supabase.co/path",
            "https://tio-qa.supabase.co?query=1",
        ):
            with self.subTest(url=url):
                with self.assertRaises(ConfigurationError):
                    resolve_runtime_config("qa_login", url, "sb_publishable_exampleKey")

    def test_qa_login_rejects_invalid_and_privileged_keys(self) -> None:
        service_role_payload = base64.urlsafe_b64encode(
            json.dumps({"role": "service_role"}).encode("utf-8")
        ).decode("ascii").rstrip("=")
        keys = (
            "sb_publishable_",
            "sb_publishable_has spaces",
            "sb_secret_not-a-client-key",
            "sb_service_role_not-a-client-key",
            f"eyJhbGciOiJub25lIn0.{service_role_payload}.signature",
        )
        for key in keys:
            with self.subTest(key_prefix=key[:18]):
                with self.assertRaises(ConfigurationError):
                    resolve_runtime_config("qa_login", "https://tio-qa.supabase.co", key)

    def test_ui_only_removes_any_existing_temporary_runtime_file(self) -> None:
        with self._workspace_temp_directory() as temp_dir:
            output = Path(temp_dir) / "runtime.json"
            output.write_text("should be removed", encoding="utf-8")
            write_runtime_config("ui_only", output)
            self.assertFalse(output.exists())

    def test_valid_qa_config_is_written_without_extra_fields(self) -> None:
        with self._workspace_temp_directory() as temp_dir:
            output = Path(temp_dir) / "runtime.json"
            write_runtime_config(
                "qa_login",
                output,
                "https://tio-qa.supabase.co",
                "sb_publishable_exampleKey_123",
            )
            self.assertEqual(
                json.loads(output.read_text(encoding="utf-8")),
                {
                    "SUPABASE_URL": "https://tio-qa.supabase.co",
                    "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_exampleKey_123",
                },
            )
            if os.name == "posix":
                self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o600)


class WorkflowContractTests(unittest.TestCase):
    def test_manual_only_contract_and_safe_artifact_selection(self) -> None:
        root = Path(__file__).resolve().parents[2]
        workflow = (root / ".github/workflows/ios-ui-build.yml").read_text(encoding="utf-8")
        self.assertIn(
            "on:\n  workflow_dispatch:\n    inputs:\n      build_mode:", workflow
        )
        trigger_block = workflow.split("on:\n", 1)[1].split("\npermissions:", 1)[0]
        self.assertIn("workflow_dispatch:", trigger_block)
        for automatic_trigger in ("push:", "pull_request:", "pull_request_target:", "schedule:", "repository_dispatch:"):
            self.assertNotIn(automatic_trigger, trigger_block)
        self.assertIn("permissions:\n  contents: read", workflow)
        self.assertIn("persist-credentials: false", workflow)
        self.assertIn("default: ui_only", workflow)
        self.assertIn("- ui_only\n          - qa_login", workflow)
        qa_config_step = workflow.split(
            "- name: Validate and write QA Supabase runtime config", 1
        )[1].split("- name: Build unsigned profile device app", 1)[0]
        self.assertIn("if: inputs.build_mode == 'qa_login'", qa_config_step)
        self.assertIn("secrets.TIO_IOS_QA_SUPABASE_URL", qa_config_step)
        self.assertIn("secrets.TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY", qa_config_step)
        self.assertNotIn("vars.TIO_IOS_QA_", workflow)
        self.assertIn("--dart-define-from-file=$RUNNER_TEMP/tio-ios-runtime-config.json", workflow)
        self.assertIn("if: always()\n        shell: bash\n        run: rm -f", workflow)
        upload_block = workflow.split("- name: Upload unsigned iPhone artifact", 1)[1]
        self.assertNotIn("runtime.json", upload_block)
        self.assertNotIn("runtime-config", upload_block)
        self.assertNotIn(".json", upload_block)
        self.assertIn('echo "build_mode=${BUILD_MODE}"', workflow)
        provenance_fields = workflow.split('echo "source_sha=', 1)[1].split("> provenance.txt", 1)[0]
        self.assertNotIn("TIO_IOS_QA_", provenance_fields)


if __name__ == "__main__":
    unittest.main()
