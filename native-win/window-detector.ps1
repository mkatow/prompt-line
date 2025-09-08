# Windows Window Detection Tool
# PowerShell equivalent of macOS window-detector.swift

param([string]$command = "")

# Add Windows API types
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Diagnostics;

    public class Win32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
        
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
        
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
        
        [StructLayout(LayoutKind.Sequential)]
        public struct RECT {
            public int Left;
            public int Top; 
            public int Right;
            public int Bottom;
        }
    }
"@

function Get-CurrentApp {
    try {
        $foregroundWindow = [Win32]::GetForegroundWindow()
        if ($foregroundWindow -eq [IntPtr]::Zero) {
            return @{ error = "No active window found" } | ConvertTo-Json -Compress
        }
        
        $processId = 0
        [Win32]::GetWindowThreadProcessId($foregroundWindow, [ref]$processId) | Out-Null
        
        if ($processId -eq 0) {
            return @{ error = "Could not get process ID" } | ConvertTo-Json -Compress
        }
        
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if (-not $process) {
            return @{ error = "Could not get process information" } | ConvertTo-Json -Compress
        }
        
        $result = @{
            name = $process.ProcessName
            bundleId = $process.Path
        }
        
        return $result | ConvertTo-Json -Compress
    }
    catch {
        return @{ error = "Exception: $($_.Exception.Message)" } | ConvertTo-Json -Compress
    }
}

function Get-WindowBounds {
    try {
        $foregroundWindow = [Win32]::GetForegroundWindow()
        if ($foregroundWindow -eq [IntPtr]::Zero) {
            return @{ error = "No active window found" } | ConvertTo-Json -Compress
        }
        
        $processId = 0
        [Win32]::GetWindowThreadProcessId($foregroundWindow, [ref]$processId) | Out-Null
        
        $rect = New-Object Win32+RECT
        $success = [Win32]::GetWindowRect($foregroundWindow, [ref]$rect)
        
        if (-not $success) {
            return @{ error = "Could not get window bounds" } | ConvertTo-Json -Compress
        }
        
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        $processName = if ($process) { $process.ProcessName } else { "Unknown" }
        $processPath = if ($process) { $process.Path } else { $null }
        
        $result = @{
            x = $rect.Left
            y = $rect.Top
            width = $rect.Right - $rect.Left
            height = $rect.Bottom - $rect.Top
            appName = $processName
            bundleId = $processPath
        }
        
        return $result | ConvertTo-Json -Compress
    }
    catch {
        return @{ error = "Exception: $($_.Exception.Message)" } | ConvertTo-Json -Compress
    }
}

# Main execution logic
switch ($command.ToLower()) {
    "current-app" {
        Get-CurrentApp
    }
    "window-bounds" {
        Get-WindowBounds
    }
    default {
        @{ error = "Unknown command. Use 'current-app' or 'window-bounds'" } | ConvertTo-Json -Compress
    }
}