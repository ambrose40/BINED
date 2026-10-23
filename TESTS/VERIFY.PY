"""Independently check artifacts produced by TESTS/TEST.BAT (Python 3)."""

from pathlib import Path
import hashlib


def main():
    root = Path(__file__).resolve().parent.parent
    build = root / "BUILD"
    data = build / "TESTDATA"
    for name in ("ASSEMBLE.LOG", "TESTASM.LOG", "KEYASM.LOG"):
        log = (build / name).read_text(encoding="ascii")
        assert "Error messages:    None" in log, (name, log)
        assert "Warning messages:  None" in log, (name, log)
    for name in ("TEST.LOG", "UI.LOG"):
        log = (build / name).read_text(encoding="ascii")
        assert "PASS:" in log and "FAIL:" not in log, (name, log)
    for name, text in (
        ("HELP.LOG", "Usage: BINED3 [filename]"),
        ("ARGS.LOG", "Invalid command line"),
        ("OPENERR.LOG", "Cannot load file"),
    ):
        assert text in (build / name).read_text(encoding="ascii"), name

    expected = bytes((i ^ (i >> 8) ^ 0x5A) & 0xFF for i in range(0x20011))
    actual = (data / "ROUND.BIN").read_bytes()
    assert actual == expected, "Multi-segment round trip changed file bytes"
    assert (data / "EMPTY.BIN").read_bytes() == b"", "Empty save is not empty"
    assert (data / "UI2.BIN").read_bytes() == b"\xff\x44", "UI edits differ"
    assert not (data / "UI.BIN").exists(), "Save-as wrote the original path"
    assert {p.name.upper() for p in data.iterdir()} == {
        "ROUND.BIN", "EMPTY.BIN", "UI2.BIN"
    }, "Unexpected leftover staging/backup files"
    assert (build / "BINED3.EXE").read_bytes()[:2] == b"MZ", "Not a DOS EXE"
    print(f"PASS: {len(actual):,}-byte round trip, empty save, exact UI output,")
    print("      clean staging directory, and warning-free TASM builds.")
    print(f"ROUND.BIN SHA-256: {hashlib.sha256(actual).hexdigest()}")


if __name__ == "__main__":
    main()
