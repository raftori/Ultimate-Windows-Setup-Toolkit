# Installation Guide

## Prerequisites

- Windows 10 (version 1809+) or Windows 11
- PowerShell 5.1 or higher (built into Windows)
- Administrator privileges
- Internet connection (for downloading apps and package managers)

## Quick Installation

### Option 1: One-Line Install (Recommended)

Open PowerShell as Administrator and run:

```powershell
irm https://raw.githubusercontent.com/Nerds489/Ultimate-Windows-Setup-Toolkit/main/Start-Toolkit.ps1 | iex
```

### Option 2: Safer One-Line Install

For more security-conscious users:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Nerds489/Ultimate-Windows-Setup-Toolkit/main/Start-Toolkit.ps1'))
```

### Option 3: Download and Run

1. Download the latest release from [GitHub Releases](https://github.com/Nerds489/Ultimate-Windows-Setup-Toolkit/releases)
2. Extract to a folder (e.g., `C:\Tools\Ultimate-Windows-Setup-Toolkit`)
3. Open PowerShell as Administrator
4. Navigate to the folder and run:

```powershell
.\Start-Toolkit.ps1
```

### Option 4: Git Clone

```powershell
git clone https://github.com/Nerds489/Ultimate-Windows-Setup-Toolkit.git
cd Ultimate-Windows-Setup-Toolkit
.\Start-Toolkit.ps1
```

## First Run Setup

### 1. Execution Policy

If you see an error about script execution, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Package Managers

On first run, go to **Application Installer** and select **Install Package Managers** to install:
- **Winget** (Windows Package Manager) - Recommended
- **Chocolatey** - Alternative package manager
- **Scoop** - User-level package manager

### 3. Create Restore Point

It's highly recommended to create a system restore point before making major changes:
1. Go to **Settings > Create System Restore Point**
2. Or run with the `-CreateRestorePoint` flag:
   ```powershell
   .\Start-Toolkit.ps1 -CreateRestorePoint
   ```

## Verifying Installation

After installation, verify everything is working:

1. Run the toolkit and check that all menu options are accessible
2. Go to **Settings** and verify your system information is displayed correctly
3. Check that the optimization profile matches your hardware
4. Test the dry-run mode:
   ```powershell
   .\Start-Toolkit.ps1 -DryRun
   ```

## Command-Line Options

```powershell
.\Start-Toolkit.ps1 [options]
```

| Option | Description |
|--------|-------------|
| `-Action <string>` | Direct action: Menu, Scan, Optimize, Debloat, Apps, Drivers, Activate |
| `-SkipConfirmation` | Skip all confirmation prompts |
| `-DryRun` | Test mode - shows what would be done without making changes |
| `-Verbose` | Enable verbose logging |
| `-LogPath <string>` | Custom log directory (default: .\logs) |
| `-CreateRestorePoint` | Create a restore point before starting |
| `-Silent` | Suppress all console output |

### Examples

```powershell
# Run in interactive mode (default)
.\Start-Toolkit.ps1

# Run optimizer directly with restore point
.\Start-Toolkit.ps1 -Action Optimize -CreateRestorePoint

# Test what debloater would do without making changes
.\Start-Toolkit.ps1 -Action Debloat -DryRun

# Silent app installation without prompts
.\Start-Toolkit.ps1 -Action Apps -SkipConfirmation -Silent
```

## Updating

To update to the latest version:

### Using Git

```powershell
cd Ultimate-Windows-Setup-Toolkit
git pull origin main
```

### Manual Update

1. Download the new version from GitHub
2. Replace the existing files (or extract to a new folder)
3. Your logs and backups in `%ProgramData%\UltimateWindowsToolkit` will be preserved

## Uninstalling

To remove the toolkit:

1. Delete the toolkit folder

2. Optionally, remove the data folder:
   ```powershell
   Remove-Item -Path "$env:ProgramData\UltimateWindowsToolkit" -Recurse -Force
   ```

3. If you want to restore Windows to before any changes:
   - Use System Restore to revert to a point before using the toolkit
   - Or restore individual registry backups from the Backups folder

## Troubleshooting Installation

### "Cannot be loaded because running scripts is disabled"

Run this command and try again:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Access Denied" errors

Make sure you're running PowerShell as Administrator:
1. Right-click on PowerShell
2. Select "Run as Administrator"
3. Navigate to the toolkit folder and try again

### Missing modules

Ensure all files were extracted correctly. The `modules` folder should contain:
- CommonFunctions.psm1
- AppInstaller.psm1
- SystemOptimizer.psm1
- Debloater.psm1
- Activator.psm1
- DriverUpdater.psm1

### Windows Defender blocking the script

The toolkit is safe, but Windows Defender may flag it due to registry modifications. You can:
1. Allow the script when prompted by Defender
2. Add an exclusion for the toolkit folder:
   ```powershell
   Add-MpPreference -ExclusionPath "C:\Path\To\Ultimate-Windows-Setup-Toolkit"
   ```
3. Review the code on GitHub before running

### PowerShell version too old

Check your PowerShell version:
```powershell
$PSVersionTable.PSVersion
```

If below 5.1, update Windows or install PowerShell 7:
```powershell
winget install Microsoft.PowerShell
```

### Network errors during download

If the one-liner fails:
1. Check your internet connection
2. Try the manual download option
3. If behind a proxy, configure PowerShell:
   ```powershell
   [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
   ```

## Directory Structure After Installation

```
Ultimate-Windows-Setup-Toolkit/
├── Start-Toolkit.ps1           # Main launcher
├── README.md
├── LICENSE
├── CHANGELOG.md
├── .gitignore
│
├── modules/                    # PowerShell modules
├── menus/                      # Menu scripts
├── configs/                    # JSON configuration files
├── docs/                       # Documentation
│
└── %ProgramData%\UltimateWindowsToolkit/
    ├── Logs/                   # Log files (auto-created)
    └── Backups/                # Registry backups (auto-created)
```

## Getting Help

If you encounter issues:

1. **Check Logs**: Review log files in `%ProgramData%\UltimateWindowsToolkit\Logs\`
2. **Read Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. **Search Issues**: Check [GitHub Issues](https://github.com/Nerds489/Ultimate-Windows-Setup-Toolkit/issues)
4. **Open Issue**: Create a new issue with:
   - Windows version (`winver`)
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Error message/screenshot
   - Steps to reproduce
