<#
.SYNOPSIS
    Windows Debloater Module for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Provides functions for removing Windows bloatware, disabling telemetry,
    and privacy hardening with Safe and Aggressive modes
.VERSION
    4.0
#>

# Import common functions
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ModulePath\CommonFunctions.psm1" -Force -ErrorAction SilentlyContinue

# ============================================================
# BLOATWARE LISTS - SAFE MODE
# ============================================================

function Get-SafeBloatwareList {
    <#
    .SYNOPSIS
        Returns the SAFE list of bloatware apps to remove
        These are generally safe to remove without breaking functionality
    #>
    [CmdletBinding()]
    param()

    return @(
        # Microsoft Bloat - Safe to Remove
        "Microsoft.3DBuilder"
        "Microsoft.549981C3F5F10"         # Cortana
        "Microsoft.BingNews"
        "Microsoft.BingWeather"
        "Microsoft.Getstarted"             # Tips
        "Microsoft.GetHelp"
        "Microsoft.Messaging"
        "Microsoft.Microsoft3DViewer"
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.MixedReality.Portal"
        "Microsoft.Office.OneNote"
        "Microsoft.OneConnect"
        "Microsoft.People"
        "Microsoft.Print3D"
        "Microsoft.SkypeApp"
        "Microsoft.Wallet"
        "Microsoft.WindowsAlarms"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.YourPhone"              # Phone Link
        "Microsoft.ZuneMusic"              # Groove Music
        "Microsoft.ZuneVideo"              # Movies & TV
        "Clipchamp.Clipchamp"
        "Microsoft.Todos"
        "Microsoft.PowerAutomateDesktop"
        "MicrosoftTeams"
        "Microsoft.MicrosoftStickyNotes"
        "Microsoft.BingSearch"

        # Third-party Bloat
        "*BubbleWitch*"
        "*CandyCrush*"
        "*Dolby*"
        "*Facebook*"
        "*Keeper*"
        "*Netflix*"
        "*Twitter*"
        "*Plex*"
        "king.com.*"
        "*Disney*"
        "*AdobePhotoshopExpress*"
        "*Duolingo*"
        "*EclipseManager*"
        "*ActiproSoftwareLLC*"
        "*SpotifyAB*"
        "*PandoraMediaInc*"
        "*Flipboard*"
        "*Wunderlist*"
        "*Drawboard*"
        "*FarmVille*"
        "*Royal Revolt*"
        "*Sway*"
        "*Speed Test*"
        "*Minecraft*"
        "*LinkedIn*"
        "*McAfee*"
        "*Norton*"
        "*HPPrinter*"
        "*DellSupportAssist*"
    )
}

# ============================================================
# BLOATWARE LISTS - AGGRESSIVE MODE
# ============================================================

function Get-AggressiveBloatwareList {
    <#
    .SYNOPSIS
        Returns the AGGRESSIVE list of bloatware apps to remove
        WARNING: May affect some Windows functionality
    #>
    [CmdletBinding()]
    param()

    # Start with safe list
    $List = Get-SafeBloatwareList

    # Add aggressive removals
    $List += @(
        # Microsoft Store and Related
        "Microsoft.WindowsStore"
        "Microsoft.StorePurchaseApp"

        # Edge Browser
        "Microsoft.MicrosoftEdge"
        "Microsoft.MicrosoftEdge.Stable"

        # Windows Security (Use with caution)
        "Microsoft.SecHealthUI"

        # OneDrive
        "Microsoft.OneDrive"
        "Microsoft.OneDriveSync"

        # Microsoft 365
        "Microsoft.Office.Desktop"
        "Microsoft.MicrosoftOfficeHub"

        # Copilot
        "Microsoft.Copilot"

        # Cortana
        "Microsoft.549981C3F5F10"

        # Mail & Calendar
        "microsoft.windowscommunicationsapps"

        # Photos (use alternative)
        "Microsoft.Windows.Photos"

        # Voice Recorder
        "Microsoft.WindowsSoundRecorder"

        # Groove Music
        "Microsoft.ZuneMusic"

        # Movies & TV
        "Microsoft.ZuneVideo"

        # News
        "Microsoft.BingNews"

        # Weather
        "Microsoft.BingWeather"

        # Xbox-related (all)
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxApp"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.GamingApp"
        "Microsoft.GamingServices"

        # Paint 3D
        "Microsoft.MSPaint"

        # Snipping Tool (classic)
        "Microsoft.ScreenSketch"
    )

    return $List | Select-Object -Unique
}

# ============================================================
# XBOX APPS LIST
# ============================================================

function Get-XboxAppsList {
    <#
    .SYNOPSIS
        Returns list of all Xbox-related apps
    #>
    [CmdletBinding()]
    param()

    return @(
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxApp"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.GamingApp"
        "Microsoft.GamingServices"
    )
}

# ============================================================
# PROTECTED APPS LIST
# ============================================================

function Get-ProtectedAppsList {
    <#
    .SYNOPSIS
        Returns list of apps that should NEVER be removed
    #>
    [CmdletBinding()]
    param()

    return @(
        "Microsoft.WindowsCalculator"
        "Microsoft.WindowsCamera"
        "Microsoft.WindowsNotepad"
        "Microsoft.Paint"
        "Microsoft.WindowsTerminal"
        "Microsoft.PowerShell"
        "Microsoft.DesktopAppInstaller"    # Winget - CRITICAL
        "Microsoft.HEIFImageExtension"
        "Microsoft.HEVCVideoExtension"
        "Microsoft.WebMediaExtensions"
        "Microsoft.VP9VideoExtensions"
        "Microsoft.WebpImageExtension"
        "Microsoft.VCLibs*"
        "Microsoft.NET*"
        "Microsoft.UI.Xaml*"
    )
}

# ============================================================
# BLOATWARE REMOVAL FUNCTIONS
# ============================================================

function Get-InstalledBloatware {
    <#
    .SYNOPSIS
        Gets list of installed bloatware apps
    .PARAMETER Mode
        Safe or Aggressive mode
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Safe', 'Aggressive')]
        [string]$Mode = 'Safe'
    )

    $BloatwareList = if ($Mode -eq 'Aggressive') {
        Get-AggressiveBloatwareList
    }
    else {
        Get-SafeBloatwareList
    }

    $ProtectedApps = Get-ProtectedAppsList
    $InstalledBloat = @()

    foreach ($Pattern in $BloatwareList) {
        try {
            $Apps = Get-AppxPackage -Name $Pattern -AllUsers -ErrorAction SilentlyContinue

            foreach ($App in $Apps) {
                # Skip protected apps
                $IsProtected = $false
                foreach ($Protected in $ProtectedApps) {
                    if ($App.Name -like $Protected) {
                        $IsProtected = $true
                        break
                    }
                }

                if (-not $IsProtected) {
                    $InstalledBloat += $App
                }
            }
        }
        catch { }
    }

    return $InstalledBloat | Sort-Object Name -Unique
}

function Remove-BloatwareApp {
    <#
    .SYNOPSIS
        Removes a single bloatware app
    .PARAMETER AppName
        Name of the app to remove
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName
    )

    try {
        # Remove for current user
        Get-AppxPackage -Name $AppName -ErrorAction SilentlyContinue |
            Remove-AppxPackage -ErrorAction SilentlyContinue

        # Remove provisioned package (prevents reinstall)
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.PackageName -like "*$AppName*" } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null

        Write-Host "    [+] Removed: $AppName" -ForegroundColor Green
        Write-Log "Removed: $AppName" -Level SUCCESS -NoConsole
        return $true
    }
    catch {
        Write-Host "    [-] Failed: $AppName" -ForegroundColor Red
        Write-Log "Failed to remove: $AppName - $($_.Exception.Message)" -Level WARNING -NoConsole
        return $false
    }
}

function Remove-SafeBloatware {
    <#
    .SYNOPSIS
        Removes bloatware using SAFE mode (default apps)
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Removing Bloatware (SAFE Mode)" -Type Header
    Write-Host "    This removes default Windows bloatware while preserving" -ForegroundColor Gray
    Write-Host "    essential system apps like Windows Store and Edge." -ForegroundColor Gray
    Write-Host ""

    $InstalledBloat = Get-InstalledBloatware -Mode 'Safe'

    if ($InstalledBloat.Count -eq 0) {
        Write-ColorOutput -Message "No bloatware found to remove" -Type Success
        return @{ Removed = 0; Failed = 0 }
    }

    Write-Host "    Found $($InstalledBloat.Count) apps to remove" -ForegroundColor Yellow
    Write-Host ""

    $Removed = 0
    $Failed = 0

    foreach ($App in $InstalledBloat) {
        if (Remove-BloatwareApp -AppName $App.Name) {
            $Removed++
        }
        else {
            $Failed++
        }
    }

    Write-Host ""
    Write-ColorOutput -Message "Safe Bloatware Removal Complete" -Type Header
    Write-Host "    Removed: $Removed" -ForegroundColor Green
    Write-Host "    Failed:  $Failed" -ForegroundColor Red

    return @{ Removed = $Removed; Failed = $Failed }
}

function Remove-AggressiveBloatware {
    <#
    .SYNOPSIS
        Removes bloatware using AGGRESSIVE mode (includes Store, Edge, etc.)
        WARNING: This may affect some Windows functionality!
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Removing Bloatware (AGGRESSIVE Mode)" -Type Header
    Write-Host ""
    Write-Host "    ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "    ║  WARNING: AGGRESSIVE MODE                                     ║" -ForegroundColor Red
    Write-Host "    ║  This will remove Windows Store, Edge, and other core apps!  ║" -ForegroundColor Red
    Write-Host "    ║  Some Windows features may stop working properly.            ║" -ForegroundColor Red
    Write-Host "    ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""

    $InstalledBloat = Get-InstalledBloatware -Mode 'Aggressive'

    if ($InstalledBloat.Count -eq 0) {
        Write-ColorOutput -Message "No bloatware found to remove" -Type Success
        return @{ Removed = 0; Failed = 0 }
    }

    Write-Host "    Found $($InstalledBloat.Count) apps to remove" -ForegroundColor Yellow
    Write-Host ""

    $Removed = 0
    $Failed = 0

    foreach ($App in $InstalledBloat) {
        if (Remove-BloatwareApp -AppName $App.Name) {
            $Removed++
        }
        else {
            $Failed++
        }
    }

    Write-Host ""
    Write-ColorOutput -Message "Aggressive Bloatware Removal Complete" -Type Header
    Write-Host "    Removed: $Removed" -ForegroundColor Green
    Write-Host "    Failed:  $Failed" -ForegroundColor Red

    return @{ Removed = $Removed; Failed = $Failed }
}

function Remove-XboxApps {
    <#
    .SYNOPSIS
        Removes all Xbox-related apps
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Removing Xbox/Gaming Apps" -Type Header

    $XboxApps = Get-XboxAppsList
    $Removed = 0
    $Failed = 0

    foreach ($AppPattern in $XboxApps) {
        $Apps = Get-AppxPackage -Name $AppPattern -AllUsers -ErrorAction SilentlyContinue
        foreach ($App in $Apps) {
            if (Remove-BloatwareApp -AppName $App.Name) {
                $Removed++
            }
            else {
                $Failed++
            }
        }
    }

    # Disable Xbox services
    Write-Host ""
    Write-Host "    Disabling Xbox services..." -ForegroundColor Yellow

    $XboxServices = @(
        "XblAuthManager",
        "XblGameSave",
        "XboxNetApiSvc",
        "XboxGipSvc"
    )

    foreach ($svc in $XboxServices) {
        try {
            Stop-Service $svc -Force -ErrorAction SilentlyContinue
            Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "    [+] Disabled: $svc" -ForegroundColor Green
        }
        catch {
            Write-Host "    [-] Failed: $svc" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-ColorOutput -Message "Xbox Apps Removal Complete" -Type Header
    Write-Host "    Removed: $Removed" -ForegroundColor Green
    Write-Host "    Failed:  $Failed" -ForegroundColor Red

    return @{ Removed = $Removed; Failed = $Failed }
}

# ============================================================
# TELEMETRY AND PRIVACY FUNCTIONS
# ============================================================

function Disable-WindowsTelemetry {
    <#
    .SYNOPSIS
        Disables Windows telemetry and data collection - COMPREHENSIVE
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Disabling Windows Telemetry" -Type Header

    # Main telemetry settings
    $TelemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $TelemetryPath)) {
        New-Item -Path $TelemetryPath -Force | Out-Null
    }
    Set-RegistryValue -Path $TelemetryPath -Name "AllowTelemetry" -Value 0 `
        -Description "Telemetry disabled"
    Set-RegistryValue -Path $TelemetryPath -Name "MaxTelemetryAllowed" -Value 0

    # Disable Connected User Experience (DiagTrack)
    Write-Host "    Disabling DiagTrack service..." -ForegroundColor Gray
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "    [+] DiagTrack (Connected User Experience) disabled" -ForegroundColor Green

    # Disable WAP Push Service (dmwappushservice)
    Write-Host "    Disabling dmwappushservice..." -ForegroundColor Gray
    Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
    Set-Service "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "    [+] dmwappushservice disabled" -ForegroundColor Green

    # Disable Diagnostics Tracking Service
    Stop-Service "diagnosticshub.standardcollector.service" -Force -ErrorAction SilentlyContinue
    Set-Service "diagnosticshub.standardcollector.service" -StartupType Disabled -ErrorAction SilentlyContinue

    # Disable Windows Error Reporting
    $WERPath = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
    Set-RegistryValue -Path $WERPath -Name "Disabled" -Value 1 `
        -Description "Windows Error Reporting disabled"

    # Disable Customer Experience Improvement Program
    $CEIPPath = "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows"
    if (-not (Test-Path $CEIPPath)) {
        New-Item -Path $CEIPPath -Force | Out-Null
    }
    Set-RegistryValue -Path $CEIPPath -Name "CEIPEnable" -Value 0 `
        -Description "CEIP disabled"

    # Disable Application Telemetry
    $AppTelemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"
    if (-not (Test-Path $AppTelemetryPath)) {
        New-Item -Path $AppTelemetryPath -Force | Out-Null
    }
    Set-RegistryValue -Path $AppTelemetryPath -Name "AITEnable" -Value 0 `
        -Description "Application telemetry disabled"
    Set-RegistryValue -Path $AppTelemetryPath -Name "DisableInventory" -Value 1
    Set-RegistryValue -Path $AppTelemetryPath -Name "DisablePCA" -Value 1
    Set-RegistryValue -Path $AppTelemetryPath -Name "DisableUAR" -Value 1

    # Disable Scheduled Tasks for telemetry
    Write-Host "    Disabling telemetry scheduled tasks..." -ForegroundColor Gray
    $TelemetryTasks = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
        "\Microsoft\Windows\Application Experience\StartupAppTask"
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
        "\Microsoft\Windows\Feedback\Siuf\DmClient"
        "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
        "\Microsoft\Windows\PI\Sqm-Tasks"
        "\Microsoft\Windows\NetTrace\GatherNetworkInfo"
    )

    $DisabledCount = 0
    foreach ($task in $TelemetryTasks) {
        try {
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            $DisabledCount++
        }
        catch { }
    }
    Write-Host "    [+] Disabled $DisabledCount telemetry tasks" -ForegroundColor Green

    Write-Log "Telemetry disabled" -Level SUCCESS
    return $true
}

function Disable-Cortana {
    <#
    .SYNOPSIS
        Disables Cortana completely
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Disabling Cortana" -Type Header

    $CortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $CortanaPath)) {
        New-Item -Path $CortanaPath -Force | Out-Null
    }

    Set-RegistryValue -Path $CortanaPath -Name "AllowCortana" -Value 0 `
        -Description "Cortana disabled"
    Set-RegistryValue -Path $CortanaPath -Name "AllowCortanaAboveLock" -Value 0
    Set-RegistryValue -Path $CortanaPath -Name "AllowSearchToUseLocation" -Value 0
    Set-RegistryValue -Path $CortanaPath -Name "DisableWebSearch" -Value 1
    Set-RegistryValue -Path $CortanaPath -Name "ConnectedSearchUseWeb" -Value 0
    Set-RegistryValue -Path $CortanaPath -Name "ConnectedSearchUseWebOverMeteredConnections" -Value 0

    # Remove Cortana app
    Get-AppxPackage -Name "Microsoft.549981C3F5F10" -AllUsers -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    Write-Host "    [+] Cortana disabled" -ForegroundColor Green
    Write-Log "Cortana disabled" -Level SUCCESS
    return $true
}

function Invoke-PrivacyHardening {
    <#
    .SYNOPSIS
        Applies comprehensive privacy hardening settings
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Applying Privacy Hardening" -Type Header

    # ---- Disable Activity History ----
    Write-Host "    Disabling Activity History..." -ForegroundColor Gray
    $ActivityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (-not (Test-Path $ActivityPath)) {
        New-Item -Path $ActivityPath -Force | Out-Null
    }
    Set-RegistryValue -Path $ActivityPath -Name "EnableActivityFeed" -Value 0
    Set-RegistryValue -Path $ActivityPath -Name "PublishUserActivities" -Value 0
    Set-RegistryValue -Path $ActivityPath -Name "UploadUserActivities" -Value 0
    Write-Host "    [+] Activity History disabled" -ForegroundColor Green

    # ---- Disable Advertising ID ----
    Write-Host "    Disabling Advertising ID..." -ForegroundColor Gray
    $AdIDPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    Set-RegistryValue -Path $AdIDPath -Name "Enabled" -Value 0
    $PrivacyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
    if (-not (Test-Path $PrivacyPath)) {
        New-Item -Path $PrivacyPath -Force | Out-Null
    }
    Set-RegistryValue -Path $PrivacyPath -Name "DisabledByGroupPolicy" -Value 1
    Write-Host "    [+] Advertising ID disabled" -ForegroundColor Green

    # ---- Disable Windows Feedback ----
    Write-Host "    Disabling Windows Feedback..." -ForegroundColor Gray
    $FeedbackPath = "HKCU:\Software\Microsoft\Siuf\Rules"
    if (-not (Test-Path $FeedbackPath)) {
        New-Item -Path $FeedbackPath -Force | Out-Null
    }
    Set-RegistryValue -Path $FeedbackPath -Name "NumberOfSIUFInPeriod" -Value 0
    Set-RegistryValue -Path $FeedbackPath -Name "PeriodInNanoSeconds" -Value 0
    Write-Host "    [+] Windows Feedback disabled" -ForegroundColor Green

    # ---- Disable Windows Tips ----
    Write-Host "    Disabling Windows Tips & Suggestions..." -ForegroundColor Gray
    $TipsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $TipsPath)) {
        New-Item -Path $TipsPath -Force | Out-Null
    }
    Set-RegistryValue -Path $TipsPath -Name "DisableSoftLanding" -Value 1
    Set-RegistryValue -Path $TipsPath -Name "DisableWindowsConsumerFeatures" -Value 1
    Set-RegistryValue -Path $TipsPath -Name "DisableWindowsSpotlightFeatures" -Value 1
    Set-RegistryValue -Path $TipsPath -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1

    $ContentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-RegistryValue -Path $ContentPath -Name "SystemPaneSuggestionsEnabled" -Value 0
    Set-RegistryValue -Path $ContentPath -Name "SubscribedContent-338388Enabled" -Value 0
    Set-RegistryValue -Path $ContentPath -Name "SubscribedContent-338389Enabled" -Value 0
    Set-RegistryValue -Path $ContentPath -Name "SubscribedContent-353696Enabled" -Value 0
    Set-RegistryValue -Path $ContentPath -Name "SubscribedContent-353698Enabled" -Value 0
    Set-RegistryValue -Path $ContentPath -Name "SilentInstalledAppsEnabled" -Value 0
    Set-RegistryValue -Path $ContentPath -Name "SoftLandingEnabled" -Value 0
    Write-Host "    [+] Windows Tips disabled" -ForegroundColor Green

    # ---- Disable Location Tracking ----
    Write-Host "    Disabling Location Tracking..." -ForegroundColor Gray
    $LocationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
    if (-not (Test-Path $LocationPath)) {
        New-Item -Path $LocationPath -Force | Out-Null
    }
    Set-RegistryValue -Path $LocationPath -Name "DisableLocation" -Value 1
    Set-RegistryValue -Path $LocationPath -Name "DisableLocationScripting" -Value 1
    Set-RegistryValue -Path $LocationPath -Name "DisableWindowsLocationProvider" -Value 1

    $LocationSvcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
    if (-not (Test-Path $LocationSvcPath)) {
        New-Item -Path $LocationSvcPath -Force | Out-Null
    }
    Set-RegistryValue -Path $LocationSvcPath -Name "Status" -Value 0
    Write-Host "    [+] Location Tracking disabled" -ForegroundColor Green

    # ---- Disable Handwriting Data Sharing ----
    Write-Host "    Disabling Handwriting Data Sharing..." -ForegroundColor Gray
    $HandwritingPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC"
    if (-not (Test-Path $HandwritingPath)) {
        New-Item -Path $HandwritingPath -Force | Out-Null
    }
    Set-RegistryValue -Path $HandwritingPath -Name "PreventHandwritingDataSharing" -Value 1
    Write-Host "    [+] Handwriting Data Sharing disabled" -ForegroundColor Green

    # ---- Disable Input Personalization ----
    Write-Host "    Disabling Input Personalization..." -ForegroundColor Gray
    $InputPath = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization"
    if (-not (Test-Path $InputPath)) {
        New-Item -Path $InputPath -Force | Out-Null
    }
    Set-RegistryValue -Path $InputPath -Name "RestrictImplicitInkCollection" -Value 1
    Set-RegistryValue -Path $InputPath -Name "RestrictImplicitTextCollection" -Value 1
    Write-Host "    [+] Input Personalization disabled" -ForegroundColor Green

    # ---- Disable Clipboard History ----
    Write-Host "    Disabling Clipboard History..." -ForegroundColor Gray
    $ClipboardPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    Set-RegistryValue -Path $ClipboardPath -Name "AllowClipboardHistory" -Value 0
    Set-RegistryValue -Path $ClipboardPath -Name "AllowCrossDeviceClipboard" -Value 0
    Write-Host "    [+] Clipboard History disabled" -ForegroundColor Green

    # ---- Disable WiFi Sense ----
    Write-Host "    Disabling WiFi Sense..." -ForegroundColor Gray
    $WifiPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi"
    if (Test-Path "$WifiPath\AllowWiFiHotSpotReporting") {
        Set-RegistryValue -Path "$WifiPath\AllowWiFiHotSpotReporting" -Name "value" -Value 0
    }
    if (Test-Path "$WifiPath\AllowAutoConnectToWiFiSenseHotspots") {
        Set-RegistryValue -Path "$WifiPath\AllowAutoConnectToWiFiSenseHotspots" -Name "value" -Value 0
    }
    Write-Host "    [+] WiFi Sense disabled" -ForegroundColor Green

    # ---- Disable Find My Device ----
    Write-Host "    Disabling Find My Device..." -ForegroundColor Gray
    $FindMyPath = "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice"
    if (-not (Test-Path $FindMyPath)) {
        New-Item -Path $FindMyPath -Force | Out-Null
    }
    Set-RegistryValue -Path $FindMyPath -Name "AllowFindMyDevice" -Value 0
    Write-Host "    [+] Find My Device disabled" -ForegroundColor Green

    Write-Host ""
    Write-ColorOutput -Message "Privacy Hardening Complete" -Type Success
    Write-Log "Privacy hardening applied" -Level SUCCESS
    return $true
}

# ============================================================
# COMPLETE DEBLOAT OPERATIONS
# ============================================================

function Invoke-Debloat {
    <#
    .SYNOPSIS
        Performs complete Windows debloat
    .PARAMETER Mode
        Safe or Aggressive mode
    .PARAMETER IncludeXbox
        Whether to remove Xbox apps
    .PARAMETER SkipBloatware
        Skip bloatware removal
    .PARAMETER SkipTelemetry
        Skip telemetry disabling
    .PARAMETER SkipPrivacy
        Skip privacy hardening
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Safe', 'Aggressive')]
        [string]$Mode = 'Safe',

        [switch]$IncludeXbox,
        [switch]$SkipBloatware,
        [switch]$SkipTelemetry,
        [switch]$SkipPrivacy
    )

    Write-ColorOutput -Message "Starting Windows Debloat ($Mode Mode)" -Type Header

    $Results = @{
        BloatwareRemoval  = $null
        XboxRemoval       = $null
        TelemetryDisabled = $null
        PrivacyHardened   = $null
    }

    # Remove bloatware
    if (-not $SkipBloatware) {
        Write-Host ""
        if ($Mode -eq 'Aggressive') {
            $Results['BloatwareRemoval'] = Remove-AggressiveBloatware
        }
        else {
            $Results['BloatwareRemoval'] = Remove-SafeBloatware
        }
    }

    # Remove Xbox apps
    if ($IncludeXbox) {
        Write-Host ""
        $Results['XboxRemoval'] = Remove-XboxApps
    }

    # Disable telemetry
    if (-not $SkipTelemetry) {
        Write-Host ""
        $Results['TelemetryDisabled'] = Disable-WindowsTelemetry
    }

    # Apply privacy hardening
    if (-not $SkipPrivacy) {
        Write-Host ""
        $Results['PrivacyHardened'] = Invoke-PrivacyHardening
    }

    # Final summary
    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-ColorOutput -Message "Debloat Complete" -Type Header
    Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "    A restart is recommended to complete all changes." -ForegroundColor Yellow
    Write-Host ""

    return $Results
}

function Invoke-FullDebloatAndActivate {
    <#
    .SYNOPSIS
        Performs full debloat + activation (calls MAS for activation)
    .DESCRIPTION
        Combines debloat operations with Windows activation
    #>
    [CmdletBinding()]
    param()

    # Run full debloat first
    $DebloatResults = Invoke-Debloat -Mode 'Safe' -IncludeXbox

    # The activation will be handled by the menu calling Invoke-WindowsActivation

    return $DebloatResults
}

# ============================================================
# LEGACY COMPATIBILITY FUNCTIONS
# ============================================================

function Get-BloatwareList {
    <#
    .SYNOPSIS
        Legacy function - returns safe bloatware list
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeXbox
    )

    $List = Get-SafeBloatwareList
    if ($IncludeXbox) {
        $List += Get-XboxAppsList
    }
    return $List
}

function Remove-AllBloatware {
    <#
    .SYNOPSIS
        Legacy function - removes bloatware using safe mode
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeXbox,
        [switch]$ShowProgress
    )

    $Results = Remove-SafeBloatware
    if ($IncludeXbox) {
        $XboxResults = Remove-XboxApps
        $Results.Removed += $XboxResults.Removed
        $Results.Failed += $XboxResults.Failed
    }
    return $Results
}

function Invoke-PrivacyProtection {
    <#
    .SYNOPSIS
        Legacy function - calls privacy hardening
    #>
    [CmdletBinding()]
    param()

    Disable-WindowsTelemetry
    Invoke-PrivacyHardening
}

# ============================================================
# ADDITIONAL HELPER FUNCTIONS
# ============================================================

function Disable-ActivityHistory {
    <#
    .SYNOPSIS
        Disables Activity History and Timeline
    #>
    [CmdletBinding()]
    param()

    $ActivityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (-not (Test-Path $ActivityPath)) {
        New-Item -Path $ActivityPath -Force | Out-Null
    }

    Set-RegistryValue -Path $ActivityPath -Name "EnableActivityFeed" -Value 0
    Set-RegistryValue -Path $ActivityPath -Name "PublishUserActivities" -Value 0
    Set-RegistryValue -Path $ActivityPath -Name "UploadUserActivities" -Value 0

    Write-ColorOutput -Message "Activity History disabled" -Type Success
    return $true
}

function Disable-AdvertisingID {
    <#
    .SYNOPSIS
        Disables Advertising ID
    #>
    [CmdletBinding()]
    param()

    $AdIDPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    Set-RegistryValue -Path $AdIDPath -Name "Enabled" -Value 0

    Write-ColorOutput -Message "Advertising ID disabled" -Type Success
    return $true
}

function Disable-WindowsFeedback {
    <#
    .SYNOPSIS
        Disables Windows feedback requests
    #>
    [CmdletBinding()]
    param()

    $FeedbackPath = "HKCU:\Software\Microsoft\Siuf\Rules"
    if (-not (Test-Path $FeedbackPath)) {
        New-Item -Path $FeedbackPath -Force | Out-Null
    }

    Set-RegistryValue -Path $FeedbackPath -Name "NumberOfSIUFInPeriod" -Value 0

    Write-ColorOutput -Message "Windows Feedback disabled" -Type Success
    return $true
}

function Disable-WindowsTips {
    <#
    .SYNOPSIS
        Disables Windows tips and suggestions
    #>
    [CmdletBinding()]
    param()

    $TipsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $TipsPath)) {
        New-Item -Path $TipsPath -Force | Out-Null
    }

    Set-RegistryValue -Path $TipsPath -Name "DisableSoftLanding" -Value 1
    Set-RegistryValue -Path $TipsPath -Name "DisableWindowsConsumerFeatures" -Value 1

    Write-ColorOutput -Message "Windows Tips disabled" -Type Success
    return $true
}

function Disable-LocationTracking {
    <#
    .SYNOPSIS
        Disables location tracking
    #>
    [CmdletBinding()]
    param()

    $LocationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
    if (-not (Test-Path $LocationPath)) {
        New-Item -Path $LocationPath -Force | Out-Null
    }

    Set-RegistryValue -Path $LocationPath -Name "DisableLocation" -Value 1

    Write-ColorOutput -Message "Location Tracking disabled" -Type Success
    return $true
}

# ============================================================
# EXPORT MODULE MEMBERS
# ============================================================

Export-ModuleMember -Function @(
    # Bloatware Lists
    'Get-SafeBloatwareList',
    'Get-AggressiveBloatwareList',
    'Get-XboxAppsList',
    'Get-ProtectedAppsList',
    'Get-BloatwareList',

    # Bloatware Removal
    'Get-InstalledBloatware',
    'Remove-BloatwareApp',
    'Remove-SafeBloatware',
    'Remove-AggressiveBloatware',
    'Remove-XboxApps',
    'Remove-AllBloatware',

    # Telemetry and Privacy
    'Disable-WindowsTelemetry',
    'Disable-Cortana',
    'Invoke-PrivacyHardening',
    'Disable-ActivityHistory',
    'Disable-AdvertisingID',
    'Disable-WindowsFeedback',
    'Disable-WindowsTips',
    'Disable-LocationTracking',
    'Invoke-PrivacyProtection',

    # Complete Operations
    'Invoke-Debloat',
    'Invoke-FullDebloatAndActivate'
)
