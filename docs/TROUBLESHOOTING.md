# Troubleshooting Guide

## Common Issues and Solutions

### Installation Issues

#### "Script cannot be run because running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### "Access Denied" when running script

**Solution:**
1. Right-click PowerShell
2. Select "Run as Administrator"
3. Navigate to script and run again

#### Module loading errors

**Solution:**
Verify all module files exist in the `modules` folder:
- CommonFunctions.psm1
- AppInstaller.psm1
- SystemOptimizer.psm1
- Debloater.psm1
- Activator.psm1
- DriverUpdater.psm1

### Application Installer Issues

#### Winget installation fails

**Possible causes:**
- No internet connection
- Windows Update service disabled
- Outdated Windows version

**Solutions:**
1. Check internet connection
2. Enable Windows Update service:
   ```powershell
   Set-Service wuauserv -StartupType Manual
   Start-Service wuauserv
   ```
3. Update Windows to latest version

#### Chocolatey installation fails

**Solution:**
Run manually:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### App installation shows "already installed" but app isn't there

**Solution:**
1. Open Settings > Apps > Apps & Features
2. Search for the app
3. If found, uninstall it
4. Try installing again

### System Optimizer Issues

#### Changes not taking effect after optimization

**Solution:**
Restart your computer. Most changes require a restart.

#### System becomes unstable after optimization

**Solution:**
1. Boot into Safe Mode (hold Shift while clicking Restart)
2. Restore from System Restore point
3. Or restore registry backups from:
   ```
   %ProgramData%\UltimateWindowsToolkit\Backups\
   ```

#### Ultimate Performance power plan not appearing

**Solution:**
Enable it manually:
```powershell
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
```

### Debloater Issues

#### Some apps won't uninstall

**Possible causes:**
- App is protected by Windows
- App is currently in use
- Insufficient permissions

**Solution:**
1. Close any instances of the app
2. Try again after restart
3. Some system apps cannot be removed (this is by design)

#### Apps reinstall after Windows Update

**Solution:**
The toolkit removes provisioned packages which prevents most reinstalls. If apps return:
1. Run debloater again after updates
2. Disable automatic app installation:
   ```
   Settings > Privacy > General > Disable suggested content
   ```

### Activation Issues

#### Windows shows "not activated" after HWID

**Solutions:**
1. Ensure internet connection during activation
2. Run activation again from the menu
3. Try KMS38 method instead
4. Use activation troubleshooter (option 6)

#### Office activation fails

**Solutions:**
1. Ensure Office is properly installed
2. Use the Ohook method from MAS menu
3. Restart Office applications after activation

### Driver Issues

#### No driver updates found

**Possible causes:**
- All drivers are up to date
- Windows Update service issue

**Solutions:**
1. Check manually in Device Manager
2. Use manufacturer's driver update utility
3. Visit GPU manufacturer website for latest drivers

#### Driver backup fails

**Solution:**
Ensure sufficient disk space (backups can be large):
```powershell
# Check available space
Get-Volume C | Select-Object DriveLetter, SizeRemaining
```

### General Issues

#### Menu not displaying correctly

**Possible causes:**
- Console font doesn't support box characters
- PowerShell version too old

**Solutions:**
1. Use Windows Terminal instead of PowerShell
2. Change console font to "Consolas" or "Cascadia Mono"

#### Slow performance after changes

**Solutions:**
1. Restart your computer
2. Check for background processes
3. Review what changes were made in logs
4. Restore to previous state using System Restore

#### Log files not being created

**Solution:**
Ensure the toolkit has write access:
```powershell
$LogDir = "$env:ProgramData\UltimateWindowsToolkit\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force
}
```

### Recovery Options

#### Using System Restore

1. Press Win + R
2. Type `rstrui` and press Enter
3. Select restore point dated before toolkit use
4. Complete the restoration

#### Manual Registry Restore

1. Navigate to: `%ProgramData%\UltimateWindowsToolkit\Backups\`
2. Find the .reg file for the setting you want to restore
3. Double-click to import

#### Reset Windows Settings

For specific categories:
- **Power**: `powercfg /restoredefaultschemes`
- **Network**: `netsh int ip reset` and `netsh winsock reset`
- **Services**: Restore to defaults using services.msc

### Getting Help

If issues persist:

1. **Check Logs**: Review log files in `%ProgramData%\UltimateWindowsToolkit\Logs\`
2. **Search Issues**: Check GitHub issues for similar problems
3. **Create Issue**: Open a new GitHub issue with:
   - Windows version
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Error message/screenshot
   - Steps to reproduce
