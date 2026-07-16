# launch_vivado_tests.ps1
# Opens one Vivado GUI window per test. Each window runs its simulation and
# stays open so you can inspect waveforms independently.
#
# Usage:
#   .\launch_vivado_tests.ps1                  # launches all 7 tests
#   .\launch_vivado_tests.ps1 direct_rw        # launches a single named test
#   .\launch_vivado_tests.ps1 direct_rw multi_slave  # launches a subset

$VivadoBat = "C:\Xilinx\Vivado\2024.1\bin\vivado.bat"
$XprFile   = "C:\Users\sankaran\Documents\lclPrj\AXI_5\AXI_5\axi_5.xpr"
$TclScript = "C:\Users\sankaran\Documents\lclPrj\AXI_5\AXI_5\vivado_run_test.tcl"

$AllTests = @(
    "direct_rw",
    "multi_slave",
    "back_to_back",
    "sequence_rw",
    "concurrent_masters",
    "nsaid_remap",
    "uvm_smoke"
)

# Decide which tests to run
if ($args.Count -gt 0) {
    $testsToRun = $args
} else {
    $testsToRun = $AllTests
}

Write-Host "Launching $($testsToRun.Count) Vivado window(s)..." -ForegroundColor Cyan

foreach ($test in $testsToRun) {
    if ($test -notin $AllTests) {
        Write-Warning "Unknown test name '$test'. Skipping. Valid: $($AllTests -join ', ')"
        continue
    }

    Write-Host "  Opening: $test" -ForegroundColor Yellow

    # Each Vivado process gets its own journal/log in a temp subdir to avoid conflicts
    $logDir = "$env:TEMP\vivado_$test"
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null

    Start-Process -FilePath $VivadoBat `
                  -ArgumentList "`"$XprFile`" -mode gui -source `"$TclScript`" -tclargs $test -journal `"$logDir\vivado.jou`" -log `"$logDir\vivado.log`"" `
                  -WindowStyle Normal
    
    # Small stagger so Vivado instances don't all hammer the disk simultaneously
    Start-Sleep -Seconds 3
}

Write-Host "`nDone. Each window will compile/elaborate (if needed) then run its test." -ForegroundColor Green
Write-Host "Close individual Vivado windows when finished inspecting waveforms." -ForegroundColor Gray
