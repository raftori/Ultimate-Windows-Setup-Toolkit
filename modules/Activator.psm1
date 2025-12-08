<#
.SYNOPSIS
    Activator Module for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Provides functions for Windows and Office activation using legitimate methods
.VERSION
    4.0
.NOTES
    This module uses Microsoft Activation Scripts (MAS) for activation.
    MAS is an open-source project that uses legitimate activation methods.
    For more information: https://github.com/massgravel/Microsoft-Activation-Scripts
#>

# Import common functions
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ModulePath\CommonFunctions.psm1" -Force -ErrorAction SilentlyContinue

# ============================================================
# ACTIVATION STATUS FUNCTIONS
# ============================================================

function Get-WindowsActivationStatus {
    <#
    .SYNOPSIS
        Gets the current Windows activation status
    #>
    [CmdletBinding()]
    param()

    try {
        $LicenseStatus = Get-CimInstance -ClassName SoftwareLicensingProduct -ErrorAction Stop |
            Where-Object { $_.Name -like "*Windows*" -and $_.ApplicationId -eq "55c92734-d682-4d71-983e-d6ec3f16059f" } |
            Where-Object { $_.PartialProductKey } |
            Select-Object -First 1

        if ($LicenseStatus) {
            $StatusMap = @{
                0 = "Unlicensed"
                1 = "Licensed"
                2 = "OOB Grace"
                3 = "OOT Grace"
                4 = "Non-Genuine Grace"
                5 = "Notification"
                6 = "Extended Grace"
            }

            $Status = @{
                Name = $LicenseStatus.Name
                Description = $LicenseStatus.Description
                LicenseStatus = $StatusMap[[int]$LicenseStatus.LicenseStatus]
                LicenseStatusCode = $LicenseStatus.LicenseStatus
                PartialProductKey = $LicenseStatus.PartialProductKey
                IsActivated = $LicenseStatus.LicenseStatus -eq 1
            }

            return $Status
        }
    }
    catch {
        Write-Log "Failed to get Windows activation status: $($_.Exception.Message)" -Level ERROR
    }

    return @{
        Name = "Unknown"
        Description = "Could not determine"
        LicenseStatus = "Unknown"
        LicenseStatusCode = -1
        PartialProductKey = "N/A"
        IsActivated = $false
    }
}

function Get-OfficeActivationStatus {
    <#
    .SYNOPSIS
        Gets the current Office activation status
    #>
    [CmdletBinding()]
    param()

    $OfficeProducts = @()

    try {
        $OfficeLicenses = Get-CimInstance -ClassName SoftwareLicensingProduct -ErrorAction Stop |
            Where-Object { $_.Name -like "*Office*" -and $_.PartialProductKey }

        foreach ($License in $OfficeLicenses) {
            $StatusMap = @{
                0 = "Unlicensed"
                1 = "Licensed"
                2 = "OOB Grace"
                3 = "OOT Grace"
                4 = "Non-Genuine Grace"
                5 = "Notification"
                6 = "Extended Grace"
            }

            $OfficeProducts += @{
                Name = $License.Name
                Description = $License.Description
                LicenseStatus = $StatusMap[[int]$License.LicenseStatus]
                LicenseStatusCode = $License.LicenseStatus
                PartialProductKey = $License.PartialProductKey
                IsActivated = $License.LicenseStatus -eq 1
            }
        }
    }
    catch {
        Write-Log "Failed to get Office activation status: $($_.Exception.Message)" -Level ERROR
    }

    return $OfficeProducts
}

function Show-ActivationStatus {
    <#
    .SYNOPSIS
        Displays the current activation status
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Checking Activation Status" -Type Header

    # Windows Status
    Write-Host "    Windows Activation:" -ForegroundColor Cyan
    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray

    $WindowsStatus = Get-WindowsActivationStatus

    Write-Host "    Product:   " -ForegroundColor Gray -NoNewline
    Write-Host "$($WindowsStatus.Name)" -ForegroundColor White

    Write-Host "    Status:    " -ForegroundColor Gray -NoNewline
    if ($WindowsStatus.IsActivated) {
        Write-Host "$($WindowsStatus.LicenseStatus)" -ForegroundColor Green
    }
    else {
        Write-Host "$($WindowsStatus.LicenseStatus)" -ForegroundColor Red
    }

    Write-Host "    Key:       " -ForegroundColor Gray -NoNewline
    Write-Host "XXXXX-XXXXX-XXXXX-XXXXX-$($WindowsStatus.PartialProductKey)" -ForegroundColor White

    # Office Status
    $OfficeProducts = Get-OfficeActivationStatus

    if ($OfficeProducts.Count -gt 0) {
        Write-Host ""
        Write-Host "    Office Activation:" -ForegroundColor Cyan
        Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray

        foreach ($Product in $OfficeProducts) {
            Write-Host "    Product:   " -ForegroundColor Gray -NoNewline
            Write-Host "$($Product.Name)" -ForegroundColor White

            Write-Host "    Status:    " -ForegroundColor Gray -NoNewline
            if ($Product.IsActivated) {
                Write-Host "$($Product.LicenseStatus)" -ForegroundColor Green
            }
            else {
                Write-Host "$($Product.LicenseStatus)" -ForegroundColor Red
            }
            Write-Host ""
        }
    }
    else {
        Write-Host ""
        Write-Host "    Office: " -ForegroundColor Gray -NoNewline
        Write-Host "Not installed or no license found" -ForegroundColor Yellow
    }

    Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    return @{
        Windows = $WindowsStatus
        Office = $OfficeProducts
    }
}

# ============================================================
# ACTIVATION FUNCTIONS (MAS)
# ============================================================

function Invoke-WindowsActivation {
    <#
    .SYNOPSIS
        Activates Windows using MAS (Microsoft Activation Scripts)
    .PARAMETER Method
        Activation method: HWID (permanent), KMS38 (until 2038), or Online KMS
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('HWID', 'KMS38', 'OnlineKMS')]
        [string]$Method = 'HWID'
    )

    Write-ColorOutput -Message "Windows Activation" -Type Header

    # Check current status
    $Status = Get-WindowsActivationStatus
    if ($Status.IsActivated) {
        Write-ColorOutput -Message "Windows is already activated" -Type Success
        Write-Host "    Current status: $($Status.LicenseStatus)" -ForegroundColor Green
        return $true
    }

    Write-ColorOutput -Message "Activating Windows using $Method method..." -Type Info
    Write-ColorOutput -Message "This uses Microsoft Activation Scripts (MAS)" -Type Info
    Write-Host ""

    try {
        # Run MAS activation script
        # Note: This downloads and runs the official MAS script
        $MASCommand = switch ($Method) {
            'HWID' {
                'irm https://get.activated.win | iex'
            }
            'KMS38' {
                'irm https://get.activated.win | iex'
            }
            'OnlineKMS' {
                'irm https://get.activated.win | iex'
            }
        }

        Write-Host ""
        Write-ColorOutput -Message "The MAS activation window will open." -Type Warning
        Write-ColorOutput -Message "Please select option [$Method] in the MAS menu." -Type Info
        Write-Host ""

        # Launch MAS
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$MASCommand`"" -Wait -Verb RunAs

        # Check status after activation
        Start-Sleep -Seconds 2
        $NewStatus = Get-WindowsActivationStatus

        if ($NewStatus.IsActivated) {
            Write-ColorOutput -Message "Windows activated successfully!" -Type Success
            return $true
        }
        else {
            Write-ColorOutput -Message "Activation may not have completed. Please check status." -Type Warning
            return $false
        }
    }
    catch {
        Write-Log "Activation failed: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Invoke-OfficeActivation {
    <#
    .SYNOPSIS
        Activates Office using MAS (Microsoft Activation Scripts)
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Office Activation" -Type Header

    # Check if Office is installed
    $OfficeProducts = Get-OfficeActivationStatus

    if ($OfficeProducts.Count -eq 0) {
        Write-ColorOutput -Message "No Office installation detected" -Type Warning
        return $false
    }

    # Check if already activated
    $AllActivated = $true
    foreach ($Product in $OfficeProducts) {
        if (-not $Product.IsActivated) {
            $AllActivated = $false
            break
        }
    }

    if ($AllActivated) {
        Write-ColorOutput -Message "All Office products are already activated" -Type Success
        return $true
    }

    Write-ColorOutput -Message "Activating Office using MAS..." -Type Info
    Write-Host ""

    try {
        # Launch MAS for Office activation
        $MASCommand = 'irm https://get.activated.win | iex'

        Write-ColorOutput -Message "The MAS activation window will open." -Type Warning
        Write-ColorOutput -Message "Please select 'Ohook' option for Office activation in the MAS menu." -Type Info
        Write-Host ""

        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$MASCommand`"" -Wait -Verb RunAs

        # Check status
        Start-Sleep -Seconds 2
        $NewStatus = Get-OfficeActivationStatus

        $SuccessCount = ($NewStatus | Where-Object { $_.IsActivated }).Count

        if ($SuccessCount -gt 0) {
            Write-ColorOutput -Message "Office activated successfully!" -Type Success
            return $true
        }
        else {
            Write-ColorOutput -Message "Activation may not have completed. Please check status." -Type Warning
            return $false
        }
    }
    catch {
        Write-Log "Office activation failed: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================================
# TROUBLESHOOTING FUNCTIONS
# ============================================================

function Reset-WindowsActivation {
    <#
    .SYNOPSIS
        Resets Windows activation (clears current key)
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Resetting Windows Activation" -Type Header
    Write-ColorOutput -Message "This will clear the current product key" -Type Warning

    $Confirm = Get-ConfirmationPrompt -Message "Are you sure you want to reset activation?"

    if (-not $Confirm) {
        Write-ColorOutput -Message "Operation cancelled" -Type Info
        return $false
    }

    try {
        # Clear product key
        $Service = Get-CimInstance -ClassName SoftwareLicensingService
        $Service | Invoke-CimMethod -MethodName "InstallProductKey" -Arguments @{ProductKey = ''} -ErrorAction SilentlyContinue

        # Run slmgr to clear
        Start-Process "cscript.exe" -ArgumentList "//B //NoLogo `"$env:SystemRoot\System32\slmgr.vbs`" /upk" -Wait -NoNewWindow
        Start-Process "cscript.exe" -ArgumentList "//B //NoLogo `"$env:SystemRoot\System32\slmgr.vbs`" /cpky" -Wait -NoNewWindow
        Start-Process "cscript.exe" -ArgumentList "//B //NoLogo `"$env:SystemRoot\System32\slmgr.vbs`" /ckms" -Wait -NoNewWindow

        Write-ColorOutput -Message "Windows activation reset successfully" -Type Success
        Write-ColorOutput -Message "You can now activate Windows with a new key or method" -Type Info
        return $true
    }
    catch {
        Write-Log "Failed to reset activation: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Get-ActivationTroubleshooter {
    <#
    .SYNOPSIS
        Runs the Windows activation troubleshooter
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Running Activation Troubleshooter" -Type Header

    try {
        Start-Process "ms-settings:activation" -Wait:$false
        Write-ColorOutput -Message "Activation settings opened" -Type Success
        Write-ColorOutput -Message "Click 'Troubleshoot' in the Settings window" -Type Info
        return $true
    }
    catch {
        Write-Log "Failed to open troubleshooter: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================================
# ACTIVATION MENU
# ============================================================

function Show-ActivationMenu {
    <#
    .SYNOPSIS
        Shows the activation options menu
    #>
    [CmdletBinding()]
    param()

    $Continue = $true

    while ($Continue) {
        Show-Banner -Title "ACTIVATION CENTER"

        Write-Host "    ║                                                                   ║" -ForegroundColor Cyan
        Show-MenuOption -Key "1" -Icon "i" -Text "Check Activation Status"
        Show-MenuOption -Key "2" -Icon "W" -Text "Activate Windows (HWID - Permanent)"
        Show-MenuOption -Key "3" -Icon "O" -Text "Activate Office (Ohook)"
        Show-MenuOption -Key "4" -Icon "A" -Text "Activate All (Windows + Office)"
        Show-MenuOption -Key "5" -Icon "R" -Text "Reset Windows Activation"
        Show-MenuOption -Key "6" -Icon "T" -Text "Open Activation Troubleshooter"
        Write-Host "    ║                                                                   ║" -ForegroundColor Cyan
        Show-MenuOption -Key "B" -Icon "<" -Text "Back to Main Menu"
        Show-MenuFooter

        $Choice = Get-MenuChoice -Prompt "Select an option" -ValidChoices @('1', '2', '3', '4', '5', '6', 'B', 'Q')

        switch ($Choice) {
            '1' {
                Show-ActivationStatus
                Wait-KeyPress
            }
            '2' {
                Invoke-WindowsActivation -Method 'HWID'
                Wait-KeyPress
            }
            '3' {
                Invoke-OfficeActivation
                Wait-KeyPress
            }
            '4' {
                Invoke-WindowsActivation -Method 'HWID'
                Invoke-OfficeActivation
                Wait-KeyPress
            }
            '5' {
                Reset-WindowsActivation
                Wait-KeyPress
            }
            '6' {
                Get-ActivationTroubleshooter
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
    'Get-WindowsActivationStatus',
    'Get-OfficeActivationStatus',
    'Show-ActivationStatus',
    'Invoke-WindowsActivation',
    'Invoke-OfficeActivation',
    'Reset-WindowsActivation',
    'Get-ActivationTroubleshooter',
    'Show-ActivationMenu'
)
