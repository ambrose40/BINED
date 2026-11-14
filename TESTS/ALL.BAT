@echo off
rem One gated workflow for DOSBox and the host runner.
call BUILD.BAT
if not "%BINED_BUILT%"=="1" goto end
call TESTS\TEST.BAT
:end
