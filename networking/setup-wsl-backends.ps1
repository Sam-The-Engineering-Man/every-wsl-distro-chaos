# setup-wsl-backends.ps1
#
# Prepares the HTML files that will become our WSL web backends.
#
# This script:
#   - Creates ~/wsl-web if needed
#   - Copies the appropriate HTML file to ~/wsl-web/index.html
#   - Checks whether Python 3 is installed
#
# This script DOES NOT start any web servers.

$windowsPath = (Resolve-Path $PSScriptRoot).Path

# Convert the folder containing this script:
# C:\some\path -> /mnt/c/some/path
$drive = $windowsPath.Substring(0, 1).ToLower()
$pathWithoutDrive = $windowsPath.Substring(2).Replace('\', '/')
$backendPath = "/mnt/$drive$pathWithoutDrive"

$backends = @(
    @{ Distro = "Ubuntu-26.04";               File = "01-Ubuntu-26.04.html";               Port = 8001 }
    @{ Distro = "OracleLinux_9_5";            File = "02-OracleLinux_9_5.html";            Port = 8002 }
    @{ Distro = "SUSE-Linux-Enterprise-16.0"; File = "03-SUSE-Linux-Enterprise-16.0.html"; Port = 8003 }
    @{ Distro = "Debian";                     File = "04-Debian.html";                      Port = 8004 }
    @{ Distro = "AlmaLinux-10";               File = "05-AlmaLinux-10.html";               Port = 8005 }
    @{ Distro = "archlinux";                  File = "06-archlinux.html";                   Port = 8006 }
    @{ Distro = "kali-linux";                 File = "07-kali-linux.html";                  Port = 8007 }
    @{ Distro = "eLxr";                       File = "08-eLxr.html";                        Port = 8008 }
    @{ Distro = "openSUSE-Leap-16.0";         File = "09-openSUSE-Leap-16.0.html";          Port = 8009 }
    @{ Distro = "FedoraLinux-44";             File = "10-FedoraLinux-44.html";              Port = 8010 }
)

$missingPython = @()
$copyFailures = @()

Write-Host ""
Write-Host "Preparing files for WSL web backends..."
Write-Host "Source directory: $backendPath"
Write-Host ""

foreach ($backend in $backends) {

    $distro = $backend.Distro
    $file   = $backend.File
    $port   = $backend.Port
    $source = "$backendPath/$file"

    Write-Host "[$distro]"
    Write-Host "  Backend port: $port"

    # Check whether our backend directory already exists
    & wsl.exe -d $distro -e sh -c 'test -d "$HOME/wsl-web"'

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Reusing existing ~/wsl-web"
    }
    else {
        & wsl.exe -d $distro -e sh -c 'mkdir -p "$HOME/wsl-web"'

        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ERROR: Could not create ~/wsl-web" -ForegroundColor Red
            $copyFailures += $distro
            Write-Host ""
            continue
        }

        Write-Host "  Created ~/wsl-web"
    }

    # Copy/replace the HTML file that will become this backend's index page
    $copyCommand = 'cp -f "{0}" "$HOME/wsl-web/index.html"' -f $source

    & wsl.exe -d $distro -e sh -c $copyCommand

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Could not copy $file" -ForegroundColor Red
        $copyFailures += $distro
        Write-Host ""
        continue
    }

    Write-Host "  Copied $file -> ~/wsl-web/index.html" -ForegroundColor Green

    # Check whether Python 3 is available for the future HTTP backend
    & wsl.exe -d $distro -e sh -c 'command -v python3 >/dev/null 2>&1'

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Python 3: Found" -ForegroundColor Green
    }
    else {
        Write-Host "  Python 3: NOT FOUND" -ForegroundColor Yellow
        $missingPython += $distro
    }

    Write-Host ""
}

Write-Host "========================================"
Write-Host "Backend file preparation complete."
Write-Host "========================================"
Write-Host ""
Write-Host "The HTML files have been prepared."
Write-Host "NO web servers have been started."
Write-Host ""

if ($copyFailures.Count -gt 0) {

    Write-Host "File preparation failed for:" -ForegroundColor Red

    foreach ($distro in $copyFailures) {
        Write-Host "  - $distro"
    }

    Write-Host ""
}

if ($missingPython.Count -gt 0) {

    Write-Host "Python 3 is missing from:" -ForegroundColor Yellow

    foreach ($distro in $missingPython) {
        Write-Host "  - $distro"
    }

    Write-Host ""
    Write-Host "Install Python 3 in the distros above, then simply run this script again."
}
else {
    Write-Host "Python 3 was found in all 10 distros." -ForegroundColor Green
    Write-Host "Ready for start-wsl-backends.ps1."
}