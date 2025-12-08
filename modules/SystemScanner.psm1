#Requires -Version 5.1
<#
.SYNOPSIS
    System Scanner & Hardware Profiler Module
.DESCRIPTION
    Comprehensive system hardware profiling module that detects all hardware
    components and returns a profile object used by other modules to adapt
    their behavior for safe, optimal configurations.
.NOTES
    Part of Ultimate Windows Setup Toolkit v4.0
#>

#region CPU Profiler

function Get-CPUProfile {
    <#
    .SYNOPSIS
        Detects CPU specifications and capabilities
    .OUTPUTS
        PSCustomObject with CPU profile
    #>

    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop

        return [PSCustomObject]@{
            Name              = $cpu.Name.Trim()
            Manufacturer      = $cpu.Manufacturer
            Cores             = $cpu.NumberOfCores
            LogicalProcessors = $cpu.NumberOfLogicalProcessors
            MaxClockSpeedMHz  = $cpu.MaxClockSpeed
            CurrentClockMHz   = $cpu.CurrentClockSpeed
            L2CacheKB         = $cpu.L2CacheSize
            L3CacheKB         = $cpu.L3CacheSize
            Architecture      = switch ($cpu.Architecture) {
                0 { "x86" }
                9 { "x64" }
                12 { "ARM64" }
                default { "Unknown" }
            }
            VirtualizationEnabled = $cpu.VirtualizationFirmwareEnabled
            Socket            = $cpu.SocketDesignation
            # Performance classification
            IsHighEnd         = ($cpu.NumberOfCores -ge 8 -and $cpu.MaxClockSpeed -ge 3000)
            IsMidRange        = ($cpu.NumberOfCores -ge 4 -and $cpu.NumberOfCores -lt 8)
            IsLowEnd          = ($cpu.NumberOfCores -lt 4)
            SupportsHyperV    = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue).HypervisorPresent
        }
    }
    catch {
        Write-Log "Error getting CPU profile: $($_.Exception.Message)" -Level ERROR
        return [PSCustomObject]@{
            Name              = "Unknown"
            Manufacturer      = "Unknown"
            Cores             = 1
            LogicalProcessors = 1
            MaxClockSpeedMHz  = 0
            CurrentClockMHz   = 0
            L2CacheKB         = 0
            L3CacheKB         = 0
            Architecture      = "Unknown"
            VirtualizationEnabled = $false
            Socket            = "Unknown"
            IsHighEnd         = $false
            IsMidRange        = $false
            IsLowEnd          = $true
            SupportsHyperV    = $false
        }
    }
}

#endregion

#region RAM Profiler

function Get-RAMProfile {
    <#
    .SYNOPSIS
        Detects RAM specifications and usage
    .OUTPUTS
        PSCustomObject with RAM profile
    #>

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $ram = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue

        $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedRAM = $totalRAM - $freeRAM

        $slots = @()
        if ($ram) {
            $slots = $ram | ForEach-Object {
                [PSCustomObject]@{
                    Bank       = $_.BankLabel
                    CapacityGB = [math]::Round($_.Capacity / 1GB, 2)
                    SpeedMHz   = $_.Speed
                    Type       = switch ($_.SMBIOSMemoryType) {
                        20 { "DDR" }
                        21 { "DDR2" }
                        24 { "DDR3" }
                        26 { "DDR4" }
                        34 { "DDR5" }
                        default { "Unknown" }
                    }
                    Manufacturer = $_.Manufacturer
                }
            }
        }

        $pageFile = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue
        $pageFileGB = if ($pageFile) { [math]::Round($pageFile.AllocatedBaseSize / 1024, 2) } else { 0 }

        return [PSCustomObject]@{
            TotalGB           = $totalRAM
            FreeGB            = $freeRAM
            UsedGB            = $usedRAM
            UsagePercent      = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
            SlotCount         = ($ram | Measure-Object).Count
            Slots             = $slots
            # Performance classification
            IsHighRAM         = ($totalRAM -ge 32)
            IsMidRAM          = ($totalRAM -ge 16 -and $totalRAM -lt 32)
            IsLowRAM          = ($totalRAM -lt 16)
            PageFileGB        = $pageFileGB
        }
    }
    catch {
        Write-Log "Error getting RAM profile: $($_.Exception.Message)" -Level ERROR
        return [PSCustomObject]@{
            TotalGB           = 0
            FreeGB            = 0
            UsedGB            = 0
            UsagePercent      = 0
            SlotCount         = 0
            Slots             = @()
            IsHighRAM         = $false
            IsMidRAM          = $false
            IsLowRAM          = $true
            PageFileGB        = 0
        }
    }
}

#endregion

#region Storage Profiler

function Get-StorageProfile {
    <#
    .SYNOPSIS
        Detects storage devices and volumes
    .OUTPUTS
        PSCustomObject with storage profile
    #>

    try {
        $disks = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction Stop
        $volumes = Get-CimInstance -ClassName Win32_LogicalDisk -ErrorAction SilentlyContinue |
                   Where-Object { $_.DriveType -eq 3 }

        $physicalDisks = @()
        foreach ($disk in $disks) {
            $diskNumber = $disk.Index
            $partStyle = $null
            try {
                $partStyle = (Get-Disk -Number $diskNumber -ErrorAction SilentlyContinue).PartitionStyle
            }
            catch { }

            $isNVMe = ($disk.Model -match "NVMe" -or $disk.PNPDeviceID -match "NVME")
            $isSSD = ($disk.MediaType -match "SSD" -or $disk.Model -match "SSD|NVMe")

            $physicalDisks += [PSCustomObject]@{
                Model          = $disk.Model.Trim()
                SizeGB         = [math]::Round($disk.Size / 1GB, 2)
                MediaType      = if ($isNVMe) { "NVMe SSD" }
                                elseif ($isSSD) { "SSD" }
                                elseif ($disk.MediaType -match "HDD" -or -not $isSSD) { "HDD" }
                                else { "Unknown" }
                Interface      = $disk.InterfaceType
                PartitionStyle = $partStyle
                IsNVMe         = $isNVMe
                IsSystemDisk   = ($diskNumber -eq 0)
            }
        }

        $volumeList = @()
        foreach ($vol in $volumes) {
            $usedPercent = 0
            if ($vol.Size -gt 0) {
                $usedPercent = [math]::Round((($vol.Size - $vol.FreeSpace) / $vol.Size) * 100, 1)
            }

            $volumeList += [PSCustomObject]@{
                DriveLetter = $vol.DeviceID
                Label       = $vol.VolumeName
                SizeGB      = [math]::Round($vol.Size / 1GB, 2)
                FreeGB      = [math]::Round($vol.FreeSpace / 1GB, 2)
                UsedPercent = $usedPercent
                FileSystem  = $vol.FileSystem
            }
        }

        $hasNVMe = ($physicalDisks | Where-Object { $_.IsNVMe }).Count -gt 0
        $hasSSD = ($physicalDisks | Where-Object { $_.MediaType -match "SSD" }).Count -gt 0

        return [PSCustomObject]@{
            PhysicalDisks   = $physicalDisks
            Volumes         = $volumeList
            SystemDrive     = $env:SystemDrive
            HasSSD          = $hasSSD
            HasNVMe         = $hasNVMe
            TotalStorageGB  = [math]::Round(($disks | Measure-Object -Property Size -Sum).Sum / 1GB, 2)
        }
    }
    catch {
        Write-Log "Error getting storage profile: $($_.Exception.Message)" -Level ERROR
        return [PSCustomObject]@{
            PhysicalDisks   = @()
            Volumes         = @()
            SystemDrive     = $env:SystemDrive
            HasSSD          = $false
            HasNVMe         = $false
            TotalStorageGB  = 0
        }
    }
}

#endregion

#region GPU Profiler

function Get-GPUProfile {
    <#
    .SYNOPSIS
        Detects GPU specifications and capabilities
    .OUTPUTS
        PSCustomObject with GPU profile
    #>

    try {
        $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop

        $adapters = @()
        foreach ($gpu in $gpus) {
            $vramGB = 0
            if ($gpu.AdapterRAM -gt 0) {
                $vramGB = [math]::Round($gpu.AdapterRAM / 1GB, 2)
            }

            $manufacturer = switch -Wildcard ($gpu.Name) {
                "*NVIDIA*" { "NVIDIA" }
                "*AMD*" { "AMD" }
                "*Radeon*" { "AMD" }
                "*Intel*" { "Intel" }
                default { $gpu.AdapterCompatibility }
            }

            $isDiscrete = ($gpu.AdapterRAM -gt 1GB -and $gpu.Name -notmatch "Intel|Integrated|UHD|HD Graphics")

            $adapters += [PSCustomObject]@{
                Name          = $gpu.Name
                Manufacturer  = $manufacturer
                VRAMGB        = $vramGB
                DriverVersion = $gpu.DriverVersion
                DriverDate    = $gpu.DriverDate
                Resolution    = "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
                RefreshRate   = $gpu.CurrentRefreshRate
                Status        = $gpu.Status
                IsDiscrete    = $isDiscrete
            }
        }

        $hasDiscrete = ($adapters | Where-Object { $_.IsDiscrete }).Count -gt 0
        $hasNVIDIA = ($gpus | Where-Object { $_.Name -match "NVIDIA" }).Count -gt 0
        $hasAMD = ($gpus | Where-Object { $_.Name -match "AMD|Radeon" }).Count -gt 0
        $hasIntel = ($gpus | Where-Object { $_.Name -match "Intel" }).Count -gt 0

        $totalVRAM = 0
        foreach ($adapter in $adapters) {
            $totalVRAM += $adapter.VRAMGB
        }

        return [PSCustomObject]@{
            Adapters           = $adapters
            HasDiscreteGPU     = $hasDiscrete
            HasNVIDIA          = $hasNVIDIA
            HasAMD             = $hasAMD
            HasIntelIntegrated = $hasIntel
            PrimaryGPU         = ($adapters | Select-Object -First 1).Name
            TotalVRAMGB        = $totalVRAM
        }
    }
    catch {
        Write-Log "Error getting GPU profile: $($_.Exception.Message)" -Level ERROR
        return [PSCustomObject]@{
            Adapters           = @()
            HasDiscreteGPU     = $false
            HasNVIDIA          = $false
            HasAMD             = $false
            HasIntelIntegrated = $false
            PrimaryGPU         = "Unknown"
            TotalVRAMGB        = 0
        }
    }
}

#endregion

#region System Info

function Get-SystemInfoProfile {
    <#
    .SYNOPSIS
        Detects system information including OS and BIOS
    .OUTPUTS
        PSCustomObject with system info profile
    #>

    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
        $mb = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue

        $isLaptop = ($cs.PCSystemType -eq 2) -or
                    ($cs.Model -match "Laptop|Notebook|Book|Surface|ThinkPad|EliteBook|Latitude|XPS|MacBook|Swift|Aspire")
        $isDesktop = ($cs.PCSystemType -eq 1)
        $isVM = ($cs.Model -match "Virtual|VMware|VirtualBox|Hyper-V|QEMU|KVM")

        # Check UEFI/SecureBoot
        $isUEFI = $false
        $secureBootEnabled = $false
        try {
            $secureBootResult = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
            $isUEFI = $null -ne $secureBootResult
            $secureBootEnabled = $secureBootResult -eq $true
        }
        catch { }

        # Get Windows Edition
        $windowsEdition = "Unknown"
        $isWindowsPro = $false
        try {
            $edition = Get-WindowsEdition -Online -ErrorAction SilentlyContinue
            $windowsEdition = $edition.Edition
            $isWindowsPro = $windowsEdition -match "Professional|Enterprise|Education"
        }
        catch { }

        $motherboard = "Unknown"
        if ($mb) {
            $motherboard = "$($mb.Manufacturer) $($mb.Product)".Trim()
        }

        return [PSCustomObject]@{
            ComputerName      = $cs.Name
            Manufacturer      = $cs.Manufacturer
            Model             = $cs.Model
            SystemType        = $cs.SystemType
            IsLaptop          = $isLaptop
            IsDesktop         = $isDesktop
            IsVM              = $isVM

            # OS Info
            OSName            = $os.Caption
            OSVersion         = $os.Version
            OSBuild           = $os.BuildNumber
            OSArchitecture    = $os.OSArchitecture
            InstallDate       = $os.InstallDate
            LastBootTime      = $os.LastBootUpTime
            UptimeHours       = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)

            # BIOS/Firmware
            BIOSManufacturer  = if ($bios) { $bios.Manufacturer } else { "Unknown" }
            BIOSVersion       = if ($bios) { $bios.SMBIOSBIOSVersion } else { "Unknown" }
            BIOSDate          = if ($bios) { $bios.ReleaseDate } else { $null }
            IsUEFI            = $isUEFI
            SecureBootEnabled = $secureBootEnabled

            # Motherboard
            Motherboard       = $motherboard

            # Domain/Workgroup
            Domain            = $cs.Domain
            PartOfDomain      = $cs.PartOfDomain

            # Windows Edition
            WindowsEdition    = $windowsEdition
            IsWindowsPro      = $isWindowsPro
        }
    }
    catch {
        Write-Log "Error getting system info: $($_.Exception.Message)" -Level ERROR
        return [PSCustomObject]@{
            ComputerName      = $env:COMPUTERNAME
            Manufacturer      = "Unknown"
            Model             = "Unknown"
            SystemType        = "Unknown"
            IsLaptop          = $false
            IsDesktop         = $true
            IsVM              = $false
            OSName            = "Unknown"
            OSVersion         = "Unknown"
            OSBuild           = "Unknown"
            OSArchitecture    = "Unknown"
            InstallDate       = $null
            LastBootTime      = $null
            UptimeHours       = 0
            BIOSManufacturer  = "Unknown"
            BIOSVersion       = "Unknown"
            BIOSDate          = $null
            IsUEFI            = $false
            SecureBootEnabled = $false
            Motherboard       = "Unknown"
            Domain            = "Unknown"
            PartOfDomain      = $false
            WindowsEdition    = "Unknown"
            IsWindowsPro      = $false
        }
    }
}

#endregion

#region Network Profiler

function Get-NetworkProfile {
    <#
    .SYNOPSIS
        Detects network adapter information
    .OUTPUTS
        PSCustomObject with network profile
    #>

    try {
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }

        $activeAdapters = @()
        foreach ($adapter in $adapters) {
            $ipConfig = $null
            try {
                $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            }
            catch { }

            $speedGbps = 0
            if ($adapter.LinkSpeed) {
                $speedStr = $adapter.LinkSpeed.ToString()
                if ($speedStr -match "(\d+\.?\d*)\s*Gbps") {
                    $speedGbps = [double]$Matches[1]
                }
                elseif ($speedStr -match "(\d+\.?\d*)\s*Mbps") {
                    $speedGbps = [double]$Matches[1] / 1000
                }
            }

            $isWiFi = $adapter.InterfaceDescription -match "Wi-Fi|Wireless|802\.11"
            $isEthernet = $adapter.InterfaceDescription -match "Ethernet|Realtek|Intel.*I[0-9]"

            $activeAdapters += [PSCustomObject]@{
                Name        = $adapter.Name
                Description = $adapter.InterfaceDescription
                Type        = if ($isWiFi) { "WiFi" } elseif ($isEthernet) { "Ethernet" } else { "Other" }
                SpeedGbps   = [math]::Round($speedGbps, 2)
                MacAddress  = $adapter.MacAddress
                IPAddress   = if ($ipConfig) { $ipConfig.IPAddress } else { "N/A" }
                IsWiFi      = $isWiFi
                IsEthernet  = $isEthernet
            }
        }

        $hasWiFi = ($adapters | Where-Object { $_.InterfaceDescription -match "Wi-Fi|Wireless" }).Count -gt 0
        $hasEthernet = ($adapters | Where-Object { $_.InterfaceDescription -match "Ethernet" }).Count -gt 0

        $dnsServers = @()
        try {
            $dns = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                   Where-Object { $_.ServerAddresses } |
                   Select-Object -First 1
            if ($dns) {
                $dnsServers = $dns.ServerAddresses
            }
        }
        catch { }

        return [PSCustomObject]@{
            ActiveAdapters = $activeAdapters
            HasWiFi        = $hasWiFi
            HasEthernet    = $hasEthernet
            PrimaryAdapter = if ($activeAdapters.Count -gt 0) { $activeAdapters[0].Name } else { "None" }
            DNSServers     = $dnsServers
        }
    }
    catch {
        Write-Log "Error getting network profile: $($_.Exception.Message)" -Level ERROR
        return [PSCustomObject]@{
            ActiveAdapters = @()
            HasWiFi        = $false
            HasEthernet    = $false
            PrimaryAdapter = "None"
            DNSServers     = @()
        }
    }
}

#endregion

#region Power Profiler

function Get-PowerProfile {
    <#
    .SYNOPSIS
        Detects power and battery information
    .OUTPUTS
        PSCustomObject with power profile
    #>

    try {
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue

        $activePowerPlan = "Unknown"
        try {
            $powerPlan = powercfg /getactivescheme 2>$null
            if ($powerPlan -match "GUID: ([a-f0-9-]+).*\((.+)\)") {
                $activePowerPlan = $Matches[2].Trim()
            }
        }
        catch { }

        $hasBattery = $null -ne $battery
        $batteryStatus = "N/A"
        $batteryPercent = 0
        $batteryHealth = 0
        $isOnACPower = $true

        if ($hasBattery) {
            $batteryStatus = switch ($battery.BatteryStatus) {
                1 { "Discharging" }
                2 { "AC Power" }
                3 { "Fully Charged" }
                4 { "Low" }
                5 { "Critical" }
                default { "Unknown" }
            }

            $batteryPercent = $battery.EstimatedChargeRemaining
            $isOnACPower = $battery.BatteryStatus -eq 2

            if ($battery.DesignCapacity -and $battery.FullChargeCapacity -and $battery.FullChargeCapacity -gt 0) {
                $batteryHealth = [math]::Round(($battery.FullChargeCapacity / $battery.DesignCapacity) * 100, 0)
            }
        }

        return [PSCustomObject]@{
            HasBattery      = $hasBattery
            BatteryStatus   = $batteryStatus
            BatteryPercent  = $batteryPercent
            BatteryHealth   = $batteryHealth
            ActivePowerPlan = $activePowerPlan
            IsOnACPower     = $isOnACPower
        }
    }
    catch {
        Write-Log "Error getting power profile: $($_.Exception.Message)" -Level ERROR
        return [PSCustomObject]@{
            HasBattery      = $false
            BatteryStatus   = "N/A"
            BatteryPercent  = 0
            BatteryHealth   = 0
            ActivePowerPlan = "Unknown"
            IsOnACPower     = $true
        }
    }
}

#endregion

#region Performance Tier Classification

function Get-PerformanceTier {
    <#
    .SYNOPSIS
        Calculates system performance tier based on hardware specs
    .PARAMETER Profile
        The system profile object
    .OUTPUTS
        PSCustomObject with performance tier information
    #>
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Profile
    )

    $score = 0

    # CPU scoring (max 30 points)
    if ($Profile.CPU.Cores -ge 8) { $score += 15 }
    elseif ($Profile.CPU.Cores -ge 6) { $score += 10 }
    elseif ($Profile.CPU.Cores -ge 4) { $score += 5 }

    if ($Profile.CPU.MaxClockSpeedMHz -ge 3500) { $score += 15 }
    elseif ($Profile.CPU.MaxClockSpeedMHz -ge 2500) { $score += 10 }
    elseif ($Profile.CPU.MaxClockSpeedMHz -ge 1500) { $score += 5 }

    # RAM scoring (max 25 points)
    if ($Profile.RAM.TotalGB -ge 32) { $score += 25 }
    elseif ($Profile.RAM.TotalGB -ge 16) { $score += 15 }
    elseif ($Profile.RAM.TotalGB -ge 8) { $score += 8 }

    # Storage scoring (max 20 points)
    if ($Profile.Storage.HasNVMe) { $score += 20 }
    elseif ($Profile.Storage.HasSSD) { $score += 12 }
    else { $score += 4 }

    # GPU scoring (max 25 points)
    if ($Profile.GPU.HasDiscreteGPU -and $Profile.GPU.TotalVRAMGB -ge 8) { $score += 25 }
    elseif ($Profile.GPU.HasDiscreteGPU) { $score += 15 }
    elseif ($Profile.GPU.HasIntelIntegrated) { $score += 5 }

    # Determine tier
    $tier = switch ($score) {
        { $_ -ge 80 } { "Ultra" }
        { $_ -ge 60 } { "High" }
        { $_ -ge 40 } { "Medium" }
        { $_ -ge 20 } { "Low" }
        default { "Minimal" }
    }

    return [PSCustomObject]@{
        Score    = $score
        MaxScore = 100
        Tier     = $tier
        Label    = switch ($tier) {
            "Ultra"   { "Ultra Performance System" }
            "High"    { "High Performance System" }
            "Medium"  { "Standard Performance System" }
            "Low"     { "Light Performance System" }
            "Minimal" { "Minimal Specs System" }
        }
    }
}

#endregion

#region System Recommendations

function Get-SystemRecommendations {
    <#
    .SYNOPSIS
        Generates adaptive recommendations based on system profile
    .PARAMETER Profile
        The system profile object
    .OUTPUTS
        Array of recommendation objects
    #>
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Profile
    )

    $recommendations = @()

    # RAM-based recommendations
    if ($Profile.RAM.TotalGB -lt 8) {
        $recommendations += [PSCustomObject]@{
            Category = "RAM"
            Priority = "High"
            Message  = "System has less than 8GB RAM. Aggressive memory optimization recommended."
            Action   = "EnableAggressiveRAMOptimization"
        }
    }
    elseif ($Profile.RAM.TotalGB -ge 32) {
        $recommendations += [PSCustomObject]@{
            Category = "RAM"
            Priority = "Info"
            Message  = "High RAM detected ($($Profile.RAM.TotalGB)GB). Disable memory compression for better performance."
            Action   = "DisableMemoryCompression"
        }
    }

    if ($Profile.RAM.UsagePercent -gt 80) {
        $recommendations += [PSCustomObject]@{
            Category = "RAM"
            Priority = "Warning"
            Message  = "RAM usage is high ($($Profile.RAM.UsagePercent)%). Consider closing unused applications."
            Action   = "OptimizeMemoryUsage"
        }
    }

    # Storage recommendations
    if (-not $Profile.Storage.HasSSD) {
        $recommendations += [PSCustomObject]@{
            Category = "Storage"
            Priority = "High"
            Message  = "No SSD detected. Consider upgrading for significant performance improvement."
            Action   = "EnableHDDOptimizations"
        }
    }

    $systemDrive = $Profile.Storage.Volumes | Where-Object { $_.DriveLetter -eq "C:" }
    if ($systemDrive -and $systemDrive.UsedPercent -gt 90) {
        $recommendations += [PSCustomObject]@{
            Category = "Storage"
            Priority = "Critical"
            Message  = "System drive is over 90% full ($($systemDrive.UsedPercent)%). Disk cleanup strongly recommended."
            Action   = "RunDiskCleanup"
        }
    }
    elseif ($systemDrive -and $systemDrive.UsedPercent -gt 80) {
        $recommendations += [PSCustomObject]@{
            Category = "Storage"
            Priority = "Warning"
            Message  = "System drive is over 80% full ($($systemDrive.UsedPercent)%). Consider freeing up space."
            Action   = "RunDiskCleanup"
        }
    }

    # Laptop-specific recommendations
    if ($Profile.System.IsLaptop) {
        $recommendations += [PSCustomObject]@{
            Category = "Power"
            Priority = "Info"
            Message  = "Laptop detected. Battery-aware power profiles will be used."
            Action   = "EnableLaptopOptimizations"
        }

        if ($Profile.Power.BatteryHealth -gt 0 -and $Profile.Power.BatteryHealth -lt 80) {
            $recommendations += [PSCustomObject]@{
                Category = "Power"
                Priority = "Warning"
                Message  = "Battery health is degraded ($($Profile.Power.BatteryHealth)%). Consider battery replacement."
                Action   = "None"
            }
        }
    }

    # Gaming potential
    if ($Profile.GPU.HasDiscreteGPU) {
        $recommendations += [PSCustomObject]@{
            Category = "Gaming"
            Priority = "Info"
            Message  = "Discrete GPU detected ($($Profile.GPU.PrimaryGPU)). Gaming optimizations available."
            Action   = "EnableGamingMode"
        }
    }

    # VM detection
    if ($Profile.System.IsVM) {
        $recommendations += [PSCustomObject]@{
            Category = "System"
            Priority = "Warning"
            Message  = "Virtual machine detected. Some optimizations may not apply."
            Action   = "UseVMSafeMode"
        }
    }

    # CPU-specific recommendations
    if ($Profile.CPU.IsHighEnd -and $Profile.CPU.VirtualizationEnabled) {
        $recommendations += [PSCustomObject]@{
            Category = "CPU"
            Priority = "Info"
            Message  = "High-end CPU with virtualization support. Hyper-V features available."
            Action   = "EnableHyperV"
        }
    }

    # Network recommendations
    if ($Profile.Network.HasWiFi -and -not $Profile.Network.HasEthernet) {
        $recommendations += [PSCustomObject]@{
            Category = "Network"
            Priority = "Info"
            Message  = "WiFi-only connection. For best performance, consider using Ethernet."
            Action   = "None"
        }
    }

    # Uptime recommendation
    if ($Profile.System.UptimeHours -gt 168) {
        $recommendations += [PSCustomObject]@{
            Category = "System"
            Priority = "Info"
            Message  = "System has been running for over a week. A restart may improve performance."
            Action   = "RestartSuggested"
        }
    }

    return $recommendations
}

#endregion

#region Main System Profile Function

function Get-SystemProfile {
    <#
    .SYNOPSIS
        Comprehensive system hardware profiler
    .DESCRIPTION
        Detects all hardware components and returns a profile object
        used by other modules to adapt their behavior
    .OUTPUTS
        PSCustomObject with full system profile
    #>

    Write-Log "Starting comprehensive system scan..." -Level INFO

    $profile = [PSCustomObject]@{
        # CPU Info
        CPU             = Get-CPUProfile
        # Memory Info
        RAM             = Get-RAMProfile
        # Storage Info
        Storage         = Get-StorageProfile
        # GPU Info
        GPU             = Get-GPUProfile
        # System Info
        System          = Get-SystemInfoProfile
        # Network Info
        Network         = Get-NetworkProfile
        # Power Info
        Power           = Get-PowerProfile
        # Calculated Tier
        PerformanceTier = $null
        # Recommendations
        Recommendations = @()
        # Scan Timestamp
        ScanTime        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    # Calculate performance tier based on specs
    $profile.PerformanceTier = Get-PerformanceTier -Profile $profile
    $profile.Recommendations = Get-SystemRecommendations -Profile $profile

    Write-Log "System scan complete. Performance Tier: $($profile.PerformanceTier.Tier)" -Level INFO

    return $profile
}

#endregion

#region Quick Hardware Check

function Get-QuickHardwareCheck {
    <#
    .SYNOPSIS
        Quick hardware summary without full scan
    .OUTPUTS
        PSCustomObject with quick hardware summary
    #>

    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        $gpu = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1

        $ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 0)

        return [PSCustomObject]@{
            CPU       = $cpu.Name.Trim()
            Cores     = $cpu.NumberOfCores
            Threads   = $cpu.NumberOfLogicalProcessors
            RAMGB     = $ramGB
            GPU       = $gpu.Name
            OS        = $os.Caption
            OSBuild   = $os.BuildNumber
        }
    }
    catch {
        Write-Log "Error in quick hardware check: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

#endregion

#region Export Report Functions

function Export-SystemReport {
    <#
    .SYNOPSIS
        Exports system profile to JSON and text files
    .PARAMETER Profile
        The system profile object to export
    .PARAMETER OutputPath
        Path for the JSON output file
    .OUTPUTS
        Hashtable with paths to generated files
    #>
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Profile,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Set default output path if not provided
    if (-not $OutputPath) {
        $logsDir = Join-Path $PSScriptRoot "..\logs"
        if (-not (Test-Path $logsDir)) {
            New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
        }
        $OutputPath = Join-Path $logsDir "SystemReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    }

    try {
        # Export to JSON
        $Profile | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

        # Also create human-readable text report
        $textPath = $OutputPath.Replace(".json", ".txt")

        # Build volumes section
        $volumesText = ""
        foreach ($vol in $Profile.Storage.Volumes) {
            $volumesText += "  $($vol.DriveLetter) - $($vol.SizeGB) GB total, $($vol.FreeGB) GB free ($($vol.UsedPercent)% used)`n"
        }

        # Build disks section
        $disksText = ""
        foreach ($disk in $Profile.Storage.PhysicalDisks) {
            $disksText += "  $($disk.Model) | $($disk.SizeGB) GB | $($disk.MediaType)`n"
        }

        # Build GPU section
        $gpuText = ""
        foreach ($gpu in $Profile.GPU.Adapters) {
            $gpuText += "  $($gpu.Name) | VRAM: $($gpu.VRAMGB) GB`n"
        }

        # Build recommendations section
        $recsText = ""
        foreach ($rec in $Profile.Recommendations) {
            $recsText += "  [$($rec.Priority)] $($rec.Category): $($rec.Message)`n"
        }

        # Build RAM slots section
        $ramText = ""
        foreach ($slot in $Profile.RAM.Slots) {
            $ramText += "  $($slot.Bank): $($slot.CapacityGB) GB $($slot.Type) @ $($slot.SpeedMHz) MHz`n"
        }

        $report = @"
================================================================================
                    SYSTEM PROFILE REPORT
                    Generated: $($Profile.ScanTime)
================================================================================

PERFORMANCE TIER: $($Profile.PerformanceTier.Label)
Score: $($Profile.PerformanceTier.Score) / $($Profile.PerformanceTier.MaxScore)

--------------------------------------------------------------------------------
SYSTEM INFORMATION
--------------------------------------------------------------------------------
Computer Name: $($Profile.System.ComputerName)
Manufacturer: $($Profile.System.Manufacturer)
Model: $($Profile.System.Model)
System Type: $(if ($Profile.System.IsLaptop) { "Laptop" } elseif ($Profile.System.IsDesktop) { "Desktop" } else { "Unknown" })
Is Virtual Machine: $($Profile.System.IsVM)

Operating System: $($Profile.System.OSName)
OS Version: $($Profile.System.OSVersion)
OS Build: $($Profile.System.OSBuild)
Architecture: $($Profile.System.OSArchitecture)
Windows Edition: $($Profile.System.WindowsEdition)

UEFI Mode: $($Profile.System.IsUEFI)
Secure Boot: $($Profile.System.SecureBootEnabled)
Uptime: $($Profile.System.UptimeHours) hours

--------------------------------------------------------------------------------
CPU INFORMATION
--------------------------------------------------------------------------------
Processor: $($Profile.CPU.Name)
Manufacturer: $($Profile.CPU.Manufacturer)
Cores: $($Profile.CPU.Cores) | Threads: $($Profile.CPU.LogicalProcessors)
Max Speed: $($Profile.CPU.MaxClockSpeedMHz) MHz
Architecture: $($Profile.CPU.Architecture)
L2 Cache: $($Profile.CPU.L2CacheKB) KB
L3 Cache: $($Profile.CPU.L3CacheKB) KB
Virtualization: $($Profile.CPU.VirtualizationEnabled)
Classification: $(if ($Profile.CPU.IsHighEnd) { "High-End" } elseif ($Profile.CPU.IsMidRange) { "Mid-Range" } else { "Entry-Level" })

--------------------------------------------------------------------------------
MEMORY INFORMATION
--------------------------------------------------------------------------------
Total RAM: $($Profile.RAM.TotalGB) GB
Available: $($Profile.RAM.FreeGB) GB ($($Profile.RAM.UsagePercent)% used)
Memory Slots: $($Profile.RAM.SlotCount)
Page File: $($Profile.RAM.PageFileGB) GB
Classification: $(if ($Profile.RAM.IsHighRAM) { "High (32GB+)" } elseif ($Profile.RAM.IsMidRAM) { "Standard (16-32GB)" } else { "Low (<16GB)" })

Installed Modules:
$ramText
--------------------------------------------------------------------------------
STORAGE INFORMATION
--------------------------------------------------------------------------------
Total Storage: $($Profile.Storage.TotalStorageGB) GB
Has SSD: $($Profile.Storage.HasSSD)
Has NVMe: $($Profile.Storage.HasNVMe)
System Drive: $($Profile.Storage.SystemDrive)

Physical Disks:
$disksText
Volumes:
$volumesText
--------------------------------------------------------------------------------
GPU INFORMATION
--------------------------------------------------------------------------------
Primary GPU: $($Profile.GPU.PrimaryGPU)
Has Discrete GPU: $($Profile.GPU.HasDiscreteGPU)
Total VRAM: $($Profile.GPU.TotalVRAMGB) GB

Adapters:
$gpuText
--------------------------------------------------------------------------------
NETWORK INFORMATION
--------------------------------------------------------------------------------
Primary Adapter: $($Profile.Network.PrimaryAdapter)
Has WiFi: $($Profile.Network.HasWiFi)
Has Ethernet: $($Profile.Network.HasEthernet)
DNS Servers: $($Profile.Network.DNSServers -join ", ")

--------------------------------------------------------------------------------
POWER INFORMATION
--------------------------------------------------------------------------------
Has Battery: $($Profile.Power.HasBattery)
Battery Status: $($Profile.Power.BatteryStatus)
Battery Percent: $($Profile.Power.BatteryPercent)%
Battery Health: $($Profile.Power.BatteryHealth)%
Active Power Plan: $($Profile.Power.ActivePowerPlan)
On AC Power: $($Profile.Power.IsOnACPower)

--------------------------------------------------------------------------------
RECOMMENDATIONS
--------------------------------------------------------------------------------
$recsText
================================================================================
"@

        $report | Out-File -FilePath $textPath -Encoding UTF8

        Write-Log "System report exported to: $OutputPath" -Level INFO

        return @{
            JsonPath = $OutputPath
            TextPath = $textPath
        }
    }
    catch {
        Write-Log "Error exporting system report: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

#endregion

#region Display Functions

function Show-CPUDetails {
    <#
    .SYNOPSIS
        Displays detailed CPU information
    #>
    param([PSCustomObject]$CPUProfile)

    Write-Host ""
    Write-Host "  CPU DETAILS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Processor:     " -NoNewline -ForegroundColor Gray
    Write-Host $CPUProfile.Name -ForegroundColor White
    Write-Host "  Manufacturer:  " -NoNewline -ForegroundColor Gray
    Write-Host $CPUProfile.Manufacturer -ForegroundColor White
    Write-Host "  Cores:         " -NoNewline -ForegroundColor Gray
    Write-Host $CPUProfile.Cores -ForegroundColor Green
    Write-Host "  Threads:       " -NoNewline -ForegroundColor Gray
    Write-Host $CPUProfile.LogicalProcessors -ForegroundColor Green
    Write-Host "  Max Speed:     " -NoNewline -ForegroundColor Gray
    Write-Host "$($CPUProfile.MaxClockSpeedMHz) MHz" -ForegroundColor Yellow
    Write-Host "  Architecture:  " -NoNewline -ForegroundColor Gray
    Write-Host $CPUProfile.Architecture -ForegroundColor White
    Write-Host "  L2 Cache:      " -NoNewline -ForegroundColor Gray
    Write-Host "$($CPUProfile.L2CacheKB) KB" -ForegroundColor White
    Write-Host "  L3 Cache:      " -NoNewline -ForegroundColor Gray
    Write-Host "$($CPUProfile.L3CacheKB) KB" -ForegroundColor White
    Write-Host "  Virtualization:" -NoNewline -ForegroundColor Gray
    Write-Host $(if ($CPUProfile.VirtualizationEnabled) { "Enabled" } else { "Disabled" }) -ForegroundColor $(if ($CPUProfile.VirtualizationEnabled) { "Green" } else { "Yellow" })
    Write-Host "  Classification:" -NoNewline -ForegroundColor Gray
    $class = if ($CPUProfile.IsHighEnd) { "High-End" } elseif ($CPUProfile.IsMidRange) { "Mid-Range" } else { "Entry-Level" }
    $classColor = if ($CPUProfile.IsHighEnd) { "Green" } elseif ($CPUProfile.IsMidRange) { "Yellow" } else { "Red" }
    Write-Host $class -ForegroundColor $classColor
    Write-Host ""
}

function Show-RAMDetails {
    <#
    .SYNOPSIS
        Displays detailed RAM information
    #>
    param([PSCustomObject]$RAMProfile)

    Write-Host ""
    Write-Host "  RAM DETAILS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Total RAM:     " -NoNewline -ForegroundColor Gray
    Write-Host "$($RAMProfile.TotalGB) GB" -ForegroundColor Green
    Write-Host "  Available:     " -NoNewline -ForegroundColor Gray
    Write-Host "$($RAMProfile.FreeGB) GB" -ForegroundColor White
    Write-Host "  In Use:        " -NoNewline -ForegroundColor Gray
    Write-Host "$($RAMProfile.UsedGB) GB ($($RAMProfile.UsagePercent)%)" -ForegroundColor $(if ($RAMProfile.UsagePercent -gt 80) { "Red" } elseif ($RAMProfile.UsagePercent -gt 60) { "Yellow" } else { "Green" })
    Write-Host "  Page File:     " -NoNewline -ForegroundColor Gray
    Write-Host "$($RAMProfile.PageFileGB) GB" -ForegroundColor White
    Write-Host "  Slots Used:    " -NoNewline -ForegroundColor Gray
    Write-Host $RAMProfile.SlotCount -ForegroundColor White
    Write-Host ""

    if ($RAMProfile.Slots.Count -gt 0) {
        Write-Host "  Installed Modules:" -ForegroundColor Gray
        foreach ($slot in $RAMProfile.Slots) {
            Write-Host "    - $($slot.Bank): " -NoNewline -ForegroundColor DarkGray
            Write-Host "$($slot.CapacityGB) GB $($slot.Type) @ $($slot.SpeedMHz) MHz" -ForegroundColor White
        }
    }
    Write-Host ""
}

function Show-StorageDetails {
    <#
    .SYNOPSIS
        Displays detailed storage information
    #>
    param([PSCustomObject]$StorageProfile)

    Write-Host ""
    Write-Host "  STORAGE DETAILS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Total Storage: " -NoNewline -ForegroundColor Gray
    Write-Host "$($StorageProfile.TotalStorageGB) GB" -ForegroundColor White
    Write-Host "  Has SSD:       " -NoNewline -ForegroundColor Gray
    Write-Host $(if ($StorageProfile.HasSSD) { "Yes" } else { "No" }) -ForegroundColor $(if ($StorageProfile.HasSSD) { "Green" } else { "Yellow" })
    Write-Host "  Has NVMe:      " -NoNewline -ForegroundColor Gray
    Write-Host $(if ($StorageProfile.HasNVMe) { "Yes" } else { "No" }) -ForegroundColor $(if ($StorageProfile.HasNVMe) { "Green" } else { "Yellow" })
    Write-Host ""

    Write-Host "  Physical Disks:" -ForegroundColor Gray
    foreach ($disk in $StorageProfile.PhysicalDisks) {
        $typeColor = if ($disk.IsNVMe) { "Cyan" } elseif ($disk.MediaType -eq "SSD") { "Green" } else { "Yellow" }
        Write-Host "    - $($disk.Model)" -ForegroundColor White
        Write-Host "      Size: $($disk.SizeGB) GB | Type: " -NoNewline -ForegroundColor DarkGray
        Write-Host $disk.MediaType -ForegroundColor $typeColor
    }
    Write-Host ""

    Write-Host "  Volumes:" -ForegroundColor Gray
    foreach ($vol in $StorageProfile.Volumes) {
        $usageColor = if ($vol.UsedPercent -gt 90) { "Red" } elseif ($vol.UsedPercent -gt 80) { "Yellow" } else { "Green" }
        Write-Host "    - $($vol.DriveLetter) " -NoNewline -ForegroundColor White
        if ($vol.Label) { Write-Host "($($vol.Label)) " -NoNewline -ForegroundColor DarkGray }
        Write-Host "| $($vol.FreeGB) GB free of $($vol.SizeGB) GB (" -NoNewline -ForegroundColor DarkGray
        Write-Host "$($vol.UsedPercent)%" -NoNewline -ForegroundColor $usageColor
        Write-Host " used)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Show-GPUDetails {
    <#
    .SYNOPSIS
        Displays detailed GPU information
    #>
    param([PSCustomObject]$GPUProfile)

    Write-Host ""
    Write-Host "  GPU DETAILS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Primary GPU:   " -NoNewline -ForegroundColor Gray
    Write-Host $GPUProfile.PrimaryGPU -ForegroundColor White
    Write-Host "  Discrete GPU:  " -NoNewline -ForegroundColor Gray
    Write-Host $(if ($GPUProfile.HasDiscreteGPU) { "Yes" } else { "No" }) -ForegroundColor $(if ($GPUProfile.HasDiscreteGPU) { "Green" } else { "Yellow" })
    Write-Host "  Total VRAM:    " -NoNewline -ForegroundColor Gray
    Write-Host "$($GPUProfile.TotalVRAMGB) GB" -ForegroundColor White
    Write-Host ""

    Write-Host "  GPU Adapters:" -ForegroundColor Gray
    foreach ($gpu in $GPUProfile.Adapters) {
        $mfgColor = switch ($gpu.Manufacturer) {
            "NVIDIA" { "Green" }
            "AMD" { "Red" }
            "Intel" { "Blue" }
            default { "White" }
        }
        Write-Host "    - $($gpu.Name)" -ForegroundColor $mfgColor
        Write-Host "      VRAM: $($gpu.VRAMGB) GB | Driver: $($gpu.DriverVersion)" -ForegroundColor DarkGray
        Write-Host "      Resolution: $($gpu.Resolution) @ $($gpu.RefreshRate) Hz" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Show-NetworkDetails {
    <#
    .SYNOPSIS
        Displays detailed network information
    #>
    param([PSCustomObject]$NetworkProfile)

    Write-Host ""
    Write-Host "  NETWORK DETAILS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Primary:       " -NoNewline -ForegroundColor Gray
    Write-Host $NetworkProfile.PrimaryAdapter -ForegroundColor White
    Write-Host "  Has WiFi:      " -NoNewline -ForegroundColor Gray
    Write-Host $(if ($NetworkProfile.HasWiFi) { "Yes" } else { "No" }) -ForegroundColor White
    Write-Host "  Has Ethernet:  " -NoNewline -ForegroundColor Gray
    Write-Host $(if ($NetworkProfile.HasEthernet) { "Yes" } else { "No" }) -ForegroundColor White
    Write-Host "  DNS Servers:   " -NoNewline -ForegroundColor Gray
    Write-Host ($NetworkProfile.DNSServers -join ", ") -ForegroundColor White
    Write-Host ""

    if ($NetworkProfile.ActiveAdapters.Count -gt 0) {
        Write-Host "  Active Adapters:" -ForegroundColor Gray
        foreach ($adapter in $NetworkProfile.ActiveAdapters) {
            $typeColor = if ($adapter.IsWiFi) { "Cyan" } elseif ($adapter.IsEthernet) { "Green" } else { "Yellow" }
            Write-Host "    - $($adapter.Name)" -ForegroundColor White
            Write-Host "      Type: " -NoNewline -ForegroundColor DarkGray
            Write-Host $adapter.Type -NoNewline -ForegroundColor $typeColor
            Write-Host " | Speed: $($adapter.SpeedGbps) Gbps | IP: $($adapter.IPAddress)" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
}

function Show-PowerDetails {
    <#
    .SYNOPSIS
        Displays detailed power/battery information
    #>
    param([PSCustomObject]$PowerProfile)

    Write-Host ""
    Write-Host "  POWER DETAILS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Power Plan:    " -NoNewline -ForegroundColor Gray
    Write-Host $PowerProfile.ActivePowerPlan -ForegroundColor White
    Write-Host "  Has Battery:   " -NoNewline -ForegroundColor Gray
    Write-Host $(if ($PowerProfile.HasBattery) { "Yes" } else { "No" }) -ForegroundColor White

    if ($PowerProfile.HasBattery) {
        Write-Host "  Battery Status:" -NoNewline -ForegroundColor Gray
        $statusColor = switch ($PowerProfile.BatteryStatus) {
            "Fully Charged" { "Green" }
            "AC Power" { "Green" }
            "Discharging" { "Yellow" }
            "Low" { "Red" }
            "Critical" { "Red" }
            default { "White" }
        }
        Write-Host $PowerProfile.BatteryStatus -ForegroundColor $statusColor

        Write-Host "  Charge Level:  " -NoNewline -ForegroundColor Gray
        $chargeColor = if ($PowerProfile.BatteryPercent -gt 50) { "Green" } elseif ($PowerProfile.BatteryPercent -gt 20) { "Yellow" } else { "Red" }
        Write-Host "$($PowerProfile.BatteryPercent)%" -ForegroundColor $chargeColor

        if ($PowerProfile.BatteryHealth -gt 0) {
            Write-Host "  Battery Health:" -NoNewline -ForegroundColor Gray
            $healthColor = if ($PowerProfile.BatteryHealth -gt 80) { "Green" } elseif ($PowerProfile.BatteryHealth -gt 50) { "Yellow" } else { "Red" }
            Write-Host "$($PowerProfile.BatteryHealth)%" -ForegroundColor $healthColor
        }

        Write-Host "  On AC Power:   " -NoNewline -ForegroundColor Gray
        Write-Host $(if ($PowerProfile.IsOnACPower) { "Yes" } else { "No" }) -ForegroundColor $(if ($PowerProfile.IsOnACPower) { "Green" } else { "Yellow" })
    }
    Write-Host ""
}

function Show-Recommendations {
    <#
    .SYNOPSIS
        Displays system recommendations
    #>
    param([array]$Recommendations)

    Write-Host ""
    Write-Host "  SYSTEM RECOMMENDATIONS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    if ($Recommendations.Count -eq 0) {
        Write-Host "  No specific recommendations at this time." -ForegroundColor Green
        Write-Host ""
        return
    }

    $grouped = $Recommendations | Group-Object -Property Priority

    foreach ($group in $grouped | Sort-Object {
        switch ($_.Name) {
            "Critical" { 1 }
            "High" { 2 }
            "Warning" { 3 }
            "Info" { 4 }
            default { 5 }
        }
    }) {
        $priorityColor = switch ($group.Name) {
            "Critical" { "Red" }
            "High" { "Red" }
            "Warning" { "Yellow" }
            "Info" { "Cyan" }
            default { "White" }
        }

        foreach ($rec in $group.Group) {
            Write-Host "  [$($rec.Priority)]" -NoNewline -ForegroundColor $priorityColor
            Write-Host " $($rec.Category): " -NoNewline -ForegroundColor Gray
            Write-Host $rec.Message -ForegroundColor White
        }
    }
    Write-Host ""
}

function Show-PerformanceTierSummary {
    <#
    .SYNOPSIS
        Displays performance tier summary with visual bar
    #>
    param([PSCustomObject]$Tier)

    $tierColor = switch ($Tier.Tier) {
        "Ultra" { "Magenta" }
        "High" { "Green" }
        "Medium" { "Yellow" }
        "Low" { "DarkYellow" }
        "Minimal" { "Red" }
        default { "White" }
    }

    Write-Host ""
    Write-Host "  PERFORMANCE TIER" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Tier: " -NoNewline -ForegroundColor Gray
    Write-Host $Tier.Label -ForegroundColor $tierColor
    Write-Host ""

    # Score bar
    $barWidth = 40
    $filled = [math]::Round(($Tier.Score / $Tier.MaxScore) * $barWidth)
    $empty = $barWidth - $filled

    Write-Host "  Score: " -NoNewline -ForegroundColor Gray
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host ("=" * $filled) -NoNewline -ForegroundColor $tierColor
    Write-Host ("-" * $empty) -NoNewline -ForegroundColor DarkGray
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($Tier.Score)/$($Tier.MaxScore)" -ForegroundColor $tierColor
    Write-Host ""
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Get-SystemProfile',
    'Get-QuickHardwareCheck',
    'Get-CPUProfile',
    'Get-RAMProfile',
    'Get-StorageProfile',
    'Get-GPUProfile',
    'Get-SystemInfoProfile',
    'Get-NetworkProfile',
    'Get-PowerProfile',
    'Get-PerformanceTier',
    'Get-SystemRecommendations',
    'Export-SystemReport',
    'Show-CPUDetails',
    'Show-RAMDetails',
    'Show-StorageDetails',
    'Show-GPUDetails',
    'Show-NetworkDetails',
    'Show-PowerDetails',
    'Show-Recommendations',
    'Show-PerformanceTierSummary'
)
