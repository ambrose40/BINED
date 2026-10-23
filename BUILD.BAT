@echo off
rem Run inside DOS/DOSBox from the repository root.
set BINED_BUILT=0
if not exist BUILD\NUL mkdir BUILD
TASM\TASM.EXE /m2 /l BINED3.ASM,BUILD\,BUILD\ > BUILD\ASSEMBLE.LOG
if errorlevel 1 goto failed
TASM\TLINK.EXE /m BUILD\BINED3.OBJ,BUILD\BINED3.EXE,BUILD\BINED3.MAP > BUILD\LINK.LOG
if errorlevel 1 goto failed
echo Build succeeded: BUILD\BINED3.EXE
set BINED_BUILT=1
goto end
:failed
echo Build failed. See BUILD\ASSEMBLE.LOG and BUILD\LINK.LOG.
:end
