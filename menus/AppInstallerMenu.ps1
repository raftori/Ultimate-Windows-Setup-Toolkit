<#
.SYNOPSIS
    Application Installer Menu for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Interactive menu for installing and managing applications
    Supports categories, bundles, search, and custom selection
.VERSION
    4.0
#>

# ============================================================
# APPLICATION INSTALLER MENU
# ============================================================

function Show-AppInstallerBanner {
    $Banner = @"

    +-----------------------------------------------------------------+
    |              APPLICATION INSTALLER                              |
    +-----------------------------------------------------------------+

"@
    Write-Host $Banner -ForegroundColor Cyan
}

function Show-AppInstallerMenu {
    <#
    .SYNOPSIS
        Displays the main application installer menu
    #>
    [CmdletBinding()]
    param()

    $Continue = $true

    while ($Continue) {
        Clear-Host
        Show-AppInstallerBanner

        # Show package manager status
        Show-PackageManagerStatus

        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "  |                                                                 |" -ForegroundColor DarkCyan
        Write-Host "  |   [1]  Browsers                    [2]  Communication           |" -ForegroundColor DarkCyan
        Write-Host "  |   [3]  Gaming                      [4]  Media & Creative        |" -ForegroundColor DarkCyan
        Write-Host "  |   [5]  Development Tools           [6]  Utilities               |" -ForegroundColor DarkCyan
        Write-Host "  |   [7]  Security & VPN              [8]  File Management         |" -ForegroundColor DarkCyan
        Write-Host "  |   [9]  Cloud & Sync                [10] System Tools            |" -ForegroundColor DarkCyan
        Write-Host "  |                                                                 |" -ForegroundColor DarkCyan
        Write-Host "  |   [11] Install ALL Essential       [12] Custom Selection        |" -ForegroundColor DarkCyan
        Write-Host "  |   [13] Install Bundles             [14] Search Applications     |" -ForegroundColor DarkCyan
        Write-Host "  |   [15] Update All Applications     [16] Setup Package Managers  |" -ForegroundColor DarkCyan
        Write-Host "  |                                                                 |" -ForegroundColor DarkCyan
        Write-Host "  |   [B]  Back to Main Menu                                        |" -ForegroundColor DarkCyan
        Write-Host "  |                                                                 |" -ForegroundColor DarkCyan
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        Write-Host "  Select an option: " -NoNewline -ForegroundColor Yellow
        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            '1' { Show-CategoryAppsMenu -Category "Browsers" }
            '2' { Show-CategoryAppsMenu -Category "Communication" }
            '3' { Show-CategoryAppsMenu -Category "Gaming" }
            '4' { Show-CategoryAppsMenu -Category "Media & Creative" }
            '5' { Show-CategoryAppsMenu -Category "Development Tools" }
            '6' { Show-CategoryAppsMenu -Category "Utilities" }
            '7' { Show-CategoryAppsMenu -Category "Security & VPN" }
            '8' { Show-CategoryAppsMenu -Category "File Management" }
            '9' { Show-CategoryAppsMenu -Category "Cloud & Sync" }
            '10' { Show-CategoryAppsMenu -Category "System Tools" }
            '11' { Install-AllEssentialApps }
            '12' { Show-CustomSelectionMenu }
            '13' { Show-BundleMenu }
            '14' { Show-SearchMenu }
            '15' {
                Update-AllApplications
                Wait-KeyPress
            }
            '16' {
                Install-AllPackageManagers
                Wait-KeyPress
            }
            'B' { $Continue = $false }
            'Q' {
                $Continue = $false
                return 'EXIT'
            }
            default {
                Write-Host "  Invalid choice. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
}

# ============================================================
# CATEGORY APPS MENU
# ============================================================

function Show-CategoryAppsMenu {
    <#
    .SYNOPSIS
        Shows apps in a specific category
    .PARAMETER Category
        The category name to display
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category
    )

    $Apps = Get-ApplicationsByCategory -Category $Category
    $Continue = $true

    while ($Continue) {
        Clear-Host

        Write-Host ""
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |   $Category" -NoNewline -ForegroundColor Cyan
        $Padding = 64 - $Category.Length
        Write-Host (" " * $Padding) -NoNewline
        Write-Host "|" -ForegroundColor Cyan
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host ""

        # Display apps in columns if many
        $Index = 1
        foreach ($App in $Apps) {
            $Essential = if ($App.Essential -eq $true) { "*" } else { " " }
            $IndexStr = $Index.ToString().PadLeft(2)

            Write-Host "  [$IndexStr]$Essential " -NoNewline -ForegroundColor $(if ($App.Essential) { "Green" } else { "White" })
            Write-Host "$($App.Name)" -NoNewline -ForegroundColor White

            # Show description if space allows
            $NameLen = $App.Name.Length
            $DescSpace = 45 - $NameLen
            if ($DescSpace -gt 10 -and $App.Description) {
                $Desc = if ($App.Description.Length -gt $DescSpace) {
                    $App.Description.Substring(0, $DescSpace - 3) + "..."
                } else { $App.Description }
                Write-Host " - $Desc" -ForegroundColor DarkGray
            } else {
                Write-Host ""
            }

            $Index++
        }

        Write-Host ""
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkGray
        Write-Host "  [A] Install ALL in category  |  [E] Install Essential only" -ForegroundColor Gray
        Write-Host "  [S] Select multiple          |  [B] Back" -ForegroundColor Gray
        Write-Host "  * = Essential application" -ForegroundColor DarkGray
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkGray
        Write-Host ""

        Write-Host "  Enter option or app number: " -NoNewline -ForegroundColor Yellow
        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            'A' {
                $Confirm = Get-ConfirmationPrompt -Message "Install all $($Apps.Count) apps from $Category?"
                if ($Confirm) {
                    Install-ApplicationBatch -Apps $Apps -ShowProgress
                }
                Wait-KeyPress
            }
            'E' {
                $EssentialApps = $Apps | Where-Object { $_.Essential -eq $true }
                if ($EssentialApps.Count -gt 0) {
                    Install-ApplicationBatch -Apps $EssentialApps -ShowProgress
                } else {
                    Write-Host "  No essential apps in this category." -ForegroundColor Yellow
                }
                Wait-KeyPress
            }
            'S' {
                Show-MultiSelectMenu -Apps $Apps -Category $Category
            }
            'B' {
                $Continue = $false
            }
            default {
                # Try to parse as app number
                if ($Choice -match '^\d+$') {
                    $AppIndex = [int]$Choice - 1
                    if ($AppIndex -ge 0 -and $AppIndex -lt $Apps.Count) {
                        $SelectedApp = $Apps[$AppIndex]
                        $Confirm = Get-ConfirmationPrompt -Message "Install $($SelectedApp.Name)?"
                        if ($Confirm) {
                            Install-ApplicationBatch -Apps @($SelectedApp)
                        }
                        Wait-KeyPress
                    } else {
                        Write-Host "  Invalid app number." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
                # Try to parse as comma-separated list
                elseif ($Choice -match '^\d+(,\d+)+$') {
                    $Indices = $Choice -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
                    $SelectedApps = @()
                    foreach ($Idx in $Indices) {
                        if ($Idx -ge 0 -and $Idx -lt $Apps.Count) {
                            $SelectedApps += $Apps[$Idx]
                        }
                    }
                    if ($SelectedApps.Count -gt 0) {
                        Install-ApplicationBatch -Apps $SelectedApps -ShowProgress
                        Wait-KeyPress
                    }
                }
                else {
                    Write-Host "  Invalid input." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
    }
}

# ============================================================
# MULTI-SELECT MENU
# ============================================================

function Show-MultiSelectMenu {
    <#
    .SYNOPSIS
        Shows a multi-select menu for apps
    #>
    [CmdletBinding()]
    param(
        [array]$Apps,
        [string]$Category
    )

    $Selected = @{}
    foreach ($App in $Apps) {
        $Selected[$App.Name] = $false
    }

    $Continue = $true

    while ($Continue) {
        Clear-Host

        Write-Host ""
        Write-Host "  MULTI-SELECT: $Category" -ForegroundColor Cyan
        Write-Host "  Use numbers to toggle selection, then press [I] to install" -ForegroundColor Gray
        Write-Host "  " + ("-" * 60) -ForegroundColor DarkGray
        Write-Host ""

        $Index = 1
        foreach ($App in $Apps) {
            $Checkbox = if ($Selected[$App.Name]) { "[X]" } else { "[ ]" }
            $Color = if ($Selected[$App.Name]) { "Green" } else { "White" }

            Write-Host "  $($Index.ToString().PadLeft(2)) $Checkbox " -NoNewline -ForegroundColor $Color
            Write-Host $App.Name -ForegroundColor $Color
            $Index++
        }

        $SelectedCount = ($Selected.Values | Where-Object { $_ -eq $true }).Count

        Write-Host ""
        Write-Host "  " + ("-" * 60) -ForegroundColor DarkGray
        Write-Host "  Selected: $SelectedCount apps" -ForegroundColor Cyan
        Write-Host "  [T] Toggle All  |  [C] Clear All  |  [I] Install Selected  |  [B] Back" -ForegroundColor Gray
        Write-Host ""

        Write-Host "  Enter option: " -NoNewline -ForegroundColor Yellow
        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            'T' {
                $AllSelected = ($Selected.Values | Where-Object { $_ -eq $true }).Count -eq $Apps.Count
                foreach ($App in $Apps) {
                    $Selected[$App.Name] = -not $AllSelected
                }
            }
            'C' {
                foreach ($App in $Apps) {
                    $Selected[$App.Name] = $false
                }
            }
            'I' {
                $ToInstall = $Apps | Where-Object { $Selected[$_.Name] -eq $true }
                if ($ToInstall.Count -gt 0) {
                    Install-ApplicationBatch -Apps $ToInstall -ShowProgress
                    Wait-KeyPress
                    $Continue = $false
                } else {
                    Write-Host "  No apps selected." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                }
            }
            'B' {
                $Continue = $false
            }
            default {
                if ($Choice -match '^\d+$') {
                    $AppIndex = [int]$Choice - 1
                    if ($AppIndex -ge 0 -and $AppIndex -lt $Apps.Count) {
                        $AppName = $Apps[$AppIndex].Name
                        $Selected[$AppName] = -not $Selected[$AppName]
                    }
                }
                elseif ($Choice -match '^\d+(,\d+)+$') {
                    $Indices = $Choice -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
                    foreach ($Idx in $Indices) {
                        if ($Idx -ge 0 -and $Idx -lt $Apps.Count) {
                            $AppName = $Apps[$Idx].Name
                            $Selected[$AppName] = -not $Selected[$AppName]
                        }
                    }
                }
            }
        }
    }
}

# ============================================================
# BUNDLE MENU
# ============================================================

function Show-BundleMenu {
    <#
    .SYNOPSIS
        Shows the bundle selection menu
    #>
    [CmdletBinding()]
    param()

    $Continue = $true

    while ($Continue) {
        Clear-Host

        Write-Host ""
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |              APPLICATION BUNDLES                                |" -ForegroundColor Cyan
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Minimal Bundle" -ForegroundColor White
        Write-Host "      Chrome, 7-Zip, Notepad++, VLC" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [2] Standard Bundle" -ForegroundColor White
        Write-Host "      Browsers, archiver, media player, utilities, terminal" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [3] Developer Bundle" -ForegroundColor White
        Write-Host "      VS Code, Git, Node.js, Python, Docker, Terminal" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [4] Gamer Bundle" -ForegroundColor White
        Write-Host "      Steam, Discord, Epic Games, monitoring tools" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [5] Creative Bundle" -ForegroundColor White
        Write-Host "      GIMP, Inkscape, Blender, OBS, Audacity, HandBrake" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [B] Back" -ForegroundColor Gray
        Write-Host ""

        Write-Host "  Select a bundle: " -NoNewline -ForegroundColor Yellow
        $Choice = Read-Host

        switch ($Choice.ToUpper()) {
            '1' {
                $Apps = Get-EssentialBundle -BundleName "Minimal"
                Show-BundleConfirmation -BundleName "Minimal" -Apps $Apps
            }
            '2' {
                $Apps = Get-EssentialBundle -BundleName "Standard"
                Show-BundleConfirmation -BundleName "Standard" -Apps $Apps
            }
            '3' {
                $Apps = Get-EssentialBundle -BundleName "Developer"
                Show-BundleConfirmation -BundleName "Developer" -Apps $Apps
            }
            '4' {
                $Apps = Get-EssentialBundle -BundleName "Gamer"
                Show-BundleConfirmation -BundleName "Gamer" -Apps $Apps
            }
            '5' {
                $Apps = Get-EssentialBundle -BundleName "Creative"
                Show-BundleConfirmation -BundleName "Creative" -Apps $Apps
            }
            'B' {
                $Continue = $false
            }
        }
    }
}

function Show-BundleConfirmation {
    <#
    .SYNOPSIS
        Shows bundle apps and confirms installation
    #>
    param(
        [string]$BundleName,
        [array]$Apps
    )

    Clear-Host

    Write-Host ""
    Write-Host "  $BundleName Bundle - $($Apps.Count) Applications" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 50) -ForegroundColor DarkGray
    Write-Host ""

    foreach ($App in $Apps) {
        Write-Host "  - $($App.Name)" -ForegroundColor White
        if ($App.Description) {
            Write-Host "    $($App.Description)" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    $Confirm = Get-ConfirmationPrompt -Message "Install $BundleName bundle?"

    if ($Confirm) {
        Install-ApplicationBatch -Apps $Apps -ShowProgress
    }

    Wait-KeyPress
}

# ============================================================
# SEARCH MENU
# ============================================================

function Show-SearchMenu {
    <#
    .SYNOPSIS
        Search for applications
    #>
    [CmdletBinding()]
    param()

    Clear-Host

    Write-Host ""
    Write-Host "  SEARCH APPLICATIONS" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 50) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  Enter search term: " -NoNewline -ForegroundColor Yellow
    $SearchTerm = Read-Host

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        return
    }

    $Results = Search-Applications -SearchTerm $SearchTerm

    if ($Results.Count -eq 0) {
        Write-Host ""
        Write-Host "  No applications found matching '$SearchTerm'" -ForegroundColor Yellow
        Wait-KeyPress
        return
    }

    Write-Host ""
    Write-Host "  Found $($Results.Count) application(s):" -ForegroundColor Green
    Write-Host ""

    $Index = 1
    foreach ($App in $Results) {
        Write-Host "  [$Index] " -NoNewline -ForegroundColor White
        Write-Host "$($App.Name)" -NoNewline -ForegroundColor Cyan
        Write-Host " ($($App.Category))" -ForegroundColor DarkGray
        if ($App.Description) {
            Write-Host "      $($App.Description)" -ForegroundColor Gray
        }
        $Index++
    }

    Write-Host ""
    Write-Host "  Enter app number to install (or B to go back): " -NoNewline -ForegroundColor Yellow
    $Choice = Read-Host

    if ($Choice -eq 'B' -or $Choice -eq 'b') {
        return
    }

    if ($Choice -match '^\d+$') {
        $AppIndex = [int]$Choice - 1
        if ($AppIndex -ge 0 -and $AppIndex -lt $Results.Count) {
            $SelectedApp = $Results[$AppIndex]
            $Confirm = Get-ConfirmationPrompt -Message "Install $($SelectedApp.Name)?"
            if ($Confirm) {
                Install-ApplicationBatch -Apps @($SelectedApp)
            }
        }
    }
    elseif ($Choice -match '^\d+(,\d+)+$') {
        $Indices = $Choice -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
        $SelectedApps = @()
        foreach ($Idx in $Indices) {
            if ($Idx -ge 0 -and $Idx -lt $Results.Count) {
                $SelectedApps += $Results[$Idx]
            }
        }
        if ($SelectedApps.Count -gt 0) {
            Install-ApplicationBatch -Apps $SelectedApps -ShowProgress
        }
    }

    Wait-KeyPress
}

# ============================================================
# CUSTOM SELECTION MENU
# ============================================================

function Show-CustomSelectionMenu {
    <#
    .SYNOPSIS
        Shows all categories for custom selection
    #>
    [CmdletBinding()]
    param()

    $Categories = Get-AllCategories
    $Continue = $true

    while ($Continue) {
        Clear-Host

        Write-Host ""
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |              CUSTOM SELECTION - Choose Category                 |" -ForegroundColor Cyan
        Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host ""

        $Index = 1
        foreach ($Category in $Categories) {
            $Apps = Get-ApplicationsByCategory -Category $Category
            $EssentialCount = ($Apps | Where-Object { $_.Essential -eq $true }).Count

            Write-Host "  [$($Index.ToString().PadLeft(2))] " -NoNewline -ForegroundColor White
            Write-Host "$Category " -NoNewline -ForegroundColor Cyan
            Write-Host "($($Apps.Count) apps" -NoNewline -ForegroundColor Gray
            if ($EssentialCount -gt 0) {
                Write-Host ", $EssentialCount essential" -NoNewline -ForegroundColor Green
            }
            Write-Host ")" -ForegroundColor Gray
            $Index++
        }

        Write-Host ""
        Write-Host "  [B] Back" -ForegroundColor Gray
        Write-Host ""

        Write-Host "  Select a category: " -NoNewline -ForegroundColor Yellow
        $Choice = Read-Host

        if ($Choice -eq 'B' -or $Choice -eq 'b') {
            $Continue = $false
        }
        elseif ($Choice -match '^\d+$') {
            $CatIndex = [int]$Choice - 1
            if ($CatIndex -ge 0 -and $CatIndex -lt $Categories.Count) {
                $SelectedCategory = $Categories[$CatIndex]
                Show-CategoryAppsMenu -Category $SelectedCategory
            }
        }
    }
}

# ============================================================
# ESSENTIAL APPS INSTALLATION
# ============================================================

function Install-AllEssentialApps {
    <#
    .SYNOPSIS
        Installs all essential apps from all categories
    #>
    [CmdletBinding()]
    param()

    Clear-Host

    Write-Host ""
    Write-Host "  INSTALL ALL ESSENTIAL APPLICATIONS" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 50) -ForegroundColor DarkGray
    Write-Host ""

    $EssentialApps = Get-EssentialApps

    if ($EssentialApps.Count -eq 0) {
        Write-Host "  No essential apps found in catalog." -ForegroundColor Yellow
        Wait-KeyPress
        return
    }

    Write-Host "  The following essential applications will be installed:" -ForegroundColor White
    Write-Host ""

    foreach ($App in $EssentialApps) {
        Write-Host "  - $($App.Name)" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  Total: $($EssentialApps.Count) applications" -ForegroundColor Cyan
    Write-Host ""

    $Confirm = Get-ConfirmationPrompt -Message "Install all essential applications?"

    if ($Confirm) {
        # Ensure Winget is available
        if (-not (Test-Winget)) {
            Write-Host ""
            Write-Host "  Winget not found. Installing..." -ForegroundColor Yellow
            Install-Winget
        }

        Install-ApplicationBatch -Apps $EssentialApps -ShowProgress
    }

    Wait-KeyPress
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-ConfirmationPrompt {
    <#
    .SYNOPSIS
        Gets user confirmation
    #>
    param([string]$Message)

    Write-Host "  $Message (Y/N): " -NoNewline -ForegroundColor Yellow
    $Response = Read-Host
    return ($Response -eq 'Y' -or $Response -eq 'y')
}

function Wait-KeyPress {
    <#
    .SYNOPSIS
        Waits for any key press
    #>
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Export function
Export-ModuleMember -Function Show-AppInstallerMenu -ErrorAction SilentlyContinue
