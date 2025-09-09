@echo off 
if "%1"=="activate-and-paste-bundle" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0keyboard-simulator.ps1" -command "%1" -bundleId "%~2"
) else if "%1"=="activate-and-paste-name" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0keyboard-simulator.ps1" -command "%1" -appName "%~2"
) else if "%1"=="activate-bundle" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0keyboard-simulator.ps1" -command "%1" -bundleId "%~2"
) else if "%1"=="activate-name" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0keyboard-simulator.ps1" -command "%1" -appName "%~2"
) else (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0keyboard-simulator.ps1" -command "%1"
)
