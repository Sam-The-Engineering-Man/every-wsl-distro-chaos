# Overview
Running one WSL distro is boring! So let's run ALL of them at the same time.  This repo includes some helper scripts and notes that I used in my video.  Feel free to use it for your own WSL experiments!

Video: <>
# Helpful Commands
To install all the distro's (**NOTE**: These names are likely to change very quickly as distro's get updated use `wsl --list --online` for latest options):
```
$env:WSL_UTF8 = 1

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

foreach ($distro in $distros) {
    Write-Host "Installing $distro..."
    wsl --install --distribution $distro --no-launch
}
```
To launch all the distro's in a neat 4 x 4 x 2 grid layout spread across 3 tabs:
```
wt -w 0 new-tab -p "OracleLinux_9_5" `; split-pane -V -p "SUSE-Linux-Enterprise-16.0" `; move-focus first `; split-pane -H -p "Debian" `; move-focus right `; split-pane -H -p "AlmaLinux-10"
wt -w 0 new-tab -p "archlinux" `; split-pane -V -p "kali-linux" `; move-focus first `; split-pane -H -p "eLxr" `; move-focus right `; split-pane -H -p "Ubuntu-26.04"
wt -w 0 new-tab -p "openSUSE-Leap-16.0" `; split-pane -V -p "FedoraLinux-44"
```
The nginx config for load balancing:
```
upstream wsl_distros {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;
    server 127.0.0.1:8004;
    server 127.0.0.1:8005;
    server 127.0.0.1:8006;
    server 127.0.0.1:8007;
    server 127.0.0.1:8008;
    server 127.0.0.1:8009;
    server 127.0.0.1:8010;
}

server {
    listen 8080;

    location / {
        proxy_pass http://wsl_distros;

        add_header Cache-Control "no-store";
    }
}
```
Sometimes windows blocks powershell scripts for security (This is a good thing!). To allow it for just your current terminal window/session:
```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
Some of the WSL distro's don't include python that can be fixed with:
```
# Debian
wsl -d Debian -u root -e sh -c "apt-get update && apt-get install -y python3"

# eLxr
wsl -d eLxr -u root -e sh -c "apt-get update && apt-get install -y python3"

# SUSE Linux Enterprise
wsl -d SUSE-Linux-Enterprise-16.0 -u root -e zypper --non-interactive install python3

# openSUSE Leap
wsl -d openSUSE-Leap-16.0 -u root -e zypper --non-interactive install python3
```
# Scripts
I have included the scripts I used for:
- performance
- networking
- gpu

You can find them in their respective directories in this repo :)