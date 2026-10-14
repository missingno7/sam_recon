@echo off
rem Turbo Pascal 5.0, TASM 1.0, LZEXE 0.91; tools on PATH.
if "%1"=="1" goto build
if "%1"=="2" goto build
if "%1"=="3" goto build
echo Usage: BUILD 1 or BUILD 2 or BUILD 3
goto end
:build
tasm /DSAM%1 CMOSPIT.ASM,CMOSPIT.OBJ,;
if errorlevel 1 goto fail
tasm /DSAM%1 TEXTOUT.ASM,TEXTOUT.OBJ,;
if errorlevel 1 goto fail
tasm /DSAM%1 GENUS.ASM,GENUS.OBJ,;
if errorlevel 1 goto fail
tasm /DSAM%1 JOYSTICK.ASM,JOYSTICK.OBJ,;
if errorlevel 1 goto fail
tasm /DSAM%1 DECODE.ASM,DECODE.OBJ,;
if errorlevel 1 goto fail
tasm /DSAM%1 PROGRAPX.ASM,PROGRAPX.OBJ,;
if errorlevel 1 goto fail
if exist SAMPLAY.TPU del SAMPLAY.TPU
if exist SAMLEVEL.TPU del SAMLEVEL.TPU
if exist SAMUI.TPU del SAMUI.TPU
if exist TEXT80.TPU del TEXT80.TPU
if exist PCXGENUS.TPU del PCXGENUS.TPU
if exist GAMEJOY.TPU del GAMEJOY.TPU
if exist SAMSOUND.TPU del SAMSOUND.TPU
if exist SAMDATA.TPU del SAMDATA.TPU
if exist PROGRPHX.TPU del PROGRPHX.TPU
tpc /M /GD /DSAM%1 /$S- /$I- /$R- /$B- SAM.PAS
if errorlevel 1 goto fail
copy SAM.EXE SAM%1.EXE > NUL
if errorlevel 1 goto fail
lzexe SAM%1.EXE
if errorlevel 1 goto fail
goto end
:fail
echo Build failed; see compiler or assembler output.
:end
