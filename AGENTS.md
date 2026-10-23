# Project instructions for coding agents

## Persistent project memory

- Before changing this project, read `.agents/PROJECT.md` and the recent
  entries in `.agents/CHANGELOG.md`. Confirm relevant details against the
  current source; memory records context, not a substitute for inspection.
- **After every changeset**, update `.agents/PROJECT.md` for any changed
  behavior, architecture, commands, constraints, or user preferences, and
  append an entry to `.agents/CHANGELOG.md`.
- A changeset means one completed logical task, whether or not it is committed.
  Update the memory before the final response, including documentation-only
  changes. Do not create commits merely to satisfy this requirement.
- Each changelog entry must state the request, files/behavior changed,
  verification actually performed, and any remaining issue. Distinguish
  previous test results from tests run for the current changeset.

## Working conventions

- Active editor: `BINED3.ASM`; output: `BUILD\BINED3.EXE`.
- Maintain compatibility with bundled TASM 2.5, TLINK 4.0, and DOSBox 0.74-2.
- Keep real-mode segments explicitly `USE16`, the 486 instruction selection
  (`P486`), DOS-owned file memory, and a single balanced editor event loop.
- Preserve the requested green-on-black palette with dark-green secondary
  text and purple selection highlights.
- **Retain debugging source code**, including `.ASM` files under `BUILD`.
  That directory is not entirely disposable. Keep `BUILD\MENUKEY.ASM`,
  `BUILD\MENUEXEC.ASM`, and `BUILD\MENU.IN` unless the user requests removal.
- Inspect existing changes before editing; preserve user files and unrelated
  changes. Historical-file deletions may already be present in the worktree.
- Keep `README.md` build/run/test instructions accurate when workflows change.
- For editor changes, build and run the relevant DOS tests and Windows-side
  byte verification described in `.agents/PROJECT.md`. For documentation-only
  changes, review the documentation and run a whitespace/diff check.
