# run_tests.ps1 - Compile, elaborate, then run each test in a separate cmd window.

$VivadoBin  = "C:\Xilinx\Vivado\2024.1\bin"
$XsimDir    = $PSScriptRoot

# Add Vivado to PATH for this session
$env:PATH = "$VivadoBin;$env:PATH"

Push-Location $XsimDir

# ── 1. Compile ──────────────────────────────────────────────────────────────
Write-Host "`n=== Compile ===" -ForegroundColor Cyan
cmd /c compile.bat
if ($LASTEXITCODE -ne 0) { Write-Error "Compile failed (exit $LASTEXITCODE). Aborting."; Pop-Location; exit 1 }
Write-Host "Compile OK" -ForegroundColor Green

# ── 2. Elaborate ────────────────────────────────────────────────────────────
Write-Host "`n=== Elaborate ===" -ForegroundColor Cyan
cmd /c elaborate.bat
if ($LASTEXITCODE -ne 0) { Write-Error "Elaborate failed (exit $LASTEXITCODE). Aborting."; Pop-Location; exit 1 }
Write-Host "Elaborate OK" -ForegroundColor Green

# ── 3. Launch each test in its own window ───────────────────────────────────
$tests = @(
    "direct_rw",
    "multi_slave",
    "back_to_back",
    "sequence_rw",
    "concurrent_masters",
    "nsaid_remap",
    "uvm_smoke"
)

foreach ($test in $tests) {
    Write-Host "`n=== Launching test: $test ===" -ForegroundColor Yellow

    $logFile = "simulate_$test.log"

    # Build the xsim command that will run in the new window.
    # The new window inherits nothing, so we prepend Vivado to PATH inside it.
    $innerCmd = "set PATH=$VivadoBin;%PATH% && cd /d `"$XsimDir`" && " +
                "xsim top_tb_behav -testplusarg TESTNAME=$test " +
                "-tclbatch run_all.tcl -log $logFile && " +
                "echo. && echo [DONE] $test - check $logFile for results && " +
                "pause"

    Start-Process cmd -ArgumentList "/k", $innerCmd -WindowStyle Normal
}

Pop-Location
Write-Host "`nAll $($tests.Count) test windows launched." -ForegroundColor Green
Write-Host "Logs are written to: $XsimDir\simulate_<testname>.log" -ForegroundColor Gray
