<p align="center">
  <img src="docs/assets/banner.png" alt="Ultimate Windows Setup Toolkit" width="800">
</p>

<h1 align="center">Ultimate Windows Setup Toolkit</h1>

<p align="center">
  <strong>The all-in-one PowerShell toolkit for Windows setup, optimization, and maintenance</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="#"><img src="https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg" alt="PowerShell 5.1+"></a>
  <a href="#"><img src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6.svg" alt="Windows 10 | 11"></a>
  <a href="https://github.com/Nerds489/Ultimate-Windows-Setup-Toolkit/stargazers"><img src="https://img.shields.io/github/stars/Nerds489/Ultimate-Windows-Setup-Toolkit?style=social" alt="Stars"></a>
  <a href="https://github.com/Nerds489/Ultimate-Windows-Setup-Toolkit/network/members"><img src="https://img.shields.io/github/forks/Nerds489/Ultimate-Windows-Setup-Toolkit?style=social" alt="Forks"></a>
</p>

<p align="center">
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-features">Features</a> •
  <a href="#-applications">Applications</a> •
  <a href="#-optimization">Optimization</a> •
  <a href="#-documentation">Documentation</a> •
  <a href="#-contributing">Contributing</a>
</p>

---

## Quick Start

### One-Line Install (Run as Administrator)

```powershell
irm https://raw.githubusercontent.com/Nerds489/Ultimate-Windows-Setup-Toolkit/main/Start-Toolkit.ps1 | iex
```

### Safer Version (Recommended)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Nerds489/Ultimate-Windows-Setup-Toolkit/main/Start-Toolkit.ps1'))
```

### Manual Installation

```powershell
# Clone the repository
git clone https://github.com/Nerds489/Ultimate-Windows-Setup-Toolkit.git

# Navigate to the directory
cd Ultimate-Windows-Setup-Toolkit

# Run the toolkit (as Administrator)
.\Start-Toolkit.ps1
```

---

## Features

| Feature | Description |
|---------|-------------|
| **Application Installer** | Install 200+ popular applications via Winget or Chocolatey |
| **System Optimizer** | 11 optimization modules for maximum performance |
| **Windows Debloater** | Remove bloatware safely with rollback capability |
| **Windows/Office Activation** | Integrated MAS (Microsoft Activation Scripts) |
| **Driver Updates** | Update drivers via Windows Update or manufacturer tools |
| **System Scanner** | Analyze system configuration and get recommendations |

### Safety Features

- **System Restore Points** - Automatic creation before changes
- **Registry Backups** - Full backup before modifications
- **Dry-Run Mode** - Test changes without applying them
- **Rollback Capability** - Undo changes if something goes wrong
- **Confirmation Prompts** - Ask before destructive operations

---

## Main Menu

```
╔══════════════════════════════════════════════════════════════════╗
║           ULTIMATE WINDOWS SETUP TOOLKIT v4.0                    ║
║                    By OffTrackMedia                              ║
╚══════════════════════════════════════════════════════════════════╝

    [1] Application Installer    - Install popular software
    [2] System Optimizer         - Optimize Windows performance
    [3] Debloat & Activate       - Remove bloatware & activate
    [4] Driver Updater           - Update system drivers
    [5] System Scanner           - Analyze system configuration

    [Q] Quit

    Select an option:
```

---

## Applications

Install 200+ applications across 14 categories:

| Category | Apps | Highlights |
|----------|------|------------|
| **Browsers** | 8 | Chrome, Firefox, Brave, Edge, Opera GX, Arc |
| **Communication** | 8 | Discord, Slack, Teams, Zoom, Telegram, Signal |
| **Gaming** | 10 | Steam, Epic, GOG, EA, Battle.net, MSI Afterburner |
| **Media & Creative** | 18 | VLC, Spotify, OBS, GIMP, Blender, DaVinci Resolve |
| **Development Tools** | 38 | VS Code, Git, Node.js, Python, Docker, JetBrains |
| **Utilities** | 27 | 7-Zip, Everything, PowerToys, ShareX, HWiNFO |
| **Security & VPN** | 16 | Bitwarden, NordVPN, ProtonVPN, Malwarebytes |
| **File Management** | 7 | Total Commander, Double Commander, dupeGuru |
| **Cloud & Sync** | 9 | OneDrive, Google Drive, Dropbox, Nextcloud |
| **System Tools** | 14 | CCleaner, O&O ShutUp10, Winaero Tweaker |
| **Productivity** | 7 | Notion, Obsidian, LibreOffice, Thunderbird |
| **AI Tools** | 2 | Claude Desktop, ChatGPT Desktop |
| **Remote Access** | 4 | TeamViewer, AnyDesk, RustDesk, Parsec |
| **Virtualization** | 2 | VirtualBox, VMware Workstation Player |

### Quick Install Bundles

| Bundle | Applications |
|--------|--------------|
| **Minimal** | Chrome, 7-Zip, Notepad++, VLC |
| **Standard** | Chrome, Firefox, 7-Zip, Notepad++, VLC, ShareX, Everything, PowerToys, Terminal |
| **Developer** | VS Code, Git, GitHub Desktop, Node.js, Python, Terminal, PowerToys, Docker |
| **Gamer** | Steam, Discord, Epic Games, MSI Afterburner, GeForce Experience |
| **Creative** | GIMP, Inkscape, Blender, OBS, Audacity, HandBrake, VLC, FFmpeg |

[View Full Application List](docs/APP_LIST.md)

---

## Optimization

### Optimization Modules

| Module | Description | Risk Level |
|--------|-------------|------------|
| **Power Settings** | High performance power plan, USB selective suspend | Low |
| **Visual Effects** | Disable animations, transparency, shadows | Low |
| **Gaming Mode** | Game Mode, Hardware GPU Scheduling, fullscreen optimizations | Low |
| **Privacy Settings** | Disable telemetry, advertising ID, activity history | Low |
| **Startup Programs** | Manage auto-start applications | Low |
| **Services** | Disable unnecessary Windows services | Medium |
| **Scheduled Tasks** | Disable telemetry and update tasks | Medium |
| **Network Optimization** | Nagle's algorithm, network throttling | Medium |
| **SSD Optimization** | TRIM, prefetch, last access timestamps | Medium |
| **Memory Management** | Pagefile settings, memory compression | Medium |
| **Windows Features** | Remove optional features and capabilities | High |

### Service Profiles

| Profile | Description | Services Disabled |
|---------|-------------|-------------------|
| **Gaming** | Maximum performance for gaming | 9 services |
| **Workstation** | Balanced for productivity | 5 services |
| **Minimal** | Aggressive for low-spec systems | 16 services |
| **Privacy** | Maximum privacy protection | 13 services |

[View Optimization Guide](docs/OPTIMIZATION_GUIDE.md)

---

## Debloater

### Safe Mode (Recommended)
Removes commonly unwanted apps while preserving essential functionality:
- Xbox apps, Cortana, OneDrive
- Get Help, Tips, Feedback Hub
- Solitaire, Mixed Reality, 3D apps
- Weather, News, Maps

### Aggressive Mode
Additional removals for advanced users:
- Microsoft Edge (optional)
- Windows Security (not recommended)
- Store apps

### Privacy Tweaks
- Disable telemetry services
- Block telemetry endpoints
- Disable advertising ID
- Remove activity history

---

## Command-Line Options

```powershell
.\Start-Toolkit.ps1 [-Action <string>] [-SkipConfirmation] [-DryRun] [-Verbose] [-LogPath <string>] [-CreateRestorePoint] [-Silent]
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-Action` | Menu, Scan, Optimize, Debloat, Apps, Drivers, Activate | Menu |
| `-SkipConfirmation` | Skip confirmation prompts | False |
| `-DryRun` | Test mode - no changes made | False |
| `-Verbose` | Enable verbose logging | False |
| `-LogPath` | Custom log directory | .\logs |
| `-CreateRestorePoint` | Create restore point on start | False |
| `-Silent` | Suppress all console output | False |

### Examples

```powershell
# Run in dry-run mode to test
.\Start-Toolkit.ps1 -DryRun

# Create restore point and run optimizer
.\Start-Toolkit.ps1 -Action Optimize -CreateRestorePoint

# Silent installation with no prompts
.\Start-Toolkit.ps1 -Action Apps -SkipConfirmation -Silent
```

---

## Directory Structure

```
Ultimate-Windows-Setup-Toolkit/
├── Start-Toolkit.ps1           # Main launcher
├── README.md                   # This file
├── LICENSE                     # MIT License
├── CHANGELOG.md               # Version history
├── .gitignore                 # Git ignore file
│
├── modules/
│   ├── CommonFunctions.psm1   # Shared utility functions
│   ├── AppInstaller.psm1      # App installation module
│   ├── SystemOptimizer.psm1   # Optimization module
│   ├── Debloater.psm1         # Debloat module
│   ├── Activator.psm1         # Activation module
│   └── DriverUpdater.psm1     # Driver module
│
├── menus/
│   ├── MainMenu.ps1           # Main menu
│   ├── AppInstallerMenu.ps1   # App installer menu
│   ├── OptimizerMenu.ps1      # Optimizer menu
│   └── DebloatActivateMenu.ps1 # Debloat menu
│
├── configs/
│   ├── apps.json              # Application catalog
│   ├── debloat-apps.json      # Bloatware list
│   ├── services.json          # Services configuration
│   └── settings.json          # Toolkit settings
│
├── docs/
│   ├── INSTALLATION.md        # Installation guide
│   ├── APP_LIST.md            # Application list
│   ├── OPTIMIZATION_GUIDE.md  # Optimization details
│   ├── TROUBLESHOOTING.md     # Common issues
│   └── CONTRIBUTING.md        # Contribution guide
│
├── logs/                      # Log files (auto-created)
└── backups/                   # Backup files (auto-created)
```

---

## Requirements

- **Operating System:** Windows 10 (1809+) or Windows 11
- **PowerShell:** 5.1 or later (7+ recommended)
- **Privileges:** Administrator rights required
- **Package Manager:** Winget (recommended) or Chocolatey

### Checking Requirements

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check if Winget is installed
winget --version

# Check if running as Administrator
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](docs/INSTALLATION.md) | Detailed installation instructions |
| [Application List](docs/APP_LIST.md) | Complete catalog of 200+ applications |
| [Optimization Guide](docs/OPTIMIZATION_GUIDE.md) | What each optimization does |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [Contributing](docs/CONTRIBUTING.md) | How to contribute to the project |
| [Changelog](CHANGELOG.md) | Version history and release notes |

---

## Screenshots

<details>
<summary>Click to view screenshots</summary>

### Main Menu
![Main Menu](docs/assets/main-menu.png)

### Application Installer
![Application Installer](docs/assets/app-installer.png)

### System Optimizer
![System Optimizer](docs/assets/optimizer.png)

### Debloater
![Debloater](docs/assets/debloater.png)

</details>

---

## FAQ

<details>
<summary><strong>Is this safe to use?</strong></summary>

Yes! The toolkit includes multiple safety features:
- Automatic system restore points before changes
- Registry backups before modifications
- Dry-run mode to preview changes
- Rollback capability for all operations
- Confirmation prompts for destructive actions

</details>

<details>
<summary><strong>Will this void my warranty?</strong></summary>

No. The toolkit only makes software-level changes that can be reversed. No hardware modifications are made.

</details>

<details>
<summary><strong>Can I customize which apps are installed?</strong></summary>

Yes! The Application Installer provides:
- Individual app selection
- Category-based installation
- Pre-defined bundles (Minimal, Standard, Developer, Gamer, Creative)
- Custom app addition via Winget IDs

</details>

<details>
<summary><strong>How do I undo changes?</strong></summary>

Several options are available:
1. Use Windows System Restore to revert to a previous point
2. The toolkit creates automatic backups before registry changes
3. Use the rollback feature for recent changes
4. Re-run specific modules to restore default settings

</details>

<details>
<summary><strong>Does this work on Windows Server?</strong></summary>

The toolkit is designed for Windows 10/11 desktop editions. Some features may work on Windows Server, but it's not officially supported.

</details>

---

## Contributing

Contributions are welcome! Please read our [Contributing Guide](docs/CONTRIBUTING.md) for details on:

- Code of Conduct
- Development setup
- Submitting pull requests
- Reporting bugs
- Suggesting features

### Quick Contribution Steps

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Acknowledgments

- [Chris Titus Tech](https://github.com/ChrisTitusTech/winutil) - Inspiration and reference
- [Microsoft Activation Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts) - Activation integration
- [O&O ShutUp10](https://www.oo-software.com/en/shutup10) - Privacy reference
- [Sophia Script](https://github.com/farag2/Sophia-Script-for-Windows) - Optimization reference

---

## Disclaimer

This toolkit modifies Windows settings and removes applications. While safety measures are in place, use at your own risk. Always:
- Create a backup before running
- Review changes before applying
- Test in a virtual machine first if unsure

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Support

- **Issues:** [GitHub Issues](https://github.com/Nerds489/Ultimate-Windows-Setup-Toolkit/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Nerds489/Ultimate-Windows-Setup-Toolkit/discussions)

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/Nerds489">OffTrackMedia</a>
</p>

<p align="center">
  <a href="#ultimate-windows-setup-toolkit">Back to Top</a>
</p>
