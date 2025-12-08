#Requires -Version 5.1
<#
.SYNOPSIS
    System Scanner Menu Interface
.DESCRIPTION
    Provides interactive menu for system scanning and hardware profiling
.NOTES
    Part of Ultimate Windows Setup Toolkit v4.0
#>

function Show-ScannerBanner {
    $banner = @"

    ╔══════════════════════════════════════════════════════════════════╗
    ║                     SYSTEM SCANNER                               ║
    ║               Hardware Profiler & Analyzer                       ║
    ╚══════════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
}

function Show-ScannerMenu {
    <#
    .SYNOPSIS
        Main system scanner menu
    #>

    while ($true) {
        Clear-Host
        Show-ScannerBanner

        # Show quick system summary if profile exists
        if ($Global:SystemProfile) {
            Write-Host "  Current Profile: " -NoNewline -ForegroundColor Gray
            Write-Host $Global:SystemProfile.PerformanceTier.Label -ForegroundColor Green
            Write-Host "  Last Scan: " -NoNewline -ForegroundColor Gray
            Write-Host $Global:SystemProfile.ScanTime -ForegroundColor White
            Write-Host ""
        }
        else {
            Write-Host "  No system scan performed yet." -ForegroundColor Yellow
            Write-Host ""
        }

        Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [1]  Full System Scan         [2]  Quick Hardware Check   ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [3]  CPU Details              [4]  RAM Details            ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [5]  Storage Analysis         [6]  GPU Information        ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [7]  Network Status           [8]  Power/Battery Status  ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [9]  Export Full Report       [10] View Recommendations   ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ║   [B]  Back to Main Menu                                     ║" -ForegroundColor DarkCyan
        Write-Host "  ║                                                              ║" -ForegroundColor DarkCyan
        Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host "  Select an option: " -NoNewline -ForegroundColor White

        $choice = Read-Host

        switch ($choice.ToUpper()) {
            "1" { Invoke-FullSystemScan }
            "2" { Invoke-QuickHardwareCheck }
            "3" { Show-CPUDetailsMenu }
            "4" { Show-RAMDetailsMenu }
            "5" { Show-StorageDetailsMenu }
            "6" { Show-GPUDetailsMenu }
            "7" { Show-NetworkDetailsMenu }
            "8" { Show-PowerDetailsMenu }
            "9" { Invoke-ExportReport }
            "10" { Show-RecommendationsMenu }
            "B" { return }
            default {
                Write-Host ""
                Write-Host "  Invalid option. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
}

function Invoke-FullSystemScan {
    <#
    .SYNOPSIS
        Performs a full system scan and updates global profile
    #>

    Clear-Host
    Show-ScannerBanner

    Write-Host "  FULL SYSTEM SCAN" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Scanning system hardware..." -ForegroundColor Yellow
    Write-Host ""

    # Show progress indicators
    $steps = @(
        @{ Name = "CPU"; Status = "Scanning processor..." },
        @{ Name = "RAM"; Status = "Analyzing memory..." },
        @{ Name = "Storage"; Status = "Checking storage devices..." },
        @{ Name = "GPU"; Status = "Detecting graphics..." },
        @{ Name = "System"; Status = "Gathering system info..." },
        @{ Name = "Network"; Status = "Scanning network adapters..." },
        @{ Name = "Power"; Status = "Checking power status..." },
        @{ Name = "Analysis"; Status = "Calculating performance tier..." }
    )

    foreach ($step in $steps) {
        Write-Host "    [$($step.Name)]" -NoNewline -ForegroundColor Cyan
        Write-Host " $($step.Status)" -ForegroundColor Gray
        Start-Sleep -Milliseconds 200
    }

    # Perform actual scan
    $Global:SystemProfile = Get-SystemProfile

    Write-Host ""
    Write-Host "  Scan complete!" -ForegroundColor Green
    Write-Host ""

    # Show summary
    Show-PerformanceTierSummary -Tier $Global:SystemProfile.PerformanceTier

    Write-Host "  Quick Summary:" -ForegroundColor White
    Write-Host "  " + ("-" * 40) -ForegroundColor DarkGray
    Write-Host "  CPU:     " -NoNewline -ForegroundColor Gray
    Write-Host "$($Global:SystemProfile.CPU.Name)" -ForegroundColor White
    Write-Host "  RAM:     " -NoNewline -ForegroundColor Gray
    Write-Host "$($Global:SystemProfile.RAM.TotalGB) GB" -ForegroundColor White
    Write-Host "  Storage: " -NoNewline -ForegroundColor Gray
    Write-Host "$(if ($Global:SystemProfile.Storage.HasNVMe) { 'NVMe SSD' } elseif ($Global:SystemProfile.Storage.HasSSD) { 'SSD' } else { 'HDD' })" -ForegroundColor White
    Write-Host "  GPU:     " -NoNewline -ForegroundColor Gray
    Write-Host "$($Global:SystemProfile.GPU.PrimaryGPU)" -ForegroundColor White
    Write-Host "  Type:    " -NoNewline -ForegroundColor Gray
    Write-Host "$(if ($Global:SystemProfile.System.IsLaptop) { 'Laptop' } elseif ($Global:SystemProfile.System.IsDesktop) { 'Desktop' } else { 'Unknown' })" -ForegroundColor White
    Write-Host ""

    if ($Global:SystemProfile.Recommendations.Count -gt 0) {
        Write-Host "  $($Global:SystemProfile.Recommendations.Count) recommendation(s) available. Use option [10] to view." -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-QuickHardwareCheck {
    <#
    .SYNOPSIS
        Performs a quick hardware check without full analysis
    #>

    Clear-Host
    Show-ScannerBanner

    Write-Host "  QUICK HARDWARE CHECK" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    $quick = Get-QuickHardwareCheck

    if ($quick) {
        Write-Host "  CPU:      " -NoNewline -ForegroundColor Gray
        Write-Host $quick.CPU -ForegroundColor White
        Write-Host "  Cores:    " -NoNewline -ForegroundColor Gray
        Write-Host "$($quick.Cores) cores / $($quick.Threads) threads" -ForegroundColor Green
        Write-Host "  RAM:      " -NoNewline -ForegroundColor Gray
        Write-Host "$($quick.RAMGB) GB" -ForegroundColor Green
        Write-Host "  GPU:      " -NoNewline -ForegroundColor Gray
        Write-Host $quick.GPU -ForegroundColor White
        Write-Host "  OS:       " -NoNewline -ForegroundColor Gray
        Write-Host "$($quick.OS) (Build $($quick.OSBuild))" -ForegroundColor White
    }
    else {
        Write-Host "  Unable to retrieve hardware information." -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-CPUDetailsMenu {
    <#
    .SYNOPSIS
        Shows CPU details from scan
    #>

    Clear-Host
    Show-ScannerBanner

    if (-not $Global:SystemProfile) {
        Write-Host "  No system scan available. Running scan first..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 1
        $Global:SystemProfile = Get-SystemProfile
    }

    Show-CPUDetails -CPUProfile $Global:SystemProfile.CPU

    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-RAMDetailsMenu {
    <#
    .SYNOPSIS
        Shows RAM details from scan
    #>

    Clear-Host
    Show-ScannerBanner

    if (-not $Global:SystemProfile) {
        Write-Host "  No system scan available. Running scan first..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 1
        $Global:SystemProfile = Get-SystemProfile
    }

    Show-RAMDetails -RAMProfile $Global:SystemProfile.RAM

    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-StorageDetailsMenu {
    <#
    .SYNOPSIS
        Shows storage details from scan
    #>

    Clear-Host
    Show-ScannerBanner

    if (-not $Global:SystemProfile) {
        Write-Host "  No system scan available. Running scan first..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 1
        $Global:SystemProfile = Get-SystemProfile
    }

    Show-StorageDetails -StorageProfile $Global:SystemProfile.Storage

    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-GPUDetailsMenu {
    <#
    .SYNOPSIS
        Shows GPU details from scan
    #>

    Clear-Host
    Show-ScannerBanner

    if (-not $Global:SystemProfile) {
        Write-Host "  No system scan available. Running scan first..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 1
        $Global:SystemProfile = Get-SystemProfile
    }

    Show-GPUDetails -GPUProfile $Global:SystemProfile.GPU

    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-NetworkDetailsMenu {
    <#
    .SYNOPSIS
        Shows network details from scan
    #>

    Clear-Host
    Show-ScannerBanner

    if (-not $Global:SystemProfile) {
        Write-Host "  No system scan available. Running scan first..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 1
        $Global:SystemProfile = Get-SystemProfile
    }

    Show-NetworkDetails -NetworkProfile $Global:SystemProfile.Network

    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-PowerDetailsMenu {
    <#
    .SYNOPSIS
        Shows power/battery details from scan
    #>

    Clear-Host
    Show-ScannerBanner

    if (-not $Global:SystemProfile) {
        Write-Host "  No system scan available. Running scan first..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 1
        $Global:SystemProfile = Get-SystemProfile
    }

    Show-PowerDetails -PowerProfile $Global:SystemProfile.Power

    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-RecommendationsMenu {
    <#
    .SYNOPSIS
        Shows system recommendations from scan
    #>

    Clear-Host
    Show-ScannerBanner

    if (-not $Global:SystemProfile) {
        Write-Host "  No system scan available. Running scan first..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 1
        $Global:SystemProfile = Get-SystemProfile
    }

    Show-Recommendations -Recommendations $Global:SystemProfile.Recommendations

    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-ExportReport {
    <#
    .SYNOPSIS
        Exports system profile to files
    #>

    Clear-Host
    Show-ScannerBanner

    Write-Host "  EXPORT SYSTEM REPORT" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkGray
    Write-Host ""

    if (-not $Global:SystemProfile) {
        Write-Host "  No system scan available. Running scan first..." -ForegroundColor Yellow
        Write-Host ""
        $Global:SystemProfile = Get-SystemProfile
    }

    Write-Host "  Exporting system report..." -ForegroundColor Yellow
    Write-Host ""

    $result = Export-SystemReport -Profile $Global:SystemProfile

    if ($result) {
        Write-Host "  Report exported successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Files created:" -ForegroundColor White
        Write-Host "    JSON: " -NoNewline -ForegroundColor Gray
        Write-Host $result.JsonPath -ForegroundColor Cyan
        Write-Host "    Text: " -NoNewline -ForegroundColor Gray
        Write-Host $result.TextPath -ForegroundColor Cyan
        Write-Host ""

        Write-Host "  Would you like to open the text report? (Y/N): " -NoNewline -ForegroundColor Yellow
        $open = Read-Host

        if ($open -eq "Y" -or $open -eq "y") {
            try {
                Start-Process notepad.exe -ArgumentList $result.TextPath
            }
            catch {
                Write-Host "  Could not open file automatically." -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "  Failed to export report." -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Export function
Export-ModuleMember -Function Show-ScannerMenu -ErrorAction SilentlyContinue
