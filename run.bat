@REM @echo off
@REM setlocal

@REM rem Project-local shortcut for Flutter Windows runs.
@REM rem It lets PowerShell users type:
@REM rem   run -d windows
@REM rem instead of:
@REM rem   G:\Flutter_SDK\flutter\bin\flutter.bat run -d windows

@REM set "FLUTTER_BAT=G:\Flutter_SDK\flutter\bin\flutter.bat"

@REM if not exist "%FLUTTER_BAT%" (
@REM   echo Flutter was not found at "%FLUTTER_BAT%".
@REM   echo Update run.bat if Flutter SDK was moved.
@REM   exit /b 1
@REM )

@REM call "%FLUTTER_BAT%" run %*


@echo off
setlocal

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found in PATH.
  echo Install Flutter and add flutter\bin to PATH, then restart the terminal.
  exit /b 1
)

flutter run %*