@echo off
setlocal

rem Project-local shortcut for Flutter Windows runs.
rem It lets PowerShell users type:
rem   run -d windows
rem instead of:
rem   G:\Flutter_SDK\flutter\bin\flutter.bat run -d windows

set "FLUTTER_BAT=G:\Flutter_SDK\flutter\bin\flutter.bat"

if not exist "%FLUTTER_BAT%" (
  echo Flutter was not found at "%FLUTTER_BAT%".
  echo Update run.bat if Flutter SDK was moved.
  exit /b 1
)

call "%FLUTTER_BAT%" run %*
