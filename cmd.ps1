# ==================================
# CachyOS Terminal
# ==================================

Clear-Host
$host.UI.RawUI.WindowTitle = "CachyOS TTY"

# Farben
$GREEN="Green"; $BLUE="Cyan"; $RED="Red"; $WHITE="White"; $GRAY="DarkGray"

# Login Screen
Write-Host "CachyOS Linux 6.7.9-cachyos tty1"
Write-Host ""
$username = Read-Host "cachyos login"
$password = Read-Host "Password" -AsSecureString
Clear-Host

# State
$user = $username
$hostn = "cachyos"
$isRoot = $false
$cwd = "/home/$user"

# Kernel zufällig
$kernel = Get-Random @(
    "6.7.9-cachyos",
    "6.8.2-cachyos",
    "6.6.15-cachyos-lts"
)

# Fake Filesystem + Files
$fs = @{
    "/" = @("home","etc","usr","var","root")
    "/home" = @($user)
    "/home/$user" = @("Desktop","Documents","Downloads")
    "/etc" = @("os-release","hostname")
    "/root" = @()
}

$files = @{}
$perms = @{}

function Show-Neofetch {
Write-Host "        /\        " -ForegroundColor $BLUE
Write-Host "       /  \       $user@$hostn" -ForegroundColor $BLUE
Write-Host "      /\   \      ------------" -ForegroundColor $BLUE
Write-Host "     /  \___\     OS: CachyOS x86_64" -ForegroundColor $BLUE
Write-Host "    /   /         Kernel: Linux $kernel" -ForegroundColor $BLUE
Write-Host "   /___/          Shell: bash" -ForegroundColor $BLUE
Write-Host ""
}

function Show-Htop {
Clear-Host
Write-Host "htop - CPU [|||||||     ] 37%" -ForegroundColor $GREEN
Write-Host "Mem [|||||||||   ] 3.4G / 7.9G" -ForegroundColor $GREEN
Write-Host ""
Write-Host " PID USER   CPU% MEM% COMMAND"
Write-Host "  1 root   0.0  0.1  systemd"
Write-Host "412 $user  1.3  0.9  bash"
Write-Host "733 $user  5.9  2.1  htop"
Write-Host ""
Write-Host "Press q to quit"
do { $k=Read-Host } until ($k -eq "q")
Clear-Host
}

function Nano-Editor($path) {
Clear-Host
Write-Host "GNU nano 7.2" -ForegroundColor $BLUE
Write-Host "File: $path"
Write-Host "-----------------------------"
$text=""
while ($true) {
    $line = Read-Host
    if ($line -eq "^O") { break }
    $text += $line + "`n"
}
$files[$path] = $text
if (-not $perms.ContainsKey($path)) { $perms[$path]="-rw-r--r--" }
Clear-Host
}

Show-Neofetch

while ($true) {

    # Prompt
    if ($isRoot) {
        Write-Host "root@$hostn" -NoNewline -ForegroundColor $RED
        Write-Host ":" -NoNewline
        Write-Host $cwd -NoNewline -ForegroundColor $BLUE
        Write-Host " # " -NoNewline
    } else {
        Write-Host "$user@$hostn" -NoNewline -ForegroundColor $GREEN
        Write-Host ":" -NoNewline
        Write-Host $cwd -NoNewline -ForegroundColor $BLUE
        Write-Host " $ " -NoNewline
    }

    $cmd = Read-Host

    switch -Regex ($cmd) {

        "^ls$" {
            if ($fs.ContainsKey($cwd)) {
                Write-Host ($fs[$cwd] -join "  ")
            }
            $files.Keys | Where-Object { $_ -like "$cwd/*" } |
            ForEach-Object { Write-Host ($_ -replace "$cwd/","") }
        }

        "^cd\s+(.+)$" {
            $t=$matches[1]
            if ($t -eq "..") {
                $cwd = ($cwd -replace "/[^/]+$","")
                if ($cwd -eq "") { $cwd="/" }
            } else {
                $n = "$cwd/$t"
                if ($fs.ContainsKey($n)) { $cwd=$n }
            }
        }

        "^pwd$" { Write-Host $cwd }

        "^touch\s+(.+)$" {
            $p="$cwd/$($matches[1])"
            $files[$p]=""
            $perms[$p]="-rw-r--r--"
        }

        "^rm\s+(.+)$" {
            $p="$cwd/$($matches[1])"
            $files.Remove($p)
            $perms.Remove($p)
        }

        "^chmod\s+\d+\s+(.+)$" {
            $p="$cwd/$($matches[1])"
            if ($perms.ContainsKey($p)) { $perms[$p]="-rwxr-xr-x" }
        }

        "^nano\s+(.+)$" {
            Nano-Editor "$cwd/$($matches[1])"
        }

        "^cat /etc/os-release$" {
@"
NAME="CachyOS"
ID=cachyos
PRETTY_NAME="CachyOS Linux"
VERSION_ID="2024"
"@
        }

        "^systemctl status$" {
Write-Host "● systemd.service - System and Service Manager"
Write-Host "   Loaded: loaded (/usr/lib/systemd/system/systemd.service)"
Write-Host "   Active: active (running) since today"
Write-Host "   Main PID: 1 (systemd)"
        }

        "^htop$" { Show-Htop }

        "^sudo -i$" {
            $isRoot=$true
            $cwd="/root"
        }

        "^exit$" {
            if ($isRoot) {
                $isRoot=$false
                $cwd="/home/$user"
            } else { break }
        }

        "^clear$" { Clear-Host }

        "^neofetch$" { Show-Neofetch }

        "" {}

        default {
            Write-Host ("bash: {0}: command not found" -f $cmd) -ForegroundColor $RED

        }
    }
}
