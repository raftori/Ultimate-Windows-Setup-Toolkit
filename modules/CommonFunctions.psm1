<#
.SYNOPSIS
    Common Functions Module for Ultimate Windows Setup Toolkit
.DESCRIPTION
    Provides shared utility functions used across all toolkit modules
.VERSION
    4.0
#>

# ============================================================
# SCRIPT CONFIGURATION
# ============================================================

$Script:ToolkitVersion = "4.0"
$Script:ToolkitName = "Ultimate Windows Setup Toolkit"
$Script:BaseDir = "$env:ProgramData\UltimateWindowsToolkit"
$Script:LogDir = "$Script:BaseDir\Logs"
$Script:BackupDir = "$Script:BaseDir\Backups"
$Script:ConfigDir = "$PSScriptRoot\..\configs"

# Dry-run and rollback tracking
$Script:DryRunMode = $false
$Script:OperationStack = [System.Collections.ArrayList]::new()
$Script:OperationTrackingEnabled = $false

# ============================================================
# INITIALIZATION
# ============================================================

function Initialize-Toolkit {
    <#
    .SYNOPSIS
        Initializes the toolkit directories and logging
    #>
    [CmdletBinding()]
    param()

    # Create required directories
    $Directories = @($Script:BaseDir, $Script:LogDir, $Script:BackupDir)
    foreach ($Dir in $Directories) {
        if (-not (Test-Path $Dir)) {
            New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        }
    }

    # Initialize log file
    $Script:CurrentLogFile = "$Script:LogDir\Toolkit_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

    Write-Log "Toolkit initialized - Version $Script:ToolkitVersion"
    return $true
}

# ============================================================
# LOGGING FUNCTIONS
# ============================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes a message to the log file and optionally to the console
    .PARAMETER Message
        The message to log
    .PARAMETER Level
        Log level: INFO, SUCCESS, WARNING, ERROR, DEBUG
    .PARAMETER NoConsole
        If specified, don't write to console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO',

        [switch]$NoConsole
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"

    # Write to log file
    if ($Script:CurrentLogFile) {
        Add-Content -Path $Script:CurrentLogFile -Value $LogMessage -ErrorAction SilentlyContinue
    }

    # Write to console with color
    if (-not $NoConsole) {
        $Color = switch ($Level) {
            'INFO'    { 'Cyan' }
            'SUCCESS' { 'Green' }
            'WARNING' { 'Yellow' }
            'ERROR'   { 'Red' }
            'DEBUG'   { 'Gray' }
            default   { 'White' }
        }

        $Symbol = switch ($Level) {
            'INFO'    { '[i]' }
            'SUCCESS' { '[+]' }
            'WARNING' { '[!]' }
            'ERROR'   { '[X]' }
            'DEBUG'   { '[D]' }
            default   { '[-]' }
        }

        Write-Host "$Symbol $Message" -ForegroundColor $Color
    }
}

function Write-ColorOutput {
    <#
    .SYNOPSIS
        Writes colored output to the console with timestamps
    .PARAMETER Message
        The message to display
    .PARAMETER Type
        Output type: Info, Success, Warning, Error, Header, Critical
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Header', 'Critical')]
        [string]$Type = 'Info'
    )

    $Timestamp = Get-Date -Format "HH:mm:ss"

    switch ($Type) {
        'Info' {
            Write-Host "[$Timestamp] " -ForegroundColor DarkGray -NoNewline
            Write-Host "[INFO] " -ForegroundColor Cyan -NoNewline
            Write-Host $Message -ForegroundColor White
        }
        'Success' {
            Write-Host "[$Timestamp] " -ForegroundColor DarkGray -NoNewline
            Write-Host "[OK] " -ForegroundColor Green -NoNewline
            Write-Host $Message -ForegroundColor Green
        }
        'Warning' {
            Write-Host "[$Timestamp] " -ForegroundColor DarkGray -NoNewline
            Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
            Write-Host $Message -ForegroundColor Yellow
        }
        'Error' {
            Write-Host "[$Timestamp] " -ForegroundColor DarkGray -NoNewline
            Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
            Write-Host $Message -ForegroundColor Red
        }
        'Critical' {
            Write-Host "[$Timestamp] " -ForegroundColor DarkGray -NoNewline
            Write-Host "[!!!] " -ForegroundColor Magenta -NoNewline
            Write-Host $Message -ForegroundColor Magenta
        }
        'Header' {
            Write-Host ""
            Write-Host ("=" * 70) -ForegroundColor Cyan
            Write-Host "  $Message" -ForegroundColor Cyan
            Write-Host ("=" * 70) -ForegroundColor Cyan
            Write-Host ""
        }
    }
}

# ============================================================
# BANNER AND MENU FUNCTIONS
# ============================================================

function Show-Banner {
    <#
    .SYNOPSIS
        Displays the toolkit ASCII art banner
    .PARAMETER Title
        Optional custom title to display
    #>
    [CmdletBinding()]
    param(
        [string]$Title = "ULTIMATE WINDOWS SETUP TOOLKIT v$Script:ToolkitVersion"
    )

    Clear-Host
    $Banner = @"

    ╔══════════════════════════════════════════════════════════════════╗
    ║          $Title
    ║          Production-Ready System Configuration                    ║
    ╠══════════════════════════════════════════════════════════════════╣
"@
    Write-Host $Banner -ForegroundColor Cyan
}

function Show-MenuOption {
    <#
    .SYNOPSIS
        Displays a formatted menu option
    .PARAMETER Key
        The key to press (e.g., "1", "Q")
    .PARAMETER Icon
        The emoji/icon for the option
    .PARAMETER Text
        The menu option text
    .PARAMETER Selected
        Whether this option is currently selected
    #>
    [CmdletBinding()]
    param(
        [string]$Key,
        [string]$Icon,
        [string]$Text,
        [switch]$Selected
    )

    $Prefix = if ($Selected) { ">>>" } else { "   " }
    $Color = if ($Selected) { "Yellow" } else { "White" }

    Write-Host "    ║  $Prefix " -ForegroundColor Cyan -NoNewline
    Write-Host "[$Key] $Icon $Text" -ForegroundColor $Color -NoNewline
    Write-Host (" " * (50 - $Text.Length)) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
}

function Show-MenuFooter {
    <#
    .SYNOPSIS
        Displays the menu footer
    #>
    Write-Host "    ║                                                                   ║" -ForegroundColor Cyan
    Write-Host "    ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-MenuChoice {
    <#
    .SYNOPSIS
        Gets a menu choice from the user
    .PARAMETER Prompt
        The prompt to display
    .PARAMETER ValidChoices
        Array of valid choices
    #>
    [CmdletBinding()]
    param(
        [string]$Prompt = "Enter your choice",
        [string[]]$ValidChoices
    )

    do {
        Write-Host ""
        Write-Host "    $Prompt`: " -ForegroundColor Yellow -NoNewline
        $Choice = Read-Host

        if ($ValidChoices -and $Choice -notin $ValidChoices) {
            Write-Host "    Invalid choice. Please try again." -ForegroundColor Red
            $Choice = $null
        }
    } while (-not $Choice)

    return $Choice.ToUpper()
}

# ============================================================
# PROGRESS FUNCTIONS
# ============================================================

function Show-Progress {
    <#
    .SYNOPSIS
        Shows a progress bar for an operation
    .PARAMETER Activity
        Description of the current activity
    .PARAMETER Status
        Current status message
    .PARAMETER PercentComplete
        Percentage complete (0-100)
    .PARAMETER Id
        Progress bar ID for nested progress
    #>
    [CmdletBinding()]
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete,
        [int]$Id = 0
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete -Id $Id
}

function Show-TaskProgress {
    <#
    .SYNOPSIS
        Shows progress for a task with visual bar
    .PARAMETER TaskName
        Name of the current task
    .PARAMETER Current
        Current item number
    .PARAMETER Total
        Total number of items
    #>
    [CmdletBinding()]
    param(
        [string]$TaskName,
        [int]$Current,
        [int]$Total
    )

    $Percent = [math]::Round(($Current / $Total) * 100)
    $BarLength = 40
    $FilledLength = [math]::Round(($Percent / 100) * $BarLength)
    $EmptyLength = $BarLength - $FilledLength

    $Bar = "[" + ("=" * $FilledLength) + (" " * $EmptyLength) + "]"

    Write-Host "`r    $TaskName $Bar $Percent% ($Current/$Total)    " -ForegroundColor Cyan -NoNewline

    if ($Current -eq $Total) {
        Write-Host ""
    }
}

# ============================================================
# ADMIN AND PRIVILEGE FUNCTIONS
# ============================================================

function Test-Administrator {
    <#
    .SYNOPSIS
        Tests if the current user has administrator privileges
    .OUTPUTS
        Boolean indicating admin status
    #>
    [CmdletBinding()]
    param()

    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminPrivileges {
    <#
    .SYNOPSIS
        Requests elevation to administrator if not already elevated
    .PARAMETER ScriptPath
        Path to the script to restart with admin privileges
    #>
    [CmdletBinding()]
    param(
        [string]$ScriptPath
    )

    if (-not (Test-Administrator)) {
        Write-ColorOutput -Message "Administrator privileges required!" -Type Error
        Write-Host ""
        Write-Host "    Please run this toolkit as Administrator:" -ForegroundColor Yellow
        Write-Host "    1. Right-click on PowerShell" -ForegroundColor White
        Write-Host "    2. Select 'Run as Administrator'" -ForegroundColor White
        Write-Host "    3. Run this script again" -ForegroundColor White
        Write-Host ""

        if ($ScriptPath) {
            $Confirm = Read-Host "    Would you like to restart with admin privileges? (Y/N)"
            if ($Confirm -eq 'Y' -or $Confirm -eq 'y') {
                Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -File `"$ScriptPath`"" -Verb RunAs
                exit
            }
        }

        return $false
    }

    return $true
}

# ============================================================
# REGISTRY FUNCTIONS
# ============================================================

function Set-RegistryValue {
    <#
    .SYNOPSIS
        Sets a registry value with error handling and logging
    .PARAMETER Path
        Registry path
    .PARAMETER Name
        Value name
    .PARAMETER Value
        Value to set
    .PARAMETER Type
        Registry value type
    .PARAMETER Description
        Description of what this setting does
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        $Value,

        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type = 'DWord',

        [string]$Description = ""
    )

    try {
        # Create path if it doesn't exist
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        # Set the value
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop

        if ($Description) {
            Write-Log "$Description" -Level SUCCESS
        } else {
            Write-Log "Set registry: $Path\$Name = $Value" -Level DEBUG -NoConsole
        }

        return $true
    }
    catch {
        Write-Log "Failed to set registry: $Path\$Name - $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Backup-RegistryKey {
    <#
    .SYNOPSIS
        Backs up a registry key to a .reg file
    .PARAMETER KeyPath
        The registry key path to backup
    .PARAMETER Description
        Description for the backup
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath,

        [string]$Description = ""
    )

    try {
        $SafeName = $KeyPath -replace '\\', '_' -replace ':', ''
        $BackupFile = "$Script:BackupDir\Registry_${SafeName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"

        $Result = Start-Process "reg" -ArgumentList "export `"$KeyPath`" `"$BackupFile`" /y" -Wait -NoNewWindow -PassThru

        if ($Result.ExitCode -eq 0) {
            Write-Log "Registry backup created: $BackupFile" -Level SUCCESS -NoConsole
            return $BackupFile
        }
    }
    catch {
        Write-Log "Failed to backup registry: $KeyPath - $($_.Exception.Message)" -Level WARNING
    }

    return $null
}

# ============================================================
# SERVICE FUNCTIONS
# ============================================================

function Set-ServiceState {
    <#
    .SYNOPSIS
        Sets the startup type and state of a Windows service
    .PARAMETER ServiceName
        Name of the service
    .PARAMETER StartupType
        Desired startup type
    .PARAMETER Stop
        Whether to stop the service
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [ValidateSet('Automatic', 'Manual', 'Disabled')]
        [string]$StartupType = 'Disabled',

        [switch]$Stop
    )

    try {
        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($Service) {
            if ($Stop -and $Service.Status -eq 'Running') {
                Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            }

            Set-Service -Name $ServiceName -StartupType $StartupType -ErrorAction Stop
            Write-Log "Service '$ServiceName' set to $StartupType" -Level SUCCESS -NoConsole
            return $true
        }
        else {
            Write-Log "Service '$ServiceName' not found" -Level WARNING -NoConsole
            return $false
        }
    }
    catch {
        Write-Log "Failed to modify service '$ServiceName': $($_.Exception.Message)" -Level ERROR -NoConsole
        return $false
    }
}

# ============================================================
# SYSTEM INFORMATION FUNCTIONS
# ============================================================

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Gets comprehensive system information
    .OUTPUTS
        Hashtable with system information
    #>
    [CmdletBinding()]
    param()

    try {
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem
        $CS = Get-CimInstance -ClassName Win32_ComputerSystem
        $CPU = Get-CimInstance -ClassName Win32_Processor
        $GPU = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -notlike "*Microsoft*" } | Select-Object -First 1
        $PhysicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue

        $SystemInfo = @{
            ComputerName    = $env:COMPUTERNAME
            OSName          = $OS.Caption
            OSVersion       = $OS.Version
            OSBuild         = $OS.BuildNumber
            Architecture    = $OS.OSArchitecture
            RAMTotal        = [math]::Round($CS.TotalPhysicalMemory / 1GB, 2)
            RAMFree         = [math]::Round($OS.FreePhysicalMemory / 1MB / 1024, 2)
            CPUName         = $CPU.Name
            CPUCores        = $CPU.NumberOfCores
            CPUThreads      = $CPU.NumberOfLogicalProcessors
            CPUMaxSpeed     = $CPU.MaxClockSpeed
            GPUName         = if ($GPU) { $GPU.Name } else { "Unknown" }
            GPURAM          = if ($GPU.AdapterRAM) { [math]::Round($GPU.AdapterRAM / 1GB, 2) } else { 0 }
            NVMeCount       = ($PhysicalDisks | Where-Object { $_.BusType -eq "NVMe" }).Count
            SSDCount        = ($PhysicalDisks | Where-Object { $_.MediaType -eq "SSD" }).Count
            IsRyzen         = $CPU.Name -like "*Ryzen*"
            IsIntel         = $CPU.Name -like "*Intel*"
            IsNVIDIA        = $GPU.Name -like "*NVIDIA*"
            IsAMD           = $GPU.Name -like "*AMD*" -or $GPU.Name -like "*Radeon*"
        }

        return $SystemInfo
    }
    catch {
        Write-Log "Failed to get system information: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Show-SystemInfo {
    <#
    .SYNOPSIS
        Displays system information in a formatted way
    #>
    [CmdletBinding()]
    param()

    $Info = Get-SystemInfo

    if ($Info) {
        Write-Host ""
        Write-Host "    System Information:" -ForegroundColor Cyan
        Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "    Computer:   " -ForegroundColor Gray -NoNewline
        Write-Host "$($Info.ComputerName)" -ForegroundColor White
        Write-Host "    OS:         " -ForegroundColor Gray -NoNewline
        Write-Host "$($Info.OSName)" -ForegroundColor White
        Write-Host "    Build:      " -ForegroundColor Gray -NoNewline
        Write-Host "$($Info.OSBuild)" -ForegroundColor White
        Write-Host "    CPU:        " -ForegroundColor Gray -NoNewline
        Write-Host "$($Info.CPUName)" -ForegroundColor White
        Write-Host "    RAM:        " -ForegroundColor Gray -NoNewline
        Write-Host "$($Info.RAMTotal) GB" -ForegroundColor White
        Write-Host "    GPU:        " -ForegroundColor Gray -NoNewline
        Write-Host "$($Info.GPUName)" -ForegroundColor White
        Write-Host "    ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""
    }
}

# ============================================================
# CONFIGURATION FUNCTIONS
# ============================================================

function Get-ToolkitConfig {
    <#
    .SYNOPSIS
        Loads a configuration file from the configs directory
    .PARAMETER ConfigName
        Name of the config file (without extension)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigName
    )

    $ConfigPath = "$Script:ConfigDir\$ConfigName.json"

    if (Test-Path $ConfigPath) {
        try {
            $Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $Config
        }
        catch {
            Write-Log "Failed to load config '$ConfigName': $($_.Exception.Message)" -Level ERROR
            return $null
        }
    }
    else {
        Write-Log "Config file not found: $ConfigPath" -Level WARNING
        return $null
    }
}

function Save-ToolkitConfig {
    <#
    .SYNOPSIS
        Saves a configuration to the configs directory
    .PARAMETER ConfigName
        Name of the config file (without extension)
    .PARAMETER Config
        The configuration object to save
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigName,

        [Parameter(Mandatory = $true)]
        $Config
    )

    $ConfigPath = "$Script:ConfigDir\$ConfigName.json"

    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Force
        Write-Log "Config saved: $ConfigName" -Level SUCCESS -NoConsole
        return $true
    }
    catch {
        Write-Log "Failed to save config '$ConfigName': $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

function Test-InternetConnection {
    <#
    .SYNOPSIS
        Tests if there is an active internet connection
    #>
    [CmdletBinding()]
    param()

    try {
        $Response = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
        return $Response
    }
    catch {
        return $false
    }
}

function Get-ConfirmationPrompt {
    <#
    .SYNOPSIS
        Gets a yes/no confirmation from the user
    .PARAMETER Message
        The message to display
    .PARAMETER DefaultYes
        Whether the default is Yes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [switch]$DefaultYes
    )

    $Options = if ($DefaultYes) { "(Y/n)" } else { "(y/N)" }
    Write-Host ""
    Write-Host "    $Message $Options`: " -ForegroundColor Yellow -NoNewline
    $Response = Read-Host

    if ([string]::IsNullOrWhiteSpace($Response)) {
        return $DefaultYes
    }

    return ($Response -eq 'Y' -or $Response -eq 'y')
}

function Wait-KeyPress {
    <#
    .SYNOPSIS
        Waits for any key press
    .PARAMETER Message
        Optional message to display
    #>
    [CmdletBinding()]
    param(
        [string]$Message = "Press any key to continue..."
    )

    Write-Host ""
    Write-Host "    $Message" -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-Countdown {
    <#
    .SYNOPSIS
        Shows a countdown timer
    .PARAMETER Seconds
        Number of seconds to count down
    .PARAMETER Message
        Message to display during countdown
    #>
    [CmdletBinding()]
    param(
        [int]$Seconds = 5,
        [string]$Message = "Continuing in"
    )

    for ($i = $Seconds; $i -gt 0; $i--) {
        Write-Host "`r    $Message $i seconds...    " -ForegroundColor Yellow -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host ""
}

# ============================================================
# RESTORE POINT FUNCTIONS
# ============================================================

function New-SystemRestorePoint {
    <#
    .SYNOPSIS
        Creates a system restore point
    .PARAMETER Description
        Description for the restore point
    #>
    [CmdletBinding()]
    param(
        [string]$Description = "Ultimate Windows Setup Toolkit"
    )

    try {
        Write-ColorOutput -Message "Creating system restore point..." -Type Info
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-ColorOutput -Message "Restore point created successfully" -Type Success
        return $true
    }
    catch {
        Write-Log "Failed to create restore point: $($_.Exception.Message)" -Level WARNING
        return $false
    }
}

# ============================================================
# DRY-RUN AND ROLLBACK FUNCTIONS
# ============================================================

function Set-DryRunMode {
    <#
    .SYNOPSIS
        Enables or disables dry-run mode
    .PARAMETER Enabled
        Whether to enable dry-run mode
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    $Script:DryRunMode = $Enabled
    if ($Enabled) {
        Write-Log "Dry-run mode ENABLED - No actual changes will be made" -Level WARNING
    } else {
        Write-Log "Dry-run mode disabled" -Level INFO
    }
}

function Test-DryRunMode {
    <#
    .SYNOPSIS
        Checks if dry-run mode is enabled
    .OUTPUTS
        Boolean indicating if dry-run mode is active
    #>
    [CmdletBinding()]
    param()

    return $Script:DryRunMode
}

function Start-OperationTracking {
    <#
    .SYNOPSIS
        Starts tracking operations for potential rollback
    .DESCRIPTION
        Clears the operation stack and enables tracking of changes
    #>
    [CmdletBinding()]
    param()

    $Script:OperationStack.Clear()
    $Script:OperationTrackingEnabled = $true
    Write-Log "Operation tracking started" -Level DEBUG -NoConsole
}

function Stop-OperationTracking {
    <#
    .SYNOPSIS
        Stops tracking operations
    #>
    [CmdletBinding()]
    param()

    $Script:OperationTrackingEnabled = $false
    Write-Log "Operation tracking stopped. $($Script:OperationStack.Count) operations recorded." -Level DEBUG -NoConsole
}

function Add-OperationToTrack {
    <#
    .SYNOPSIS
        Records an operation for potential rollback
    .PARAMETER OperationType
        Type of operation: Registry, Service, File, ScheduledTask, Feature
    .PARAMETER Target
        The target of the operation (path, service name, etc.)
    .PARAMETER OriginalValue
        The original value before the change
    .PARAMETER NewValue
        The new value after the change
    .PARAMETER RollbackCommand
        Optional scriptblock to execute for rollback
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Registry', 'Service', 'File', 'ScheduledTask', 'Feature', 'Other')]
        [string]$OperationType,

        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter()]
        $OriginalValue,

        [Parameter()]
        $NewValue,

        [Parameter()]
        [scriptblock]$RollbackCommand
    )

    if (-not $Script:OperationTrackingEnabled) {
        return
    }

    $Operation = [PSCustomObject]@{
        Timestamp       = Get-Date
        OperationType   = $OperationType
        Target          = $Target
        OriginalValue   = $OriginalValue
        NewValue        = $NewValue
        RollbackCommand = $RollbackCommand
    }

    [void]$Script:OperationStack.Add($Operation)
    Write-Log "Tracked operation: $OperationType on $Target" -Level DEBUG -NoConsole
}

function Get-TrackedOperations {
    <#
    .SYNOPSIS
        Returns the list of tracked operations
    .OUTPUTS
        Array of tracked operation objects
    #>
    [CmdletBinding()]
    param()

    return $Script:OperationStack.ToArray()
}

function Invoke-Rollback {
    <#
    .SYNOPSIS
        Rolls back all tracked operations in reverse order
    .PARAMETER Confirm
        Require confirmation before rollback
    .OUTPUTS
        Boolean indicating success
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )

    if ($Script:OperationStack.Count -eq 0) {
        Write-ColorOutput -Message "No operations to rollback" -Type Warning
        return $true
    }

    $OperationCount = $Script:OperationStack.Count
    Write-ColorOutput -Message "Rolling back $OperationCount operations..." -Type Warning

    if (-not $Force) {
        $Confirm = Get-ConfirmationPrompt -Message "Do you want to rollback $OperationCount operations?"
        if (-not $Confirm) {
            Write-ColorOutput -Message "Rollback cancelled" -Type Info
            return $false
        }
    }

    $SuccessCount = 0
    $FailCount = 0

    # Process in reverse order (LIFO)
    for ($i = $Script:OperationStack.Count - 1; $i -ge 0; $i--) {
        $Operation = $Script:OperationStack[$i]
        $Progress = [math]::Round((($OperationCount - $i) / $OperationCount) * 100)

        Write-Progress -Activity "Rolling back changes" -Status "Processing: $($Operation.Target)" -PercentComplete $Progress

        try {
            if ($Operation.RollbackCommand) {
                # Execute custom rollback command
                & $Operation.RollbackCommand
                $SuccessCount++
            }
            else {
                # Handle standard rollback based on operation type
                switch ($Operation.OperationType) {
                    'Registry' {
                        if ($null -eq $Operation.OriginalValue) {
                            # Value didn't exist before, remove it
                            Remove-ItemProperty -Path $Operation.Target -Name (Split-Path $Operation.Target -Leaf) -ErrorAction Stop
                        }
                        else {
                            # Restore original value
                            Set-ItemProperty -Path (Split-Path $Operation.Target -Parent) -Name (Split-Path $Operation.Target -Leaf) -Value $Operation.OriginalValue -ErrorAction Stop
                        }
                        $SuccessCount++
                    }
                    'Service' {
                        Set-Service -Name $Operation.Target -StartupType $Operation.OriginalValue -ErrorAction Stop
                        $SuccessCount++
                    }
                    'File' {
                        if ($Operation.OriginalValue -and (Test-Path $Operation.OriginalValue)) {
                            Copy-Item -Path $Operation.OriginalValue -Destination $Operation.Target -Force -ErrorAction Stop
                        }
                        $SuccessCount++
                    }
                    'ScheduledTask' {
                        if ($Operation.OriginalValue -eq 'Enabled') {
                            Enable-ScheduledTask -TaskName $Operation.Target -ErrorAction Stop
                        }
                        else {
                            Disable-ScheduledTask -TaskName $Operation.Target -ErrorAction Stop
                        }
                        $SuccessCount++
                    }
                    default {
                        Write-Log "Cannot auto-rollback operation type: $($Operation.OperationType)" -Level WARNING
                        $FailCount++
                    }
                }
            }

            Write-Log "Rolled back: $($Operation.OperationType) on $($Operation.Target)" -Level INFO -NoConsole
        }
        catch {
            Write-Log "Failed to rollback $($Operation.Target): $($_.Exception.Message)" -Level ERROR
            $FailCount++
        }
    }

    Write-Progress -Activity "Rolling back changes" -Completed

    # Clear the operation stack after rollback
    $Script:OperationStack.Clear()

    Write-ColorOutput -Message "Rollback complete: $SuccessCount succeeded, $FailCount failed" -Type $(if ($FailCount -eq 0) { 'Success' } else { 'Warning' })

    return ($FailCount -eq 0)
}

function Export-OperationLog {
    <#
    .SYNOPSIS
        Exports the operation log to a JSON file for later analysis or rollback
    .PARAMETER Path
        Path to save the operation log
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = "$Script:BackupDir\OperationLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )

    if ($Script:OperationStack.Count -eq 0) {
        Write-ColorOutput -Message "No operations to export" -Type Warning
        return $null
    }

    try {
        # Ensure backup directory exists
        $BackupParent = Split-Path $Path -Parent
        if (-not (Test-Path $BackupParent)) {
            New-Item -ItemType Directory -Path $BackupParent -Force | Out-Null
        }

        # Convert operation stack to exportable format (scriptblocks can't be serialized)
        $ExportData = @{
            ExportTime  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ToolkitVersion = $Script:ToolkitVersion
            OperationCount = $Script:OperationStack.Count
            Operations  = $Script:OperationStack | ForEach-Object {
                @{
                    Timestamp     = $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    OperationType = $_.OperationType
                    Target        = $_.Target
                    OriginalValue = $_.OriginalValue
                    NewValue      = $_.NewValue
                    HasCustomRollback = ($null -ne $_.RollbackCommand)
                }
            }
        }

        $ExportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $Path -Encoding UTF8

        Write-ColorOutput -Message "Operation log exported to: $Path" -Type Success
        Write-Log "Exported $($Script:OperationStack.Count) operations to $Path" -Level INFO -NoConsole

        return $Path
    }
    catch {
        Write-Log "Failed to export operation log: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Invoke-WithDryRunCheck {
    <#
    .SYNOPSIS
        Executes a scriptblock only if not in dry-run mode
    .DESCRIPTION
        Wrapper function that checks dry-run mode before executing operations.
        In dry-run mode, logs what would happen without making changes.
    .PARAMETER ScriptBlock
        The code to execute
    .PARAMETER Description
        Description of the operation for dry-run logging
    .PARAMETER OperationType
        Type of operation for tracking
    .PARAMETER Target
        Target of the operation for tracking
    .PARAMETER OriginalValue
        Original value for rollback tracking
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter()]
        [ValidateSet('Registry', 'Service', 'File', 'ScheduledTask', 'Feature', 'Other')]
        [string]$OperationType = 'Other',

        [Parameter()]
        [string]$Target = '',

        [Parameter()]
        $OriginalValue = $null
    )

    if ($Script:DryRunMode) {
        Write-ColorOutput -Message "[DRY-RUN] Would execute: $Description" -Type Info
        Write-Log "[DRY-RUN] $Description" -Level INFO -NoConsole
        return $true
    }

    try {
        $Result = & $ScriptBlock

        # Track the operation if tracking is enabled
        if ($Script:OperationTrackingEnabled -and $Target) {
            Add-OperationToTrack -OperationType $OperationType -Target $Target -OriginalValue $OriginalValue -NewValue $Result
        }

        return $Result
    }
    catch {
        Write-Log "Operation failed: $Description - $($_.Exception.Message)" -Level ERROR
        throw
    }
}

# ============================================================
# EXPORT MODULE MEMBERS
# ============================================================

Export-ModuleMember -Function @(
    # Initialization
    'Initialize-Toolkit',

    # Logging
    'Write-Log',
    'Write-ColorOutput',

    # UI/Menu
    'Show-Banner',
    'Show-MenuOption',
    'Show-MenuFooter',
    'Get-MenuChoice',
    'Show-Progress',
    'Show-TaskProgress',

    # Admin/Security
    'Test-Administrator',
    'Request-AdminPrivileges',

    # Registry/Service Operations
    'Set-RegistryValue',
    'Backup-RegistryKey',
    'Set-ServiceState',

    # System Info
    'Get-SystemInfo',
    'Show-SystemInfo',

    # Configuration
    'Get-ToolkitConfig',
    'Save-ToolkitConfig',

    # Utilities
    'Test-InternetConnection',
    'Get-ConfirmationPrompt',
    'Wait-KeyPress',
    'Start-Countdown',

    # Restore Point
    'New-SystemRestorePoint',

    # Dry-Run and Rollback
    'Set-DryRunMode',
    'Test-DryRunMode',
    'Start-OperationTracking',
    'Stop-OperationTracking',
    'Add-OperationToTrack',
    'Get-TrackedOperations',
    'Invoke-Rollback',
    'Export-OperationLog',
    'Invoke-WithDryRunCheck'
)

Export-ModuleMember -Variable @(
    'ToolkitVersion',
    'ToolkitName',
    'BaseDir',
    'LogDir',
    'BackupDir',
    'ConfigDir',
    'CurrentLogFile',
    'DryRunMode',
    'OperationTrackingEnabled'
)
