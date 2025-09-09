# Windows Keyboard Simulation Tool
# PowerShell equivalent of macOS keyboard-simulator.swift

param([string]$command = "", [string]$appName = "", [string]$bundleId = "")

# Load Windows Forms for SendKeys first
Add-Type -AssemblyName System.Windows.Forms

# Add Windows API types for advanced keyboard simulation
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;

    public class Win32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
        
        [DllImport("user32.dll")]
        public static extern bool EnumWindows(EnumWindowsDelegate lpEnumFunc, IntPtr lParam);
        
        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);
        
        public delegate bool EnumWindowsDelegate(IntPtr hWnd, IntPtr lParam);
        
        public const int SW_RESTORE = 9;
        public const int SW_SHOW = 5;
    }
"@

function Send-Paste {
    try {
        # Send Ctrl+V keystroke
        [System.Windows.Forms.SendKeys]::SendWait("^v")
        
        # Small delay to ensure the paste operation completes
        Start-Sleep -Milliseconds 50
        
        $result = @{
            success = $true
            command = "paste"
            hasAccessibility = $true  # Windows doesn't require explicit accessibility permissions
        }
        
        return $result | ConvertTo-Json -Compress
    }
    catch {
        $result = @{
            success = $false
            command = "paste"
            hasAccessibility = $true
            error = $_.Exception.Message
        }
        
        return $result | ConvertTo-Json -Compress
    }
}

function Activate-AppByName {
    param([string]$targetAppName)
    
    try {
        # Find processes by name (without .exe extension)
        $processes = Get-Process -Name $targetAppName -ErrorAction SilentlyContinue
        
        if (-not $processes) {
            # Try with common executable extensions
            $processes = Get-Process -Name "$targetAppName*" -ErrorAction SilentlyContinue
        }
        
        if (-not $processes) {
            return @{
                success = $false
                command = "activate-name"
                error = "Application '$targetAppName' not found"
            } | ConvertTo-Json -Compress
        }
        
        # Get the first process with a main window
        foreach ($process in $processes) {
            if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
                [Win32]::ShowWindow($process.MainWindowHandle, [Win32]::SW_RESTORE) | Out-Null
                [Win32]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
                
                # Small delay to ensure window is activated
                Start-Sleep -Milliseconds 100
                
                return @{
                    success = $true
                    command = "activate-name"
                    appName = $process.ProcessName
                } | ConvertTo-Json -Compress
            }
        }
        
        return @{
            success = $false
            command = "activate-name"
            error = "No visible window found for '$targetAppName'"
        } | ConvertTo-Json -Compress
    }
    catch {
        return @{
            success = $false
            command = "activate-name"
            error = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }
}

function Activate-AppByPath {
    param([string]$targetPath)
    
    try {
        # Extract process name from path
        $processName = [System.IO.Path]::GetFileNameWithoutExtension($targetPath)
        
        # Find processes by matching path
        $processes = Get-Process | Where-Object { 
            $_.Path -eq $targetPath -or $_.ProcessName -eq $processName 
        }
        
        if (-not $processes) {
            return @{
                success = $false
                command = "activate-bundle"
                error = "Application at path '$targetPath' not found"
            } | ConvertTo-Json -Compress
        }
        
        # Get the first process with a main window
        foreach ($process in $processes) {
            if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
                [Win32]::ShowWindow($process.MainWindowHandle, [Win32]::SW_RESTORE) | Out-Null
                [Win32]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
                
                # Small delay to ensure window is activated
                Start-Sleep -Milliseconds 100
                
                return @{
                    success = $true
                    command = "activate-bundle"
                    appName = $process.ProcessName
                    bundleId = $process.Path
                } | ConvertTo-Json -Compress
            }
        }
        
        return @{
            success = $false
            command = "activate-bundle"
            error = "No visible window found for application at '$targetPath'"
        } | ConvertTo-Json -Compress
    }
    catch {
        return @{
            success = $false
            command = "activate-bundle"
            error = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }
}

function Activate-AndPasteByName {
    param([string]$targetAppName)
    
    try {
        # First activate the application
        $activateResult = Activate-AppByName -targetAppName $targetAppName
        $activateData = $activateResult | ConvertFrom-Json
        
        if (-not $activateData.success) {
            return @{
                success = $false
                command = "activate-and-paste-name"
                error = "Failed to activate app: $($activateData.error)"
            } | ConvertTo-Json -Compress
        }
        
        # Small delay to ensure the window is ready
        Start-Sleep -Milliseconds 200
        
        # Then send paste command
        [System.Windows.Forms.SendKeys]::SendWait("^v")
        Start-Sleep -Milliseconds 50
        
        return @{
            success = $true
            command = "activate-and-paste-name"
            appName = $activateData.appName
        } | ConvertTo-Json -Compress
    }
    catch {
        return @{
            success = $false
            command = "activate-and-paste-name"
            error = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }
}

function Activate-AndPasteByPath {
    param([string]$targetPath)
    
    try {
        # First activate the application
        $activateResult = Activate-AppByPath -targetPath $targetPath
        $activateData = $activateResult | ConvertFrom-Json
        
        if (-not $activateData.success) {
            return @{
                success = $false
                command = "activate-and-paste-bundle"
                error = "Failed to activate app: $($activateData.error)"
            } | ConvertTo-Json -Compress
        }
        
        # Small delay to ensure the window is ready
        Start-Sleep -Milliseconds 200
        
        # Then send paste command
        [System.Windows.Forms.SendKeys]::SendWait("^v")
        Start-Sleep -Milliseconds 50
        
        return @{
            success = $true
            command = "activate-and-paste-bundle"
            appName = $activateData.appName
            bundleId = $activateData.bundleId
        } | ConvertTo-Json -Compress
    }
    catch {
        return @{
            success = $false
            command = "activate-and-paste-bundle"
            error = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }
}

# Main execution logic
switch ($command.ToLower()) {
    "paste" {
        Send-Paste
    }
    "activate-name" {
        if ([string]::IsNullOrEmpty($appName)) {
            @{ success = $false; command = "activate-name"; error = "App name is required" } | ConvertTo-Json -Compress
        } else {
            Activate-AppByName -targetAppName $appName
        }
    }
    "activate-bundle" {
        if ([string]::IsNullOrEmpty($bundleId)) {
            @{ success = $false; command = "activate-bundle"; error = "Bundle ID (path) is required" } | ConvertTo-Json -Compress
        } else {
            Activate-AppByPath -targetPath $bundleId
        }
    }
    "activate-and-paste-name" {
        if ([string]::IsNullOrEmpty($appName)) {
            @{ success = $false; command = "activate-and-paste-name"; error = "App name is required" } | ConvertTo-Json -Compress
        } else {
            Activate-AndPasteByName -targetAppName $appName
        }
    }
    "activate-and-paste-bundle" {
        if ([string]::IsNullOrEmpty($bundleId)) {
            @{ success = $false; command = "activate-and-paste-bundle"; error = "Bundle ID (path) is required" } | ConvertTo-Json -Compress
        } else {
            Activate-AndPasteByPath -targetPath $bundleId
        }
    }
    default {
        @{ 
            success = $false
            error = "Unknown command. Use: paste, activate-name, activate-bundle, activate-and-paste-name, activate-and-paste-bundle" 
        } | ConvertTo-Json -Compress
    }
}