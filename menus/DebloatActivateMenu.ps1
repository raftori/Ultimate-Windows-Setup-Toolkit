#Requires -Version 5.1
<#
.SYNOPSIS
    Debloat & Activation Menu for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Interactive menu for debloating Windows, privacy protection, and Windows/Office activation
.VERSION
    4.0
#>

# ============================================================
# BANNER FUNCTION
# ============================================================

function Show-DebloatBanner {
    $Banner = @"

    ╔══════════════════════════════════════════════════════════════════╗
    ║                   DEBLOAT & ACTIVATION                           ║
    ║            Privacy Protection & Windows Activation               ║
    ╚══════════════════════════════════════════════════════════════════╝

"@
    Write-Host $Banner -ForegroundColor Cyan
}

# ============================================================
# MAIN DEBLOAT & ACTIVATION MENU
# ============================================================

function Show-DebloatMenu {
    <#
    .SYNOPSIS
        Displays the debloat and activation menu with 10 options
    #>
    [CmdletBinding()]
    param()

    while ($true) {
        Clear-Host
        Show-DebloatBanner

        Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
        Write-Host "  ║  BLOATWARE REMOVAL                                           ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [1]  Remove Bloatware (SAFE)      [2]  Remove (AGGRESSIVE) ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [3]  Remove Xbox/Gaming Apps      [4]  View Bloatware List ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
        Write-Host "  ║  PRIVACY & TELEMETRY                                         ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [5]  Disable Telemetry            [6]  Disable Cortana     ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [7]  Privacy Hardening                                     ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
        Write-Host "  ║  ACTIVATION                                                  ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [8]  Activate Windows             [9]  Activate Office     ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [10] Check Activation Status                               ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [11] FULL DEBLOAT + ACTIVATE      [B]  Back to Main Menu   ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host "  Select an option: " -NoNewline -ForegroundColor White

        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            "1" { Invoke-SafeDebloat }
            "2" { Invoke-AggressiveDebloat }
            "3" { Invoke-XboxRemoval }
            "4" { Show-BloatwareList }
            "5" { Invoke-DisableTelemetry }
            "6" { Invoke-DisableCortana }
            "7" { Invoke-PrivacyHarden }
            "8" { Show-WindowsActivationMenu }
            "9" { Show-OfficeActivationMenu }
            "10" { Show-ActivationStatus }
            "11" { Show-FullDebloatActivateWizard }
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
# [1] SAFE BLOATWARE REMOVAL
# ============================================================

function Invoke-SafeDebloat {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  SAFE BLOATWARE REMOVAL" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This will remove default Windows bloatware while preserving:" -ForegroundColor Gray
    Write-Host "  - Windows Store" -ForegroundColor Gray
    Write-Host "  - Microsoft Edge" -ForegroundColor Gray
    Write-Host "  - Windows Security" -ForegroundColor Gray
    Write-Host "  - Essential system apps" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  Proceed with safe bloatware removal? (Y/N): " -NoNewline -ForegroundColor Yellow
    $Confirm = Read-Host

    if ($Confirm -eq "Y" -or $Confirm -eq "y") {
        Write-Host ""
        Remove-SafeBloatware
    }
    else {
        Write-Host ""
        Write-ColorOutput -Message "Operation cancelled" -Type Info
    }

    Pause-DebloatMenu
}

# ============================================================
# [2] AGGRESSIVE BLOATWARE REMOVAL
# ============================================================

function Invoke-AggressiveDebloat {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  AGGRESSIVE BLOATWARE REMOVAL" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║  WARNING: AGGRESSIVE MODE                                     ║" -ForegroundColor Red
    Write-Host "  ║                                                               ║" -ForegroundColor Red
    Write-Host "  ║  This will remove:                                            ║" -ForegroundColor Red
    Write-Host "  ║  - Windows Store                                              ║" -ForegroundColor Red
    Write-Host "  ║  - Microsoft Edge                                             ║" -ForegroundColor Red
    Write-Host "  ║  - Windows Security UI                                        ║" -ForegroundColor Red
    Write-Host "  ║  - Xbox Apps                                                  ║" -ForegroundColor Red
    Write-Host "  ║  - Microsoft 365 components                                   ║" -ForegroundColor Red
    Write-Host "  ║  - OneDrive                                                   ║" -ForegroundColor Red
    Write-Host "  ║  - Copilot                                                    ║" -ForegroundColor Red
    Write-Host "  ║                                                               ║" -ForegroundColor Red
    Write-Host "  ║  Some Windows features may stop working properly!             ║" -ForegroundColor Red
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""

    Write-Host "  Are you SURE you want to proceed? (Type 'YES' to confirm): " -NoNewline -ForegroundColor Red
    $Confirm = Read-Host

    if ($Confirm -eq "YES") {
        Write-Host ""
        Remove-AggressiveBloatware
    }
    else {
        Write-Host ""
        Write-ColorOutput -Message "Operation cancelled" -Type Info
    }

    Pause-DebloatMenu
}

# ============================================================
# [3] XBOX APPS REMOVAL
# ============================================================

function Invoke-XboxRemoval {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  REMOVE XBOX/GAMING APPS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This will remove all Xbox-related apps:" -ForegroundColor Gray
    Write-Host "  - Xbox App" -ForegroundColor Gray
    Write-Host "  - Xbox Game Bar" -ForegroundColor Gray
    Write-Host "  - Xbox Gaming Overlay" -ForegroundColor Gray
    Write-Host "  - Xbox Identity Provider" -ForegroundColor Gray
    Write-Host "  - Xbox Speech to Text" -ForegroundColor Gray
    Write-Host "  - Gaming Services" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Note: This will also disable Xbox-related services." -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  Proceed with Xbox apps removal? (Y/N): " -NoNewline -ForegroundColor Yellow
    $Confirm = Read-Host

    if ($Confirm -eq "Y" -or $Confirm -eq "y") {
        Write-Host ""
        Remove-XboxApps
    }
    else {
        Write-Host ""
        Write-ColorOutput -Message "Operation cancelled" -Type Info
    }

    Pause-DebloatMenu
}

# ============================================================
# [4] VIEW BLOATWARE LIST
# ============================================================

function Show-BloatwareList {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  INSTALLED BLOATWARE" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Scanning for bloatware..." -ForegroundColor Yellow
    Write-Host ""

    $SafeBloat = Get-InstalledBloatware -Mode 'Safe'

    if ($SafeBloat.Count -eq 0) {
        Write-Host "  No bloatware found! Your system is clean." -ForegroundColor Green
    }
    else {
        Write-Host "  Found $($SafeBloat.Count) bloatware apps:" -ForegroundColor Yellow
        Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray

        $i = 1
        foreach ($App in $SafeBloat | Sort-Object Name) {
            $IsXbox = $App.Name -like "*Xbox*" -or $App.Name -like "*Gaming*"
            $Color = if ($IsXbox) { "Cyan" } else { "White" }
            $Tag = if ($IsXbox) { " [Xbox]" } else { "" }
            Write-Host "  [$i] $($App.Name)$Tag" -ForegroundColor $Color
            $i++
        }

        Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Estimated space: ~$([math]::Round($SafeBloat.Count * 50, 0)) MB" -ForegroundColor Gray
    }

    Pause-DebloatMenu
}

# ============================================================
# [5] DISABLE TELEMETRY
# ============================================================

function Invoke-DisableTelemetry {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  DISABLE WINDOWS TELEMETRY" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This will:" -ForegroundColor Gray
    Write-Host "  - Disable Connected User Experience (DiagTrack)" -ForegroundColor Gray
    Write-Host "  - Disable WAP Push Service (dmwappushservice)" -ForegroundColor Gray
    Write-Host "  - Disable Windows Error Reporting" -ForegroundColor Gray
    Write-Host "  - Disable Customer Experience Improvement Program" -ForegroundColor Gray
    Write-Host "  - Disable Application Telemetry" -ForegroundColor Gray
    Write-Host "  - Disable telemetry scheduled tasks" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  Proceed with disabling telemetry? (Y/N): " -NoNewline -ForegroundColor Yellow
    $Confirm = Read-Host

    if ($Confirm -eq "Y" -or $Confirm -eq "y") {
        Write-Host ""
        Disable-WindowsTelemetry
    }
    else {
        Write-Host ""
        Write-ColorOutput -Message "Operation cancelled" -Type Info
    }

    Pause-DebloatMenu
}

# ============================================================
# [6] DISABLE CORTANA
# ============================================================

function Invoke-DisableCortana {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  DISABLE CORTANA" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This will:" -ForegroundColor Gray
    Write-Host "  - Disable Cortana assistant" -ForegroundColor Gray
    Write-Host "  - Disable Cortana above lock screen" -ForegroundColor Gray
    Write-Host "  - Disable web search in Start menu" -ForegroundColor Gray
    Write-Host "  - Remove Cortana app" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  Proceed with disabling Cortana? (Y/N): " -NoNewline -ForegroundColor Yellow
    $Confirm = Read-Host

    if ($Confirm -eq "Y" -or $Confirm -eq "y") {
        Write-Host ""
        Disable-Cortana
    }
    else {
        Write-Host ""
        Write-ColorOutput -Message "Operation cancelled" -Type Info
    }

    Pause-DebloatMenu
}

# ============================================================
# [7] PRIVACY HARDENING
# ============================================================

function Invoke-PrivacyHarden {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  PRIVACY HARDENING" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This will apply comprehensive privacy settings:" -ForegroundColor Gray
    Write-Host "  - Disable Activity History" -ForegroundColor Gray
    Write-Host "  - Disable Advertising ID" -ForegroundColor Gray
    Write-Host "  - Disable Windows Feedback" -ForegroundColor Gray
    Write-Host "  - Disable Windows Tips & Suggestions" -ForegroundColor Gray
    Write-Host "  - Disable Location Tracking" -ForegroundColor Gray
    Write-Host "  - Disable Handwriting Data Sharing" -ForegroundColor Gray
    Write-Host "  - Disable Input Personalization" -ForegroundColor Gray
    Write-Host "  - Disable Clipboard History" -ForegroundColor Gray
    Write-Host "  - Disable WiFi Sense" -ForegroundColor Gray
    Write-Host "  - Disable Find My Device" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  Proceed with privacy hardening? (Y/N): " -NoNewline -ForegroundColor Yellow
    $Confirm = Read-Host

    if ($Confirm -eq "Y" -or $Confirm -eq "y") {
        Write-Host ""
        Invoke-PrivacyHardening
    }
    else {
        Write-Host ""
        Write-ColorOutput -Message "Operation cancelled" -Type Info
    }

    Pause-DebloatMenu
}

# ============================================================
# [8] WINDOWS ACTIVATION MENU
# ============================================================

function Show-WindowsActivationMenu {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  WINDOWS ACTIVATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This uses Microsoft Activation Scripts (MAS) for activation." -ForegroundColor Gray
    Write-Host "  Choose an activation method:" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  HWID Activation (Recommended - Permanent)             ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  KMS38 Activation (Valid until 2038)                   ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [3]  Online KMS Activation (180 days, auto-renew)          ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select method: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            Write-Host "  Starting HWID activation..." -ForegroundColor Yellow
            Write-Host "  This provides permanent digital license activation." -ForegroundColor Gray
            Write-Host ""
            Invoke-WindowsActivation -Method "HWID"
            Pause-DebloatMenu
        }
        "2" {
            Write-Host ""
            Write-Host "  Starting KMS38 activation..." -ForegroundColor Yellow
            Write-Host "  This provides activation valid until 2038." -ForegroundColor Gray
            Write-Host ""
            Invoke-WindowsActivation -Method "KMS38"
            Pause-DebloatMenu
        }
        "3" {
            Write-Host ""
            Write-Host "  Starting Online KMS activation..." -ForegroundColor Yellow
            Write-Host "  This provides 180-day activation with auto-renewal." -ForegroundColor Gray
            Write-Host ""
            Invoke-WindowsActivation -Method "KMS"
            Pause-DebloatMenu
        }
        "B" { return }
        default {
            Write-Host ""
            Write-Host "  Invalid option." -ForegroundColor Red
            Pause-DebloatMenu
        }
    }
}

# ============================================================
# [9] OFFICE ACTIVATION MENU
# ============================================================

function Show-OfficeActivationMenu {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  OFFICE ACTIVATION" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This uses Microsoft Activation Scripts (MAS) for Office activation." -ForegroundColor Gray
    Write-Host ""

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [1]  Online KMS Activation (180 days, auto-renew)          ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [2]  Ohook Activation (Permanent)                          ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ║   [B]  Back                                                  ║" -ForegroundColor DarkCyan
    Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Select method: " -NoNewline -ForegroundColor White

    $Choice = Read-Host

    switch ($Choice.ToUpper()) {
        "1" {
            Write-Host ""
            Write-Host "  Starting Office KMS activation..." -ForegroundColor Yellow
            Write-Host ""
            Invoke-OfficeActivation -Method "KMS"
            Pause-DebloatMenu
        }
        "2" {
            Write-Host ""
            Write-Host "  Starting Ohook activation..." -ForegroundColor Yellow
            Write-Host ""
            Invoke-OfficeActivation -Method "Ohook"
            Pause-DebloatMenu
        }
        "B" { return }
        default {
            Write-Host ""
            Write-Host "  Invalid option." -ForegroundColor Red
            Pause-DebloatMenu
        }
    }
}

# ============================================================
# [10] CHECK ACTIVATION STATUS
# ============================================================

function Show-ActivationStatus {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  ACTIVATION STATUS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    # Check Windows activation
    Write-Host "  Checking Windows activation status..." -ForegroundColor Yellow
    Write-Host ""

    try {
        $LicenseStatus = Get-CimInstance -ClassName SoftwareLicensingProduct |
            Where-Object { $_.PartialProductKey -and $_.Name -like "*Windows*" } |
            Select-Object -First 1

        $StatusText = switch ($LicenseStatus.LicenseStatus) {
            0 { "Unlicensed" }
            1 { "Licensed (Activated)" }
            2 { "OOBGrace" }
            3 { "OOTGrace" }
            4 { "NonGenuineGrace" }
            5 { "Notification" }
            6 { "ExtendedGrace" }
            default { "Unknown" }
        }

        $StatusColor = if ($LicenseStatus.LicenseStatus -eq 1) { "Green" } else { "Red" }

        Write-Host "  WINDOWS:" -ForegroundColor White
        Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray
        Write-Host "  Status:           " -NoNewline -ForegroundColor Gray
        Write-Host $StatusText -ForegroundColor $StatusColor
        Write-Host "  Product:          " -NoNewline -ForegroundColor Gray
        Write-Host $LicenseStatus.Name -ForegroundColor White
        Write-Host "  Partial Key:      " -NoNewline -ForegroundColor Gray
        Write-Host $LicenseStatus.PartialProductKey -ForegroundColor White

        if ($LicenseStatus.LicenseStatus -eq 1) {
            Write-Host "  License Type:     " -NoNewline -ForegroundColor Gray
            Write-Host $LicenseStatus.Description -ForegroundColor White
        }
    }
    catch {
        Write-Host "  Unable to retrieve Windows activation status." -ForegroundColor Red
    }

    Write-Host ""

    # Check Office activation
    Write-Host "  Checking Office activation status..." -ForegroundColor Yellow
    Write-Host ""

    try {
        $OfficeLicense = Get-CimInstance -ClassName SoftwareLicensingProduct |
            Where-Object { $_.PartialProductKey -and $_.Name -like "*Office*" } |
            Select-Object -First 1

        if ($OfficeLicense) {
            $OfficeStatus = switch ($OfficeLicense.LicenseStatus) {
                0 { "Unlicensed" }
                1 { "Licensed (Activated)" }
                2 { "OOBGrace" }
                3 { "OOTGrace" }
                4 { "NonGenuineGrace" }
                5 { "Notification" }
                6 { "ExtendedGrace" }
                default { "Unknown" }
            }

            $OfficeColor = if ($OfficeLicense.LicenseStatus -eq 1) { "Green" } else { "Red" }

            Write-Host "  OFFICE:" -ForegroundColor White
            Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray
            Write-Host "  Status:           " -NoNewline -ForegroundColor Gray
            Write-Host $OfficeStatus -ForegroundColor $OfficeColor
            Write-Host "  Product:          " -NoNewline -ForegroundColor Gray
            Write-Host $OfficeLicense.Name -ForegroundColor White
            Write-Host "  Partial Key:      " -NoNewline -ForegroundColor Gray
            Write-Host $OfficeLicense.PartialProductKey -ForegroundColor White
        }
        else {
            Write-Host "  OFFICE:" -ForegroundColor White
            Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray
            Write-Host "  No Office installation found or not activated." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  Unable to retrieve Office activation status." -ForegroundColor Red
    }

    Pause-DebloatMenu
}

# ============================================================
# [11] FULL DEBLOAT + ACTIVATE WIZARD
# ============================================================

function Show-FullDebloatActivateWizard {
    Clear-Host
    Show-DebloatBanner

    Write-Host "  FULL DEBLOAT + ACTIVATE" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This wizard will perform the following:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Remove Windows bloatware (Safe mode)" -ForegroundColor Green
    Write-Host "  [2] Disable Windows telemetry" -ForegroundColor Green
    Write-Host "  [3] Disable Cortana" -ForegroundColor Green
    Write-Host "  [4] Apply privacy hardening" -ForegroundColor Green
    Write-Host "  [5] Activate Windows (HWID)" -ForegroundColor Green
    Write-Host ""

    # Options
    Write-Host "  Options:" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Include Xbox apps removal? (Y/N) [N]: " -NoNewline -ForegroundColor Yellow
    $XboxChoice = Read-Host
    $IncludeXbox = ($XboxChoice -eq "Y" -or $XboxChoice -eq "y")

    Write-Host "  Activate Windows? (Y/N) [Y]: " -NoNewline -ForegroundColor Yellow
    $ActivateChoice = Read-Host
    $DoActivate = ($ActivateChoice -ne "N" -and $ActivateChoice -ne "n")

    Write-Host ""
    Write-Host "  Proceed with full debloat" -NoNewline -ForegroundColor Yellow
    if ($DoActivate) { Write-Host " and activation" -NoNewline -ForegroundColor Yellow }
    Write-Host "? (Y/N): " -NoNewline -ForegroundColor Yellow
    $Confirm = Read-Host

    if ($Confirm -ne "Y" -and $Confirm -ne "y") {
        Write-Host ""
        Write-ColorOutput -Message "Operation cancelled" -Type Info
        Pause-DebloatMenu
        return
    }

    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  STARTING FULL DEBLOAT" -ForegroundColor Cyan
    Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Run debloat
    $DebloatResults = Invoke-Debloat -Mode 'Safe' -IncludeXbox:$IncludeXbox

    # Activate Windows
    if ($DoActivate) {
        Write-Host ""
        Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  ACTIVATING WINDOWS" -ForegroundColor Cyan
        Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Invoke-WindowsActivation -Method "HWID"
    }

    # Summary
    Write-Host ""
    Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  FULL DEBLOAT + ACTIVATE COMPLETE!" -ForegroundColor Green
    Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "  A restart is recommended to apply all changes." -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  Restart now? (Y/N): " -NoNewline -ForegroundColor Yellow
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
        Pause-DebloatMenu
    }
}

# ============================================================
# ACTIVATION HELPER FUNCTIONS
# ============================================================

function Invoke-WindowsActivation {
    <#
    .SYNOPSIS
        Activates Windows using MAS
    .PARAMETER Method
        HWID, KMS38, or KMS
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('HWID', 'KMS38', 'KMS')]
        [string]$Method = 'HWID'
    )

    Write-ColorOutput -Message "Activating Windows ($Method)" -Type Header

    try {
        # Use Microsoft Activation Scripts (MAS)
        $MASUrl = "https://get.activated.win"

        Write-Host "    Downloading activation script..." -ForegroundColor Gray

        switch ($Method) {
            'HWID' {
                # HWID activation - permanent digital license
                $Command = "irm $MASUrl | iex"
                Write-Host "    Running HWID activation..." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "    NOTE: A window will open. Select option 1 (HWID) when prompted." -ForegroundColor Cyan
                Write-Host ""
                Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $Command -Wait
            }
            'KMS38' {
                # KMS38 activation - valid until 2038
                $Command = "irm $MASUrl | iex"
                Write-Host "    Running KMS38 activation..." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "    NOTE: A window will open. Select option 2 (KMS38) when prompted." -ForegroundColor Cyan
                Write-Host ""
                Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $Command -Wait
            }
            'KMS' {
                # Online KMS activation
                $Command = "irm $MASUrl | iex"
                Write-Host "    Running Online KMS activation..." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "    NOTE: A window will open. Select option 3 (Online KMS) when prompted." -ForegroundColor Cyan
                Write-Host ""
                Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $Command -Wait
            }
        }

        Write-Host ""
        Write-ColorOutput -Message "Activation process completed" -Type Success
        Write-Host "    Check activation status to verify." -ForegroundColor Gray
    }
    catch {
        Write-Host ""
        Write-ColorOutput -Message "Activation failed: $($_.Exception.Message)" -Type Error
    }
}

function Invoke-OfficeActivation {
    <#
    .SYNOPSIS
        Activates Office using MAS
    .PARAMETER Method
        KMS or Ohook
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('KMS', 'Ohook')]
        [string]$Method = 'KMS'
    )

    Write-ColorOutput -Message "Activating Office ($Method)" -Type Header

    try {
        $MASUrl = "https://get.activated.win"

        Write-Host "    Downloading activation script..." -ForegroundColor Gray

        switch ($Method) {
            'KMS' {
                $Command = "irm $MASUrl | iex"
                Write-Host "    Running Office KMS activation..." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "    NOTE: A window will open. Select option 3 (Online KMS) and then Office." -ForegroundColor Cyan
                Write-Host ""
                Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $Command -Wait
            }
            'Ohook' {
                $Command = "irm $MASUrl | iex"
                Write-Host "    Running Ohook activation..." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "    NOTE: A window will open. Select option 6 (Ohook) when prompted." -ForegroundColor Cyan
                Write-Host ""
                Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $Command -Wait
            }
        }

        Write-Host ""
        Write-ColorOutput -Message "Activation process completed" -Type Success
        Write-Host "    Check activation status to verify." -ForegroundColor Gray
    }
    catch {
        Write-Host ""
        Write-ColorOutput -Message "Activation failed: $($_.Exception.Message)" -Type Error
    }
}

# ============================================================
# HELPER FUNCTION
# ============================================================

function Pause-DebloatMenu {
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ============================================================
# EXPORT
# ============================================================

Export-ModuleMember -Function Show-DebloatMenu -ErrorAction SilentlyContinue
