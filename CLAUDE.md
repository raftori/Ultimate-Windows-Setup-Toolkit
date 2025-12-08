# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ultimate Windows Setup Toolkit v4.0 - A PowerShell toolkit for Windows system setup, optimization, and maintenance. Requires PowerShell 5.1+ and Administrator privileges. Target platforms: Windows 10/11.

## Running the Toolkit

```powershell
# Interactive menu (default)
.\Start-Toolkit.ps1

# Direct action with options
.\Start-Toolkit.ps1 -Action Optimize -CreateRestorePoint
.\Start-Toolkit.ps1 -Action Debloat -DryRun
.\Start-Toolkit.ps1 -Action Apps -SkipConfirmation -Silent
```

**Parameters:** `-Action` (Menu|Scan|Optimize|Debloat|Apps|Drivers|Activate), `-DryRun`, `-SkipConfirmation`, `-CreateRestorePoint`, `-LogPath`, `-Silent`

## Architecture

### Module System
All functionality is in PowerShell modules (`modules/*.psm1`) that are imported by menu scripts:

- **CommonFunctions.psm1** - Core utilities: logging (`Write-Log`), UI (`Show-Banner`, `Get-MenuChoice`), registry operations (`Set-RegistryValue`, `Backup-RegistryKey`), dry-run/rollback tracking, system restore points
- **AppInstaller.psm1** - Application installation via Winget/Chocolatey/Scoop
- **SystemOptimizer.psm1** - Performance optimizations (memory, CPU, GPU, services)
- **Debloater.psm1** - Bloatware removal and privacy settings
- **Activator.psm1** - Windows/Office activation (MAS integration)
- **DriverUpdater.psm1** - Driver management

### Menu Flow
`Start-Toolkit.ps1` → `menus/MainMenu.ps1` → Feature-specific menus (`AppInstallerMenu.ps1`, `OptimizerMenu.ps1`, etc.)

### Configuration Files (JSON)
- **configs/apps.json** - Application catalog with WingetId, ChocoId, categories, Essential flag
- **configs/services.json** - Service profiles (gaming, workstation, minimal, privacy) with disable/manual/enable arrays
- **configs/settings.json** - Default optimization profiles based on system specs
- **configs/debloat-apps.json** - Bloatware package definitions

### Data Storage
Runtime data stored in `%ProgramData%\UltimateWindowsToolkit\`:
- `Logs/` - Timestamped log files
- `Backups/` - Registry backups before modifications

## Key Patterns

### Function Template
```powershell
function Verb-Noun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        # Use Write-Log for all operations
        Write-Log "Performing action on $Name" -Level INFO
        # Implementation
    }
    catch {
        Write-Log "Failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}
```

### Dry-Run Mode
Always wrap destructive operations:
```powershell
Invoke-WithDryRunCheck -ScriptBlock {
    # actual operation
} -Description "What this does" -OperationType Registry -Target $path
```

### Registry Operations
Always backup before modifying:
```powershell
Backup-RegistryKey -Path "HKLM:\SOFTWARE\..."
Set-RegistryValue -Path $path -Name $name -Value $value -Type DWord
```

### Logging
```powershell
Write-Log "Message" -Level INFO|SUCCESS|WARNING|ERROR|DEBUG
Write-ColorOutput -Message "Console message" -Type Info|Success|Warning|Error
```

### Adding Applications
Edit `configs/apps.json`:
```json
{ "Name": "App Name", "WingetId": "Publisher.App", "ChocoId": "package", "Description": "...", "Essential": false }
```
Verify IDs with `winget search "name"` or `choco search "name"`.

### Adding Service Profiles
Edit `configs/services.json` under `profiles`:
```json
"profile_name": {
    "name": "Display Name",
    "description": "...",
    "disable": ["Service1", "Service2"],
    "manual": ["Service3"],
    "enable": ["Service4"]
}
```

## Important Constraints

- All scripts require `#Requires -RunAsAdministrator` and `#Requires -Version 5.1`
- Use `Set-StrictMode -Version Latest` in main scripts
- Export public functions with `Export-ModuleMember -Function @(...)`
- JSON configs must have `Version` and `LastUpdated` fields
- Color coding: SUCCESS=Green, WARNING=Yellow, ERROR=Red, INFO=Cyan
