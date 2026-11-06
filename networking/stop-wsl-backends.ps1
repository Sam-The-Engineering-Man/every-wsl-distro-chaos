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

foreach ($distro in $distros) {
    Write-Host "Stopping web server in $distro..."
    wsl -d $distro -e pkill -f "python3 -m http.server"
}

Write-Host "All backend servers stopped."