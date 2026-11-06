$backends = @(
    @{ Distro = "Ubuntu-26.04";               Port = 8001 }
    @{ Distro = "OracleLinux_9_5";            Port = 8002 }
    @{ Distro = "SUSE-Linux-Enterprise-16.0"; Port = 8003 }
    @{ Distro = "Debian";                     Port = 8004 }
    @{ Distro = "AlmaLinux-10";               Port = 8005 }
    @{ Distro = "archlinux";                  Port = 8006 }
    @{ Distro = "kali-linux";                 Port = 8007 }
    @{ Distro = "eLxr";                       Port = 8008 }
    @{ Distro = "openSUSE-Leap-16.0";         Port = 8009 }
    @{ Distro = "FedoraLinux-44";             Port = 8010 }
)

foreach ($backend in $backends) {

    $distro = $backend.Distro
    $port   = $backend.Port

    Write-Host "Starting $distro on port $port..."

    # Ask this distro for its actual Linux home directory
    $linuxHome = (
        wsl -d $distro -e sh -c 'printf %s "$HOME"'
    ).Trim()

    $webPath = "$linuxHome/wsl-web"

    $arguments = @(
        "-d"
        $distro
        "--"
        "python3"
        "-m"
        "http.server"
        "$port"
        "--bind"
        "127.0.0.1"
        "--directory"
        $webPath
    )

    Start-Process `
        -FilePath "wsl.exe" `
        -ArgumentList $arguments `
        -WindowStyle Hidden
}

Write-Host ""
Write-Host "All 10 WSL backends started."
Write-Host ""
Write-Host "Backend URLs:"

foreach ($backend in $backends) {
    Write-Host "$($backend.Distro) -> http://localhost:$($backend.Port)"
}