"""Negative freshness/link-result checks in isolated temporary workspaces."""
from pathlib import Path
import contextlib
import io
import json
import shutil
import tempfile
import unittest
import VERIFY


class FreshnessTests(unittest.TestCase):
    def setUp(self):
        source = Path(__file__).resolve().parent.parent
        self.temp = tempfile.TemporaryDirectory(prefix="bined-host-", dir=Path(tempfile.gettempdir()) / "opencode")
        self.root = Path(self.temp.name)
        manifest = json.loads((source / "BUILD/VERIFIED.JSON").read_text(encoding="utf-8"))
        for relative in list(manifest["files"]) + ["BUILD/VERIFIED.JSON", "BUILD/BUILD.OK", "BUILD/TEST.OK"]:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source / relative, target)

    def tearDown(self):
        self.temp.cleanup()

    def check_rejected(self):
        with self.assertRaises((AssertionError, FileNotFoundError)), contextlib.redirect_stdout(io.StringIO()):
            VERIFY.verify(self.root, fresh=True)

    def test_changed_source(self):
        with (self.root / "BINED3.ASM").open("a", encoding="ascii") as stream:
            stream.write("\n; changed after build\n")
        self.check_rejected()

    def test_changed_executable(self):
        with (self.root / "BUILD/BINED3.EXE").open("ab") as stream:
            stream.write(b"stale")
        self.check_rejected()

    def test_link_failure(self):
        (self.root / "BUILD/LINK.LOG").write_text("Turbo Link\nFatal: cannot create EXE\n", encoding="ascii")
        self.check_rejected()

    def test_missing_completion(self):
        (self.root / "BUILD/TEST.OK").unlink()
        self.check_rejected()

    def test_missing_manifest(self):
        (self.root / "BUILD/VERIFIED.JSON").unlink()
        self.check_rejected()


if __name__ == "__main__":
    unittest.main()
