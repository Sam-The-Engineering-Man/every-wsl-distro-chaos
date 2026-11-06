param(
    [int]$Duration = 60,
    [int]$MemoryMB = 64,
    [int]$Iterations = 2048
)

$distros = @(
    "Ubuntu-26.04",
    "OracleLinux_9_5",
    "SUSE-Linux-Enterprise-16.0",
    "Debian",
    "AlmaLinux-10",
    "archlinux",
    "kali-linux",
    "eLxr",
    "openSUSE-Leap-16.0",
    "FedoraLinux-44"
)

$gpuScript = "/mnt/c/Users/sjr/Desktop/wsl-every-distro/gpu/gpu-stress.py"

$logDir = Join-Path $PSScriptRoot "logs"

New-Item `
    -ItemType Directory `
    -Force `
    -Path $logDir | Out-Null

Write-Host ""
Write-Host "Starting GPU workload across all 10 WSL distros..."
Write-Host ""
Write-Host "Duration:   $Duration seconds"
Write-Host "VRAM:       $MemoryMB MiB per distro"
Write-Host "Iterations: $Iterations"
Write-Host ""

$processes = @()

foreach ($distro in $distros) {

    $safeName = $distro -replace '[^\w\-]', '_'

    $stdout = Join-Path $logDir "$safeName.log"
    $stderr = Join-Path $logDir "$safeName-error.log"

    # Remove logs from previous run
    Remove-Item $stdout -ErrorAction SilentlyContinue
    Remove-Item $stderr -ErrorAction SilentlyContinue

    Write-Host "Starting $distro..."

    $process = Start-Process `
        -FilePath "wsl.exe" `
        -ArgumentList @(
            "-d", $distro,
            "--",
            "python3",
            $gpuScript,
            "--duration", $Duration,
            "--memory-mb", $MemoryMB,
            "--iterations", $Iterations
        ) `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr `
        -WindowStyle Hidden `
        -PassThru

    $processes += @{
        Distro  = $distro
        Process = $process
        Log     = $stdout
        Error   = $stderr
    }
}

Write-Host ""
Write-Host "All 10 GPU workloads launched."
Write-Host ""
Write-Host "Waiting for workloads to finish..."

foreach ($item in $processes) {
    $item.Process.WaitForExit()
}

Write-Host ""
Write-Host "========================================"
Write-Host "GPU stress test complete"
Write-Host "========================================"
Write-Host ""

foreach ($item in $processes) {

    Write-Host "[$($item.Distro)]"

    if (Test-Path $item.Log) {
        Get-Content $item.Log | ForEach-Object {
            Write-Host "  $_"
        }
    }

    if (
        (Test-Path $item.Error) -and
        ((Get-Item $item.Error).Length -gt 0)
    ) {
        Write-Host "  STDERR:" -ForegroundColor Yellow

        Get-Content $item.Error | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Yellow
        }
    }

    Write-Host ""
}