param(
    [ValidateSet("CPU", "Memory", "Both")]
    [string]$Test = "CPU",

    [int]$CpuWorkers = 4,

    [string]$MemoryPerDistro = "2048M",

    [int]$Duration = 300
)

$distros = @(
    "Ubuntu-26.04",
    "openSUSE-Leap-16.0",
    "SUSE-Linux-Enterprise-16.0",
    "kali-linux",
    "Debian",
    "AlmaLinux-10",
    "archlinux",
    "FedoraLinux-44",
    "eLxr",
    "OracleLinux_9_5"
)

$processes = foreach ($distro in $distros) {

    Write-Host "Starting $Test stress test on $distro..."

    $stressArgs = @()

    switch ($Test) {

        "CPU" {
            $stressArgs += @(
                "--cpu", "$CpuWorkers"
            )
        }

        "Memory" {
            $stressArgs += @(
                "--vm", "1",
                "--vm-bytes", "$MemoryPerDistro",
                "--vm-keep"
            )
        }

        "Both" {
            $stressArgs += @(
                "--cpu", "$CpuWorkers",
                "--vm", "1",
                "--vm-bytes", "$MemoryPerDistro",
                "--vm-keep"
            )
        }
    }

    $stressArgs += @(
        "--timeout", "${Duration}s",
        "--metrics-brief"
    )

    $arguments = @(
        "-d",
        $distro,
        "--",
        "stress-ng"
    ) + $stressArgs

    Start-Process `
        -FilePath "wsl.exe" `
        -ArgumentList $arguments `
        -PassThru `
        -NoNewWindow
}

Write-Host "`nAll 10 distros are under $Test load.`n"

$processes | Wait-Process

Write-Host "`nStress test complete."