# Project changeset memory

Changesets below describe completed logical tasks, not Git commits. Earlier
entries were reconstructed from this work session when persistent memory was
introduced on 2026-10-23.

## 2026-10-23 — Rewrite as BINED3

- **Request:** Analyze BINED/BINED2 and create a readable 486-class editor,
  fixing memory/stack problems and supporting command-line file editing.
- **Changes:** Added `BINED3.ASM`, `dosbox_bined.conf`, `README.md`, and DOS/core/
  Python tests under `TESTS`; retargeted `BUILD.BAT` and `LAUNCH.BAT` to the
  EXE. Introduced DOS-owned memory, 32-bit logical offsets, bounded chunked
  I/O, one event loop, structured editing/rendering, and staged saves.
- **Verification:** Warning-free bundled TASM/TLINK build; core and release
  integration tests; independent Python byte checks; reduced-memory tests.
  A 131,089-byte file round-tripped correctly; 60,000 key events preserved SP.
- **Remaining:** DOSBox mounted-drive read-only reporting limitation; no undo;
  conventional-memory file limit of at most 512 KiB. See `PROJECT.md`.

## 2026-10-23 — Launcher test option and operating instructions

- **Request:** Add build/run/test instructions and tests to the launcher menu.
- **Changes:** Expanded `README.md`; added option 6 to build/run tests and
  expanded option 4 to show test diagnostics in `LAUNCH.BAT`. Kept option 5
  as the DOS prompt. Failure paths report build/test outcomes.
- **Verification:** Exercised option 6 with a temporary BIOS key feeder;
  `BINED_TESTED=1` confirmed success. Python verification and diff check passed.
- **Remaining:** Debugging sources were initially removed after checking;
  restored in the next changeset at the user's request.

## 2026-10-23 — Restore debugging sources and original color theme

- **Request:** Restore intermediate debugging sources under `BUILD`; return
  green-on-black with dark-green and purple highlights.
- **Changes:** Restored working `BUILD\MENUKEY.ASM`, preserved the earlier
  experiment as `BUILD\MENUEXEC.ASM`, and restored `BUILD\MENU.IN`. Updated
  `BINED3.ASM` attributes, existing video assertions in `TESTS\CORE.INC`, and
  `README.md` preservation/reproduction instructions.
- **Verification:** Both restored assembly sources compiled without warnings.
  The working feeder drove launcher option 6 successfully; production/core/
  integration tests and Python exact-byte checks passed. Diff check passed.
- **Remaining:** `MENUEXEC` and redirected input remain reference experiments;
  use `MENUKEY` for the working launcher check. Preserve these source files.

## 2026-10-23 — Introduce persistent agent memory

- **Request:** Save project memory in `.agents` and update it after each
  changeset.
- **Changes:** Added `.agents/PROJECT.md` for current architecture, preferences,
  file roles, commands, verification history and quirks; added this changelog.
  Added root `AGENTS.md` requiring future agents to read and maintain both
  memory files after each logical changeset, including documentation changes.
- **Verification:** Reviewed memory against current sources, README, and
  session results; ran `git diff --check`. Runtime tests were not rerun for
  this documentation-only task; preceding runtime results are labeled above.
- **Remaining:** None for this request. Keep the snapshot and changelog current
  before the final response to every future changeset.

## 2026-10-23 — Commit the consolidated project rewrite

- **Request:** Commit all implemented changes with a descriptive commit message.
- **Changes:** Prepared the user's staged project snapshot: BINED3 rewrite,
  launcher/build configuration, regression tests, palette restoration,
  preserved debugging sources and artifacts, operating instructions, persistent
  agent memory, and already-staged historical cleanup/sample files. Updated
  this memory to record the packaging context.
- **Verification:** Reviewed staged status, source/configuration diffs, and
  recent history; staged text secret-pattern scan found no matches. Reran
  `python TESTS\VERIFY.PY` successfully. Source/documentation whitespace check
  passed. A full staged whitespace check reports DOS-generated formatting in
  logs/listings/maps; those generated files are retained as staged. Runtime
  DOS tests were not rerun for this commit-only task; earlier results remain
  documented in the preceding entries.
- **Remaining:** Existing DOSBox attribute-reporting limitation is unchanged.
