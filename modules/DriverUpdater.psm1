<#
.SYNOPSIS
    Driver Updater Module for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Provides functions for updating and managing Windows drivers
.VERSION
    4.0
#>

# Import common functions
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ModulePath\CommonFunctions.psm1" -Force -ErrorAction SilentlyContinue

# ============================================================
# DRIVER INFORMATION FUNCTIONS
# ============================================================

function Get-InstalledDrivers {
    <#
    .SYNOPSIS
        Gets list of installed drivers with details
    .PARAMETER Category
        Filter by device category
    #>
    [CmdletBinding()]
    param(
        [string]$Category
    )

    try {
        $Drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop |
            Where-Object { $_.DeviceName } |
            Select-Object @{
                Name = 'DeviceName'; Expression = { $_.DeviceName }
            }, @{
                Name = 'Manufacturer'; Expression = { $_.Manufacturer }
            }, @{
                Name = 'DriverVersion'; Expression = { $_.DriverVersion }
            }, @{
                Name = 'DriverDate'; Expression = {
                    if ($_.DriverDate) {
                        [Management.ManagementDateTimeConverter]::ToDateTime($_.DriverDate)
                    }
                }
            }, @{
                Name = 'DeviceClass'; Expression = { $_.DeviceClass }
            }, @{
                Name = 'DeviceID'; Expression = { $_.DeviceID }
            }, @{
                Name = 'IsSigned'; Expression = { $_.IsSigned }
            }

        if ($Category) {
            $Drivers = $Drivers | Where-Object { $_.DeviceClass -like "*$Category*" }
        }

        return $Drivers | Sort-Object DeviceClass, DeviceName
    }
    catch {
        Write-Log "Failed to get installed drivers: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Get-OutdatedDrivers {
    <#
    .SYNOPSIS
        Identifies potentially outdated drivers
    #>
    [CmdletBinding()]
    param()

    $Drivers = Get-InstalledDrivers
    $CutoffDate = (Get-Date).AddYears(-2)

    $OutdatedDrivers = $Drivers | Where-Object {
        $_.DriverDate -and $_.DriverDate -lt $CutoffDate
    }

    return $OutdatedDrivers
}

function Get-ProblemDevices {
    <#
    .SYNOPSIS
        Gets devices with driver problems
    #>
    [CmdletBinding()]
    param()

    try {
        $Devices = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop |
            Where-Object { $_.ConfigManagerErrorCode -ne 0 } |
            Select-Object @{
                Name = 'Name'; Expression = { $_.Name }
            }, @{
                Name = 'Status'; Expression = { $_.Status }
            }, @{
                Name = 'ErrorCode'; Expression = { $_.ConfigManagerErrorCode }
            }, @{
                Name = 'ErrorDescription'; Expression = {
                    $ErrorCodes = @{
                        1 = "Device not configured correctly"
                        3 = "Driver corrupted"
                        10 = "Device cannot start"
                        12 = "Not enough resources"
                        14 = "Restart required"
                        18 = "Reinstall drivers"
                        19 = "Registry problem"
                        21 = "Windows is removing device"
                        22 = "Device disabled"
                        24 = "Device not present"
                        28 = "Drivers not installed"
                        29 = "Device disabled by firmware"
                        31 = "Device not working properly"
                        32 = "Driver blocked"
                        33 = "Device can't determine resources"
                        34 = "Device can't determine resources"
                        35 = "System firmware incomplete"
                        36 = "IRQ conflict"
                        37 = "Driver cannot be loaded"
                        38 = "Previous driver still in memory"
                        39 = "Registry corrupted"
                        40 = "Service registry key missing"
                        41 = "Device enumeration error"
                        42 = "Duplicate device detected"
                        43 = "Driver reported failure"
                        44 = "Device stopped"
                        45 = "Device not connected"
                        46 = "Windows cannot access device"
                        47 = "Device in safe removal"
                        48 = "Driver blocked"
                        49 = "Registry too large"
                        50 = "Device cannot be verified"
                        51 = "Device is preparing"
                        52 = "Driver signature problem"
                    }
                    if ($ErrorCodes.ContainsKey([int]$_.ConfigManagerErrorCode)) {
                        $ErrorCodes[[int]$_.ConfigManagerErrorCode]
                    } else {
                        "Unknown error ($($_.ConfigManagerErrorCode))"
                    }
                }
            }, @{
                Name = 'DeviceID'; Expression = { $_.DeviceID }
            }

        return $Devices
    }
    catch {
        Write-Log "Failed to get problem devices: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Show-DriverSummary {
    <#
    .SYNOPSIS
        Displays a summary of installed drivers
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Driver Summary" -Type Header

    $Drivers = Get-InstalledDrivers
    $OutdatedDrivers = Get-OutdatedDrivers
    $ProblemDevices = Get-ProblemDevices

    # Group drivers by class
    $DriversByClass = $Drivers | Group-Object DeviceClass

    Write-Host "    Driver Categories:" -ForegroundColor Cyan
    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray

    foreach ($Group in $DriversByClass | Sort-Object Count -Descending | Select-Object -First 10) {
        Write-Host "    $($Group.Name): " -ForegroundColor Gray -NoNewline
        Write-Host "$($Group.Count) drivers" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "    Statistics:" -ForegroundColor Cyan
    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "    Total Drivers:    " -ForegroundColor Gray -NoNewline
    Write-Host "$($Drivers.Count)" -ForegroundColor White
    Write-Host "    Outdated (>2yr):  " -ForegroundColor Gray -NoNewline
    if ($OutdatedDrivers.Count -gt 0) {
        Write-Host "$($OutdatedDrivers.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "$($OutdatedDrivers.Count)" -ForegroundColor Green
    }
    Write-Host "    Problem Devices:  " -ForegroundColor Gray -NoNewline
    if ($ProblemDevices.Count -gt 0) {
        Write-Host "$($ProblemDevices.Count)" -ForegroundColor Red
    } else {
        Write-Host "$($ProblemDevices.Count)" -ForegroundColor Green
    }
    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================================
# WINDOWS UPDATE DRIVER FUNCTIONS
# ============================================================

function Get-WindowsUpdateDrivers {
    <#
    .SYNOPSIS
        Gets available driver updates from Windows Update
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Checking Windows Update for Drivers" -Type Info

    try {
        # Create Windows Update session
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

        # Search for driver updates
        Write-ColorOutput -Message "Searching for driver updates..." -Type Info
        $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Driver'")

        $AvailableDrivers = @()

        if ($SearchResult.Updates.Count -gt 0) {
            foreach ($Update in $SearchResult.Updates) {
                $AvailableDrivers += @{
                    Title = $Update.Title
                    Description = $Update.Description
                    DriverClass = $Update.DriverClass
                    DriverManufacturer = $Update.DriverManufacturer
                    DriverModel = $Update.DriverModel
                    DriverVerDate = $Update.DriverVerDate
                    Size = [math]::Round($Update.MaxDownloadSize / 1MB, 2)
                }
            }

            Write-ColorOutput -Message "Found $($AvailableDrivers.Count) driver updates available" -Type Success
        }
        else {
            Write-ColorOutput -Message "No driver updates available from Windows Update" -Type Success
        }

        return $AvailableDrivers
    }
    catch {
        Write-Log "Failed to check Windows Update: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Install-WindowsUpdateDrivers {
    <#
    .SYNOPSIS
        Installs available driver updates from Windows Update
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Installing Driver Updates from Windows Update" -Type Header

    try {
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

        Write-ColorOutput -Message "Searching for driver updates..." -Type Info
        $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Driver'")

        if ($SearchResult.Updates.Count -eq 0) {
            Write-ColorOutput -Message "No driver updates available" -Type Success
            return @{ Installed = 0; Failed = 0 }
        }

        Write-ColorOutput -Message "Found $($SearchResult.Updates.Count) driver updates" -Type Info
        Write-Host ""

        # Show available updates
        Write-Host "    Available Updates:" -ForegroundColor Cyan
        Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
        foreach ($Update in $SearchResult.Updates) {
            Write-Host "    - $($Update.Title)" -ForegroundColor White
        }
        Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""

        # Confirm installation
        $Confirm = Get-ConfirmationPrompt -Message "Install all driver updates?"
        if (-not $Confirm) {
            Write-ColorOutput -Message "Installation cancelled" -Type Info
            return @{ Installed = 0; Failed = 0; Cancelled = $true }
        }

        # Download updates
        Write-ColorOutput -Message "Downloading updates..." -Type Info
        $UpdatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl

        foreach ($Update in $SearchResult.Updates) {
            if (-not $Update.IsDownloaded) {
                $UpdatesToDownload.Add($Update) | Out-Null
            }
        }

        if ($UpdatesToDownload.Count -gt 0) {
            $Downloader = $UpdateSession.CreateUpdateDownloader()
            $Downloader.Updates = $UpdatesToDownload
            $DownloadResult = $Downloader.Download()
        }

        # Install updates
        Write-ColorOutput -Message "Installing updates..." -Type Info
        $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

        foreach ($Update in $SearchResult.Updates) {
            if ($Update.IsDownloaded) {
                $UpdatesToInstall.Add($Update) | Out-Null
            }
        }

        if ($UpdatesToInstall.Count -gt 0) {
            $Installer = $UpdateSession.CreateUpdateInstaller()
            $Installer.Updates = $UpdatesToInstall
            $InstallResult = $Installer.Install()

            $Installed = 0
            $Failed = 0

            for ($i = 0; $i -lt $UpdatesToInstall.Count; $i++) {
                $UpdateResult = $InstallResult.GetUpdateResult($i)
                if ($UpdateResult.ResultCode -eq 2) {  # Succeeded
                    $Installed++
                    Write-Host "    [+] $($UpdatesToInstall.Item($i).Title)" -ForegroundColor Green
                }
                else {
                    $Failed++
                    Write-Host "    [X] $($UpdatesToInstall.Item($i).Title)" -ForegroundColor Red
                }
            }

            Write-Host ""
            Write-ColorOutput -Message "Driver Update Complete" -Type Header
            Write-Host "    Installed: " -ForegroundColor Green -NoNewline
            Write-Host "$Installed" -ForegroundColor White
            Write-Host "    Failed:    " -ForegroundColor Red -NoNewline
            Write-Host "$Failed" -ForegroundColor White

            if ($InstallResult.RebootRequired) {
                Write-Host ""
                Write-ColorOutput -Message "A restart is required to complete the installation" -Type Warning
            }

            return @{ Installed = $Installed; Failed = $Failed; RebootRequired = $InstallResult.RebootRequired }
        }
    }
    catch {
        Write-Log "Failed to install driver updates: $($_.Exception.Message)" -Level ERROR
        return @{ Installed = 0; Failed = 0; Error = $_.Exception.Message }
    }

    return @{ Installed = 0; Failed = 0 }
}

# ============================================================
# DRIVER BACKUP AND RESTORE
# ============================================================

function Backup-Drivers {
    <#
    .SYNOPSIS
        Backs up all third-party drivers
    .PARAMETER BackupPath
        Path to save the backup
    #>
    [CmdletBinding()]
    param(
        [string]$BackupPath
    )

    if (-not $BackupPath) {
        $BackupPath = "$env:ProgramData\UltimateWindowsToolkit\Backups\Drivers_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }

    Write-ColorOutput -Message "Backing Up Drivers" -Type Header
    Write-ColorOutput -Message "Destination: $BackupPath" -Type Info

    try {
        # Create backup directory
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }

        # Use DISM to export drivers
        Write-ColorOutput -Message "Exporting drivers (this may take a few minutes)..." -Type Info

        $Result = Start-Process "dism.exe" -ArgumentList "/Online /Export-Driver /Destination:`"$BackupPath`"" -Wait -NoNewWindow -PassThru

        if ($Result.ExitCode -eq 0) {
            # Count backed up drivers
            $BackedUpDrivers = Get-ChildItem -Path $BackupPath -Directory
            Write-ColorOutput -Message "Backed up $($BackedUpDrivers.Count) driver packages" -Type Success
            Write-Host "    Location: $BackupPath" -ForegroundColor White

            return @{
                Success = $true
                Path = $BackupPath
                Count = $BackedUpDrivers.Count
            }
        }
        else {
            Write-ColorOutput -Message "Driver backup failed with exit code $($Result.ExitCode)" -Type Error
            return @{ Success = $false }
        }
    }
    catch {
        Write-Log "Driver backup failed: $($_.Exception.Message)" -Level ERROR
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Restore-Driver {
    <#
    .SYNOPSIS
        Restores a driver from backup
    .PARAMETER InfPath
        Path to the driver INF file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InfPath
    )

    if (-not (Test-Path $InfPath)) {
        Write-ColorOutput -Message "Driver file not found: $InfPath" -Type Error
        return $false
    }

    Write-ColorOutput -Message "Installing driver: $InfPath" -Type Info

    try {
        $Result = Start-Process "pnputil.exe" -ArgumentList "/add-driver `"$InfPath`" /install" -Wait -NoNewWindow -PassThru

        if ($Result.ExitCode -eq 0) {
            Write-ColorOutput -Message "Driver installed successfully" -Type Success
            return $true
        }
        else {
            Write-ColorOutput -Message "Driver installation failed" -Type Error
            return $false
        }
    }
    catch {
        Write-Log "Driver restore failed: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================================
# MANUFACTURER-SPECIFIC DRIVERS
# ============================================================

function Get-GPUDriverInfo {
    <#
    .SYNOPSIS
        Gets GPU driver information and update links
    #>
    [CmdletBinding()]
    param()

    $SysInfo = Get-SystemInfo

    $GPUInfo = @{
        Name = $SysInfo.GPUName
        IsNVIDIA = $SysInfo.IsNVIDIA
        IsAMD = $SysInfo.IsAMD
        IsIntel = $SysInfo.CPUName -like "*Intel*" -and -not $SysInfo.IsNVIDIA -and -not $SysInfo.IsAMD
        UpdateURL = ""
        DriverTool = ""
    }

    if ($GPUInfo.IsNVIDIA) {
        $GPUInfo.UpdateURL = "https://www.nvidia.com/Download/index.aspx"
        $GPUInfo.DriverTool = "GeForce Experience"
    }
    elseif ($GPUInfo.IsAMD) {
        $GPUInfo.UpdateURL = "https://www.amd.com/en/support"
        $GPUInfo.DriverTool = "AMD Software: Adrenalin Edition"
    }
    elseif ($GPUInfo.IsIntel) {
        $GPUInfo.UpdateURL = "https://www.intel.com/content/www/us/en/download-center/home.html"
        $GPUInfo.DriverTool = "Intel Driver & Support Assistant"
    }

    return $GPUInfo
}

function Open-DriverDownloadPage {
    <#
    .SYNOPSIS
        Opens the appropriate driver download page for the system's GPU
    #>
    [CmdletBinding()]
    param()

    $GPUInfo = Get-GPUDriverInfo

    Write-ColorOutput -Message "GPU Driver Information" -Type Header
    Write-Host "    GPU:         " -ForegroundColor Gray -NoNewline
    Write-Host "$($GPUInfo.Name)" -ForegroundColor White
    Write-Host "    Driver Tool: " -ForegroundColor Gray -NoNewline
    Write-Host "$($GPUInfo.DriverTool)" -ForegroundColor White
    Write-Host ""

    if ($GPUInfo.UpdateURL) {
        Write-ColorOutput -Message "Opening driver download page..." -Type Info
        Start-Process $GPUInfo.UpdateURL
        Write-ColorOutput -Message "Download the latest driver from the opened page" -Type Info
    }
    else {
        Write-ColorOutput -Message "Could not determine GPU manufacturer" -Type Warning
    }
}

# ============================================================
# DRIVER UPDATE MENU
# ============================================================

function Show-DriverMenu {
    <#
    .SYNOPSIS
        Shows the driver management menu
    #>
    [CmdletBinding()]
    param()

    $Continue = $true

    while ($Continue) {
        Show-Banner -Title "DRIVER MANAGER"

        Write-Host "    ║                                                                   ║" -ForegroundColor Cyan
        Show-MenuOption -Key "1" -Icon "i" -Text "Show Driver Summary"
        Show-MenuOption -Key "2" -Icon "?" -Text "Show Problem Devices"
        Show-MenuOption -Key "3" -Icon "U" -Text "Check for Driver Updates (Windows Update)"
        Show-MenuOption -Key "4" -Icon "I" -Text "Install Driver Updates"
        Show-MenuOption -Key "5" -Icon "G" -Text "Open GPU Driver Download Page"
        Show-MenuOption -Key "6" -Icon "B" -Text "Backup All Drivers"
        Write-Host "    ║                                                                   ║" -ForegroundColor Cyan
        Show-MenuOption -Key "B" -Icon "<" -Text "Back to Main Menu"
        Show-MenuFooter

        $Choice = Get-MenuChoice -Prompt "Select an option" -ValidChoices @('1', '2', '3', '4', '5', '6', 'B', 'Q')

        switch ($Choice) {
            '1' {
                Show-DriverSummary
                Wait-KeyPress
            }
            '2' {
                Write-ColorOutput -Message "Problem Devices" -Type Header
                $Problems = Get-ProblemDevices
                if ($Problems.Count -gt 0) {
                    foreach ($Device in $Problems) {
                        Write-Host "    [!] $($Device.Name)" -ForegroundColor Red
                        Write-Host "        Error: $($Device.ErrorDescription)" -ForegroundColor Yellow
                        Write-Host ""
                    }
                }
                else {
                    Write-ColorOutput -Message "No problem devices found" -Type Success
                }
                Wait-KeyPress
            }
            '3' {
                $Available = Get-WindowsUpdateDrivers
                if ($Available.Count -gt 0) {
                    Write-Host ""
                    Write-Host "    Available Driver Updates:" -ForegroundColor Cyan
                    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
                    foreach ($Driver in $Available) {
                        Write-Host "    - $($Driver.Title)" -ForegroundColor White
                        Write-Host "      Size: $($Driver.Size) MB" -ForegroundColor Gray
                    }
                    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
                }
                Wait-KeyPress
            }
            '4' {
                Install-WindowsUpdateDrivers
                Wait-KeyPress
            }
            '5' {
                Open-DriverDownloadPage
                Wait-KeyPress
            }
            '6' {
                Backup-Drivers
                Wait-KeyPress
            }
            'B' { $Continue = $false }
            'Q' {
                $Continue = $false
                return 'EXIT'
            }
        }
    }
}

# ============================================================
# EXPORT MODULE MEMBERS
# ============================================================

Export-ModuleMember -Function @(
    'Get-InstalledDrivers',
    'Get-OutdatedDrivers',
    'Get-ProblemDevices',
    'Show-DriverSummary',
    'Get-WindowsUpdateDrivers',
    'Install-WindowsUpdateDrivers',
    'Backup-Drivers',
    'Restore-Driver',
    'Get-GPUDriverInfo',
    'Open-DriverDownloadPage',
    'Show-DriverMenu'
)
