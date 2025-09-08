# Windows Native Tools

This directory contains Windows-specific native tools for Prompt Line, implemented in PowerShell as equivalents to the macOS Swift tools.

## Files

- `window-detector.ps1` - Window bounds and application detection
- `keyboard-simulator.ps1` - Keyboard automation and application activation
- `text-field-detector.ps1` - Focused text field detection
- `compile.bat` - Build script that copies tools and creates wrappers

## Building

Run the build script:
```cmd
compile.bat
```

This creates the output directory `../src/native-tools-win/` with:
- PowerShell scripts
- Batch wrapper files for easier execution
- Pre-configured execution policy bypass

## Usage

### Window Detection
```cmd
# Get current application info
native-tools-win\window-detector.bat current-app

# Get active window bounds
native-tools-win\window-detector.bat window-bounds
```

### Keyboard Automation
```cmd
# Send Ctrl+V to current application
native-tools-win\keyboard-simulator.bat paste

# Activate application by name then paste
native-tools-win\keyboard-simulator.bat activate-and-paste-name "notepad"

# Activate application by path then paste
native-tools-win\keyboard-simulator.bat activate-and-paste-bundle "C:\Windows\notepad.exe"
```

### Text Field Detection
```cmd
# Get focused text field bounds
native-tools-win\text-field-detector.bat get-focused-text-field
```

## Output Format

All tools return JSON format matching the macOS Swift tools:

```json
{
  "success": true,
  "name": "notepad",
  "bundleId": "C:\\Windows\\notepad.exe"
}
```

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- UI Automation support (for text field detection)

## Security

The batch wrappers use `-ExecutionPolicy Bypass` to avoid PowerShell execution policy restrictions while maintaining security through:
- Local file execution only
- No network access
- Sandboxed PowerShell environment
- JSON-only output format