# System Optimization Guide

## Overview

The System Optimizer automatically detects your hardware and applies the optimal settings for your system.

## Optimization Profiles

### EXTREME_PERFORMANCE (64GB+ RAM, 8+ cores)

Best for: High-end gaming rigs, workstations, content creators

**Settings Applied:**
- Aggressive memory management (kernel kept in RAM)
- Large system cache enabled
- 16GB page file
- Hibernation disabled (saves 64GB+ disk space)
- Power throttling disabled
- Gaming optimizations enabled
- Superfetch/Prefetch disabled (NVMe optimization)

### HIGH_PERFORMANCE (32GB+ RAM, 6+ cores)

Best for: Gaming systems, developers, power users

**Settings Applied:**
- 8GB page file
- Power throttling disabled
- Gaming optimizations enabled
- Superfetch/Prefetch disabled for NVMe

### BALANCED (16GB+ RAM, 4+ cores)

Best for: General purpose computers

**Settings Applied:**
- 4GB page file
- Standard memory management
- Gaming mode enabled
- Standard visual effects

### PERFORMANCE_SAVER (<16GB RAM)

Best for: Older systems, budget computers

**Settings Applied:**
- 2GB page file
- Visual effects disabled
- Indexing disabled
- Maximum performance focus

## What Each Optimization Does

### Memory Management

| Setting | What it does |
|---------|-------------|
| DisablePagingExecutive | Keeps Windows kernel in RAM (faster) |
| LargeSystemCache | Allocates more RAM for file caching |
| ClearPageFileAtShutdown | Disabled for faster shutdowns |
| Prefetcher/Superfetch | Disabled for NVMe (not needed) |

### CPU Optimization

| Setting | What it does |
|---------|-------------|
| Win32PrioritySeparation | Prioritizes foreground applications |
| PowerThrottlingOff | Prevents CPU throttling |
| MMCSS Service | Better multimedia/gaming scheduling |
| Core Parking | Configures CPU core management |

### GPU Optimization

| Setting | What it does |
|---------|-------------|
| HwSchMode (HAGS) | Hardware Accelerated GPU Scheduling |
| TdrDelay | Prevents driver timeout during heavy loads |
| PowerMizer | Disables power saving on NVIDIA GPUs |
| Network Latency | Reduces latency for online gaming |

### Storage Optimization

| Setting | What it does |
|---------|-------------|
| TRIM | Maintains SSD/NVMe performance |
| Defragmentation | Disabled for SSDs (not needed) |
| Storage Sense | Disabled (manual control preferred) |

### Power Settings

| Setting | What it does |
|---------|-------------|
| Ultimate Performance | Maximum CPU/GPU performance |
| USB Selective Suspend | Disabled (prevents USB issues) |
| PCI Express Power | Disabled (maximum GPU power) |
| Fast Startup | Disabled (better hardware initialization) |

### Gaming Optimizations

| Setting | What it does |
|---------|-------------|
| Game Mode | Prioritizes gaming processes |
| Game DVR | Disabled (reduces overhead) |
| Fullscreen Optimization | Disabled (better frame timing) |
| GPU Priority | Set to High for games |
| Mouse Acceleration | Disabled (better aiming) |

### Network Optimization

| Setting | What it does |
|---------|-------------|
| TCP Window Scaling | Better throughput |
| Network Throttling | Disabled |
| Nagle's Algorithm | Disabled (lower latency) |

### Visual Effects

| Setting | What it does |
|---------|-------------|
| MenuShowDelay | Instant menu response |
| Transparency | Disabled (saves GPU resources) |
| Animations | Optimized for performance |

### Services Disabled

| Service | Reason |
|---------|--------|
| DiagTrack | Telemetry |
| dmwappushservice | Telemetry |
| WerSvc | Error reporting |
| SysMain | Not needed for NVMe |
| RetailDemo | Unnecessary |
| Fax | Unnecessary |

### Scheduled Tasks Disabled

- Microsoft Compatibility Appraiser
- Customer Experience Improvement Program
- Disk Diagnostic Data Collector
- Windows Error Reporting
- Maps Update Task

## Manual Optimization

You can run individual optimizations from the menu:

1. Memory Optimization - Just memory settings
2. CPU Optimization - CPU scheduling and power
3. GPU Optimization - Graphics settings
4. Storage Optimization - Disk-related settings
5. Power Settings - Power plan configuration
6. Gaming Optimizations - Game-specific tweaks
7. Network Optimization - Network latency
8. Visual Effects - UI performance
9. Services & Tasks - Background processes

## Reverting Changes

### Using System Restore

1. Press Win + R
2. Type `rstrui` and press Enter
3. Select a restore point created before optimization
4. Follow the wizard to restore

### Manual Registry Restore

Registry backups are saved to:
```
%ProgramData%\UltimateWindowsToolkit\Backups\
```

Double-click a .reg file to restore those settings.

### Re-enabling Services

```powershell
Set-Service -Name "ServiceName" -StartupType Automatic
Start-Service -Name "ServiceName"
```

## Recommended Post-Optimization Steps

1. **Restart your computer** (required for all changes to take effect)
2. **Run benchmarks** to verify improvements:
   - Cinebench R23 (CPU)
   - 3DMark Time Spy (GPU)
   - CrystalDiskMark (Storage)
3. **Monitor temperatures** during first use
4. **Test your applications** to ensure compatibility

## Performance Expectations

With proper optimization, you should see:

| System Type | Expected Improvement |
|-------------|---------------------|
| High-end (64GB+) | 5-15% faster, lower latency |
| Mid-range (32GB) | 10-20% faster |
| Budget (<16GB) | 15-30% faster |

Note: Actual results vary based on current system state and usage patterns.
