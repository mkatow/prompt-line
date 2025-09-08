@echo off
REM Windows Native Tools Build Script
REM Equivalent to the macOS Makefile

echo Building Windows native tools...

REM Create output directory
set OUTPUT_DIR=..\src\native-tools-win
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Copy PowerShell scripts to output directory
echo Copying PowerShell scripts...
copy "window-detector.ps1" "%OUTPUT_DIR%\window-detector.ps1"
copy "keyboard-simulator.ps1" "%OUTPUT_DIR%\keyboard-simulator.ps1" 
copy "text-field-detector.ps1" "%OUTPUT_DIR%\text-field-detector.ps1"

REM Create wrapper batch files for easier execution
echo Creating wrapper scripts...

REM Window detector wrapper
echo @echo off > "%OUTPUT_DIR%\window-detector.bat"
echo powershell.exe -ExecutionPolicy Bypass -File "%%~dp0window-detector.ps1" %%* >> "%OUTPUT_DIR%\window-detector.bat"

REM Keyboard simulator wrapper  
echo @echo off > "%OUTPUT_DIR%\keyboard-simulator.bat"
echo powershell.exe -ExecutionPolicy Bypass -File "%%~dp0keyboard-simulator.ps1" %%* >> "%OUTPUT_DIR%\keyboard-simulator.bat"

REM Text field detector wrapper
echo @echo off > "%OUTPUT_DIR%\text-field-detector.bat"
echo powershell.exe -ExecutionPolicy Bypass -File "%%~dp0text-field-detector.ps1" %%* >> "%OUTPUT_DIR%\text-field-detector.bat"

echo Windows native tools build complete!
echo Output directory: %OUTPUT_DIR%
echo.
echo Available tools:
echo   window-detector.bat - Window and app detection
echo   keyboard-simulator.bat - Keyboard automation and app activation
echo   text-field-detector.bat - Text field detection
echo.
echo Test the tools:
echo   "%OUTPUT_DIR%\window-detector.bat" current-app
echo   "%OUTPUT_DIR%\keyboard-simulator.bat" paste
echo   "%OUTPUT_DIR%\text-field-detector.bat" get-focused-text-field