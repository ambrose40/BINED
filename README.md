# EZ Binary Editor 3

`BINED3.ASM` is a DOS hex/binary editor with ASCII-column and full-screen Text
editing, built with the supplied
TASM 2.5 and TLINK 4.0. The runnable output is **`BUILD\BINED3.EXE`**.

## Build, run, and test

### Using the launcher menu

Open PowerShell in the project directory and start the supplied DOSBox:

```powershell
.\DOSBOX\DOSBox.exe -conf dosbox_bined.conf
```

The configuration mounts the project as drive `C:` and opens `LAUNCH.BAT`.
Select an option:

| Option | Action |
| --- | --- |
| **1** | Build the editor and run it if the build succeeds |
| **2** | Build only; output is `BUILD\BINED3.EXE` |
| **3** | Run the existing build |
| **4** | Display build and test logs |
| **5** | Return to the DOS prompt |
| **6** | Build the editor, then build and run the DOS test suite |

Option **6** prints the test results and a final success/failure message.
Press a key after the results to return to the menu. Choose **4** to inspect
logs if a build or test fails. The DOS tests use the supplied assembler,
linker, and DOSBox; Python is needed only for the optional Windows-side
verification below.

### Build from the DOS prompt

Choose **5** in the menu, then run:

```dos
call BUILD.BAT
```

A successful build prints `Build succeeded: BUILD\BINED3.EXE`. Assembly and
linker logs are written to `BUILD\ASSEMBLE.LOG` and `BUILD\LINK.LOG`.

### Execute the editor

At the same DOS prompt, run one of:

```dos
BUILD\BINED3.EXE TEXT.COM
BUILD\BINED3.EXE NEW.BIN
BUILD\BINED3.EXE
BUILD\BINED3.EXE /?
```

The command line accepts one filename, optionally quoted. Paths are resolved
inside the DOSBox mounted drive. Use DOS-visible names (normally 8.3 names);
quoting does not add Windows long-filename support to DOSBox.

The editor loads an existing file automatically. A missing filename starts an
empty document which is created on save. With no argument it opens
`UNTITLED.BIN`, or starts that file empty if it does not exist. F4 chooses a
different save path. `LAUNCH.BAT filename` also passes that filename to the editor.

Use **Esc** to quit the editor. To reopen the launcher from the DOS prompt:

```dos
call LAUNCH.BAT
```

### Run tests

Choose **6** in the launcher to build and run the tests automatically. To do
the same from the DOS prompt, run these commands in order:

```dos
call BUILD.BAT
call TESTS\TEST.BAT
```

Run the second command after the build succeeds. The suite prints `PASS:`
results for the core tests and release-EXE integration test. Logs and generated
test files are under `BUILD`.

For an additional byte-for-byte check of the generated files, run this in
**Windows PowerShell**, from the project directory, after the DOS tests finish:

```powershell
python TESTS\VERIFY.PY
```

This optional step requires Python 3 and prints `PASS:` on success. See
[Regression checks](#regression-checks) for an unattended command and coverage
details.

**`dosbox_bined.conf`** selects the 486 CPU configuration and editor launcher.
`BUILD.BAT` and `LAUNCH.BAT` now target this editor.

## Controls

| Key | Action |
| --- | --- |
| `0`–`9`, `A`–`F` in hex mode | Overwrite one hex digit; lowercase also works |
| `0`, `1` in binary mode | Overwrite one bit, most significant bit first |
| Printable characters in ASCII mode | Overwrite one whole byte, including spaces; preserve case |
| Printable characters in Text mode | Insert characters at the cursor |
| Tab in HEX/BIN | Toggle numeric ↔ right-hand ASCII editing in the current view |
| Tab in Text | Insert one tab byte (`09h`), displayed at 8-column tab stops |
| F5 / F6 | Binary / hex view with digit/bit editing |
| F7 | Full-screen Text editor |
| Enter in Text | Insert a DOS CR/LF line break (`0Dh 0Ah`) |
| Left / Right | Previous / next hex digit, bit, or ASCII byte |
| Up / Down | Previous / next row |
| PgUp / PgDn | Previous / next screenful |
| Home / End | First / last digit, bit, or ASCII byte of the current row |
| Ctrl-Home / Ctrl-End | Start of file / EOF append position |
| Space | Next byte in HEX/BIN; type a space in ASCII |
| Backspace | Previous byte in HEX/BIN/ASCII; delete previous character/line break in Text |
| Insert | Insert a zero byte before the cursor |
| Delete | Remove the byte at the cursor; a CR/LF pair is deleted together in Text |
| F1 | Open the centred help window; any key returns |
| F2 | Save |
| F4 | Save as; Enter accepts, Esc cancels |
| Esc | Quit; modified files prompt for Save, Discard, or Esc to cancel |

The selected byte is highlighted. HEX view shows 16 bytes per row; BIN view
shows 6. **Tab** puts the editing cursor in the current view's right-hand ASCII
column and back, preserving its layout and viewport. The title shows
**ASCII (HEX)** or **ASCII (BIN)** while editing that column. **F5**, **F6**, and
**F7** directly select **BIN**, **HEX**, and **Text**, respectively.
Left/Right move one byte at a time in ASCII mode. Numeric/ASCII views show
printable ASCII characters (`20h`–`7Eh`); other bytes appear as dots.
Offsets, file size and buffer capacity are displayed in **hexadecimal**.

### Full-screen Text editing

**F7** uses the full 80-column editing area, without the offset/numeric gutters.
Text wraps at 80 display columns and scrolls through 20 rows. Typing printable
characters **inserts** them; **Enter** inserts CR/LF and **Tab** inserts a real
`09h` byte, expanded visually to the next 8-column tab stop. No spaces replace
tabs in the saved file. Existing CR/LF, bare CR, and bare LF all display as line
breaks without converting the file's bytes.

Left/Right move over characters, tabs, and complete CR/LF pairs. Up/Down and
PgUp/PgDn move by display rows, retaining the column where possible and clamping
on shorter rows; tabs have a single cursor position at their first cell.
Home/End select the current display-row start/end; Ctrl-Home/Ctrl-End select
file start/EOF. Backspace and Delete remove a whole CR/LF pair when joining
lines. Enter needs two free bytes and leaves the document untouched if only
one remains. Other unassigned control/non-ASCII input is ignored; non-printable
file bytes display as dots and can still be inspected or deleted. Insert keeps
its zero-byte insertion behavior. Use F5/F6 to edit any byte numerically.

The bottom-right **`HEX:`** and **`BIN:`** fields show the actual selected byte
(including `09h` or `0Dh` for a tab/line break). At EOF they show the latest
typed byte until another key is pressed; Enter's fallback value is `0Dh`.
Dashes indicate that no byte is selected. EOF is shown as `-`; the cursor on a
line break is a highlighted blank. Changing views does not convert the file.

The editor uses a **green-on-black** theme: bright-green hex/binary data and
status labels, dark-green row offsets, and purple selected-byte highlights in
the hex/binary data. The **filename and Save As input are also purple**.
The editor title is **bright white**,
the **OFFSET, DATA, and ASCII column labels are bright red**,
the active **HEX/BIN/ASCII/Text mode is bright yellow**, and the
right-hand **ASCII preview is light gray**. In ASCII mode the selected
character or EOF marker is purple; in HEX/BIN the entire preview stays gray.
Full-screen **Text characters are bright green** and the **current character
or EOF marker is purple**, matching numeric editing. A selected tab highlights
its first cell. The byte inspector has green labels and dark-purple values.
The numeric **Offset, Size, and Capacity values are dark purple**;
the **bottom status line and Save As/unsaved-quit prompts are light gray**.
F1 opens a centred, black-filled window
with a purple border, one help instruction per line, bright-yellow key names
contrasting with light-gray descriptions (including the EOF note), and an
any-key dismissal prompt with a yellow key label and dark-green description.
The editing cursor is hidden while help is open. All backgrounds stay
black. The `ATTR_*` constants near the top of `BINED3.ASM` define the palette
using standard VGA text attributes.

The `--` / `--------` entry marks EOF, with an additional `-` in the ASCII
editing column. Typing at EOF appends a byte. HEX/BIN start that byte at zero
and change its selected digit/bit; typing within the file preserves its other
bits. ASCII writes the typed character's complete byte and advances to the
next byte. ASCII accepts printable 7-bit characters, including spaces and
punctuation; Enter and other unassigned control/non-ASCII characters are
ignored in the right-hand ASCII column. Text mode additionally inserts CR/LF
and tabs; use numeric HEX/BIN for other control/high bytes. Insert/Delete change
file length; ordinary typing overwrites in numeric/right-column ASCII modes
and inserts in Text.
Delete at EOF is a no-op. There is no undo command.

## Memory and CPU design

The former tiny `.COM` layout has been replaced by a small-style `.EXE`
layout: separate **USE16 code, data, and 4 KiB stack segments**. TASM 2.5 uses
**`P486`**, its spelling of the `.486` CPU directive. The CPU directive and
memory model are separate choices: selecting a 486 alone does not provide a
flat address space or allocate memory.

This editor stays in real mode and needs no DOS extender. At startup it
shrinks the DOS-owned program block through the end of its stack, then uses
DOS `INT 21h/AH=48h` to allocate up to **512 KiB** for file bytes. If less
conventional memory is available, it allocates the largest available block.
The displayed capacity is the actual limit; an oversized file is rejected.
A file which exactly fills the buffer can be overwritten or shortened but
cannot grow until space is available.

Logical offsets and sizes use 32-bit registers/variables. `MapBuffer`
converts each logical offset to a normalized `FS:BX` pointer. DOS file
transfers are limited to 16 KiB per call and normalize the pointer for every
chunk, so neither a 64 KiB boundary nor a DOS 16-bit transfer count wraps.
DGROUP holds only editor state and paths, never the file contents.

### Procedure organization

- **Lifetime:** `Main`, `AllocateBuffer`, `Shutdown`.
- **Arguments and disk:** `ParseCommandLine`, `LoadFile`, `TransferFile`,
  `SaveDocument` and small handle/rename helpers.
- **Byte storage:** `MapBuffer`, `ReadByte`, `WriteByte`.
- **Editing/navigation:** `EditDigit`, `EditAscii`, `EditText`, `InsertByte`,
  `DeleteByte`, `DeleteText`, `SetMode`, movement procedures, `EnsureVisible`.
- **Text layout:** `NextTextRow`, `FindTextRow`, `TextColumn`,
  `TextOffsetAtColumn`, `TextLineOffset`, `TextVertical`, `EnsureTextVisible`.
- **Input:** `HandleKey` dispatches one BIOS key and returns.
- **Display:** `RenderScreen`, `RenderByte`, `RenderText`, `RenderTextValues`, bounded text/hex output,
  cursor placement and modal dialogs.

Only `Main` owns the editor event loop. Procedures return normally and use
balanced stack operations. There are no SP resets or recursive drawing loops.
Switching modes simply renders the same bytes differently; the display is
never parsed back into file data. The previous video mode/page and cursor
settings are restored on exit; previous screen contents are not retained.

### Saving and error handling

Saving first writes and closes a unique temporary file **in the target
directory**. Only after a complete transfer does the editor rename the old
file to a unique backup and install the new file. If installation fails it
attempts to restore the original. Successful saves remove the backup; failed
saves retain the modified flag. Read-only and directory targets are rejected
when DOS reports those attributes.

If a filesystem error prevents recovery, temporary/backup files may remain
beside the target, as indicated by the error message. These have DOS-generated
names. A save needs free disk space for a complete additional copy. This is
error-resistant staged replacement, not a guarantee against power loss
between DOS rename operations. Existing writable files receive a new
timestamp and normal attributes on replacement.

All opened handles are closed and the allocated memory is freed on exit.
Startup failures print an error and return DOS exit code 1; help and normal
exit return 0.

## What was wrong in the old versions?

`BINED.ASM` is the more complete historical implementation, but its control
flow cannot be made reliable just by changing the CPU directive:

- Render loops call themselves once per byte; input and render routines
  repeatedly enter more keyboard loops without unwinding their callers.
- `mov sp,0` discards live return addresses and saved registers to conceal
  that stack growth. Other branches manually pop registers belonging to
  different procedures or jump into their internals.
- File bytes are placed at hard-coded segment `9000h` without asking DOS to
  own that memory. State is also stored at fixed DS offsets which can overlap
  an expanding program. Insert/Delete address DS instead of the file segment.
- Screen characters serve as a second editable copy of the file. Re-reading
  them during mode changes, paging and saving can lose or alter data.
- File lengths/offsets are 16-bit, handles are leaked, and DOS errors and
  short reads/writes are mostly unchecked.

`BINED2.ASM` begins replacing magic addresses with variables and procedures,
but retains the nested event loops and unsafe memory layout. It also has
unfinished instructions (`mov ax,`), duplicate definitions/labels, misspelled
symbols (`hanlder5`, `hanlder7`), cross-procedure jumps and mismatched stack
operations. It is an unfinished refactor rather than a sounder base.

`BINED3.ASM` therefore rewrites the internals while retaining the useful
hex/binary workflow, including the historical F5/F6 mode keys.

## Regression checks

Choose **6: Build and run tests** in `LAUNCH.BAT`, or use the DOSBox prompt:

```dos
call BUILD.BAT
call TESTS\TEST.BAT
```

Or run the build and tests unattended from PowerShell:

```powershell
Start-Process -FilePath '.\DOSBOX\DOSBox.exe' -ArgumentList `
  '-conf dosbox_bined.conf -noautoexec -c "mount c ." -c "c:" -c "call BUILD.BAT" -c "call TESTS\TEST.BAT" -c "exit"' -Wait
python TESTS\VERIFY.PY
```

`-Wait` ensures the DOSBox GUI process finishes before host verification reads
the output files and logs.

The tests generate artifacts only under `BUILD`. The procedure-level test
EXE exercises command tails, EOF editing, ASCII focus in HEX and BIN views,
all 95 printable ASCII characters, space input, ignored controls, unchanged
overwrite dirty state, full/empty bounds, ASCII overwrite and insert/delete
across 64 KiB, navigation, 10,000 dispatch cycles
(90,000 key events) with unchanged SP, screen bounds/cursor rendering,
status colours, modal help layout/bounds and editor redraw, a
131,089-byte disk round trip, replacement saves, oversized loads and short
reads. It requires at least 131,089 bytes of available file-buffer memory.
Text checks additionally cover CR/LF insertion/deletion across 64 KiB, an exact
`A\r\nB` save/load, atomic Enter at capacity, mixed newline styles, 8-column
tabs and vertical navigation, full-width wrapping/EOF/empty-line scrolling,
text/selection colours, and selected/typed HEX/BIN values. A separate 1,000-cycle
Text insert/newline/backspace stress check preserves SP over 4,000 key events.

`KEYDRIVE.COM` separately runs the **release EXE** via DOS EXEC, supplying
BIOS keystrokes for help, numeric/right-column ASCII editing, F5/F6/F7 mode
selection, Tab focus toggling, full-screen Text with CR/LF/tab insertion,
Backspace/Delete, navigation, save-as and save-and-quit. The final UI output is
`b"\xffz !? H\r\nText\r\n\tOK"`. `TEXT.BIN` independently round-trips
`b"A\r\nB"` through production save/load procedures.
`VERIFY.PY` independently checks the exact output bytes and
absence of leftover staging files. No test code is included in the release
editor.

Logs are `BUILD\ASSEMBLE.LOG`, `LINK.LOG`, `TESTASM.LOG`, `TESTLINK.LOG`,
`TEST.LOG`, `KEYASM.LOG`, `KEYLINK.LOG`, `UI.LOG`, `HELP.LOG`, `ARGS.LOG` and
`OPENERR.LOG`. The batch files set
`BINED_BUILT` / `BINED_TESTED` to `1` on success.

Additional checks were run with DOSBox `LOADFIX`: the core suite passes with
256 KiB reserved, exercising allocation below the 512 KiB maximum. With
500 KiB reserved, the release editor rejects the 131,089-byte test file with
the expected capacity error (`BUILD\LOWMEM.LOG` and `BUILD\LARGE.LOG`).

The bundled DOSBox 0.74-2 mounted drive accepts read-only attribute changes
without reporting the attribute back. The test suite reports that limitation
and exercises the directory-protection branch instead. On a DOS filesystem
which implements read-only attributes it also checks the read-only branch.

### Preserved launcher-debugging sources

The intermediate debugging sources have been restored under `BUILD`:

- **`BUILD\MENUKEY.ASM`**: the working resident BIOS-key feeder used to select
  menu option 6, dismiss the results, then select option 5 automatically.
- **`BUILD\MENUEXEC.ASM`**: the earlier child-`COMMAND.COM`/DOS EXEC experiment,
  preserved for reference. The working menu check uses `MENUKEY.ASM`.
- **`BUILD\MENU.IN`**: the input file from the earlier stdin-redirection
  experiment. The successful check feeds BIOS keys instead.

These are preserved source/reference files, so retain them when cleaning
generated files from `BUILD`. The normal build/test scripts leave them there.

To reproduce the working launcher check, open a **fresh DOSBox session**,
choose **5** for its DOS prompt, then run:

```dos
TASM\TASM.EXE BUILD\MENUKEY.ASM,BUILD\
TASM\TLINK.EXE /t BUILD\MENUKEY.OBJ,BUILD\MENUKEY.COM
set BINED_TESTED=0
BUILD\MENUKEY.COM
call LAUNCH.BAT
if "%BINED_TESTED%"=="1" echo PASS: launcher option 6
exit
```

`MENUKEY.COM` installs a resident `INT 16h` handler for this automated check;
ending that DOSBox session releases it. Assembly/link commands for the older
experiment are also included in the header of `BUILD\MENUEXEC.ASM`.
