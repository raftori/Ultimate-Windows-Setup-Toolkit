#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Ultimate Windows Setup Toolkit v4.0
    Production-Ready System Configuration Tool

.DESCRIPTION
    A comprehensive, menu-driven PowerShell toolkit for Windows system setup,
    optimization, and application management.

    Features:
    - Application Installation (via Winget, Chocolatey, Scoop)
    - System Performance Optimization
    - Windows Debloating & Privacy Protection
    - Windows/Office Activation
    - Driver Management

.NOTES
    Version:        4.0.0
    Author:         OffTrackMedia
    License:        MIT
    Requires:       PowerShell 5.1+ and Administrator privileges
    Repository:     https://github.com/yourusername/Ultimate-Windows-Setup-Toolkit

.PARAMETER Action
    The action to perform. Options: Menu, Scan, Optimize, Debloat, Apps, Drivers, Activate

.PARAMETER SkipConfirmation
    Skip all confirmation prompts (for automation)

.PARAMETER DryRun
    Test mode - show what would be done without making changes

.PARAMETER Verbose
    Enable verbose logging output

.PARAMETER LogPath
    Custom path for log files (default: .\logs)

.PARAMETER CreateRestorePoint
    Automatically create a system restore point before changes

.EXAMPLE
    .\Start-Toolkit.ps1
    # Run the interactive menu

.EXAMPLE
    .\Start-Toolkit.ps1 -Action Optimize -CreateRestorePoint
    # Run optimization with automatic restore point creation

.EXAMPLE
    .\Start-Toolkit.ps1 -Action Debloat -SkipConfirmation -DryRun
    # Test debloat operation without making changes

.EXAMPLE
    .\Start-Toolkit.ps1 -Action Apps -LogPath "C:\Logs" -Verbose
    # Install apps with custom log path and verbose output

.LINK
    https://github.com/yourusername/Ultimate-Windows-Setup-Toolkit
#>

[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Scan', 'Optimize', 'Debloat', 'Apps', 'Drivers', 'Activate')]
    [string]$Action = 'Menu',

    [Alias('SkipAdminCheck')]
    [switch]$SkipConfirmation,

    [switch]$DryRun,

    [switch]$Verbose,

    [string]$LogPath = ".\logs",

    [switch]$CreateRestorePoint,

    [switch]$Silent
)

# ============================================================
# SCRIPT CONFIGURATION
# ============================================================

# Enable strict mode for better error detection
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$ProgressPreference = "Continue"

# Script-level variables
$Script:Version = "4.0.0"
$Script:Title = "Ultimate Windows Setup Toolkit"
$Script:RootPath = $PSScriptRoot
$Script:ModulesPath = "$PSScriptRoot\modules"
$Script:MenusPath = "$PSScriptRoot\menus"
$Script:ConfigsPath = "$PSScriptRoot\configs"
$Script:LogDir = if ($LogPath -eq ".\logs") { "$PSScriptRoot\logs" } else { $LogPath }

# Global settings from parameters
$Script:DryRunMode = $DryRun
$Script:SkipConfirmations = $SkipConfirmation
$Script:VerboseMode = $Verbose
$Script:SilentMode = $Silent

# ============================================================
# INITIALIZATION
# ============================================================

function Initialize-ToolkitModules {
    <#
    .SYNOPSIS
        Initializes the toolkit and loads all modules
    #>

    # Create log directory if using custom path
    if (-not (Test-Path $Script:LogDir)) {
        New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
    }

    # Import all modules
    $Modules = @(
        "CommonFunctions",
        "SystemScanner",
        "AppInstaller",
        "SystemOptimizer",
        "Debloater",
        "Activator",
        "DriverUpdater"
    )

    foreach ($Module in $Modules) {
        $ModulePath = "$Script:ModulesPath\$Module.psm1"
        if (Test-Path $ModulePath) {
            try {
                Import-Module $ModulePath -Force -Global -ErrorAction Stop
                if ($Script:VerboseMode) {
                    Write-Host "[DEBUG] Loaded module: $Module" -ForegroundColor Gray
                }
            }
            catch {
                Write-Host "[ERROR] Failed to load module: $Module" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "[WARNING] Module not found: $Module" -ForegroundColor Yellow
            # Continue loading other modules - some may be optional
        }
    }

    # Initialize CommonFunctions toolkit (creates directories, starts logging)
    try {
        Initialize-Toolkit | Out-Null
    }
    catch {
        Write-Host "[WARNING] CommonFunctions Initialize-Toolkit not available" -ForegroundColor Yellow
    }

    # Show dry run warning if enabled
    if ($Script:DryRunMode) {
        Write-Host ""
        Write-Host "    ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "    ║                    DRY RUN MODE ENABLED                          ║" -ForegroundColor Yellow
        Write-Host "    ║         No actual changes will be made to the system             ║" -ForegroundColor Yellow
        Write-Host "    ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 2
    }

    # Create restore point if requested
    if ($CreateRestorePoint -and -not $Script:DryRunMode) {
        Write-Host "[INFO] Creating system restore point..." -ForegroundColor Cyan
        try {
            Checkpoint-Computer -Description "Ultimate Windows Setup Toolkit - Pre-Operation" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-Host "[SUCCESS] Restore point created" -ForegroundColor Green
        }
        catch {
            Write-Host "[WARNING] Failed to create restore point: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Log startup
    Write-Log "Starting Ultimate Windows Setup Toolkit v$Script:Version" -Level INFO -NoConsole
    Write-Log "Running as Administrator: $(Test-AdminPrivileges)" -Level INFO -NoConsole
    if ($Script:DryRunMode) { Write-Log "DRY RUN MODE ENABLED" -Level WARNING -NoConsole }

    return $true
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Checks if running as administrator
    #>

    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-WelcomeBanner {
    <#
    .SYNOPSIS
        Displays the welcome banner
    #>

    Clear-Host

    $Banner = @"

    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                   ║
    ║     ██╗   ██╗██╗    ██╗███████╗████████╗                         ║
    ║     ██║   ██║██║    ██║██╔════╝╚══██╔══╝                         ║
    ║     ██║   ██║██║ █╗ ██║███████╗   ██║                            ║
    ║     ██║   ██║██║███╗██║╚════██║   ██║                            ║
    ║     ╚██████╔╝╚███╔███╔╝███████║   ██║                            ║
    ║      ╚═════╝  ╚══╝╚══╝ ╚══════╝   ╚═╝                            ║
    ║                                                                   ║
    ║          ULTIMATE WINDOWS SETUP TOOLKIT v$Script:Version                     ║
    ║          Production-Ready System Configuration                    ║
    ║                                                                   ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║   [1] Application Installer                                       ║
    ║   [2] System Scanner & Profiler                                  ║
    ║   [3] System Optimizer                                           ║
    ║   [4] Debloat & Privacy                                          ║
    ║   [5] Windows/Office Activation                                  ║
    ║   [6] Driver Manager                                             ║
    ║   [7] View Logs                                                  ║
    ║   [8] Settings & System Info                                     ║
    ║                                                                   ║
    ║   [Q] Exit                                                        ║
    ║                                                                   ║
    ╚══════════════════════════════════════════════════════════════════╝

"@

    Write-Host $Banner -ForegroundColor Cyan
}

# ============================================================
# MAIN MENU HANDLER
# ============================================================

function Start-MainMenu {
    <#
    .SYNOPSIS
        Main menu loop
    #>

    $Continue = $true

    while ($Continue) {
        Show-WelcomeBanner

        # Show system info summary
        try {
            $SysInfo = Get-SystemInfo
            Write-Host "    System: " -ForegroundColor Gray -NoNewline
            Write-Host "$($SysInfo.ComputerName) | $($SysInfo.OSName -replace 'Microsoft ', '') | $($SysInfo.RAMTotal)GB RAM" -ForegroundColor White
        }
        catch {
            Write-Host "    System: Loading..." -ForegroundColor Gray
        }
        Write-Host ""

        # Get user choice
        Write-Host "    Enter your choice: " -ForegroundColor Yellow -NoNewline
        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            '1' {
                . "$Script:MenusPath\AppInstallerMenu.ps1"
                $Result = Show-AppInstallerMenu
                if ($Result -eq 'EXIT') { $Continue = $false }
            }
            '2' {
                . "$Script:MenusPath\SystemScannerMenu.ps1"
                Show-ScannerMenu
            }
            '3' {
                . "$Script:MenusPath\OptimizerMenu.ps1"
                $Result = Show-OptimizerMenu
                if ($Result -eq 'EXIT') { $Continue = $false }
            }
            '4' {
                . "$Script:MenusPath\DebloatActivateMenu.ps1"
                $Result = Show-DebloatMenu
                if ($Result -eq 'EXIT') { $Continue = $false }
            }
            '5' {
                $Result = Show-ActivationMenu
                if ($Result -eq 'EXIT') { $Continue = $false }
            }
            '6' {
                $Result = Show-DriverMenu
                if ($Result -eq 'EXIT') { $Continue = $false }
            }
            '7' {
                Show-LogViewer
            }
            '8' {
                Show-SettingsMenu
            }
            'Q' {
                $Continue = $false
                Show-ExitMessage
            }
            default {
                Write-Host "    Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Show-LogViewer {
    <#
    .SYNOPSIS
        Log viewer interface
    #>

    Write-ColorOutput -Message "Log Viewer" -Type Header

    $LogDir = "$env:ProgramData\UltimateWindowsToolkit\Logs"

    if (-not (Test-Path $LogDir)) {
        Write-ColorOutput -Message "No logs found." -Type Warning
        Wait-KeyPress
        return
    }

    $LogFiles = Get-ChildItem -Path $LogDir -Filter "*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    if ($LogFiles.Count -eq 0) {
        Write-ColorOutput -Message "No log files found." -Type Warning
        Wait-KeyPress
        return
    }

    Write-Host ""
    Write-Host "    Available Log Files:" -ForegroundColor Cyan
    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray

    $Index = 1
    foreach ($Log in $LogFiles | Select-Object -First 10) {
        Write-Host "    [$Index] " -ForegroundColor Yellow -NoNewline
        Write-Host "$($Log.Name) " -ForegroundColor White -NoNewline
        Write-Host "($($Log.LastWriteTime.ToString('yyyy-MM-dd HH:mm')))" -ForegroundColor Gray
        $Index++
    }

    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    [O] Open Log Directory" -ForegroundColor White
    Write-Host "    [B] Back" -ForegroundColor White
    Write-Host ""

    Write-Host "    Select (or B): " -ForegroundColor Yellow -NoNewline
    $Choice = Read-Host

    if ($Choice -eq 'O' -or $Choice -eq 'o') {
        Start-Process explorer $LogDir
    }
    elseif ($Choice -ne 'B' -and $Choice -ne 'b' -and $Choice -match '^\d+$') {
        $LogIndex = [int]$Choice - 1
        if ($LogIndex -ge 0 -and $LogIndex -lt $LogFiles.Count) {
            $SelectedLog = $LogFiles[$LogIndex]
            Clear-Host
            Write-Host ""
            Write-Host "    Log: $($SelectedLog.Name)" -ForegroundColor Cyan
            Write-Host "    ═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Get-Content -Path $SelectedLog.FullName -Tail 50 | ForEach-Object {
                $Color = if ($_ -match '\[ERROR\]') { 'Red' }
                         elseif ($_ -match '\[WARNING\]') { 'Yellow' }
                         elseif ($_ -match '\[SUCCESS\]') { 'Green' }
                         else { 'Gray' }
                Write-Host "    $_" -ForegroundColor $Color
            }
            Write-Host ""
            Wait-KeyPress
        }
    }
}

function Show-SettingsMenu {
    <#
    .SYNOPSIS
        Settings menu
    #>

    $Continue = $true

    while ($Continue) {
        Clear-Host

        Write-ColorOutput -Message "Settings & System Information" -Type Header

        Show-SystemInfo

        Write-Host ""
        Write-Host "    Options:" -ForegroundColor Cyan
        Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "    [1] View Optimization Profile" -ForegroundColor White
        Write-Host "    [2] Create System Restore Point" -ForegroundColor White
        Write-Host "    [3] Open Backup Directory" -ForegroundColor White
        Write-Host "    [4] Open Log Directory" -ForegroundColor White
        Write-Host "    [5] Check Internet Connection" -ForegroundColor White
        Write-Host "    [B] Back to Main Menu" -ForegroundColor White
        Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""

        Write-Host "    Enter your choice: " -ForegroundColor Yellow -NoNewline
        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            '1' {
                $Profile = Get-OptimizationProfile
                Write-Host ""
                Write-Host "    Optimization Profile:" -ForegroundColor Cyan
                Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
                Write-Host "    Name:        " -ForegroundColor Gray -NoNewline
                Write-Host "$($Profile.Name)" -ForegroundColor Yellow
                Write-Host "    Description: " -ForegroundColor Gray -NoNewline
                Write-Host "$($Profile.Description)" -ForegroundColor White
                Write-Host "    RAM:         " -ForegroundColor Gray -NoNewline
                Write-Host "$($Profile.RAM_GB) GB" -ForegroundColor White
                Write-Host "    CPU Cores:   " -ForegroundColor Gray -NoNewline
                Write-Host "$($Profile.CPU_Cores)" -ForegroundColor White
                Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
                Wait-KeyPress
            }
            '2' {
                New-SystemRestorePoint -Description "Ultimate Windows Setup Toolkit"
                Wait-KeyPress
            }
            '3' {
                $BackupDir = "$env:ProgramData\UltimateWindowsToolkit\Backups"
                if (-not (Test-Path $BackupDir)) {
                    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
                }
                Start-Process explorer $BackupDir
            }
            '4' {
                $LogDir = "$env:ProgramData\UltimateWindowsToolkit\Logs"
                if (-not (Test-Path $LogDir)) {
                    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
                }
                Start-Process explorer $LogDir
            }
            '5' {
                Write-Host ""
                Write-ColorOutput -Message "Checking internet connection..." -Type Info
                if (Test-InternetConnection) {
                    Write-ColorOutput -Message "Internet connection is available" -Type Success
                }
                else {
                    Write-ColorOutput -Message "No internet connection detected" -Type Error
                }
                Wait-KeyPress
            }
            'B' { $Continue = $false }
        }
    }
}

function Show-ExitMessage {
    <#
    .SYNOPSIS
        Shows exit message
    #>

    Write-Host ""
    Write-Host "    ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "    ║                                                                   ║" -ForegroundColor Cyan
    Write-Host "    ║   Thank you for using Ultimate Windows Setup Toolkit!            ║" -ForegroundColor Cyan
    Write-Host "    ║                                                                   ║" -ForegroundColor Cyan
    Write-Host "    ║   Created by: Network & Firewall Technicians / OffTrackMedia     ║" -ForegroundColor Cyan
    Write-Host "    ║                                                                   ║" -ForegroundColor Cyan
    Write-Host "    ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 3; $i -gt 0; $i--) {
        Write-Host "`r    Exiting in $i seconds...    " -ForegroundColor Yellow -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host ""
}

# ============================================================
# COMMAND-LINE ACTIONS
# ============================================================

function Invoke-Action {
    <#
    .SYNOPSIS
        Handles command-line actions
    #>
    param([string]$ActionName)

    switch ($ActionName) {
        'Scan' {
            Write-ColorOutput -Message "Running System Scan..." -Type Header
            $Global:SystemProfile = Get-SystemProfile
            Show-PerformanceTierSummary -Tier $Global:SystemProfile.PerformanceTier
            Write-Host ""
            Write-Host "  CPU:     $($Global:SystemProfile.CPU.Name)" -ForegroundColor White
            Write-Host "  RAM:     $($Global:SystemProfile.RAM.TotalGB) GB" -ForegroundColor White
            Write-Host "  Storage: $(if ($Global:SystemProfile.Storage.HasNVMe) { 'NVMe SSD' } elseif ($Global:SystemProfile.Storage.HasSSD) { 'SSD' } else { 'HDD' })" -ForegroundColor White
            Write-Host "  GPU:     $($Global:SystemProfile.GPU.PrimaryGPU)" -ForegroundColor White
            Write-Host ""
            if ($Global:SystemProfile.Recommendations.Count -gt 0) {
                Show-Recommendations -Recommendations $Global:SystemProfile.Recommendations
            }
        }
        'Optimize' {
            Write-ColorOutput -Message "Running System Optimization..." -Type Header
            Invoke-SystemOptimization -CreateRestorePoint
        }
        'Debloat' {
            Write-ColorOutput -Message "Running Windows Debloat..." -Type Header
            Invoke-Debloat
        }
        'Apps' {
            Write-ColorOutput -Message "Installing Package Managers..." -Type Header
            Install-AllPackageManagers
        }
        'Drivers' {
            Write-ColorOutput -Message "Checking for Driver Updates..." -Type Header
            Install-WindowsUpdateDrivers
        }
        'Activate' {
            Write-ColorOutput -Message "Opening Activation Menu..." -Type Header
            Show-ActivationMenu
        }
    }
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Check admin privileges
if (-not $SkipConfirmation -and -not (Test-AdminPrivileges)) {
    Write-Host ""
    Write-Host "    ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "    ║   ERROR: Administrator privileges required!                       ║" -ForegroundColor Red
    Write-Host "    ╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "    ║                                                                   ║" -ForegroundColor Red
    Write-Host "    ║   Please run this script as Administrator:                        ║" -ForegroundColor Red
    Write-Host "    ║                                                                   ║" -ForegroundColor Red
    Write-Host "    ║   1. Right-click on PowerShell                                    ║" -ForegroundColor Red
    Write-Host "    ║   2. Select 'Run as Administrator'                                ║" -ForegroundColor Red
    Write-Host "    ║   3. Navigate to this script and run it again                     ║" -ForegroundColor Red
    Write-Host "    ║                                                                   ║" -ForegroundColor Red
    Write-Host "    ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""

    Write-Host "    Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Initialize toolkit
$InitResult = Initialize-ToolkitModules

if (-not $InitResult) {
    Write-Host ""
    Write-Host "    Failed to initialize toolkit. Please check that all module files exist." -ForegroundColor Red
    Write-Host "    Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Log parameters
Write-Log "Parameters: Action=$Action, DryRun=$DryRun, SkipConfirmation=$SkipConfirmation" -Level INFO -NoConsole

# Handle action or show menu
if ($Action -eq 'Menu') {
    Start-MainMenu
}
else {
    Invoke-Action -ActionName $Action
}

# Clean exit
exit 0
