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

## 2026-11-14 — Commit the user's launcher display edits

- **Request:** Commit the user's `LAUNCH.BAT` edits with a corresponding message.
- **Changes:** Preserved the user's edits exactly: four DOS invocation examples
  below the menu and additional `echo .` dot separators in action/error/exit
  paths. Prepared `feat(launcher): show usage examples and output separators`.
  Updated both memory files before committing, including confirmation that the
  preceding ASCII feature commit `db6147e` was pushed to `origin/master`.
- **Verification:** Reviewed status, full launcher source/diff, and recent
  history. Launcher whitespace check passed. No DOS runtime tests were rerun
  for this commit-only display update; earlier editor test results are recorded
  above and are not current launcher runtime verification.
- **Remaining:** No runtime issue identified in the reviewed display-only diff.
  This request authorizes a local commit; pushing was not requested.

## 2026-11-14 — Full-screen Text editing with CR/LF, tabs and byte inspector

- **Request:** Add full-screen ASCII/Text editing with carriage returns, matching
  green/purple data/selection colours, bottom-right HEX:/BIN: values, help and
  tests. During implementation the user clarified the final controls: F5 BIN,
  F6 HEX, F7 Text; Tab toggles numeric/right-column ASCII in HEX/BIN and inserts
  a tabulation character in Text. This supersedes the initial Tab-view-cycle
  proposal and the previous F7 ASCII-focus binding.
- **Changes:** Extended `BINED3.ASM` with Text view/edit state, an 80-column by
  20-row editing area, green characters/purple current byte, insertion typing,
  atomic DOS CR/LF insertion, actual `09h` tabs with 8-column stops, CR/LF-aware
  Left/Right and Backspace/Delete, display-row Home/End/Up/Down/page navigation,
  wrapping/scrolling, and preserved raw file bytes. Shared bounded row/column
  mapping keeps display and navigation consistent; EOF/line-break/tab cursor
  positions stay within the text screen. Added the bottom-right byte inspector
  for selected bytes or the latest typed byte at EOF, with dashes otherwise.
  Updated F1 help and README, expanded `TESTS/CORE.INC` and release key driver,
  updated `TESTS/VERIFY.PY`, generated `BUILD/TESTDATA/TEXT.BIN`, and rebuilt
  tracked editor/test artifacts. Updated memory for final controls and recorded
  the already-completed local launcher commit `31cf0c4`.
- **Verification:** Ran the waited DOSBox production build and `TESTS\TEST.BAT`.
  Core and release integration passed with error-/warning-free TASM builds.
  New checks cover insert/overwrite distinctions, CR/LF/tab exact bytes,
  CR/LF-pair deletion, atomic Enter with one free byte, full/empty/ignored-input
  bounds, mixed newline styles, 8-column tab navigation/expansion, cross-64-KiB
  Text insertion/deletion and cursor bounds, wrapping/EOF/empty-line scrolling,
  green/purple text/tab selection, selected/typed HEX/BIN values, and 1,000 Text
  stress cycles (4,000 events) with unchanged SP. Existing 90,000-event dispatch
  and I/O checks also passed. Regression runs exposed a short-final-row EOF
  mapping bug, which was fixed, and a fixture viewport setup issue, which was
  corrected before the successful final run. Python independently verified the
  131,089-byte pattern round trip, empty save, `TEXT.BIN` = `b"A\r\nB"`,
  `UI2.BIN` = `b"\xffz !? H\r\nText\r\n\tOK"`, absent original UI path,
  clean staging directory, and warning-free logs. Authored-file diff check passed.
- **Remaining:** None for this request. Existing DOSBox attribute-reporting
  limitation remains. Reduced-memory and launcher automation checks were not
  rerun for this changeset. No commit or push was requested.

## 2026-11-14 — Package full-screen Text editing for commit and push

- **Request:** Commit the implemented Text-mode changes and push upstream.
- **Changes:** Prepared `feat(editor): add full-screen text editing and byte
  inspector` with the complete Text insertion/navigation/rendering feature,
  CR/LF/tab behavior, corrected F5/F6/F7/Tab controls, updated F1 help/README,
  core/release/host tests, tracked rebuilt BUILD artifacts, and the new
  `BUILD/TESTDATA/TEXT.BIN` regression fixture. Reviewed and updated both project
  memory files before committing. Packaging starts at `31cf0c4` on `master`,
  tracking `origin/master` in `ambrose40/BINED`.
- **Verification:** Reviewed status, source/test/docs/log/map diffs, relevant
  listing entries, recent history, and branch/remote tracking. Reran
  `python TESTS\VERIFY.PY`: exact 131,089-byte pattern round trip, empty save,
  CR/LF Text output, CR/LF/tab integration output, staging cleanup and warning-
  free build logs all passed. Authored-file whitespace check passed. Native
  DOS-generated whitespace in listings/maps/logs is preserved as documented.
  DOS runtime tests were not repeated for this commit-only packaging step;
  passing core/release and 94,000-event stress results are recorded above.
- **Remaining:** Commit/push completion is reported in the final response.
  Existing DOSBox attribute-reporting limitation remains unchanged.

## 2026-11-14 — Improvement 1: exact-width Text boundaries

- **Request:** Implement the first of four improvement steps, update memory,
  and make a corresponding commit before proceeding to the next step.
- **Changes:** `BINED3.ASM` now absorbs newlines immediately following 80 display
  columns, exposes parsed row width/kind, keeps End on a full row at EOF or
  before a newline, and bounds newline cursors/rendering to column 79 with a
  purple `<` marker. Added `TESTS/BOUNDS.INC` with a width/newline matrix and
  exact-width tabs; extended core video assertions and README. Rebuilt tracked
  BUILD artifacts; updated both project memory files before committing.
- **Verification:** Bundled DOSBox production/core/release tests passed with
  warning-/error-free TASM; Python exact-byte/log verification passed; authored
  source/docs whitespace check passed. An initial TASM case-insensitive constant/
  label collision was corrected before the successful run.
- **Remaining:** Steps 2 (fresh builds/save failures), 3 (Text layout cache),
  and 4 (navigation/viewport/status polish) follow as separate commits.

## 2026-11-14 — Improvement 2: fresh builds and save-failure regression

- **Request:** Complete the second improvement step and commit it separately
  after verification and memory updates.
- **Changes:** Added RUN.PY and gated ALL.BAT; build/test completion markers,
  linker-result checks, and source/output SHA-256 provenance prevent stale
  releases being mistaken for fresh results. Added five isolated HOSTTEST
  rejection cases and narrow local-output ignores. Added SAVEFAIL.INC DOS
  interception for failed/short writes, close failure, install failure with
  rollback, and restore failure with retained recovery bytes. Release DISK_INT
  expands directly to INT 21h. Updated README, both memory files and rebuilt
  tracked artifacts; preserved all debugging sources.
- **Verification:** `python TESTS/RUN.PY` rebuilt production/core/release with
  warning-/error-free TASM, passed DOS save faults and existing regressions,
  checked exact bytes/logs and fresh hashes. `python TESTS/HOSTTEST.PY` passed
  all five negative cases. Authored-file whitespace check passed.
- **Remaining:** Steps 3 and 4 follow. No push was requested.

## 2026-11-14 — Improvement 3: bounded Text layout checkpoints

- **Request:** Cache Text layout for responsiveness, verify, update memory and
  commit as the third independent improvement step.
- **Changes:** Added a 128-entry row/offset checkpoint ring, nearest-anchor
  lookups, periodic/recent checkpoints and lazy edit invalidation in BINED3.ASM.
  Byte writes, tail deletion, load and unmarked size changes invalidate safely;
  existing DOS-owned bytes remain authoritative. Added CACHE.INC correctness/
  scan-work regressions, README/memory updates and rebuilt tracked artifacts.
- **Verification:** RUN.PY fresh production/core/release tests, exact bytes/logs/
  manifest checks, five HOSTTEST cases and authored whitespace check passed.
  Cached results matched uncached scans after mutations; 32 warm large-file
  viewport updates required at most 96 row parses. External DOSBox audit now
  places exact-width End at 79 and following text on row 1; both small/large
  warm timing batches were below one BIOS tick (old large batch: 39 ticks).
  An initial TLINK 4 rejection of 32-bit indexed relocations was corrected by
  using explicitly 16-bit DGROUP indexing before successful verification.
- **Remaining:** Step 4 follows. No push was requested.

## 2026-11-14 — Improvement 4: navigation, viewport and status polish

- **Request:** Finish the fourth improvement step, verify, update memory and
  make its own corresponding commit.
- **Changes:** Text vertical/page movement remembers a preferred column across
  short rows and resets it on other input/edit/mode changes. Reselecting Text
  with F7 preserves its viewport. Added hexadecimal one-based Ln/Col and INS
  status, a bounded Text footer and a full save-error modal with DOS code and
  wrapped target/backup/staging paths. SaveDocument retains accurate error
  codes through rollback and updates staging flags after cleanup. Added
  POLISH.INC, strengthened save-fault assertions and release failed-Save-As
  dismissal coverage; updated README/current memory and rebuilt artifacts.
- **Verification:** RUN.PY fresh production/core/release tests, byte/log/hash
  checks, five HOSTTEST cases and authored-file whitespace check passed.
  Core checked sticky/reset columns, viewport retention, status colours/values,
  inspector reservation, complete error text, long recovery paths and bounds.
  Release integration dismissed a real failed Save As before successful save-
  and-quit. The external DOSBox audit reports offset 23 after two Down moves
  through a short row, retained viewOffset 320 on F7, fixed exact-width rows,
  and both warm performance batches below one BIOS tick.
- **Remaining:** All four requested implementation steps are complete, each
  memory-updated and committed separately. No push was requested.

## 2026-11-14 — F8 Go to offset

- **Request:** Add higher-level Go to offset convenience on F8.
- **Changes:** Added a bottom-row Go to offset dialog in `BINED3.ASM`, strict
  1..8-digit absolute hexadecimal parsing, current/EOF values, Backspace/Esc,
  inline input/range errors, EOF/zero acceptance, and scrolling while preserving
  mode/focus. Accepted jumps reset digit and preferred-column state; Text uses
  its existing shared CR/LF cursor behavior. Added GOTO.INC parser/input/mode/
  bounds/colour tests and actual F8 release keystrokes, updated F1 help, README,
  both memory files and rebuilt tracked artifacts. Initial BUILD/BINED3.LST
  differences were inspected as timestamp-only before rebuilding.
- **Verification:** `python TESTS/RUN.PY` passed fresh warning-/error-free DOS
  production/core/release builds, exact outputs, staging cleanup and hashes.
  `python TESTS/HOSTTEST.PY` passed all five negative cases. New core checks
  include FFFFFFFF, nine-digit/empty/invalid input, correction/cancellation,
  empty-file/EOF/cross-64-KiB destinations, unchanged data/dirty state and mode,
  cursor visibility, CR/LF normalization, prompt colours and SP. Release
  integration exercised F8 in all views/foci and preserved a cancelled low
  nibble. Authored source/documentation whitespace check passed.
- **Remaining:** None for this request. Existing DOSBox attribute-reporting
  limitation remains. No commit or push was requested for this feature.

## 2026-11-14 — Commit F8 and publish the improvement series

- **Request:** Commit implemented changes and push upstream.
- **Changes:** Prepared `feat(editor): add F8 go-to-offset navigation` with F8
  implementation, F1 help/README, core/release/GOTO.INC tests, both updated
  memory files and tracked rebuilt BUILD artifacts. The push also publishes
  the four existing local commits: `4265b58` exact-width rows, `5559de6` fresh
  builds/save failures, `0c52671` Text layout cache, and `5fb98de` UI polish.
  Reviewed and updated both memory files before committing.
- **Verification:** Reviewed status/diffs, new regression source, generated
  maps/logs/listing entries, recent and outgoing commit history, branch tracking
  and remote URL. `python TESTS/VERIFY.PY --fresh` passed source/output hashes,
  exact bytes, staging cleanup and build logs; `python TESTS/HOSTTEST.PY` passed
  all five negative cases. Authored source/docs whitespace check passed. DOS
  runtime tests were not repeated for this packaging-only task; the preceding
  F8 entry records the passing fresh production/core/release run.
- **Remaining:** Commit/push completion is reported in the final response.
  The known DOSBox mounted-drive attribute-reporting limitation is unchanged.
