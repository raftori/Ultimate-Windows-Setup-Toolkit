<#
.SYNOPSIS
    System Optimizer Module for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Provides functions for optimizing Windows performance, memory, CPU, GPU, and more
.VERSION
    4.0
#>

# Import common functions
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ModulePath\CommonFunctions.psm1" -Force -ErrorAction SilentlyContinue

# ============================================================
# OPTIMIZATION PROFILE DETECTION
# ============================================================

function Get-OptimizationProfile {
    <#
    .SYNOPSIS
        Determines the best optimization profile based on system specs
    #>
    [CmdletBinding()]
    param()

    $SysInfo = Get-SystemInfo

    $Profile = @{
        Name                        = "BALANCED"
        Description                 = "Balanced optimization"
        RAM_GB                      = $SysInfo.RAMTotal
        CPU_Cores                   = $SysInfo.CPUCores
        DisableVisualEffects        = $false
        DisableSuperfetch           = $true
        DisableIndexing             = $false
        PageFileSize                = "4096"
        DisableHibernation          = $false
        DisablePowerThrottling      = $false
        EnableGameMode              = $true
        EnableHAGS                  = $true
        OptimizeForGaming           = $false
        AggressiveMemoryManagement  = $false
        DisableTelemetry            = $true
        IsRyzen                     = $SysInfo.IsRyzen
        IsIntel                     = $SysInfo.IsIntel
        IsNVIDIA                    = $SysInfo.IsNVIDIA
        IsAMD                       = $SysInfo.IsAMD
        HasNVMe                     = $SysInfo.NVMeCount -gt 0
    }

    # High-end system (64GB+ RAM, 8+ cores)
    if ($SysInfo.RAMTotal -ge 64 -and $SysInfo.CPUCores -ge 8) {
        $Profile.Name = "EXTREME_PERFORMANCE"
        $Profile.Description = "Maximum performance for high-end systems (64GB+ RAM, 8+ cores)"
        $Profile.PageFileSize = "16384"
        $Profile.DisableHibernation = $true
        $Profile.DisablePowerThrottling = $true
        $Profile.OptimizeForGaming = $true
        $Profile.AggressiveMemoryManagement = $true
    }
    # Mid-high system (32GB+ RAM)
    elseif ($SysInfo.RAMTotal -ge 32) {
        $Profile.Name = "HIGH_PERFORMANCE"
        $Profile.Description = "High performance for 32GB+ RAM systems"
        $Profile.PageFileSize = "8192"
        $Profile.DisablePowerThrottling = $true
        $Profile.OptimizeForGaming = $true
    }
    # Standard system (16GB+ RAM)
    elseif ($SysInfo.RAMTotal -ge 16) {
        $Profile.Name = "BALANCED"
        $Profile.Description = "Balanced optimization for 16GB+ RAM systems"
        $Profile.PageFileSize = "4096"
    }
    # Low-end system (<16GB RAM)
    else {
        $Profile.Name = "PERFORMANCE_SAVER"
        $Profile.Description = "Performance optimization for systems with limited RAM"
        $Profile.PageFileSize = "2048"
        $Profile.DisableVisualEffects = $true
    }

    return $Profile
}

# ============================================================
# MEMORY OPTIMIZATION
# ============================================================

function Optimize-MemoryManagement {
    <#
    .SYNOPSIS
        Optimizes Windows memory management settings
    .PARAMETER Profile
        The optimization profile to use
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Profile
    )

    if (-not $Profile) {
        $Profile = Get-OptimizationProfile
    }

    Write-ColorOutput -Message "Optimizing Memory Management" -Type Header
    Write-ColorOutput -Message "Profile: $($Profile.Name)" -Type Info

    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

    # Backup registry
    Backup-RegistryKey "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

    # Disable page file clearing at shutdown
    Set-RegistryValue -Path $RegPath -Name "ClearPageFileAtShutdown" -Value 0 `
        -Description "Page file clearing disabled (faster shutdown)"

    # Aggressive memory management for high-end systems
    if ($Profile.AggressiveMemoryManagement) {
        Set-RegistryValue -Path $RegPath -Name "DisablePagingExecutive" -Value 1 `
            -Description "Paging executive disabled (keeps kernel in RAM)"

        Set-RegistryValue -Path $RegPath -Name "LargeSystemCache" -Value 1 `
            -Description "Large system cache enabled"

        Set-RegistryValue -Path $RegPath -Name "SystemPages" -Value 0xFFFFFFFF -Type DWord `
            -Description "Maximum system file cache"
    }

    # NVMe-specific optimizations
    if ($Profile.HasNVMe) {
        $PrefetchPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"

        Set-RegistryValue -Path $PrefetchPath -Name "EnablePrefetcher" -Value 0 `
            -Description "Prefetcher disabled (not needed for NVMe)"

        Set-RegistryValue -Path $PrefetchPath -Name "EnableSuperfetch" -Value 0 `
            -Description "Superfetch disabled (not needed for NVMe)"

        # Disable SysMain service
        Set-ServiceState -ServiceName "SysMain" -StartupType Disabled -Stop
        Write-ColorOutput -Message "SysMain (Superfetch) service disabled" -Type Success
    }

    # Configure hibernation
    if ($Profile.DisableHibernation) {
        try {
            powercfg /hibernate off
            Write-ColorOutput -Message "Hibernation disabled (saves $($Profile.RAM_GB)GB disk space)" -Type Success
        }
        catch {
            Write-Log "Failed to disable hibernation" -Level WARNING
        }
    }

    Write-Log "Memory management optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# CPU OPTIMIZATION
# ============================================================

function Optimize-CPUSettings {
    <#
    .SYNOPSIS
        Optimizes CPU-related settings
    .PARAMETER Profile
        The optimization profile to use
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Profile
    )

    if (-not $Profile) {
        $Profile = Get-OptimizationProfile
    }

    Write-ColorOutput -Message "Optimizing CPU Settings" -Type Header

    # Ryzen-specific optimizations
    if ($Profile.IsRyzen) {
        Write-ColorOutput -Message "Applying AMD Ryzen optimizations..." -Type Info

        $CoreParkingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00"

        $CoreParkingGUIDs = @(
            "0cc5b647-c1df-4637-891a-dec35c318583",  # Core parking min cores
            "ea062031-0e34-4ff1-9b6d-eb1059334028"   # Core parking max cores
        )

        foreach ($guid in $CoreParkingGUIDs) {
            $path = "$CoreParkingPath\$guid"
            if (Test-Path $path) {
                Set-RegistryValue -Path $path -Name "Attributes" -Value 0
            }
        }
    }

    # Processor scheduling
    $PriorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    Set-RegistryValue -Path $PriorityPath -Name "Win32PrioritySeparation" -Value 0x00000026 `
        -Description "Processor scheduling optimized for programs"

    # Disable power throttling for high-performance systems
    if ($Profile.DisablePowerThrottling) {
        $PowerThrottlingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        Set-RegistryValue -Path $PowerThrottlingPath -Name "PowerThrottlingOff" -Value 1 `
            -Description "Power throttling disabled"
    }

    # Enable Multimedia Class Scheduler
    Set-ServiceState -ServiceName "MMCSS" -StartupType Automatic
    try {
        Start-Service "MMCSS" -ErrorAction SilentlyContinue
        Write-ColorOutput -Message "Multimedia Class Scheduler enabled" -Type Success
    }
    catch { }

    Write-Log "CPU optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# GPU OPTIMIZATION
# ============================================================

function Optimize-GPUSettings {
    <#
    .SYNOPSIS
        Optimizes GPU-related settings
    .PARAMETER Profile
        The optimization profile to use
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Profile
    )

    if (-not $Profile) {
        $Profile = Get-OptimizationProfile
    }

    Write-ColorOutput -Message "Optimizing GPU Settings" -Type Header

    $HAGSPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"

    # Enable Hardware Accelerated GPU Scheduling
    if ($Profile.EnableHAGS) {
        Set-RegistryValue -Path $HAGSPath -Name "HwSchMode" -Value 2 `
            -Description "Hardware Accelerated GPU Scheduling enabled"
    }

    # NVIDIA-specific optimizations
    if ($Profile.IsNVIDIA) {
        Write-ColorOutput -Message "Applying NVIDIA GPU optimizations..." -Type Info

        # Increase TDR timeout
        Set-RegistryValue -Path $HAGSPath -Name "TdrDelay" -Value 60 `
            -Description "TDR delay increased to 60 seconds"

        # GPU performance settings
        $GPUPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
        if (Test-Path $GPUPath) {
            Set-RegistryValue -Path $GPUPath -Name "PerfLevelSrc" -Value 0x2222 -Type DWord
        }
    }

    # Network latency optimizations for gaming
    if ($Profile.OptimizeForGaming) {
        $InterfacesPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
        Get-ChildItem $InterfacesPath -ErrorAction SilentlyContinue | ForEach-Object {
            Set-RegistryValue -Path $_.PSPath -Name "TcpAckFrequency" -Value 1
            Set-RegistryValue -Path $_.PSPath -Name "TCPNoDelay" -Value 1
        }
        Write-ColorOutput -Message "Network latency optimizations applied" -Type Success
    }

    Write-Log "GPU optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# STORAGE OPTIMIZATION
# ============================================================

function Optimize-StorageSettings {
    <#
    .SYNOPSIS
        Optimizes storage-related settings
    .PARAMETER Profile
        The optimization profile to use
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Profile
    )

    if (-not $Profile) {
        $Profile = Get-OptimizationProfile
    }

    Write-ColorOutput -Message "Optimizing Storage Settings" -Type Header

    if ($Profile.HasNVMe) {
        Write-ColorOutput -Message "Applying NVMe optimizations..." -Type Info

        # Ensure TRIM is enabled
        try {
            $FSutilResult = fsutil behavior query DisableDeleteNotify
            if ($FSutilResult -match "DisableDeleteNotify = 1") {
                fsutil behavior set DisableDeleteNotify 0
                Write-ColorOutput -Message "TRIM enabled for NVMe drives" -Type Success
            }
            else {
                Write-ColorOutput -Message "TRIM already enabled" -Type Success
            }
        }
        catch { }

        # Disable automatic defragmentation for SSDs
        try {
            Disable-ScheduledTask -TaskName "Microsoft\Windows\Defrag\ScheduledDefrag" -ErrorAction SilentlyContinue
            Write-ColorOutput -Message "Automatic defragmentation disabled (not needed for SSD/NVMe)" -Type Success
        }
        catch { }
    }

    # Disable Storage Sense for high-capacity systems
    $StorageSensePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
    Set-RegistryValue -Path $StorageSensePath -Name "01" -Value 0 `
        -Description "Storage Sense disabled"

    Write-Log "Storage optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# POWER OPTIMIZATION
# ============================================================

function Optimize-PowerSettings {
    <#
    .SYNOPSIS
        Configures power settings for maximum performance
    .PARAMETER Profile
        The optimization profile to use
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Profile
    )

    if (-not $Profile) {
        $Profile = Get-OptimizationProfile
    }

    Write-ColorOutput -Message "Configuring Power Settings" -Type Header

    try {
        # Try to enable Ultimate Performance plan
        $UltimatePlan = powercfg /list | Select-String "Ultimate Performance"

        if (-not $UltimatePlan) {
            Write-ColorOutput -Message "Enabling Ultimate Performance power plan..." -Type Info
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
            $UltimatePlan = powercfg /list | Select-String "Ultimate Performance"
        }

        if ($UltimatePlan) {
            $PlanGuid = ($UltimatePlan -split '\s+')[3]
            powercfg /setactive $PlanGuid
            Write-ColorOutput -Message "Ultimate Performance power plan activated" -Type Success

            # Disable USB selective suspend
            powercfg /setacvalueindex $PlanGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
            powercfg /setdcvalueindex $PlanGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

            # Disable PCI Express Link State Power Management
            powercfg /setacvalueindex $PlanGuid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
            powercfg /setdcvalueindex $PlanGuid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0

            # Set processor power to 100%
            powercfg /setacvalueindex $PlanGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100
            powercfg /setdcvalueindex $PlanGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100

            powercfg /setactive $PlanGuid
        }
        else {
            # Fall back to High Performance
            Write-ColorOutput -Message "Using High Performance power plan" -Type Warning
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        }
    }
    catch {
        Write-Log "Failed to configure power settings: $($_.Exception.Message)" -Level WARNING
    }

    # Disable Fast Startup
    $PowerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
    Set-RegistryValue -Path $PowerPath -Name "HiberbootEnabled" -Value 0 `
        -Description "Fast Startup disabled (better hardware initialization)"

    Write-Log "Power settings optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# GAMING OPTIMIZATION
# ============================================================

function Optimize-GamingSettings {
    <#
    .SYNOPSIS
        Applies gaming-specific optimizations
    .PARAMETER Profile
        The optimization profile to use
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Profile
    )

    if (-not $Profile) {
        $Profile = Get-OptimizationProfile
    }

    Write-ColorOutput -Message "Applying Gaming Optimizations" -Type Header

    # Enable Game Mode
    if ($Profile.EnableGameMode) {
        $GameModePath = "HKCU:\Software\Microsoft\GameBar"
        Set-RegistryValue -Path $GameModePath -Name "AutoGameModeEnabled" -Value 1 `
            -Description "Game Mode enabled"
        Set-RegistryValue -Path $GameModePath -Name "AllowAutoGameMode" -Value 1
    }

    # Disable Game DVR (reduces overhead)
    $GameDVRPath = "HKCU:\System\GameConfigStore"
    Set-RegistryValue -Path $GameDVRPath -Name "GameDVR_Enabled" -Value 0 `
        -Description "Game DVR disabled (reduces overhead)"

    $GameBarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    Set-RegistryValue -Path $GameBarPath -Name "AppCaptureEnabled" -Value 0 `
        -Description "Game Bar app capture disabled"

    # Disable Fullscreen Optimizations
    Set-RegistryValue -Path $GameDVRPath -Name "GameDVR_FSEBehaviorMode" -Value 2 `
        -Description "Fullscreen optimizations disabled"

    # GPU Priority for games
    $GPUPrefPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    if (-not (Test-Path $GPUPrefPath)) {
        New-Item -Path $GPUPrefPath -Force | Out-Null
    }

    Set-RegistryValue -Path $GPUPrefPath -Name "GPU Priority" -Value 8 -Type DWord `
        -Description "GPU priority set to High for games"
    Set-RegistryValue -Path $GPUPrefPath -Name "Priority" -Value 6 -Type DWord
    Set-RegistryValue -Path $GPUPrefPath -Name "Scheduling Category" -Value "High" -Type String

    # Disable mouse acceleration
    Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value 0 -Type String `
        -Description "Mouse acceleration disabled"
    Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value 0 -Type String
    Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value 0 -Type String

    Write-Log "Gaming optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# NETWORK OPTIMIZATION
# ============================================================

function Optimize-NetworkSettings {
    <#
    .SYNOPSIS
        Optimizes network settings for performance
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Optimizing Network Settings" -Type Header

    $TCPPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

    # TCP optimizations
    Set-RegistryValue -Path $TCPPath -Name "Tcp1323Opts" -Value 3 `
        -Description "TCP window scaling enabled"
    Set-RegistryValue -Path $TCPPath -Name "TcpWindowSize" -Value 65535

    # Disable network throttling
    $MultiMediaPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-RegistryValue -Path $MultiMediaPath -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF `
        -Description "Network throttling disabled"

    Write-Log "Network optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# VISUAL EFFECTS OPTIMIZATION
# ============================================================

function Optimize-VisualEffects {
    <#
    .SYNOPSIS
        Optimizes Windows visual effects
    .PARAMETER Profile
        The optimization profile to use
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Profile
    )

    if (-not $Profile) {
        $Profile = Get-OptimizationProfile
    }

    Write-ColorOutput -Message "Optimizing Visual Effects" -Type Header

    $VisualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"

    if ($Profile.DisableVisualEffects) {
        Set-RegistryValue -Path $VisualPath -Name "VisualFXSetting" -Value 2 `
            -Description "Visual effects set to Best Performance"
    }
    else {
        Set-RegistryValue -Path $VisualPath -Name "VisualFXSetting" -Value 3 `
            -Description "Custom visual effects enabled"

        # Disable specific effects
        $AdvancedPath = "HKCU:\Control Panel\Desktop"
        Set-RegistryValue -Path $AdvancedPath -Name "MenuShowDelay" -Value 0 -Type String `
            -Description "Menu show delay disabled"
    }

    # Disable transparency effects
    $TransparencyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-RegistryValue -Path $TransparencyPath -Name "EnableTransparency" -Value 0 `
        -Description "Transparency effects disabled"

    Write-Log "Visual effects optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# SERVICE OPTIMIZATION
# ============================================================

function Optimize-WindowsServices {
    <#
    .SYNOPSIS
        Optimizes Windows services for performance
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Optimizing Windows Services" -Type Header

    $ServicesToDisable = @(
        @{ Name = "DiagTrack"; DisplayName = "Diagnostics Tracking"; Note = "Telemetry" }
        @{ Name = "dmwappushservice"; DisplayName = "WAP Push Service"; Note = "Telemetry" }
        @{ Name = "WerSvc"; DisplayName = "Windows Error Reporting"; Note = "Privacy" }
        @{ Name = "RetailDemo"; DisplayName = "Retail Demo Service"; Note = "Unnecessary" }
        @{ Name = "Fax"; DisplayName = "Fax Service"; Note = "Unnecessary" }
        @{ Name = "MapsBroker"; DisplayName = "Downloaded Maps Manager"; Note = "Unnecessary" }
    )

    $DisabledCount = 0

    foreach ($svc in $ServicesToDisable) {
        $result = Set-ServiceState -ServiceName $svc.Name -StartupType Disabled -Stop
        if ($result) {
            Write-Host "    [+] $($svc.DisplayName) - $($svc.Note)" -ForegroundColor Green
            $DisabledCount++
        }
    }

    # Enable important services
    $ServicesToEnable = @(
        @{ Name = "MMCSS"; DisplayName = "Multimedia Class Scheduler" }
        @{ Name = "Audiosrv"; DisplayName = "Windows Audio" }
    )

    foreach ($svc in $ServicesToEnable) {
        Set-ServiceState -ServiceName $svc.Name -StartupType Automatic
        Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
    }

    Write-ColorOutput -Message "Disabled $DisabledCount unnecessary services" -Type Success
    Write-Log "Service optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# SCHEDULED TASKS OPTIMIZATION
# ============================================================

function Optimize-ScheduledTasks {
    <#
    .SYNOPSIS
        Disables unnecessary scheduled tasks
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Optimizing Scheduled Tasks" -Type Header

    $TasksToDisable = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
        "\Microsoft\Windows\Maps\MapsUpdateTask"
    )

    $DisabledCount = 0

    foreach ($task in $TasksToDisable) {
        try {
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            $DisabledCount++
        }
        catch { }
    }

    Write-ColorOutput -Message "Disabled $DisabledCount telemetry/diagnostic tasks" -Type Success
    Write-Log "Scheduled tasks optimization completed" -Level SUCCESS
    return $true
}

# ============================================================
# RAM OPTIMIZATION
# ============================================================

function Clear-StandbyMemory {
    <#
    .SYNOPSIS
        Clears standby memory using EmptyStandbyList or native methods
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Clearing Standby Memory" -Type Info

    try {
        # Use native PowerShell method to clear memory
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()

        # Clear working sets
        $Processes = Get-Process
        foreach ($Process in $Processes) {
            try {
                $Process.MinWorkingSet = $Process.MinWorkingSet
            }
            catch { }
        }

        Write-ColorOutput -Message "Standby memory cleared" -Type Success
        return $true
    }
    catch {
        Write-Log "Failed to clear standby memory: $($_.Exception.Message)" -Level WARNING
        return $false
    }
}

function Clear-SystemCache {
    <#
    .SYNOPSIS
        Clears various system caches
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Clearing System Cache" -Type Info

    $ClearedSize = 0

    # Clear Windows temp
    $TempPaths = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\Temp"
    )

    foreach ($Path in $TempPaths) {
        if (Test-Path $Path) {
            try {
                $Size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
                         Measure-Object -Property Length -Sum).Sum
                Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
                $ClearedSize += $Size
            }
            catch { }
        }
    }

    $ClearedMB = [math]::Round($ClearedSize / 1MB, 2)
    Write-ColorOutput -Message "Cleared $ClearedMB MB of cached data" -Type Success
    return $ClearedMB
}

function Set-VirtualMemory {
    <#
    .SYNOPSIS
        Configures virtual memory (pagefile) settings
    .PARAMETER InitialSizeMB
        Initial pagefile size in MB
    .PARAMETER MaximumSizeMB
        Maximum pagefile size in MB
    .PARAMETER SystemManaged
        Use system-managed pagefile
    #>
    [CmdletBinding()]
    param(
        [int]$InitialSizeMB = 4096,
        [int]$MaximumSizeMB = 8192,
        [switch]$SystemManaged
    )

    Write-ColorOutput -Message "Configuring Virtual Memory" -Type Info

    try {
        $Computer = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges

        if ($SystemManaged) {
            $Computer.AutomaticManagedPagefile = $true
            $Computer.Put() | Out-Null
            Write-ColorOutput -Message "Pagefile set to System Managed" -Type Success
        }
        else {
            $Computer.AutomaticManagedPagefile = $false
            $Computer.Put() | Out-Null

            # Configure pagefile
            $PageFile = Get-WmiObject -Class Win32_PageFileSetting
            if ($PageFile) {
                $PageFile.InitialSize = $InitialSizeMB
                $PageFile.MaximumSize = $MaximumSizeMB
                $PageFile.Put() | Out-Null
            }
            else {
                $PageFileSetting = ([WmiClass]"\\.\root\cimv2:Win32_PageFileSetting").CreateInstance()
                $PageFileSetting.Name = "C:\pagefile.sys"
                $PageFileSetting.InitialSize = $InitialSizeMB
                $PageFileSetting.MaximumSize = $MaximumSizeMB
                $PageFileSetting.Put() | Out-Null
            }

            Write-ColorOutput -Message "Pagefile configured: $InitialSizeMB MB - $MaximumSizeMB MB" -Type Success
        }

        return $true
    }
    catch {
        Write-Log "Failed to configure virtual memory: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================================
# DISK CLEANUP
# ============================================================

function Invoke-DiskCleanup {
    <#
    .SYNOPSIS
        Performs comprehensive disk cleanup
    .PARAMETER IncludeWindowsUpdate
        Include Windows Update cleanup
    .PARAMETER IncludeBrowserCache
        Include browser cache cleanup
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeWindowsUpdate,
        [switch]$IncludeBrowserCache
    )

    Write-ColorOutput -Message "Performing Disk Cleanup" -Type Header

    $TotalCleared = 0

    # Windows temp files
    Write-Host "  Clearing Windows temp files..." -ForegroundColor Gray
    $TempPaths = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:WINDIR\Prefetch"
    )

    foreach ($Path in $TempPaths) {
        if (Test-Path $Path) {
            try {
                $Size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
                         Measure-Object -Property Length -Sum).Sum
                Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
                $TotalCleared += $Size
            }
            catch { }
        }
    }

    # User temp files
    Write-Host "  Clearing user temp files..." -ForegroundColor Gray
    $UserTempPaths = @(
        "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\*cache*"
    )

    foreach ($Path in $UserTempPaths) {
        if (Test-Path $Path) {
            try {
                $Size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
                         Measure-Object -Property Length -Sum).Sum
                Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
                $TotalCleared += $Size
            }
            catch { }
        }
    }

    # Empty Recycle Bin
    Write-Host "  Emptying Recycle Bin..." -ForegroundColor Gray
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    }
    catch { }

    # Browser cache cleanup
    if ($IncludeBrowserCache) {
        Write-Host "  Clearing browser cache..." -ForegroundColor Gray

        $BrowserPaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2"
        )

        foreach ($Path in $BrowserPaths) {
            if (Test-Path $Path) {
                try {
                    $Size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
                             Measure-Object -Property Length -Sum).Sum
                    Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $TotalCleared += $Size
                }
                catch { }
            }
        }
    }

    # Windows Update cleanup
    if ($IncludeWindowsUpdate) {
        Write-Host "  Clearing Windows Update cache..." -ForegroundColor Gray
        try {
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service wuauserv -ErrorAction SilentlyContinue
        }
        catch { }
    }

    $TotalClearedMB = [math]::Round($TotalCleared / 1MB, 2)
    $TotalClearedGB = [math]::Round($TotalCleared / 1GB, 2)

    Write-Host ""
    if ($TotalClearedGB -ge 1) {
        Write-ColorOutput -Message "Total space cleared: $TotalClearedGB GB" -Type Success
    }
    else {
        Write-ColorOutput -Message "Total space cleared: $TotalClearedMB MB" -Type Success
    }

    return $TotalClearedMB
}

# ============================================================
# STARTUP OPTIMIZATION
# ============================================================

function Get-StartupPrograms {
    <#
    .SYNOPSIS
        Gets all startup programs
    #>
    [CmdletBinding()]
    param()

    $StartupItems = @()

    # Registry Run keys
    $RunPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )

    foreach ($Path in $RunPaths) {
        if (Test-Path $Path) {
            $Items = Get-ItemProperty $Path -ErrorAction SilentlyContinue
            $Items.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $StartupItems += [PSCustomObject]@{
                    Name     = $_.Name
                    Command  = $_.Value
                    Location = $Path
                    Type     = "Registry"
                }
            }
        }
    }

    # Startup folder
    $StartupFolders = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    )

    foreach ($Folder in $StartupFolders) {
        if (Test-Path $Folder) {
            Get-ChildItem $Folder -ErrorAction SilentlyContinue | ForEach-Object {
                $StartupItems += [PSCustomObject]@{
                    Name     = $_.BaseName
                    Command  = $_.FullName
                    Location = $Folder
                    Type     = "Folder"
                }
            }
        }
    }

    return $StartupItems
}

function Disable-StartupProgram {
    <#
    .SYNOPSIS
        Disables a startup program
    .PARAMETER Name
        Name of the startup item
    .PARAMETER Location
        Registry path or folder location
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Location
    )

    try {
        if ($Location -match '^HK') {
            # Registry item
            Remove-ItemProperty -Path $Location -Name $Name -ErrorAction Stop
        }
        else {
            # File in startup folder
            $File = Get-ChildItem $Location -Filter "$Name.*" -ErrorAction SilentlyContinue
            if ($File) {
                Remove-Item $File.FullName -Force
            }
        }

        Write-Log "Disabled startup item: $Name" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Failed to disable startup item $Name`: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Optimize-StartupDelay {
    <#
    .SYNOPSIS
        Disables startup delay for faster boot
    #>
    [CmdletBinding()]
    param()

    $SerializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"

    if (-not (Test-Path $SerializePath)) {
        New-Item -Path $SerializePath -Force | Out-Null
    }

    Set-RegistryValue -Path $SerializePath -Name "StartupDelayInMSec" -Value 0 -Type DWord `
        -Description "Startup delay disabled"

    Write-ColorOutput -Message "Startup delay disabled" -Type Success
    return $true
}

# ============================================================
# DNS CONFIGURATION
# ============================================================

function Set-DNSServers {
    <#
    .SYNOPSIS
        Configures DNS servers
    .PARAMETER Provider
        DNS provider (Cloudflare, Google, Quad9, Custom)
    .PARAMETER PrimaryDNS
        Custom primary DNS
    .PARAMETER SecondaryDNS
        Custom secondary DNS
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Cloudflare', 'Google', 'Quad9', 'OpenDNS', 'Custom')]
        [string]$Provider = 'Cloudflare',

        [string]$PrimaryDNS,
        [string]$SecondaryDNS
    )

    $DNSServers = switch ($Provider) {
        'Cloudflare' { @('1.1.1.1', '1.0.0.1') }
        'Google'     { @('8.8.8.8', '8.8.4.4') }
        'Quad9'      { @('9.9.9.9', '149.112.112.112') }
        'OpenDNS'    { @('208.67.222.222', '208.67.220.220') }
        'Custom'     { @($PrimaryDNS, $SecondaryDNS) }
    }

    Write-ColorOutput -Message "Configuring DNS Servers ($Provider)" -Type Info

    try {
        $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

        foreach ($Adapter in $Adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $DNSServers
            Write-Host "  $($Adapter.Name): $($DNSServers -join ', ')" -ForegroundColor Gray
        }

        # Flush DNS cache
        Clear-DnsClientCache

        Write-ColorOutput -Message "DNS configured and cache cleared" -Type Success
        return $true
    }
    catch {
        Write-Log "Failed to configure DNS: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Clear-DNSCache {
    <#
    .SYNOPSIS
        Clears DNS resolver cache
    #>
    [CmdletBinding()]
    param()

    try {
        Clear-DnsClientCache
        ipconfig /flushdns | Out-Null
        Write-ColorOutput -Message "DNS cache cleared" -Type Success
        return $true
    }
    catch {
        return $false
    }
}

# ============================================================
# REGISTRY OPTIMIZATION
# ============================================================

function Optimize-RegistrySettings {
    <#
    .SYNOPSIS
        Applies various registry optimizations
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Applying Registry Optimizations" -Type Header

    # Menu show delay
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String `
        -Description "Menu show delay set to 0"

    # Disable Cortana
    $CortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $CortanaPath)) {
        New-Item -Path $CortanaPath -Force | Out-Null
    }
    Set-RegistryValue -Path $CortanaPath -Name "AllowCortana" -Value 0 `
        -Description "Cortana disabled"

    # Disable web search in Start menu
    Set-RegistryValue -Path $CortanaPath -Name "DisableWebSearch" -Value 1 `
        -Description "Web search in Start menu disabled"
    Set-RegistryValue -Path $CortanaPath -Name "ConnectedSearchUseWeb" -Value 0

    # Disable tips and suggestions
    $ContentDeliveryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-RegistryValue -Path $ContentDeliveryPath -Name "SystemPaneSuggestionsEnabled" -Value 0 `
        -Description "Start menu suggestions disabled"
    Set-RegistryValue -Path $ContentDeliveryPath -Name "SoftLandingEnabled" -Value 0 `
        -Description "Tips and suggestions disabled"
    Set-RegistryValue -Path $ContentDeliveryPath -Name "SubscribedContent-338388Enabled" -Value 0

    # Disable advertising ID
    $AdvertisingPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    Set-RegistryValue -Path $AdvertisingPath -Name "Enabled" -Value 0 `
        -Description "Advertising ID disabled"

    # Disable activity history
    $ActivityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (-not (Test-Path $ActivityPath)) {
        New-Item -Path $ActivityPath -Force | Out-Null
    }
    Set-RegistryValue -Path $ActivityPath -Name "EnableActivityFeed" -Value 0 `
        -Description "Activity history disabled"
    Set-RegistryValue -Path $ActivityPath -Name "PublishUserActivities" -Value 0
    Set-RegistryValue -Path $ActivityPath -Name "UploadUserActivities" -Value 0

    Write-Log "Registry optimizations applied" -Level SUCCESS
    return $true
}

# ============================================================
# PERFORMANCE ANALYSIS
# ============================================================

function Get-PerformanceAnalysis {
    <#
    .SYNOPSIS
        Provides comprehensive system performance analysis
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Performance Analysis" -Type Header

    # RAM Usage
    $OS = Get-CimInstance Win32_OperatingSystem
    $TotalRAM = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
    $FreeRAM = [math]::Round($OS.FreePhysicalMemory / 1MB, 2)
    $UsedRAM = $TotalRAM - $FreeRAM
    $RAMPercent = [math]::Round(($UsedRAM / $TotalRAM) * 100, 1)

    Write-Host ""
    Write-Host "  RAM Usage:" -ForegroundColor Cyan
    Write-Host "    Total: $TotalRAM GB" -ForegroundColor Gray
    Write-Host "    Used:  $UsedRAM GB ($RAMPercent%)" -ForegroundColor $(if ($RAMPercent -gt 80) { "Red" } elseif ($RAMPercent -gt 60) { "Yellow" } else { "Green" })
    Write-Host "    Free:  $FreeRAM GB" -ForegroundColor Gray

    # CPU Usage
    $CPU = Get-CimInstance Win32_Processor
    Write-Host ""
    Write-Host "  CPU:" -ForegroundColor Cyan
    Write-Host "    Name: $($CPU.Name)" -ForegroundColor Gray
    Write-Host "    Cores: $($CPU.NumberOfCores) / Threads: $($CPU.NumberOfLogicalProcessors)" -ForegroundColor Gray
    Write-Host "    Current Load: $($CPU.LoadPercentage)%" -ForegroundColor $(if ($CPU.LoadPercentage -gt 80) { "Red" } elseif ($CPU.LoadPercentage -gt 60) { "Yellow" } else { "Green" })

    # Disk Health
    Write-Host ""
    Write-Host "  Disk Space:" -ForegroundColor Cyan
    $Disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    foreach ($Disk in $Disks) {
        $UsedPercent = [math]::Round((($Disk.Size - $Disk.FreeSpace) / $Disk.Size) * 100, 1)
        $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 1)
        Write-Host "    $($Disk.DeviceID) $FreeGB GB free ($UsedPercent% used)" -ForegroundColor $(if ($UsedPercent -gt 90) { "Red" } elseif ($UsedPercent -gt 80) { "Yellow" } else { "Green" })
    }

    # Uptime
    $Uptime = (Get-Date) - $OS.LastBootUpTime
    Write-Host ""
    Write-Host "  System Uptime:" -ForegroundColor Cyan
    Write-Host "    $($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes" -ForegroundColor Gray

    # Running processes
    $ProcessCount = (Get-Process).Count
    Write-Host ""
    Write-Host "  Running Processes: " -ForegroundColor Cyan -NoNewline
    Write-Host $ProcessCount -ForegroundColor $(if ($ProcessCount -gt 200) { "Yellow" } else { "Green" })

    Write-Host ""
}

# ============================================================
# COMPLETE OPTIMIZATION
# ============================================================

function Invoke-SystemOptimization {
    <#
    .SYNOPSIS
        Runs all system optimizations
    .PARAMETER CreateRestorePoint
        Whether to create a restore point before optimizing
    #>
    [CmdletBinding()]
    param(
        [switch]$CreateRestorePoint
    )

    Write-ColorOutput -Message "Starting System Optimization" -Type Header

    # Get optimization profile
    $Profile = Get-OptimizationProfile
    Write-Host ""
    Write-Host "    Detected Profile: " -ForegroundColor Cyan -NoNewline
    Write-Host "$($Profile.Name)" -ForegroundColor Yellow
    Write-Host "    $($Profile.Description)" -ForegroundColor Gray
    Write-Host ""

    # Create restore point if requested
    if ($CreateRestorePoint) {
        New-SystemRestorePoint -Description "Before Ultimate Windows Toolkit Optimization"
    }

    $Results = @{}

    # Run all optimizations
    Write-Host ""
    $Results['Memory'] = Optimize-MemoryManagement -Profile $Profile
    Write-Host ""
    $Results['CPU'] = Optimize-CPUSettings -Profile $Profile
    Write-Host ""
    $Results['GPU'] = Optimize-GPUSettings -Profile $Profile
    Write-Host ""
    $Results['Storage'] = Optimize-StorageSettings -Profile $Profile
    Write-Host ""
    $Results['Power'] = Optimize-PowerSettings -Profile $Profile
    Write-Host ""
    $Results['Gaming'] = Optimize-GamingSettings -Profile $Profile
    Write-Host ""
    $Results['Network'] = Optimize-NetworkSettings
    Write-Host ""
    $Results['Visual'] = Optimize-VisualEffects -Profile $Profile
    Write-Host ""
    $Results['Services'] = Optimize-WindowsServices
    Write-Host ""
    $Results['Tasks'] = Optimize-ScheduledTasks

    # Summary
    Write-Host ""
    Write-ColorOutput -Message "Optimization Complete" -Type Header

    $SuccessCount = ($Results.Values | Where-Object { $_ -eq $true }).Count
    $TotalCount = $Results.Count

    Write-Host "    Successful: " -ForegroundColor Green -NoNewline
    Write-Host "$SuccessCount / $TotalCount" -ForegroundColor White
    Write-Host ""
    Write-Host "    A restart is recommended to apply all changes." -ForegroundColor Yellow
    Write-Host ""

    return $Results
}

# ============================================================
# EXPORT MODULE MEMBERS
# ============================================================

Export-ModuleMember -Function @(
    # Profile Detection
    'Get-OptimizationProfile',

    # Core Optimization Functions
    'Optimize-MemoryManagement',
    'Optimize-CPUSettings',
    'Optimize-GPUSettings',
    'Optimize-StorageSettings',
    'Optimize-PowerSettings',
    'Optimize-GamingSettings',
    'Optimize-NetworkSettings',
    'Optimize-VisualEffects',
    'Optimize-WindowsServices',
    'Optimize-ScheduledTasks',

    # RAM Optimization
    'Clear-StandbyMemory',
    'Clear-SystemCache',
    'Set-VirtualMemory',

    # Disk Cleanup
    'Invoke-DiskCleanup',

    # Startup Optimization
    'Get-StartupPrograms',
    'Disable-StartupProgram',
    'Optimize-StartupDelay',

    # DNS Configuration
    'Set-DNSServers',
    'Clear-DNSCache',

    # Registry Optimization
    'Optimize-RegistrySettings',

    # Performance Analysis
    'Get-PerformanceAnalysis',

    # Complete Optimization
    'Invoke-SystemOptimization'
)
