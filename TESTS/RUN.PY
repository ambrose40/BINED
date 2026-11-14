"""Fresh, gated DOSBox build/test run, followed by source/output hash checks."""
from pathlib import Path
import json
import subprocess
import VERIFY


def main():
    root = Path(__file__).resolve().parent.parent
    build = root / "BUILD"
    build.mkdir(exist_ok=True)
    # Remove only workflow products, preserving debugging sources/references.
    for name in (
        "BUILD.OK", "TEST.OK", "VERIFIED.JSON", "BINED3.EXE", "TEST3.EXE",
        "KEYDRIVE.COM", "ASSEMBLE.LOG", "LINK.LOG", "TESTASM.LOG", "TESTLINK.LOG",
        "KEYASM.LOG", "KEYLINK.LOG", "TEST.LOG", "UI.LOG", "HELP.LOG", "ARGS.LOG",
        "OPENERR.LOG",
    ):
        (build / name).unlink(missing_ok=True)
    sources = [root / "BINED3.ASM", root / "BUILD.BAT"]
    sources += sorted(p for p in (root / "TESTS").iterdir()
                      if p.suffix.upper() in {".ASM", ".INC", ".BAT", ".PY"})
    before = {p.relative_to(root).as_posix(): VERIFY.digest(p) for p in sources}
    subprocess.run([
        str(root / "DOSBOX" / "DOSBox.exe"), "-conf", "dosbox_bined.conf",
        "-noautoexec", "-c", "mount c .", "-c", "c:",
        "-c", r"call TESTS\ALL.BAT", "-c", "exit",
    ], cwd=root, check=True, timeout=180)
    for name in ("BUILD.OK", "TEST.OK"):
        assert (build / name).read_text(encoding="ascii").strip() == "PASS", name
    VERIFY.verify(root)
    for relative, expected in before.items():
        assert VERIFY.digest(root / relative) == expected, f"Source changed during run: {relative}"
    products = [p for p in build.iterdir() if p.suffix.upper() == ".LOG"
                and p.name in {"ASSEMBLE.LOG", "LINK.LOG", "TESTASM.LOG", "TESTLINK.LOG",
                               "KEYASM.LOG", "KEYLINK.LOG", "TEST.LOG", "UI.LOG",
                               "HELP.LOG", "ARGS.LOG", "OPENERR.LOG"}]
    products += [build / n for n in ("BINED3.EXE", "TEST3.EXE", "KEYDRIVE.COM")]
    products += sorted((build / "TESTDATA").iterdir())
    files = before | {p.relative_to(root).as_posix(): VERIFY.digest(p) for p in products}
    (build / "VERIFIED.JSON").write_text(json.dumps({"files": files}, indent=2) + "\n", encoding="utf-8")
    VERIFY.verify(root, fresh=True)
    print("PASS: fresh build, gated DOS tests, and source/output manifest.")


if __name__ == "__main__":
    main()
