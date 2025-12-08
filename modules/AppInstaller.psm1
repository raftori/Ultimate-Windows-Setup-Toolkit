<#
.SYNOPSIS
    Application Installer Module for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Provides functions for installing applications via Winget, Chocolatey, and Scoop
.VERSION
    4.0
#>

# Import common functions
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ModulePath\CommonFunctions.psm1" -Force -ErrorAction SilentlyContinue

# ============================================================
# PACKAGE MANAGER FUNCTIONS
# ============================================================

function Test-Winget {
    <#
    .SYNOPSIS
        Tests if Winget is installed and available
    #>
    [CmdletBinding()]
    param()

    try {
        $WingetPath = Get-Command winget -ErrorAction SilentlyContinue
        return $null -ne $WingetPath
    }
    catch {
        return $false
    }
}

function Test-Chocolatey {
    <#
    .SYNOPSIS
        Tests if Chocolatey is installed and available
    #>
    [CmdletBinding()]
    param()

    try {
        $ChocoPath = Get-Command choco -ErrorAction SilentlyContinue
        return $null -ne $ChocoPath
    }
    catch {
        return $false
    }
}

function Test-Scoop {
    <#
    .SYNOPSIS
        Tests if Scoop is installed and available
    #>
    [CmdletBinding()]
    param()

    try {
        $ScoopPath = Get-Command scoop -ErrorAction SilentlyContinue
        return $null -ne $ScoopPath
    }
    catch {
        return $false
    }
}

function Install-Winget {
    <#
    .SYNOPSIS
        Installs or updates the Windows Package Manager (Winget)
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Installing Windows Package Manager (Winget)" -Type Header

    if (Test-Winget) {
        $Version = winget --version
        Write-ColorOutput -Message "Winget is already installed: $Version" -Type Success
        return $true
    }

    try {
        Write-ColorOutput -Message "Downloading Winget..." -Type Info

        $ProgressPreference = 'SilentlyContinue'

        # Download VCLibs dependency
        $VCLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $VCLibsPath = "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Invoke-WebRequest -Uri $VCLibsUrl -OutFile $VCLibsPath

        # Get latest Winget release
        $WingetRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $WingetUrl = $WingetRelease.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -First 1 -ExpandProperty browser_download_url
        $WingetPath = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
        Invoke-WebRequest -Uri $WingetUrl -OutFile $WingetPath

        # Install VCLibs and Winget
        Write-ColorOutput -Message "Installing dependencies..." -Type Info
        Add-AppxPackage -Path $VCLibsPath -ErrorAction SilentlyContinue
        Add-AppxPackage -Path $WingetPath

        # Cleanup
        Remove-Item -Path $VCLibsPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $WingetPath -Force -ErrorAction SilentlyContinue

        if (Test-Winget) {
            Write-ColorOutput -Message "Winget installed successfully" -Type Success
            return $true
        }
    }
    catch {
        Write-Log "Failed to install Winget: $($_.Exception.Message)" -Level ERROR
    }

    return $false
}

function Install-Chocolatey {
    <#
    .SYNOPSIS
        Installs or updates Chocolatey Package Manager
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Installing Chocolatey Package Manager" -Type Header

    if (Test-Chocolatey) {
        $Version = choco --version
        Write-ColorOutput -Message "Chocolatey is already installed: $Version" -Type Success

        # Update Chocolatey
        Write-ColorOutput -Message "Updating Chocolatey..." -Type Info
        choco upgrade chocolatey -y --limit-output | Out-Null
        return $true
    }

    try {
        Write-ColorOutput -Message "Installing Chocolatey..." -Type Info

        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Test-Chocolatey) {
            Write-ColorOutput -Message "Chocolatey installed successfully" -Type Success
            return $true
        }
    }
    catch {
        Write-Log "Failed to install Chocolatey: $($_.Exception.Message)" -Level ERROR
    }

    return $false
}

function Install-Scoop {
    <#
    .SYNOPSIS
        Installs Scoop Package Manager
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Installing Scoop Package Manager" -Type Header

    if (Test-Scoop) {
        Write-ColorOutput -Message "Scoop is already installed" -Type Success

        # Update Scoop
        Write-ColorOutput -Message "Updating Scoop..." -Type Info
        scoop update | Out-Null
        return $true
    }

    try {
        Write-ColorOutput -Message "Installing Scoop..." -Type Info

        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod get.scoop.sh | Invoke-Expression

        # Add common buckets
        Write-ColorOutput -Message "Adding Scoop buckets..." -Type Info
        scoop bucket add extras | Out-Null
        scoop bucket add java | Out-Null
        scoop bucket add versions | Out-Null

        if (Test-Scoop) {
            Write-ColorOutput -Message "Scoop installed successfully" -Type Success
            return $true
        }
    }
    catch {
        Write-Log "Failed to install Scoop: $($_.Exception.Message)" -Level ERROR
    }

    return $false
}

function Install-AllPackageManagers {
    <#
    .SYNOPSIS
        Installs all package managers (Winget, Chocolatey, Scoop)
    #>
    [CmdletBinding()]
    param()

    $Results = @{
        Winget     = Install-Winget
        Chocolatey = Install-Chocolatey
        Scoop      = Install-Scoop
    }

    Write-Host ""
    Write-ColorOutput -Message "Package Manager Installation Summary" -Type Header

    foreach ($PM in $Results.Keys) {
        if ($Results[$PM]) {
            Write-Host "    [+] $PM" -ForegroundColor Green -NoNewline
            Write-Host " - Installed" -ForegroundColor White
        }
        else {
            Write-Host "    [X] $PM" -ForegroundColor Red -NoNewline
            Write-Host " - Failed" -ForegroundColor White
        }
    }

    return $Results
}

# ============================================================
# APPLICATION INSTALLATION FUNCTIONS
# ============================================================

function Install-WingetApp {
    <#
    .SYNOPSIS
        Installs an application via Winget
    .PARAMETER AppId
        The Winget package ID
    .PARAMETER AppName
        Display name for logging
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId,

        [string]$AppName = $AppId
    )

    if (-not (Test-Winget)) {
        Write-Log "Winget not available for installing $AppName" -Level WARNING
        return $false
    }

    try {
        # Check if already installed
        $Installed = winget list --id $AppId 2>$null
        if ($Installed -match $AppId) {
            Write-Log "$AppName is already installed (skipped)" -Level WARNING
            return $true
        }

        # Install the app
        $Result = winget install --id $AppId --silent --accept-source-agreements --accept-package-agreements 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "$AppName installed successfully" -Level SUCCESS
            return $true
        }
        else {
            Write-Log "Failed to install $AppName via Winget" -Level WARNING -NoConsole
            return $false
        }
    }
    catch {
        Write-Log "Error installing $AppName`: $($_.Exception.Message)" -Level ERROR -NoConsole
        return $false
    }
}

function Install-ChocoApp {
    <#
    .SYNOPSIS
        Installs an application via Chocolatey
    .PARAMETER PackageId
        The Chocolatey package ID
    .PARAMETER AppName
        Display name for logging
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,

        [string]$AppName = $PackageId
    )

    if (-not (Test-Chocolatey)) {
        Write-Log "Chocolatey not available for installing $AppName" -Level WARNING
        return $false
    }

    try {
        $Result = choco install $PackageId -y --limit-output 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "$AppName installed successfully via Chocolatey" -Level SUCCESS
            return $true
        }
        else {
            Write-Log "Failed to install $AppName via Chocolatey" -Level WARNING -NoConsole
            return $false
        }
    }
    catch {
        Write-Log "Error installing $AppName`: $($_.Exception.Message)" -Level ERROR -NoConsole
        return $false
    }
}

function Install-ScoopApp {
    <#
    .SYNOPSIS
        Installs an application via Scoop
    .PARAMETER PackageId
        The Scoop package ID
    .PARAMETER AppName
        Display name for logging
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,

        [string]$AppName = $PackageId
    )

    if (-not (Test-Scoop)) {
        Write-Log "Scoop not available for installing $AppName" -Level WARNING
        return $false
    }

    try {
        $Result = scoop install $PackageId 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "$AppName installed successfully via Scoop" -Level SUCCESS
            return $true
        }
        else {
            Write-Log "Failed to install $AppName via Scoop" -Level WARNING -NoConsole
            return $false
        }
    }
    catch {
        Write-Log "Error installing $AppName`: $($_.Exception.Message)" -Level ERROR -NoConsole
        return $false
    }
}

function Install-Application {
    <#
    .SYNOPSIS
        Installs an application using the best available package manager
    .PARAMETER App
        Hashtable with app details (Name, WingetId, ChocoId, ScoopId)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$App
    )

    $AppName = $App.Name

    # Try Winget first
    if ($App.WingetId) {
        if (Install-WingetApp -AppId $App.WingetId -AppName $AppName) {
            return $true
        }
    }

    # Fall back to Chocolatey
    if ($App.ChocoId) {
        if (Install-ChocoApp -PackageId $App.ChocoId -AppName $AppName) {
            return $true
        }
    }

    # Fall back to Scoop
    if ($App.ScoopId) {
        if (Install-ScoopApp -PackageId $App.ScoopId -AppName $AppName) {
            return $true
        }
    }

    Write-Log "All installation methods failed for $AppName" -Level ERROR
    return $false
}

function Install-ApplicationBatch {
    <#
    .SYNOPSIS
        Installs multiple applications from a list
    .PARAMETER Apps
        Array of application hashtables
    .PARAMETER ShowProgress
        Whether to show progress bar
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Apps,

        [switch]$ShowProgress
    )

    $Total = $Apps.Count
    $Current = 0
    $Successful = 0
    $Failed = 0
    $Skipped = 0
    $FailedApps = @()

    Write-ColorOutput -Message "Installing $Total applications..." -Type Header

    foreach ($App in $Apps) {
        $Current++

        if ($ShowProgress) {
            Show-TaskProgress -TaskName "Installing" -Current $Current -Total $Total
        }

        Write-Host "`n    Installing: " -ForegroundColor Cyan -NoNewline
        Write-Host "$($App.Name)" -ForegroundColor White

        if ($App.Description) {
            Write-Host "    $($App.Description)" -ForegroundColor Gray
        }

        $Result = Install-Application -App $App

        if ($Result) {
            $Successful++
        }
        else {
            $Failed++
            $FailedApps += $App.Name
        }
    }

    # Summary
    Write-Host ""
    Write-ColorOutput -Message "Installation Complete" -Type Header
    Write-Host "    Successful: " -ForegroundColor Green -NoNewline
    Write-Host "$Successful" -ForegroundColor White
    Write-Host "    Failed:     " -ForegroundColor Red -NoNewline
    Write-Host "$Failed" -ForegroundColor White
    Write-Host "    Skipped:    " -ForegroundColor Yellow -NoNewline
    Write-Host "$Skipped" -ForegroundColor White

    if ($FailedApps.Count -gt 0) {
        Write-Host ""
        Write-Host "    Failed applications:" -ForegroundColor Red
        foreach ($FailedApp in $FailedApps) {
            Write-Host "      - $FailedApp" -ForegroundColor Red
        }
    }

    return @{
        Successful = $Successful
        Failed     = $Failed
        Skipped    = $Skipped
        FailedApps = $FailedApps
    }
}

# ============================================================
# APPLICATION UPDATE FUNCTIONS
# ============================================================

function Update-AllApplications {
    <#
    .SYNOPSIS
        Updates all installed applications using all package managers
    #>
    [CmdletBinding()]
    param()

    Write-ColorOutput -Message "Updating All Applications" -Type Header

    $Results = @{
        Winget     = $false
        Chocolatey = $false
        Scoop      = $false
    }

    # Update Winget apps
    if (Test-Winget) {
        Write-ColorOutput -Message "Updating Winget applications..." -Type Info
        try {
            winget upgrade --all --silent 2>&1 | Out-Null
            $Results.Winget = $true
            Write-ColorOutput -Message "Winget applications updated" -Type Success
        }
        catch {
            Write-Log "Failed to update Winget apps: $($_.Exception.Message)" -Level WARNING
        }
    }

    # Update Chocolatey apps
    if (Test-Chocolatey) {
        Write-ColorOutput -Message "Updating Chocolatey applications..." -Type Info
        try {
            choco upgrade all -y --limit-output 2>&1 | Out-Null
            $Results.Chocolatey = $true
            Write-ColorOutput -Message "Chocolatey applications updated" -Type Success
        }
        catch {
            Write-Log "Failed to update Chocolatey apps: $($_.Exception.Message)" -Level WARNING
        }
    }

    # Update Scoop apps
    if (Test-Scoop) {
        Write-ColorOutput -Message "Updating Scoop applications..." -Type Info
        try {
            scoop update *
            $Results.Scoop = $true
            Write-ColorOutput -Message "Scoop applications updated" -Type Success
        }
        catch {
            Write-Log "Failed to update Scoop apps: $($_.Exception.Message)" -Level WARNING
        }
    }

    return $Results
}

# ============================================================
# APPLICATION UNINSTALL FUNCTIONS
# ============================================================

function Uninstall-Application {
    <#
    .SYNOPSIS
        Uninstalls an application using the best available method
    .PARAMETER App
        Hashtable with app details
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$App
    )

    $AppName = $App.Name

    # Try Winget first
    if ($App.WingetId -and (Test-Winget)) {
        try {
            $Result = winget uninstall --id $App.WingetId --silent 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$AppName uninstalled via Winget" -Level SUCCESS
                return $true
            }
        }
        catch { }
    }

    # Try Chocolatey
    if ($App.ChocoId -and (Test-Chocolatey)) {
        try {
            $Result = choco uninstall $App.ChocoId -y --limit-output 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$AppName uninstalled via Chocolatey" -Level SUCCESS
                return $true
            }
        }
        catch { }
    }

    # Try Scoop
    if ($App.ScoopId -and (Test-Scoop)) {
        try {
            $Result = scoop uninstall $App.ScoopId 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$AppName uninstalled via Scoop" -Level SUCCESS
                return $true
            }
        }
        catch { }
    }

    Write-Log "Failed to uninstall $AppName" -Level ERROR
    return $false
}

# ============================================================
# APPLICATION CATALOG FUNCTIONS
# ============================================================

function Get-ApplicationCatalog {
    <#
    .SYNOPSIS
        Gets the application catalog from the config file
    #>
    [CmdletBinding()]
    param()

    $Config = Get-ToolkitConfig -ConfigName "apps"

    if ($Config) {
        return $Config
    }

    # Return default catalog if config not found
    return Get-DefaultApplicationCatalog
}

function Get-DefaultApplicationCatalog {
    <#
    .SYNOPSIS
        Returns the default application catalog
    #>
    [CmdletBinding()]
    param()

    return @{
        Categories = @{
            "Browsers"       = @(
                @{ Name = "Google Chrome"; WingetId = "Google.Chrome"; ChocoId = "googlechrome"; Description = "Fast, secure web browser" }
                @{ Name = "Mozilla Firefox"; WingetId = "Mozilla.Firefox"; ChocoId = "firefox"; Description = "Free and open-source browser" }
                @{ Name = "Brave Browser"; WingetId = "Brave.Brave"; ChocoId = "brave"; Description = "Privacy-focused browser" }
                @{ Name = "Microsoft Edge"; WingetId = "Microsoft.Edge"; ChocoId = "microsoft-edge"; Description = "Microsoft's modern browser" }
            )
            "Development"    = @(
                @{ Name = "Visual Studio Code"; WingetId = "Microsoft.VisualStudioCode"; ChocoId = "vscode"; Description = "Code editor by Microsoft" }
                @{ Name = "Git"; WingetId = "Git.Git"; ChocoId = "git"; Description = "Version control system" }
                @{ Name = "Python 3"; WingetId = "Python.Python.3.12"; ChocoId = "python312"; Description = "Python programming language" }
                @{ Name = "Node.js"; WingetId = "OpenJS.NodeJS.LTS"; ChocoId = "nodejs-lts"; Description = "JavaScript runtime" }
                @{ Name = "Docker Desktop"; WingetId = "Docker.DockerDesktop"; ChocoId = "docker-desktop"; Description = "Container platform" }
            )
            "Utilities"      = @(
                @{ Name = "7-Zip"; WingetId = "7zip.7zip"; ChocoId = "7zip"; Description = "File archiver" }
                @{ Name = "VLC Media Player"; WingetId = "VideoLAN.VLC"; ChocoId = "vlc"; Description = "Multimedia player" }
                @{ Name = "Notepad++"; WingetId = "Notepad++.Notepad++"; ChocoId = "notepadplusplus"; Description = "Text editor" }
                @{ Name = "Everything Search"; WingetId = "voidtools.Everything"; ChocoId = "everything"; Description = "Fast file search" }
                @{ Name = "PowerToys"; WingetId = "Microsoft.PowerToys"; ChocoId = "powertoys"; Description = "Windows utilities" }
            )
            "Communication"  = @(
                @{ Name = "Discord"; WingetId = "Discord.Discord"; ChocoId = "discord"; Description = "Voice and text chat" }
                @{ Name = "Slack"; WingetId = "SlackTechnologies.Slack"; ChocoId = "slack"; Description = "Team collaboration" }
                @{ Name = "Zoom"; WingetId = "Zoom.Zoom"; ChocoId = "zoom"; Description = "Video conferencing" }
                @{ Name = "Microsoft Teams"; WingetId = "Microsoft.Teams"; ChocoId = "microsoft-teams"; Description = "Collaboration platform" }
            )
            "System Tools"   = @(
                @{ Name = "Windows Terminal"; WingetId = "Microsoft.WindowsTerminal"; ChocoId = "microsoft-windows-terminal"; Description = "Modern terminal" }
                @{ Name = "PowerShell 7"; WingetId = "Microsoft.PowerShell"; ChocoId = "powershell-core"; Description = "Cross-platform PowerShell" }
                @{ Name = "HWiNFO"; WingetId = "REALiX.HWiNFO"; ChocoId = "hwinfo"; Description = "Hardware information" }
            )
            "Security"       = @(
                @{ Name = "Bitwarden"; WingetId = "Bitwarden.Bitwarden"; ChocoId = "bitwarden"; Description = "Password manager" }
                @{ Name = "KeePassXC"; WingetId = "KeePassXCTeam.KeePassXC"; ChocoId = "keepassxc"; Description = "Password manager" }
            )
        }
    }
}

function Get-ApplicationsByCategory {
    <#
    .SYNOPSIS
        Gets applications from a specific category
    .PARAMETER Category
        The category name
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category
    )

    $Catalog = Get-ApplicationCatalog

    if ($Catalog.Categories.ContainsKey($Category)) {
        return $Catalog.Categories[$Category]
    }

    return @()
}

function Get-AllCategories {
    <#
    .SYNOPSIS
        Gets all available application categories
    #>
    [CmdletBinding()]
    param()

    $Catalog = Get-ApplicationCatalog
    return $Catalog.Categories.Keys | Sort-Object
}

function Get-EssentialApps {
    <#
    .SYNOPSIS
        Gets all applications marked as essential
    #>
    [CmdletBinding()]
    param()

    $Catalog = Get-ApplicationCatalog
    $Essential = @()

    foreach ($Category in $Catalog.Categories.Keys) {
        $Apps = $Catalog.Categories[$Category]
        foreach ($App in $Apps) {
            if ($App.Essential -eq $true) {
                $Essential += $App
            }
        }
    }

    return $Essential
}

function Get-EssentialBundle {
    <#
    .SYNOPSIS
        Gets applications for a specific bundle
    .PARAMETER BundleName
        Name of the bundle (Minimal, Standard, Developer, Gamer, Creative)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Minimal', 'Standard', 'Developer', 'Gamer', 'Creative')]
        [string]$BundleName
    )

    $Catalog = Get-ApplicationCatalog
    $Bundle = @()

    if ($Catalog.EssentialBundles -and $Catalog.EssentialBundles.ContainsKey($BundleName)) {
        $AppNames = $Catalog.EssentialBundles[$BundleName]

        foreach ($Category in $Catalog.Categories.Keys) {
            foreach ($App in $Catalog.Categories[$Category]) {
                if ($AppNames -contains $App.Name) {
                    $Bundle += $App
                }
            }
        }
    }

    return $Bundle
}

function Get-CategoryIcon {
    <#
    .SYNOPSIS
        Gets the icon/emoji for a category
    .PARAMETER Category
        The category name
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category
    )

    $Icons = @{
        "Browsers"          = "Web"
        "Communication"     = "Chat"
        "Gaming"            = "Game"
        "Media & Creative"  = "Media"
        "Development Tools" = "Dev"
        "Utilities"         = "Tool"
        "Security & VPN"    = "Lock"
        "File Management"   = "File"
        "Cloud & Sync"      = "Cloud"
        "System Tools"      = "Sys"
        "Productivity"      = "Work"
        "AI Tools"          = "AI"
        "Remote Access"     = "Remote"
        "Virtualization"    = "VM"
    }

    if ($Icons.ContainsKey($Category)) {
        return $Icons[$Category]
    }

    return "App"
}

function Search-Applications {
    <#
    .SYNOPSIS
        Searches for applications by name across all categories
    .PARAMETER SearchTerm
        The search term
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SearchTerm
    )

    $Catalog = Get-ApplicationCatalog
    $Results = @()

    foreach ($Category in $Catalog.Categories.Keys) {
        foreach ($App in $Catalog.Categories[$Category]) {
            if ($App.Name -like "*$SearchTerm*" -or $App.Description -like "*$SearchTerm*") {
                $AppWithCategory = @{
                    Name        = $App.Name
                    WingetId    = $App.WingetId
                    ChocoId     = $App.ChocoId
                    Description = $App.Description
                    Essential   = $App.Essential
                    Category    = $Category
                }
                $Results += $AppWithCategory
            }
        }
    }

    return $Results
}

function Test-ApplicationInstalled {
    <#
    .SYNOPSIS
        Checks if an application is already installed
    .PARAMETER App
        The application hashtable with WingetId
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$App
    )

    if (-not (Test-Winget)) {
        return $false
    }

    if (-not $App.WingetId) {
        return $false
    }

    try {
        $Installed = winget list --id $App.WingetId 2>$null
        return ($Installed -match $App.WingetId)
    }
    catch {
        return $false
    }
}

function Get-InstalledApplications {
    <#
    .SYNOPSIS
        Gets list of installed applications from winget
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-Winget)) {
        return @()
    }

    try {
        $Installed = winget list --accept-source-agreements 2>$null
        return $Installed
    }
    catch {
        return @()
    }
}

function Install-CategoryApps {
    <#
    .SYNOPSIS
        Installs all apps from a category
    .PARAMETER Category
        The category name
    .PARAMETER SelectedOnly
        Install only selected apps (array of app names)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,

        [array]$SelectedOnly
    )

    $Apps = Get-ApplicationsByCategory -Category $Category

    if ($SelectedOnly -and $SelectedOnly.Count -gt 0) {
        $Apps = $Apps | Where-Object { $SelectedOnly -contains $_.Name }
    }

    if ($Apps.Count -eq 0) {
        Write-ColorOutput -Message "No applications to install" -Type Warning
        return @{ Successful = 0; Failed = 0 }
    }

    return Install-ApplicationBatch -Apps $Apps -ShowProgress
}

function Install-EssentialBundle {
    <#
    .SYNOPSIS
        Installs an essential bundle
    .PARAMETER BundleName
        Name of the bundle
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Minimal', 'Standard', 'Developer', 'Gamer', 'Creative')]
        [string]$BundleName
    )

    $Apps = Get-EssentialBundle -BundleName $BundleName

    if ($Apps.Count -eq 0) {
        Write-ColorOutput -Message "No applications found in bundle: $BundleName" -Type Warning
        return @{ Successful = 0; Failed = 0 }
    }

    Write-ColorOutput -Message "Installing $BundleName Bundle ($($Apps.Count) apps)" -Type Header

    return Install-ApplicationBatch -Apps $Apps -ShowProgress
}

function Show-PackageManagerStatus {
    <#
    .SYNOPSIS
        Shows the status of all package managers
    #>
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "  Package Manager Status:" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray

    # Winget
    Write-Host "  Winget:     " -NoNewline -ForegroundColor Gray
    if (Test-Winget) {
        $Version = (winget --version 2>$null) -replace 'v', ''
        Write-Host "Installed ($Version)" -ForegroundColor Green
    }
    else {
        Write-Host "Not Installed" -ForegroundColor Red
    }

    # Chocolatey
    Write-Host "  Chocolatey: " -NoNewline -ForegroundColor Gray
    if (Test-Chocolatey) {
        $Version = (choco --version 2>$null)
        Write-Host "Installed ($Version)" -ForegroundColor Green
    }
    else {
        Write-Host "Not Installed" -ForegroundColor Yellow
    }

    # Scoop
    Write-Host "  Scoop:      " -NoNewline -ForegroundColor Gray
    if (Test-Scoop) {
        Write-Host "Installed" -ForegroundColor Green
    }
    else {
        Write-Host "Not Installed" -ForegroundColor Yellow
    }

    Write-Host ""
}

# ============================================================
# EXPORT MODULE MEMBERS
# ============================================================

Export-ModuleMember -Function @(
    'Test-Winget',
    'Test-Chocolatey',
    'Test-Scoop',
    'Install-Winget',
    'Install-Chocolatey',
    'Install-Scoop',
    'Install-AllPackageManagers',
    'Install-WingetApp',
    'Install-ChocoApp',
    'Install-ScoopApp',
    'Install-Application',
    'Install-ApplicationBatch',
    'Update-AllApplications',
    'Uninstall-Application',
    'Get-ApplicationCatalog',
    'Get-DefaultApplicationCatalog',
    'Get-ApplicationsByCategory',
    'Get-AllCategories',
    'Get-EssentialApps',
    'Get-EssentialBundle',
    'Get-CategoryIcon',
    'Search-Applications',
    'Test-ApplicationInstalled',
    'Get-InstalledApplications',
    'Install-CategoryApps',
    'Install-EssentialBundle',
    'Show-PackageManagerStatus'
)
