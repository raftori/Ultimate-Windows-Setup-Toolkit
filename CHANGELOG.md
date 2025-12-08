# Changelog

All notable changes to the Ultimate Windows Setup Toolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2025-01-01

### Added
- Unified toolkit consolidating all previous scripts
- Interactive main menu with professional ASCII art banners
- Application installer with 200+ apps across 14 categories
- System optimizer with 11 optimization modules
- Debloater with safe and aggressive modes
- Windows/Office activation via MAS integration
- Comprehensive logging system with timestamped entries
- System restore point creation before changes
- Registry backup before modifications
- **Dry-run mode** for testing changes without applying them
- **Rollback capability** for all tracked operations
- Operation tracking and export to JSON
- JSON-based configuration files for easy customization
- Service optimization profiles (Gaming, Workstation, Minimal, Privacy)
- Quick install bundles (Minimal, Standard, Developer, Gamer, Creative)
- Command-line parameters for automation
- Color-coded console output (SUCCESS, WARNING, ERROR, INFO)
- Progress indicators for long operations
- Confirmation prompts for destructive actions

### Changed
- Migrated from monolithic scripts to modular architecture
- Reorganized into modules/, menus/, configs/, docs/ structure
- Improved error handling with try-catch blocks throughout
- Enhanced progress indicators with percentage display
- Standardized color coding across all modules
- Updated all Winget IDs to latest versions
- Expanded application catalog from 100 to 200+ apps

### Fixed
- Various Winget ID corrections for newer packages
- Menu navigation returning to correct parent menu
- Logging timestamp format consistency
- Registry backup paths for special characters
- Service state detection for disabled services

### Security
- Registry changes backed up before modification
- Protected apps list prevents removal of essential Windows components
- Confirmation prompts for all destructive operations
- Dry-run mode allows safe testing

### Removed
- Acer-specific branding (now universal for all systems)
- Duplicate functions across scripts (consolidated into CommonFunctions.psm1)
- Hardcoded paths (now use environment variables)

---

## [3.0.0] - Previous Version

### Features from Original Scripts
- Basic app installation via GUI
- System optimization for high-end systems
- Windows debloating
- RAM optimization
- Driver updates via Windows Update

---

## Roadmap

### Planned for v4.1
- [ ] Scheduled optimization tasks
- [ ] More granular debloat options
- [ ] Dark/light theme toggle for console
- [ ] Export/import settings profiles
- [ ] Backup and restore Windows settings

### Planned for v4.2
- [ ] Network optimization profiles
- [ ] Custom app bundles (user-defined)
- [ ] Automatic backup scheduling
- [ ] Performance benchmarking integration
- [ ] GUI version using Windows Forms

### Planned for v5.0
- [ ] Cross-platform support (PowerShell Core)
- [ ] Plugin architecture for custom modules
- [ ] Remote execution support
- [ ] Enterprise deployment features

---

## Migration from Previous Versions

If upgrading from v3.x or earlier:

1. The new version uses a different directory structure
2. Previous settings are not automatically migrated
3. Logs and backups are now stored in `%ProgramData%\UltimateWindowsToolkit`
4. Old scripts can be safely removed after installing v4.0
5. Configuration files are now JSON-based (apps.json, services.json, settings.json)

### Breaking Changes
- Function names have changed (e.g., `Initialize-Toolkit` in CommonFunctions.psm1)
- Configuration format changed from inline scripts to JSON files
- Menu navigation structure updated

### New Configuration Files
| File | Purpose |
|------|---------|
| apps.json | Application catalog with Winget/Chocolatey IDs |
| services.json | Service profiles for optimization |
| settings.json | Toolkit configuration and defaults |
| debloat-apps.json | Bloatware definitions |

---

## Contributors

- **OffTrackMedia** - Creator and maintainer

## Acknowledgments

- [Chris Titus Tech](https://github.com/ChrisTitusTech/winutil) - Inspiration
- [Microsoft Activation Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts) - Activation integration
- [Sophia Script](https://github.com/farag2/Sophia-Script-for-Windows) - Optimization reference
