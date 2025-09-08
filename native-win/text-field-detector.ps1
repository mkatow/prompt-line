# Windows Text Field Detection Tool
# PowerShell equivalent of macOS text-field-detector.swift

param([string]$command = "")

# Add UI Automation types for text field detection
Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class Win32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetFocus();
        
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
        
        [DllImport("user32.dll")]
        public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);
        
        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern int GetClassName(IntPtr hWnd, System.Text.StringBuilder lpClassName, int nMaxCount);
        
        [StructLayout(LayoutKind.Sequential)]
        public struct RECT {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }
        
        public const uint GW_CHILD = 5;
        public const uint GW_HWNDNEXT = 2;
    }
"@

# Load UI Automation assemblies
try {
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    $uiAutomationAvailable = $true
} catch {
    $uiAutomationAvailable = $false
}

function Get-FocusedTextField {
    try {
        if (-not $uiAutomationAvailable) {
            return @{ error = "UI Automation not available" } | ConvertTo-Json -Compress
        }
        
        # Get the currently focused element using UI Automation
        $focusedElement = [System.Windows.Automation.AutomationElement]::FocusedElement
        
        if (-not $focusedElement) {
            return @{ error = "No focused element found" } | ConvertTo-Json -Compress
        }
        
        # Check if the focused element is a text input control
        $controlType = $focusedElement.Current.ControlType
        $isTextControl = $false
        
        # Check for various text input control types
        if ($controlType -eq [System.Windows.Automation.ControlType]::Edit -or
            $controlType -eq [System.Windows.Automation.ControlType]::Document -or
            $controlType -eq [System.Windows.Automation.ControlType]::Text) {
            $isTextControl = $true
        }
        
        # Also check if it supports TextPattern (indicates text input capability)
        try {
            $textPattern = $focusedElement.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern)
            if ($textPattern) {
                $isTextControl = $true
            }
        } catch {
            # Element doesn't support TextPattern, continue with other checks
        }
        
        if (-not $isTextControl) {
            return @{ error = "Focused element is not a text input control" } | ConvertTo-Json -Compress
        }
        
        # Get the bounding rectangle of the focused text field
        $boundingRect = $focusedElement.Current.BoundingRectangle
        
        if ($boundingRect.IsEmpty) {
            return @{ error = "Could not get bounds of text field" } | ConvertTo-Json -Compress
        }
        
        $result = @{
            x = [int]$boundingRect.X
            y = [int]$boundingRect.Y
            width = [int]$boundingRect.Width
            height = [int]$boundingRect.Height
            controlType = $controlType.ToString()
            name = $focusedElement.Current.Name
        }
        
        return $result | ConvertTo-Json -Compress
        
    } catch {
        return @{ error = "Exception: $($_.Exception.Message)" } | ConvertTo-Json -Compress
    }
}

function Get-FocusedTextFieldFallback {
    # Fallback method using basic Windows API
    try {
        $focusedWindow = [Win32]::GetFocus()
        
        if ($focusedWindow -eq [IntPtr]::Zero) {
            $foregroundWindow = [Win32]::GetForegroundWindow()
            if ($foregroundWindow -eq [IntPtr]::Zero) {
                return @{ error = "No focused window found" } | ConvertTo-Json -Compress
            }
            $focusedWindow = $foregroundWindow
        }
        
        # Get window class name to identify text controls
        $className = New-Object System.Text.StringBuilder 256
        [Win32]::GetClassName($focusedWindow, $className, 256) | Out-Null
        $classNameStr = $className.ToString()
        
        # Common Windows text control class names
        $textControlClasses = @("Edit", "RichEdit", "RichEdit20A", "RichEdit20W", "RichEdit50W", "RICHEDIT_CLASS")
        $isTextControl = $textControlClasses -contains $classNameStr
        
        if (-not $isTextControl) {
            return @{ error = "Focused window is not a recognized text control (class: $classNameStr)" } | ConvertTo-Json -Compress
        }
        
        # Get window bounds
        $rect = New-Object Win32+RECT
        $success = [Win32]::GetWindowRect($focusedWindow, [ref]$rect)
        
        if (-not $success) {
            return @{ error = "Could not get window bounds" } | ConvertTo-Json -Compress
        }
        
        $result = @{
            x = $rect.Left
            y = $rect.Top
            width = $rect.Right - $rect.Left
            height = $rect.Bottom - $rect.Top
            controlType = $classNameStr
            name = "Text Control"
            fallbackMethod = $true
        }
        
        return $result | ConvertTo-Json -Compress
        
    } catch {
        return @{ error = "Exception in fallback method: $($_.Exception.Message)" } | ConvertTo-Json -Compress
    }
}

# Main execution logic
switch ($command.ToLower()) {
    "get-focused-text-field" {
        # Try UI Automation first, then fallback to basic API
        $result = Get-FocusedTextField
        $resultData = $result | ConvertFrom-Json
        
        if ($resultData.error) {
            # Try fallback method
            Get-FocusedTextFieldFallback
        } else {
            $result
        }
    }
    default {
        @{ error = "Unknown command. Use 'get-focused-text-field'" } | ConvertTo-Json -Compress
    }
}