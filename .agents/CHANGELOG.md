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

## 2026-10-24 — Modal F1 help and status colours

- **Request:** Redesign F1 help as a small modal pseudo text window with each
  sentence on its own line; use dark purple for Offset/Size/Capacity values
  and blue for the bottom sentence starting with `F1 Help`.
- **Changes:** Updated `BINED3.ASM` with a centred, black-filled 58x19 help
  window, purple CP437 border/title, 15 separate instruction lines, and an
  any-key dismissal prompt. The cursor is hidden during help and its shape
  restored afterward. Added VGA attributes `05h` for the three numeric values
  and `01h` for the bottom status line. Updated `TESTS/CORE.INC` with palette,
  help layout/bounds, clearing, and editor-redraw checks; updated `README.md`
  and project memory. Rebuilt production/test artifacts under `BUILD`.
- **Verification:** Ran the documented unattended DOSBox build and
  `TESTS\TEST.BAT`; production/core/integration assembly had no errors or
  warnings, core tests passed, and the actual release EXE passed help,
  editing, save-as, and save-and-quit integration. Ran `python TESTS\VERIFY.PY`:
  exact 131,089-byte round trip, empty output, `UI2.BIN` bytes `FF 44`, and
  staging cleanup all passed. Source/documentation whitespace check passed.
- **Remaining:** None for this request. Existing DOSBox mounted-drive
  attribute-reporting limitation remains; reduced-memory and launcher-menu
  automation were previously verified, not rerun for this changeset.

## 2026-10-24 — Improve F1 help key/description contrast

- **Request:** Give help key names and their descriptions contrasting colours,
  suggesting bright-yellow keys or gray descriptions.
- **Changes:** Added bright-yellow `ATTR_HELP_KEY` (`0Eh`) and `PutHelpLine`
  in `BINED3.ASM` to highlight key labels before colons while keeping help
  descriptions green. Made digit-input and any-key return text use matching
  key labels; the EOF note stays green. Updated existing help video assertions
  in `TESTS/CORE.INC`, `README.md`, and project memory. Rebuilt the editor and
  test artifacts under `BUILD`.
- **Verification:** Reran the documented unattended DOSBox build and
  `TESTS\TEST.BAT`; core and release-EXE integration tests passed. Reran
  `python TESTS\VERIFY.PY`; exact output bytes, staging cleanup and
  warning-free assembly checks passed. Source/documentation whitespace check
  passed.
- **Remaining:** None for this request; existing DOSBox attribute-reporting
  limitation remains.

## 2026-10-24 — White headings, yellow mode, and gray ASCII preview

- **Request:** Make heading text bright white, the selected HEX/BIN mode
  bright yellow, and right-hand ASCII symbols light gray.
- **Changes:** Added `ATTR_HEADING` (`0Fh`), `ATTR_MODE` (`0Eh`), and
  `ATTR_ASCII` (`07h`) in `BINED3.ASM`. The editor title, modified marker,
  and column headings use white; the current mode uses yellow; ASCII output
  always uses light gray, including the selected byte's preview. Updated
  existing rendering checks in `TESTS/CORE.INC`, `README.md`, and project
  memory; rebuilt production/test artifacts under `BUILD`.
- **Verification:** Reran the documented unattended DOSBox build and
  `TESTS\TEST.BAT`; core rendering/colour checks and release-EXE integration
  passed. Reran `python TESTS\VERIFY.PY`; warning-free assembly, exact output
  bytes and staging cleanup passed. Source/documentation whitespace check
  passed.
- **Remaining:** None for this request; existing DOSBox attribute-reporting
  limitation remains.

## 2026-10-24 — Bright-red column labels

- **Request:** Make OFFSET, DATA, and ASCII labels bright red.
- **Changes:** Added `ATTR_COLUMN` (`0Ch`) in `BINED3.ASM` for the column
  labels. Updated existing colour assertions in `TESTS/CORE.INC`, covering
  all three labels and binary-mode ASCII, plus `README.md` and project memory.
  Rebuilt production/test artifacts under `BUILD`.
- **Verification:** Reran the unattended DOSBox build and `TESTS\TEST.BAT`;
  core and release-EXE integration tests passed. Reran
  `python TESTS\VERIFY.PY`; warning-free assembly, exact file bytes, and
  staging cleanup passed. Source/documentation whitespace check passed.
- **Remaining:** None for this request; existing DOSBox attribute-reporting
  limitation remains.

## 2026-10-24 — Document the user's latest colour edits

- **Request:** Check recent user colour edits and update project memory and
  README to match.
- **Changes:** Reviewed `BINED3.ASM` constants and render/dialog paths.
  Updated `README.md` and `.agents/PROJECT.md` for the light-gray footer,
  help descriptions/EOF note, and Save As/unsaved-quit prompts, plus purple
  filename and Save As input. Recorded current attribute reuse and the
  remaining dark-green help return description. Preserved the user's source
  edits and recorded that previous runtime results predate these changes.
- **Verification:** Compared documentation with current constants,
  `RenderScreen`, `RenderHelpWindow`, `DialogPrompt`, `SaveAsDialog`, and
  existing colour assertions; reviewed documentation diffs and ran the
  source/documentation whitespace check. No build or runtime/host tests were
  run for this documentation-only changeset.
- **Remaining:** `TESTS/CORE.INC` still expects the previous blue footer and
  green help description/EOF colours; refresh those assertions before the
  next test run. Existing DOSBox attribute-reporting limitation remains.

## 2026-10-24 — Synchronize tests with the current light-gray palette

- **Request:** Fix the stale footer and help-description colour assertions
  identified during the documentation review.
- **Changes:** Updated three assertions/comments in `TESTS/CORE.INC` to expect
  light-gray `0746h` (footer `F`), `076Dh` (help description `m`), and `0741h`
  (EOF note `A`). Rebuilt production/test artifacts under `BUILD`; updated
  project memory to resolve the pending follow-up. README already describes
  the current palette accurately.
- **Verification:** Reran the documented unattended DOSBox build and
  `TESTS\TEST.BAT`; core and actual release-EXE integration tests passed.
  Reran `python TESTS\VERIFY.PY`; warning-free assembly, exact output bytes,
  and staging cleanup passed. Source/documentation whitespace check passed.
- **Remaining:** None for this request; existing DOSBox attribute-reporting
  limitation remains.

## 2026-10-24 — Package the help/palette update for commit

- **Request:** Commit the completed work using a commit-message convention.
- **Changes:** Prepared the modal F1 help, final user palette, updated colour
  assertions, README/project memory, and tracked rebuilt `BUILD` artifacts as
  one changeset with message `feat(ui): redesign F1 help and refine editor colours`.
  Recorded Conventional Commits as the user's commit-message preference.
- **Verification:** Reviewed Git status, recent history, source/test/docs and
  generated log/map diffs, and listing palette entries. Source/documentation
  whitespace check passed. DOS tests and Python byte verification were already
  run successfully in the preceding assertion-fix changeset; no runtime tests
  were repeated for this commit-only task.
- **Remaining:** None for packaging; existing DOSBox attribute-reporting
  limitation remains.

## 2026-11-14 — Refresh memory and add ASCII editing mode

- **Request:** Bring project memory up to date with all completed work, require
  updates before every commit, and add a third ASCII text-editing mode with
  assigned keys, help, and tests.
- **Changes:** Reconciled `.agents/PROJECT.md` with source and the clean initial
  worktree/history: rewrite `c220f36`, cleanup `4242af6` (removed the tracked
  IndexerVolumeGuid), and help/palette commit `6b7cc88`. Prior entries retain
  the detailed rewrite, launcher, debugging-source, palette, and test history.
  Added the explicit pre-commit memory-review/update requirement to `AGENTS.md`
  and current memory. In `BINED3.ASM`, F7 selects ASCII; Tab cycles HEX -> BIN
  -> ASCII -> HEX. ASCII retains the 16-byte hex layout and edits in the right
  column, highlights the selected character/EOF in purple, overwrites/appends
  printable 7-bit characters (including spaces), preserves case, and advances
  by one byte. Backspace navigates; controls/non-ASCII input are ignored.
  Expanded modal help from 58x19 to 58x21 for 17 instruction lines. Updated
  `README.md`, core DOS tests, release-EXE key driver, Python exact-byte
  verification, and tracked rebuilt editor/test artifacts under `BUILD`.
  Documented `Start-Process -Wait` for unattended DOSBox testing to avoid
  reading output before the GUI process finishes.
- **Verification:** Built and ran `TESTS\TEST.BAT` in bundled DOSBox with
  TASM/TLINK; core and release integration passed, and assembly was warning-
  and error-free. New core checks cover all 95 printable characters, spaces,
  mode selection/cycling, ignored input, dirty-state preservation, empty/EOF/
  full bounds, byte/row movement, ASCII Insert/Delete, cross-64-KiB overwrite,
  right-column cursor/selection, scrolled EOF, and expanded help. The dispatch
  stress test now checks 90,000 key events over 10,000 cycles with unchanged SP.
  Initial host byte verification exposed an extra Right-arrow in the test
  driver's ASCII sequence; corrected the driver and reran build/DOS/host tests.
  `python TESTS\VERIFY.PY` passed: unchanged 131,089-byte pattern round trip,
  empty save, final UI bytes `FF 7A 20 21 3F`, absent original UI save-as path,
  and clean staging directory. Authored source/documentation diff check passed;
  full diff check reports native generated whitespace in BUILD LST/MAP/log
  artifacts, as in earlier changesets.
- **Remaining:** None for this request. Existing DOSBox mounted-drive attribute
  reporting limitation remains. Reduced-memory and launcher automation results
  are historical and were not rerun for this changeset. No commit was requested.

## 2026-11-14 — ASCII editing in both HEX and BIN views

- **Request:** Allow ASCII editing in BIN as well as HEX, with the workflow
  HEX -> F7 -> ASCII -> Tab -> BIN -> F7 -> ASCII.
- **Changes:** Split numeric layout (`viewMode`) from editing focus (`editMode`)
  in `BINED3.ASM`. F7 preserves the current layout/viewport and selects ASCII;
  Tab switches to the opposite numeric view and digit/bit editing. F5/F6
  retain direct BIN/HEX selection. ASCII now keeps 16-byte HEX or six-byte BIN
  rows, the matching hex digits/binary bits, and a cursor/highlight/EOF at
  column 61 or 66. Titles distinguish `ASCII (HEX)` and `ASCII (BIN)`. Updated
  F1 help, README controls/workflow, `TESTS/CORE.INC`, `TESTS/KEYDRIVE.ASM`,
  `TESTS/VERIFY.PY`, project memory, and tracked rebuilt BUILD artifacts.
  Preserved the existing uncommitted ASCII-mode changeset and debugging files.
- **Verification:** Ran the documented waited DOSBox build and `TESTS\TEST.BAT`;
  core and release-EXE integration passed. `python TESTS\VERIFY.PY` confirmed
  error-/warning-free assembly, the 131,089-byte round trip and empty save,
  exact UI output `FF 7A 20 21 3F 20 48`, absent original UI path, and no
  staging leftovers. Added checks for BIN -> F7 layout/viewport retention,
  ASCII whole-byte overwrite/space/append in BIN, six-byte row/page navigation,
  Tab exit from either ASCII layout, preserved data/dirty state, eight-bit
  binary rendering, column-66 ASCII selection/EOF, and scrolled cursor bounds.
  Existing HEX-ASCII and 90,000-key-event stack checks also passed. Reviewed
  source/docs/test diffs and ran the authored-file whitespace check successfully.
- **Remaining:** None for this request. The previously documented DOSBox
  attribute-reporting limitation remains; reduced-memory/launcher automation
  checks were not rerun. No commit was requested.

## 2026-11-14 — Independent Tab view switching and F7 focus toggling

- **Request:** Use the exact sequence HEX -> F7 -> ASCII (HEX) -> Tab ->
  ASCII (BIN) -> Tab -> ASCII (HEX) -> F7 -> HEX -> Tab -> BIN -> Tab -> HEX.
- **Changes:** Updated `BINED3.ASM`: Tab changes HEX/BIN layout while preserving
  ASCII or numeric editing focus, and F7 toggles ASCII/numeric focus within
  the current layout. F7 entry/exit preserve the viewport and reset digitIndex;
  selecting an unchanged numeric layout also retains its viewport. F5/F6
  retain direct numeric mode selection. Updated F1 help, README, current project
  memory, core transition/viewport checks, and release integration key sequence;
  rebuilt tracked BUILD artifacts. The final UI byte expectation is unchanged.
  Preserved prior uncommitted work and debugging sources.
- **Verification:** Ran the documented waited DOSBox build and `TESTS\TEST.BAT`.
  Core tests and release-EXE integration passed, including the requested exact
  sequence, numeric/ASCII navigation widths, F7 return to binary bits, viewport
  retention on F7 entry/exit, unchanged data/dirty state, and the existing
  90,000-key-event stack check. `python TESTS\VERIFY.PY` passed: warning-/error-
  free builds, 131,089-byte round trip, empty save, exact UI bytes
  `FF 7A 20 21 3F 20 48`, absent original UI path, and no staging leftovers.
  Reviewed updated input/test/docs and passed the authored-file whitespace check.
- **Remaining:** None for this request. Existing DOSBox attribute-reporting
  limitation remains; reduced-memory and launcher automation checks were not
  rerun. No commit was requested.

## 2026-11-14 — Package ASCII editing for commit and push

- **Request:** Commit the implemented changes and push upstream.
- **Changes:** Prepared one Conventional Commit for ASCII whole-byte editing in
  HEX/BIN views, independent Tab layout switching and F7 focus toggling, modal
  help updates, core/release/host regression coverage, README, pre-commit memory
  instructions, current memory/history, and tracked rebuilt BUILD artifacts.
  Reviewed and updated both memory files before committing. The target is
  `master` -> `origin/master` in `ambrose40/BINED`. Separate local user edits to
  `LAUNCH.BAT` were inspected and preserved outside this feature commit.
- **Verification:** Reviewed worktree status, source/tests/docs/generated diffs,
  recent history, remote URL and branch tracking. Reran `python TESTS\VERIFY.PY`
  successfully: warning-free assembly logs, exact round-trip/empty/UI outputs,
  and staging cleanup. Authored-file whitespace check passed. Full generated
  listings/maps/logs retain the previously documented native DOS formatting.
  DOS runtime tests were not repeated for this packaging-only task; the final
  Tab/F7 changeset above records the passing core/release/90,000-event results.
- **Remaining:** Commit/push completion is reported in the final response.
  `LAUNCH.BAT` remains local user work; the known DOSBox attribute-reporting
  limitation is unchanged.
