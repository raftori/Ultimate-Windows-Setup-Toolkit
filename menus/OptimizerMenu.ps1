#Requires -Version 5.1
<#
.SYNOPSIS
    System Optimizer Menu for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Interactive menu for comprehensive system optimization options including
    RAM, Disk, Startup, Service, Gaming, Power, Network, Visual, and Registry optimizations
.VERSION
    4.0
#>

# ============================================================
# BANNER FUNCTION
# ============================================================

function Show-OptimizerBanner {
    $Banner = @"

    ╔══════════════════════════════════════════════════════════════════╗
    ║                      SYSTEM OPTIMIZER                            ║
    ║               Performance Tuning & Enhancement                   ║
    ╚══════════════════════════════════════════════════════════════════╝

"@
    Write-Host $Banner -ForegroundColor Cyan
}

# ============================================================
# MAIN OPTIMIZER MENU
# ============================================================

function Show-OptimizerMenu {
    <#
    .SYNOPSIS
        Displays the system optimizer menu with 11 options
    #>
    [CmdletBinding()]
    param()

    while ($true) {
        Clear-Host
        Show-OptimizerBanner

        # Show current profile
        $Profile = Get-OptimizationProfile
        Write-Host "  Current Profile: " -NoNewline -ForegroundColor Gray
        Write-Host "$($Profile.Name)" -ForegroundColor Yellow
        Write-Host "  $($Profile.Description)" -ForegroundColor DarkGray
        Write-Host ""

        Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [1]  RAM Optimization          [2]  Disk Cleanup           ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [3]  Startup Optimization      [4]  Service Optimization   ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [5]  Gaming Mode               [6]  Power Configuration    ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [7]  Network Optimization      [8]  Visual Performance     ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [9]  Performance Analysis      [10] Registry Optimization  ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [11] FULL OPTIMIZATION         [V]  View Profile           ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [B]  Back to Main Menu                                     ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host "  Select an option: " -NoNewline -ForegroundColor White

        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            "1" { Show-RAMOptimizationMenu }
            "2" { Show-DiskCleanupMenu }
            "3" { Show-StartupOptimizationMenu }
            "4" { Show-ServiceOptimizationMenu }
            "5" { Show-GamingModeMenu }
            "6" { Show-PowerConfigurationMenu }
            "7" { Show-NetworkOptimizationMenu }
            "8" { Show-VisualPerformanceMenu }
            "9" { Show-PerformanceAnalysisMenu }
            "10" { Show-RegistryOptimizationMenu }
            "11" { Show-FullOptimizationWizard }
            "V" { Show-OptimizationProfile; Pause-Menu }
            "B" { return }
            default {
                Write-Host ""
                Write-Host "  Invalid option. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
}

# ============================================================
# [1] RAM OPTIMIZATION MENU
# ============================================================

function Show-RAMOptimizationMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  RAM OPTIMIZATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Clear Standby Memory                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Clear System Cache                                    ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Configure Virtual Memory                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Optimize Memory Management                            ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [5]  Run ALL RAM Optimizations                             ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            Clear-StandbyMemory
            Pause-Menu
        }
        "2" {
            Write-Host ""
            Clear-SystemCache
            Pause-Menu
        }
        "3" {
            Show-VirtualMemoryConfig
        }
        "4" {
            Write-Host ""
            Optimize-MemoryManagement
            Pause-Menu
        }
        "5" {
            Write-Host ""
            Write-Host "  Running all RAM optimizations..." -ForegroundColor Yellow
            Write-Host ""
            Clear-StandbyMemory
            Write-Host ""
            Clear-SystemCache
            Write-Host ""
            Optimize-MemoryManagement
            Pause-Menu
        }
        "B" { return }
    }
}

function Show-VirtualMemoryConfig {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  CONFIGURE VIRTUAL MEMORY" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    # Get current RAM
    $TotalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)
    $RecommendedMin = $TotalRAM * 1024  # Same as RAM in MB
    $RecommendedMax = $TotalRAM * 1024 * 2  # 2x RAM in MB

    Write-Host "  Current RAM: $TotalRAM GB" -ForegroundColor Gray
    Write-Host "  Recommended: $RecommendedMin MB - $RecommendedMax MB" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  System Managed (Recommended)                          ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Custom Size (Advanced)                                ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Disable Virtual Memory (Not Recommended)              ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice) {
        "1" {
            Write-Host ""
            Set-VirtualMemory -SystemManaged
            Pause-Menu
        }
        "2" {
            Write-Host ""
            Write-Host "  Enter initial size in MB [$RecommendedMin]: " -NoNewline -ForegroundColor Yellow
            $InitSize = Read-Host
            if ([string]::IsNullOrEmpty($InitSize)) { $InitSize = $RecommendedMin }

            Write-Host "  Enter maximum size in MB [$RecommendedMax]: " -NoNewline -ForegroundColor Yellow
            $MaxSize = Read-Host
            if ([string]::IsNullOrEmpty($MaxSize)) { $MaxSize = $RecommendedMax }

            Set-VirtualMemory -InitialSizeMB ([int]$InitSize) -MaximumSizeMB ([int]$MaxSize)
            Pause-Menu
        }
        "3" {
            Write-Host ""
            Write-Host "  WARNING: Disabling virtual memory is not recommended!" -ForegroundColor Red
            Write-Host "  This can cause system instability." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Are you sure? (Y/N): " -NoNewline -ForegroundColor Red
            $Confirm = Read-Host
            if ($Confirm -eq "Y" -or $Confirm -eq "y") {
                Set-VirtualMemory -InitialSizeMB 0 -MaximumSizeMB 0
            }
            Pause-Menu
        }
        "B" { return }
    }
}

# ============================================================
# [2] DISK CLEANUP MENU
# ============================================================

function Show-DiskCleanupMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  DISK CLEANUP" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Quick Cleanup (Temp Files Only)                       ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Standard Cleanup (Temp + Recycle Bin)                 ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Include Browser Cache                                 ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Include Windows Update Cache                          ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [5]  FULL Cleanup (All of the above)                       ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [6]  Optimize Storage Settings                             ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            Clear-SystemCache
            Pause-Menu
        }
        "2" {
            Write-Host ""
            Invoke-DiskCleanup
            Pause-Menu
        }
        "3" {
            Write-Host ""
            Invoke-DiskCleanup -IncludeBrowserCache
            Pause-Menu
        }
        "4" {
            Write-Host ""
            Invoke-DiskCleanup -IncludeWindowsUpdate
            Pause-Menu
        }
        "5" {
            Write-Host ""
            Write-Host "  Running FULL disk cleanup..." -ForegroundColor Yellow
            Write-Host ""
            Invoke-DiskCleanup -IncludeBrowserCache -IncludeWindowsUpdate
            Pause-Menu
        }
        "6" {
            Write-Host ""
            Optimize-StorageSettings
            Pause-Menu
        }
        "B" { return }
    }
}

# ============================================================
# [3] STARTUP OPTIMIZATION MENU
# ============================================================

function Show-StartupOptimizationMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  STARTUP OPTIMIZATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  View Startup Programs                                 ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Disable Startup Program                               ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Disable Startup Delay                                 ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Quick Boot Optimization                               ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Show-StartupProgramsList
        }
        "2" {
            Show-DisableStartupMenu
        }
        "3" {
            Write-Host ""
            Optimize-StartupDelay
            Pause-Menu
        }
        "4" {
            Write-Host ""
            Write-Host "  Applying quick boot optimization..." -ForegroundColor Yellow
            Write-Host ""
            Optimize-StartupDelay
            Pause-Menu
        }
        "B" { return }
    }
}

function Show-StartupProgramsList {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  STARTUP PROGRAMS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    $StartupItems = Get-StartupPrograms

    if ($StartupItems.Count -eq 0) {
        Write-Host "  No startup programs found." -ForegroundColor Yellow
    }
    else {
        $i = 1
        foreach ($Item in $StartupItems) {
            $TypeColor = if ($Item.Type -eq "Registry") { "Cyan" } else { "Magenta" }
            Write-Host "  [$i] " -NoNewline -ForegroundColor DarkGray
            Write-Host "$($Item.Name)" -NoNewline -ForegroundColor White
            Write-Host " ($($Item.Type))" -ForegroundColor $TypeColor
            Write-Host "      $($Item.Command)" -ForegroundColor DarkGray
            $i++
        }
        Write-Host ""
        Write-Host "  Total: $($StartupItems.Count) startup items" -ForegroundColor Gray
    }

    Write-Host ""
    Pause-Menu
}

function Show-DisableStartupMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  DISABLE STARTUP PROGRAM" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    $StartupItems = Get-StartupPrograms

    if ($StartupItems.Count -eq 0) {
        Write-Host "  No startup programs found." -ForegroundColor Yellow
        Pause-Menu
        return
    }

    $i = 1
    foreach ($Item in $StartupItems) {
        Write-Host "  [$i] $($Item.Name)" -ForegroundColor White
        $i++
    }

    Write-Host ""
    Write-Host "  Enter number to disable (or B to go back): " -NoNewline -ForegroundColor Yellow
    $Selection = Read-Host

    if ($Selection.ToUpper() -eq "B") { return }

    $Index = [int]$Selection - 1
    if ($Index -ge 0 -and $Index -lt $StartupItems.Count) {
        $Item = $StartupItems[$Index]
        Write-Host ""
        Write-Host "  Disabling: $($Item.Name)..." -ForegroundColor Yellow
        $Result = Disable-StartupProgram -Name $Item.Name -Location $Item.Location
        if ($Result) {
            Write-Host "  Successfully disabled $($Item.Name)" -ForegroundColor Green
        }
        else {
            Write-Host "  Failed to disable $($Item.Name)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  Invalid selection." -ForegroundColor Red
    }

    Pause-Menu
}

# ============================================================
# [4] SERVICE OPTIMIZATION MENU
# ============================================================

function Show-ServiceOptimizationMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  SERVICE OPTIMIZATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Disable Telemetry Services                            ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Disable Unnecessary Services                          ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Disable Scheduled Tasks                               ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Run ALL Service Optimizations                         ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            Write-Host "  Disabling telemetry services..." -ForegroundColor Yellow
            # Specifically disable telemetry services
            $TelemetryServices = @("DiagTrack", "dmwappushservice")
            foreach ($svc in $TelemetryServices) {
                try {
                    Stop-Service $svc -Force -ErrorAction SilentlyContinue
                    Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
                    Write-Host "  Disabled: $svc" -ForegroundColor Green
                }
                catch {
                    Write-Host "  Failed: $svc" -ForegroundColor Red
                }
            }
            Pause-Menu
        }
        "2" {
            Write-Host ""
            Optimize-WindowsServices
            Pause-Menu
        }
        "3" {
            Write-Host ""
            Optimize-ScheduledTasks
            Pause-Menu
        }
        "4" {
            Write-Host ""
            Write-Host "  Running all service optimizations..." -ForegroundColor Yellow
            Write-Host ""
            Optimize-WindowsServices
            Write-Host ""
            Optimize-ScheduledTasks
            Pause-Menu
        }
        "B" { return }
    }
}

# ============================================================
# [5] GAMING MODE MENU
# ============================================================

function Show-GamingModeMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  GAMING MODE" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Enable Game Mode                                      ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Disable Game DVR/Bar                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Disable Fullscreen Optimizations                      ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Set High Performance Power Plan                       ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [5]  Optimize GPU Settings                                 ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [6]  Apply ALL Gaming Optimizations                        ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            $GameModePath = "HKCU:\Software\Microsoft\GameBar"
            Set-RegistryValue -Path $GameModePath -Name "AutoGameModeEnabled" -Value 1 `
                -Description "Game Mode enabled"
            Write-ColorOutput -Message "Game Mode enabled" -Type Success
            Pause-Menu
        }
        "2" {
            Write-Host ""
            $GameDVRPath = "HKCU:\System\GameConfigStore"
            Set-RegistryValue -Path $GameDVRPath -Name "GameDVR_Enabled" -Value 0 `
                -Description "Game DVR disabled"
            $GameBarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
            Set-RegistryValue -Path $GameBarPath -Name "AppCaptureEnabled" -Value 0 `
                -Description "Game Bar capture disabled"
            Write-ColorOutput -Message "Game DVR/Bar disabled" -Type Success
            Pause-Menu
        }
        "3" {
            Write-Host ""
            $FSOptPath = "HKCU:\System\GameConfigStore"
            Set-RegistryValue -Path $FSOptPath -Name "GameDVR_FSEBehaviorMode" -Value 2 `
                -Description "Fullscreen optimizations disabled"
            Set-RegistryValue -Path $FSOptPath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1
            Set-RegistryValue -Path $FSOptPath -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1
            Write-ColorOutput -Message "Fullscreen optimizations disabled" -Type Success
            Pause-Menu
        }
        "4" {
            Write-Host ""
            Optimize-PowerSettings
            Pause-Menu
        }
        "5" {
            Write-Host ""
            Optimize-GPUSettings
            Pause-Menu
        }
        "6" {
            Write-Host ""
            Write-Host "  Applying all gaming optimizations..." -ForegroundColor Yellow
            Write-Host ""
            Optimize-GamingSettings
            Write-Host ""
            Optimize-GPUSettings
            Write-Host ""
            Optimize-PowerSettings
            Pause-Menu
        }
        "B" { return }
    }
}

# ============================================================
# [6] POWER CONFIGURATION MENU
# ============================================================

function Show-PowerConfigurationMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  POWER CONFIGURATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Ultimate Performance Plan                             ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  High Performance Plan                                 ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Balanced Plan (Default)                               ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Disable USB Selective Suspend                         ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [5]  Disable Sleep/Hibernate                               ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [6]  Apply Full Power Optimization                         ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            Write-Host "  Creating Ultimate Performance power plan..." -ForegroundColor Yellow
            # Enable Ultimate Performance plan
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
            powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            if ($?) {
                Write-ColorOutput -Message "Ultimate Performance plan activated" -Type Success
            }
            else {
                # Try to activate High Performance as fallback
                powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
                Write-ColorOutput -Message "High Performance plan activated (Ultimate not available)" -Type Warning
            }
            Pause-Menu
        }
        "2" {
            Write-Host ""
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
            Write-ColorOutput -Message "High Performance plan activated" -Type Success
            Pause-Menu
        }
        "3" {
            Write-Host ""
            powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
            Write-ColorOutput -Message "Balanced plan activated" -Type Success
            Pause-Menu
        }
        "4" {
            Write-Host ""
            powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
            powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
            powercfg /SETACTIVE SCHEME_CURRENT
            Write-ColorOutput -Message "USB Selective Suspend disabled" -Type Success
            Pause-Menu
        }
        "5" {
            Write-Host ""
            powercfg -change -standby-timeout-ac 0
            powercfg -change -standby-timeout-dc 0
            powercfg -change -hibernate-timeout-ac 0
            powercfg -change -hibernate-timeout-dc 0
            powercfg /hibernate off
            Write-ColorOutput -Message "Sleep and Hibernate disabled" -Type Success
            Pause-Menu
        }
        "6" {
            Write-Host ""
            Optimize-PowerSettings
            Pause-Menu
        }
        "B" { return }
    }
}

# ============================================================
# [7] NETWORK OPTIMIZATION MENU
# ============================================================

function Show-NetworkOptimizationMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  NETWORK OPTIMIZATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Configure DNS (Cloudflare 1.1.1.1)                    ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Configure DNS (Google 8.8.8.8)                        ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Configure DNS (Quad9 9.9.9.9)                         ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Configure DNS (OpenDNS)                               ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [5]  Configure Custom DNS                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [6]  Flush DNS Cache                                       ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [7]  Disable Nagle's Algorithm (Gaming)                    ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [8]  Apply Full Network Optimization                       ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            Set-DNSServers -Provider 'Cloudflare'
            Pause-Menu
        }
        "2" {
            Write-Host ""
            Set-DNSServers -Provider 'Google'
            Pause-Menu
        }
        "3" {
            Write-Host ""
            Set-DNSServers -Provider 'Quad9'
            Pause-Menu
        }
        "4" {
            Write-Host ""
            Set-DNSServers -Provider 'OpenDNS'
            Pause-Menu
        }
        "5" {
            Write-Host ""
            Write-Host "  Enter Primary DNS: " -NoNewline -ForegroundColor Yellow
            $Primary = Read-Host
            Write-Host "  Enter Secondary DNS: " -NoNewline -ForegroundColor Yellow
            $Secondary = Read-Host
            Set-DNSServers -Provider 'Custom' -PrimaryDNS $Primary -SecondaryDNS $Secondary
            Pause-Menu
        }
        "6" {
            Write-Host ""
            Clear-DNSCache
            Pause-Menu
        }
        "7" {
            Write-Host ""
            Write-Host "  Disabling Nagle's Algorithm..." -ForegroundColor Yellow
            # Disable Nagle's Algorithm
            $NaglePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            Get-ChildItem $NaglePath | ForEach-Object {
                Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            }
            Write-ColorOutput -Message "Nagle's Algorithm disabled (reduces latency)" -Type Success
            Pause-Menu
        }
        "8" {
            Write-Host ""
            Optimize-NetworkSettings
            Pause-Menu
        }
        "B" { return }
    }
}

# ============================================================
# [8] VISUAL PERFORMANCE MENU
# ============================================================

function Show-VisualPerformanceMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  VISUAL PERFORMANCE" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Best Performance (Disable All Effects)                ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Custom (Keep Smooth Fonts & Edges)                    ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Disable Transparency Effects                          ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Disable Menu Animations                               ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [5]  Set Menu Delay to Zero                                ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [6]  Best Appearance (Default)                             ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            $VisualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
            Set-RegistryValue -Path $VisualPath -Name "VisualFXSetting" -Value 2 `
                -Description "Visual effects set to Best Performance"
            Write-ColorOutput -Message "Visual effects set to Best Performance" -Type Success
            Pause-Menu
        }
        "2" {
            Write-Host ""
            Optimize-VisualEffects
            Pause-Menu
        }
        "3" {
            Write-Host ""
            $TransparencyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
            Set-RegistryValue -Path $TransparencyPath -Name "EnableTransparency" -Value 0 `
                -Description "Transparency effects disabled"
            Write-ColorOutput -Message "Transparency effects disabled" -Type Success
            Pause-Menu
        }
        "4" {
            Write-Host ""
            $AnimationPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
            Set-RegistryValue -Path $AnimationPath -Name "MinAnimate" -Value "0" -Type String `
                -Description "Window animations disabled"
            Write-ColorOutput -Message "Menu animations disabled" -Type Success
            Pause-Menu
        }
        "5" {
            Write-Host ""
            Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String `
                -Description "Menu show delay set to 0"
            Write-ColorOutput -Message "Menu delay set to zero" -Type Success
            Pause-Menu
        }
        "6" {
            Write-Host ""
            $VisualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
            Set-RegistryValue -Path $VisualPath -Name "VisualFXSetting" -Value 1 `
                -Description "Visual effects set to Best Appearance"
            Write-ColorOutput -Message "Visual effects set to Best Appearance" -Type Success
            Pause-Menu
        }
        "B" { return }
    }
}

# ============================================================
# [9] PERFORMANCE ANALYSIS MENU
# ============================================================

function Show-PerformanceAnalysisMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  PERFORMANCE ANALYSIS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Get-PerformanceAnalysis

    Pause-Menu
}

# ============================================================
# [10] REGISTRY OPTIMIZATION MENU
# ============================================================

function Show-RegistryOptimizationMenu {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  REGISTRY OPTIMIZATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Disable Cortana                                       ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Disable Web Search in Start Menu                      ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Disable Tips & Suggestions                            ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [4]  Disable Advertising ID                                ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [5]  Disable Activity History                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [6]  Set Menu Delay to Zero                                ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [7]  Apply ALL Registry Optimizations                      ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select an option: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            $CortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $CortanaPath)) {
                New-Item -Path $CortanaPath -Force | Out-Null
            }
            Set-RegistryValue -Path $CortanaPath -Name "AllowCortana" -Value 0 `
                -Description "Cortana disabled"
            Write-ColorOutput -Message "Cortana disabled" -Type Success
            Pause-Menu
        }
        "2" {
            Write-Host ""
            $SearchPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $SearchPath)) {
                New-Item -Path $SearchPath -Force | Out-Null
            }
            Set-RegistryValue -Path $SearchPath -Name "DisableWebSearch" -Value 1 `
                -Description "Web search disabled"
            Set-RegistryValue -Path $SearchPath -Name "ConnectedSearchUseWeb" -Value 0
            Write-ColorOutput -Message "Web search in Start menu disabled" -Type Success
            Pause-Menu
        }
        "3" {
            Write-Host ""
            $ContentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Set-RegistryValue -Path $ContentPath -Name "SystemPaneSuggestionsEnabled" -Value 0 `
                -Description "Suggestions disabled"
            Set-RegistryValue -Path $ContentPath -Name "SoftLandingEnabled" -Value 0
            Set-RegistryValue -Path $ContentPath -Name "SubscribedContent-338388Enabled" -Value 0
            Write-ColorOutput -Message "Tips and suggestions disabled" -Type Success
            Pause-Menu
        }
        "4" {
            Write-Host ""
            $AdPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            Set-RegistryValue -Path $AdPath -Name "Enabled" -Value 0 `
                -Description "Advertising ID disabled"
            Write-ColorOutput -Message "Advertising ID disabled" -Type Success
            Pause-Menu
        }
        "5" {
            Write-Host ""
            $ActivityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            if (-not (Test-Path $ActivityPath)) {
                New-Item -Path $ActivityPath -Force | Out-Null
            }
            Set-RegistryValue -Path $ActivityPath -Name "EnableActivityFeed" -Value 0 `
                -Description "Activity history disabled"
            Set-RegistryValue -Path $ActivityPath -Name "PublishUserActivities" -Value 0
            Set-RegistryValue -Path $ActivityPath -Name "UploadUserActivities" -Value 0
            Write-ColorOutput -Message "Activity history disabled" -Type Success
            Pause-Menu
        }
        "6" {
            Write-Host ""
            Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String `
                -Description "Menu show delay set to 0"
            Write-ColorOutput -Message "Menu delay set to zero" -Type Success
            Pause-Menu
        }
        "7" {
            Write-Host ""
            Optimize-RegistrySettings
            Pause-Menu
        }
        "B" { return }
    }
}

# ============================================================
# [11] FULL OPTIMIZATION WIZARD
# ============================================================

function Show-FullOptimizationWizard {
    Clear-Host
    Show-OptimizerBanner

    Write-Host "  FULL SYSTEM OPTIMIZATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    # Get profile info
    $Profile = Get-OptimizationProfile
    $SysInfo = Get-SystemInfo

    Write-Host "  System Analysis:" -ForegroundColor White
    Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray
    Write-Host "  CPU:      " -NoNewline -ForegroundColor Gray
    Write-Host "$($SysInfo.CPUName)" -ForegroundColor White
    Write-Host "  RAM:      " -NoNewline -ForegroundColor Gray
    Write-Host "$($SysInfo.RAMTotal) GB" -ForegroundColor White
    Write-Host "  GPU:      " -NoNewline -ForegroundColor Gray
    Write-Host "$($SysInfo.GPUName)" -ForegroundColor White
    Write-Host "  Profile:  " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.Name)" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  This will apply the following optimizations:" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray
    Write-Host "  [+] Memory management optimization" -ForegroundColor Green
    Write-Host "  [+] CPU scheduling optimization" -ForegroundColor Green
    Write-Host "  [+] GPU performance settings" -ForegroundColor Green
    Write-Host "  [+] Storage optimization (TRIM, caching)" -ForegroundColor Green
    Write-Host "  [+] Power plan: Ultimate Performance" -ForegroundColor Green
    Write-Host "  [+] Gaming optimizations" -ForegroundColor Green
    Write-Host "  [+] Network latency reduction" -ForegroundColor Green
    Write-Host "  [+] Visual effects optimization" -ForegroundColor Green
    Write-Host "  [+] Disable unnecessary services" -ForegroundColor Green
    Write-Host "  [+] Disable telemetry tasks" -ForegroundColor Green
    Write-Host "  [+] Registry optimizations" -ForegroundColor Green
    Write-Host ""

    Write-Host "  [!] A system restart will be recommended after optimization" -ForegroundColor Yellow
    Write-Host ""

    # Ask about restore point
    Write-Host "  Create a system restore point before proceeding? (Y/N): " -NoNewline -ForegroundColor Yellow
    $RestoreChoice = Read-Host
    $CreateRestore = ($RestoreChoice -eq "Y" -or $RestoreChoice -eq "y")

    # Confirm
    Write-Host ""
    Write-Host "  Proceed with FULL system optimization? (Y/N): " -NoNewline -ForegroundColor Yellow
    $Confirm = Read-Host

    if ($Confirm -ne "Y" -and $Confirm -ne "y") {
        Write-Host ""
        Write-ColorOutput -Message "Optimization cancelled" -Type Info
        Pause-Menu
        return
    }

    Write-Host ""

    # Run complete optimization
    $Results = Invoke-SystemOptimization -CreateRestorePoint:$CreateRestore

    # Also run the new functions
    Write-Host ""
    Optimize-RegistrySettings

    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  OPTIMIZATION COMPLETE!" -ForegroundColor Green
    Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    # Restart prompt
    Write-Host "  Restart now to apply all changes? (Y/N): " -NoNewline -ForegroundColor Yellow
    $RestartChoice = Read-Host

    if ($RestartChoice -eq "Y" -or $RestartChoice -eq "y") {
        Write-Host ""
        Write-ColorOutput -Message "System will restart in 10 seconds..." -Type Warning
        Write-Host "  Press Ctrl+C to cancel" -ForegroundColor Gray
        for ($i = 10; $i -gt 0; $i--) {
            Write-Host "`r  Restarting in $i seconds...  " -NoNewline -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        Restart-Computer -Force
    }
    else {
        Write-Host ""
        Write-ColorOutput -Message "Please restart your computer manually to apply all changes" -Type Warning
        Pause-Menu
    }
}

# ============================================================
# VIEW OPTIMIZATION PROFILE
# ============================================================

function Show-OptimizationProfile {
    Clear-Host
    Show-OptimizerBanner

    $Profile = Get-OptimizationProfile

    Write-Host "  OPTIMIZATION PROFILE DETAILS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  Profile Name:    " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.Name)" -ForegroundColor Yellow

    Write-Host "  Description:     " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.Description)" -ForegroundColor White

    Write-Host ""
    Write-Host "  System Specifications:" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray
    Write-Host "  RAM:             " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.RAM_GB) GB" -ForegroundColor White
    Write-Host "  CPU Cores:       " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.CPU_Cores)" -ForegroundColor White
    Write-Host "  Is Ryzen:        " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.IsRyzen)" -ForegroundColor $(if ($Profile.IsRyzen) { "Green" } else { "Gray" })
    Write-Host "  Is Intel:        " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.IsIntel)" -ForegroundColor $(if ($Profile.IsIntel) { "Green" } else { "Gray" })
    Write-Host "  Is NVIDIA:       " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.IsNVIDIA)" -ForegroundColor $(if ($Profile.IsNVIDIA) { "Green" } else { "Gray" })
    Write-Host "  Has NVMe:        " -NoNewline -ForegroundColor Gray
    Write-Host "$($Profile.HasNVMe)" -ForegroundColor $(if ($Profile.HasNVMe) { "Green" } else { "Gray" })

    Write-Host ""
    Write-Host "  Optimization Settings:" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray

    $Settings = @(
        @{ Name = "Page File Size (MB)"; Value = $Profile.PageFileSize }
        @{ Name = "Disable Visual Effects"; Value = $Profile.DisableVisualEffects }
        @{ Name = "Disable Superfetch"; Value = $Profile.DisableSuperfetch }
        @{ Name = "Disable Hibernation"; Value = $Profile.DisableHibernation }
        @{ Name = "Disable Power Throttling"; Value = $Profile.DisablePowerThrottling }
        @{ Name = "Enable Game Mode"; Value = $Profile.EnableGameMode }
        @{ Name = "Enable HAGS"; Value = $Profile.EnableHAGS }
        @{ Name = "Optimize for Gaming"; Value = $Profile.OptimizeForGaming }
        @{ Name = "Aggressive Memory Mgmt"; Value = $Profile.AggressiveMemoryManagement }
        @{ Name = "Disable Telemetry"; Value = $Profile.DisableTelemetry }
    )

    foreach ($Setting in $Settings) {
        Write-Host "  $($Setting.Name): " -NoNewline -ForegroundColor Gray

        $DisplayValue = if ($Setting.Value -is [bool]) {
            if ($Setting.Value) { "Yes" } else { "No" }
        }
        else {
            $Setting.Value
        }

        $Color = if ($Setting.Value -is [bool]) {
            if ($Setting.Value) { 'Green' } else { 'Gray' }
        }
        else {
            'White'
        }

        Write-Host "$DisplayValue" -ForegroundColor $Color
    }

    Write-Host ""
}

# ============================================================
# HELPER FUNCTION
# ============================================================

function Pause-Menu {
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ============================================================
# EXPORT
# ============================================================

Export-ModuleMember -Function Show-OptimizerMenu -ErrorAction SilentlyContinue
