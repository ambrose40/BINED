@echo off
rem Run inside DOSBox, from the project root.
set BINED_TESTED=0
if not exist BUILD\NUL mkdir BUILD
if not exist BUILD\TESTDATA\NUL mkdir BUILD\TESTDATA
if exist BUILD\TESTDATA\UI.BIN del BUILD\TESTDATA\UI.BIN
if exist BUILD\TESTDATA\UI2.BIN del BUILD\TESTDATA\UI2.BIN
TASM\TASM.EXE /m2 TESTS\TEST3.ASM,BUILD\ > BUILD\TESTASM.LOG
if errorlevel 1 goto failed
TASM\TLINK.EXE /m BUILD\TEST3.OBJ,BUILD\TEST3.EXE,BUILD\TEST3.MAP > BUILD\TESTLINK.LOG
if errorlevel 1 goto failed
BUILD\TEST3.EXE > BUILD\TEST.LOG
if errorlevel 1 goto failed
TASM\TASM.EXE TESTS\KEYDRIVE.ASM,BUILD\ > BUILD\KEYASM.LOG
if errorlevel 1 goto failed
TASM\TLINK.EXE /t BUILD\KEYDRIVE.OBJ,BUILD\KEYDRIVE.COM > BUILD\KEYLINK.LOG
if errorlevel 1 goto failed
BUILD\KEYDRIVE.COM > BUILD\UI.LOG
if errorlevel 1 goto failed
BUILD\BINED3.EXE /? > BUILD\HELP.LOG
if errorlevel 1 goto failed
BUILD\BINED3.EXE first second > BUILD\ARGS.LOG
if not errorlevel 1 goto failed
BUILD\BINED3.EXE BUILD\NO_SUCH\BAD.BIN > BUILD\OPENERR.LOG
if not errorlevel 1 goto failed
set BINED_TESTED=1
type BUILD\TEST.LOG
type BUILD\UI.LOG
goto end
:failed
echo Tests failed. See BUILD\TEST*.LOG, KEY*.LOG and UI.LOG.
:end
