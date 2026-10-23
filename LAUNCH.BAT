@echo off
rem Run from the project directory. CHOICE is built into DOSBox.
:menu
cls
echo EZ Binary Editor 3
echo ==================
echo.
echo 1. Build and run
echo 2. Build only
echo 3. Run existing build
echo 4. View build and test logs
echo 5. Return to DOS prompt
echo 6. Build and run tests
echo.
choice /c123456 /n Select [1-6]:
rem Test ERRORLEVEL in descending order: IF means greater than or equal.
if errorlevel 6 goto tests
if errorlevel 5 goto end
if errorlevel 4 goto logs
if errorlevel 3 goto run
if errorlevel 2 goto build
if errorlevel 1 goto buildrun
goto menu

:buildrun
call BUILD.BAT
if "%BINED_BUILT%"=="1" goto run
pause
goto menu

:build
call BUILD.BAT
pause
goto menu

:tests
call BUILD.BAT
if not "%BINED_BUILT%"=="1" goto testbuildfailed
call TESTS\TEST.BAT
if not "%BINED_TESTED%"=="1" goto testfailed
echo.
echo All DOS tests passed.
echo Optional byte-for-byte verification from Windows: python TESTS\VERIFY.PY
pause
goto menu

:testbuildfailed
echo Tests were not run because the editor build failed. Choose 4 for logs.
pause
goto menu

:testfailed
echo Tests failed. Choose 4 to view build and test logs.
pause
goto menu

:run
if not exist BUILD\BINED3.EXE goto missing
echo.
echo Opening UNTITLED.BIN, or the filename passed to LAUNCH.BAT.
echo To open another file, choose 5 and use:
echo Usage: BUILD\BINED3.EXE filename
echo        BUILD\BINED3.EXE "path with spaces"
echo.
BUILD\BINED3.EXE %1
goto menu

:missing
echo No BUILD\BINED3.EXE found. Choose 1 or 2 to build first.
pause
goto menu

:logs
echo.
echo --- Assembler ---
if exist BUILD\ASSEMBLE.LOG type BUILD\ASSEMBLE.LOG
if not exist BUILD\ASSEMBLE.LOG echo No assembler log. Build the editor first.
echo.
echo --- Linker ---
if exist BUILD\LINK.LOG type BUILD\LINK.LOG
if not exist BUILD\LINK.LOG echo No linker log. Build the editor first.
echo.
echo --- Test assembler ---
if exist BUILD\TESTASM.LOG type BUILD\TESTASM.LOG
echo.
echo --- Test linker ---
if exist BUILD\TESTLINK.LOG type BUILD\TESTLINK.LOG
echo.
echo --- Core tests ---
if exist BUILD\TEST.LOG type BUILD\TEST.LOG
if not exist BUILD\TEST.LOG echo No core test log. Choose 6 to build and run tests.
echo.
echo --- Integration driver assembler ---
if exist BUILD\KEYASM.LOG type BUILD\KEYASM.LOG
echo.
echo --- Integration driver linker ---
if exist BUILD\KEYLINK.LOG type BUILD\KEYLINK.LOG
echo.
echo --- Release EXE integration tests ---
if exist BUILD\UI.LOG type BUILD\UI.LOG
echo.
echo --- Command-line help ---
if exist BUILD\HELP.LOG type BUILD\HELP.LOG
echo.
echo --- Invalid-argument check ---
if exist BUILD\ARGS.LOG type BUILD\ARGS.LOG
echo.
echo --- Load-error check ---
if exist BUILD\OPENERR.LOG type BUILD\OPENERR.LOG
echo.
pause
goto menu

:end
