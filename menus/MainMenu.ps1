<#
.SYNOPSIS
    Main Menu for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Displays the main interactive menu for the toolkit
.VERSION
    4.0
#>

param(
    [string]$ModulesPath = "$PSScriptRoot\..\modules"
)

# Import modules
Import-Module "$ModulesPath\CommonFunctions.psm1" -Force
Import-Module "$ModulesPath\SystemScanner.psm1" -Force
Import-Module "$ModulesPath\AppInstaller.psm1" -Force
Import-Module "$ModulesPath\SystemOptimizer.psm1" -Force
Import-Module "$ModulesPath\Debloater.psm1" -Force
Import-Module "$ModulesPath\Activator.psm1" -Force
Import-Module "$ModulesPath\DriverUpdater.psm1" -Force

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    <#
    .SYNOPSIS
        Displays the main menu and handles user input
    #>
    [CmdletBinding()]
    param()

    $Continue = $true

    while ($Continue) {
        Clear-Host

        # Display banner
        $Banner = @"

    ╔══════════════════════════════════════════════════════════════════╗
    ║          ULTIMATE WINDOWS SETUP TOOLKIT v4.0                     ║
    ║          Production-Ready System Configuration                    ║
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

        # Show system info summary
        Write-Host "    System: " -ForegroundColor Gray -NoNewline
        $SysInfo = Get-SystemInfo
        Write-Host "$($SysInfo.ComputerName) | $($SysInfo.OSName) | $($SysInfo.RAMTotal)GB RAM" -ForegroundColor White
        Write-Host ""

        # Get user choice
        Write-Host "    Enter your choice: " -ForegroundColor Yellow -NoNewline
        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            '1' {
                . "$PSScriptRoot\AppInstallerMenu.ps1"
                $Result = Show-AppInstallerMenu
                if ($Result -eq 'EXIT') { $Continue = $false }
            }
            '2' {
                . "$PSScriptRoot\SystemScannerMenu.ps1"
                Show-ScannerMenu
            }
            '3' {
                . "$PSScriptRoot\OptimizerMenu.ps1"
                $Result = Show-OptimizerMenu
                if ($Result -eq 'EXIT') { $Continue = $false }
            }
            '4' {
                . "$PSScriptRoot\DebloatActivateMenu.ps1"
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
                Write-Host ""
                Write-ColorOutput -Message "Thank you for using Ultimate Windows Setup Toolkit!" -Type Success
                Write-Host ""
                Start-Countdown -Seconds 3 -Message "Exiting in"
            }
            default {
                Write-Host "    Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ============================================================
# LOG VIEWER
# ============================================================

function Show-LogViewer {
    <#
    .SYNOPSIS
        Displays the log viewer interface
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Log Viewer" -Type Header

    $LogDir = "$env:ProgramData\UltimateWindowsToolkit\Logs"

    if (-not (Test-Path $LogDir)) {
        Write-ColorOutput -Message "No logs found. Log directory does not exist." -Type Warning
        Wait-KeyPress
        return
    }

    $LogFiles = Get-ChildItem -Path $LogDir -Filter "*.log" | Sort-Object LastWriteTime -Descending

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

    Write-Host "    Select a log to view (or B to go back): " -ForegroundColor Yellow -NoNewline
    $Choice = Read-Host

    if ($Choice -eq 'O' -or $Choice -eq 'o') {
        Start-Process explorer $LogDir
    }
    elseif ($Choice -ne 'B' -and $Choice -ne 'b') {
        $LogIndex = [int]$Choice - 1
        if ($LogIndex -ge 0 -and $LogIndex -lt $LogFiles.Count) {
            $SelectedLog = $LogFiles[$LogIndex]
            Write-Host ""
            Write-Host "    ═══════════════════════════════════════════════════════" -ForegroundColor Cyan
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

# ============================================================
# SETTINGS MENU
# ============================================================

function Show-SettingsMenu {
    <#
    .SYNOPSIS
        Displays settings and system information
    #>
    [CmdletBinding()]
    param()

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
        Write-Host "    [5] Check for Internet Connection" -ForegroundColor White
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
                New-SystemRestorePoint -Description "Ultimate Windows Setup Toolkit - Manual"
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

# Export function
Export-ModuleMember -Function Show-MainMenu -ErrorAction SilentlyContinue
