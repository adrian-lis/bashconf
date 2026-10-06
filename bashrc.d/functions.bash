# =============================================================================
# Core Functions
# =============================================================================

# This file intentionally defines functions even when optional tools are not
# installed. Each function checks its dependency when it is called instead of
# disappearing from the shell.

# -----------------------------------------------------------------------------
# Common helpers
# -----------------------------------------------------------------------------

require_cmd() {
    local cmd="$1"
    local message="${2:-$cmd is required.}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'Error: %s\n' "$message" >&2
        return 127
    fi
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}


# -----------------------------------------------------------------------------
# Navigation
# -----------------------------------------------------------------------------

up() {
    local count="${1:-1}"
    local target="."
    local i

    [[ "$count" =~ ^[0-9]+$ ]] || {
        echo 'Usage: up <number>'
        return 1
    }

    for ((i = 0; i < count; i++)); do
        target+="/.."
    done

    cd -- "$target"
}

mkcd() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: mkcd <directory>'
        return 1
    }

    mkdir -p -- "$@" && cd -- "${!#}"
}

croot() {
    require_cmd git 'Git is required for croot.' || return

    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo 'Not inside a Git repository.'
        return 1
    }

    cd -- "$root"
}


# -----------------------------------------------------------------------------
# Files and directories
# -----------------------------------------------------------------------------

fileinfo() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: fileinfo <file> [file...]'
        return 1
    }

    local target

    for target in "$@"; do
        [[ -e "$target" || -L "$target" ]] || {
            printf 'Not found: %s\n' "$target" >&2
            continue
        }

        printf '\n=== %s ===\n' "$target"
        printf 'Path:        %s\n' "$(realpath -- "$target" 2>/dev/null || printf '%s' "$target")"

        if has_cmd file; then
            printf 'Type:        %s\n' "$(file -b -- "$target")"
        fi

        if stat --version >/dev/null 2>&1; then
            printf 'Size:        %s bytes\n' "$(stat -c '%s' -- "$target")"
            printf 'Permissions: %s\n' "$(stat -c '%A' -- "$target")"
            printf 'Owner:       %s:%s\n' "$(stat -c '%U' -- "$target")" "$(stat -c '%G' -- "$target")"
            printf 'Modified:    %s\n' "$(stat -c '%y' -- "$target")"
        fi
    done
}

findfile() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: findfile <pattern> [path]'
        return 1
    }

    local pattern="$1"
    local base='.'

    shift
    if [[ $# -gt 0 && "${1:0:1}" != '-' ]]; then
        base="$1"
        shift
    fi

    if has_cmd fd; then
        fd --hidden --exclude .git "$pattern" "$base" "$@"
    elif has_cmd fdfind; then
        fdfind --hidden --exclude .git "$pattern" "$base" "$@"
    else
        find "$base" -not -path '*/.git/*' -iname "*${pattern}*" "$@"
    fi
}

fdall() {
    if has_cmd fd; then
        fd --hidden --exclude .git --type f "$@"
    elif has_cmd fdfind; then
        fdfind --hidden --exclude .git --type f "$@"
    else
        find . -type f -not -path './.git/*' "$@"
    fi
}

findtext() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: findtext <pattern> [path]'
        return 1
    }

    if has_cmd rg; then
        rg --hidden --glob '!.git' "$@"
    else
        grep -RIn --exclude-dir=.git -- "$@" .
    fi
}

extract() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: extract <archive>'
        return 1
    }

    local archive="$1"
    [[ -f "$archive" ]] || {
        printf 'File not found: %s\n' "$archive" >&2
        return 1
    }

    case "$archive" in
        *.tar.gz|*.tgz) tar -xzf "$archive" ;;
        *.tar.bz2|*.tbz2) tar -xjf "$archive" ;;
        *.tar.xz|*.txz) tar -xJf "$archive" ;;
        *.tar.zst) tar --zstd -xf "$archive" ;;
        *.tar) tar -xf "$archive" ;;
        *.zip)
            require_cmd unzip 'unzip is required to extract ZIP files.' || return
            unzip -- "$archive"
            ;;
        *.7z)
            if has_cmd 7z; then
                7z x -- "$archive"
            elif has_cmd 7zz; then
                7zz x -- "$archive"
            else
                echo '7z or 7zz is required to extract 7z archives.' >&2
                return 127
            fi
            ;;
        *.rar)
            if has_cmd unrar; then
                unrar x -- "$archive"
            elif has_cmd 7z; then
                7z x -- "$archive"
            elif has_cmd 7zz; then
                7zz x -- "$archive"
            else
                echo 'unrar, 7z, or 7zz is required to extract RAR archives.' >&2
                return 127
            fi
            ;;
        *.gz) gunzip -- "$archive" ;;
        *.bz2) bunzip2 -- "$archive" ;;
        *.xz) unxz -- "$archive" ;;
        *.zst)
            require_cmd unzstd 'unzstd is required to extract Zstandard files.' || return
            unzstd -- "$archive"
            ;;
        *)
            printf 'Unsupported archive format: %s\n' "$archive" >&2
            return 1
            ;;
    esac
}

compress() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: compress <file-or-directory> [output.tar.gz]'
        return 1
    }

    local input="$1"
    local output="${2:-${input%/}.tar.gz}"

    [[ -e "$input" ]] || {
        printf 'Not found: %s\n' "$input" >&2
        return 1
    }

    tar -czf "$output" -- "$input"
    printf 'Created: %s\n' "$output"
}

backup() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: backup <file-or-directory>'
        return 1
    }

    local source="$1"
    local timestamp
    timestamp="$(date '+%Y%m%d-%H%M%S')"

    [[ -e "$source" || -L "$source" ]] || {
        printf 'Not found: %s\n' "$source" >&2
        return 1
    }

    cp -a -- "$source" "${source}.backup-${timestamp}"
    printf 'Backup created: %s\n' "${source}.backup-${timestamp}"
}

serve() {
    local port="${1:-8000}"

    [[ "$port" =~ ^[0-9]+$ ]] || {
        echo 'Usage: serve [port]'
        return 1
    }

    if has_cmd python3; then
        python3 -m http.server "$port"
    elif has_cmd python; then
        python -m http.server "$port"
    else
        echo 'Python 3 is required for serve.' >&2
        return 127
    fi
}


# -----------------------------------------------------------------------------
# Environment and shell diagnostics
# -----------------------------------------------------------------------------

envgrep() {
    if [[ $# -eq 0 ]]; then
        env | sort
    else
        env | grep -i -- "$*"
    fi
}

path() {
    printf '%s\n' "$PATH" | tr ':' '\n'
}

pathgrep() {
    if [[ $# -eq 0 ]]; then
        path
    else
        path | grep -i -- "$*"
    fi
}

whichall() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: whichall <command>'
        return 1
    }

    type -a -- "$1"
}

where() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: where <command>'
        return 1
    }

    command -v -- "$1"
}

cmdinfo() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: cmdinfo <command>'
        return 1
    }

    printf 'Command: %s\n' "$1"
    type -a -- "$1"

    if command -v "$1" >/dev/null 2>&1; then
        printf 'Path:    %s\n' "$(command -v "$1")"
    fi
}

shellinfo() {
    printf 'Shell:       %s\n' "${SHELL:-unknown}"
    printf 'Bash:        %s\n' "$BASH_VERSION"
    printf 'PID:         %s\n' "$$"
    printf 'PPID:        %s\n' "$PPID"
    printf 'User:        %s\n' "${USER:-unknown}"
    printf 'Home:        %s\n' "$HOME"
    printf 'PWD:         %s\n' "$PWD"
    printf 'Editor:      %s\n' "${EDITOR:-not set}"
    printf 'Pager:       %s\n' "${PAGER:-not set}"
    printf 'Interactive: %s\n' "yes"
}

reload() {
    source "$HOME/.bashrc"
    printf 'Reloaded: %s\n' "$HOME/.bashrc"
}

cmdtime() {
    [[ $# -gt 0 ]] || {
        echo 'Usage: cmdtime <command> [args...]'
        return 1
    }

    time "$@"
}

sha256() {
    [[ $# -gt 0 ]] || {
        echo 'Usage: sha256 <file> [file...]'
        return 1
    }

    require_cmd sha256sum 'sha256sum is required.' || return
    sha256sum -- "$@"
}

aliasinfo() {
    alias
    printf '\nFunctions:\n'
    declare -F | awk '{print $3}' | sort
}

bashrc_status() {
    local module status
    local count=0

    printf 'Bash configuration\n'
    printf '%s\n' '-------------------'
    printf 'Main file:   %s\n' "$HOME/.bashrc"
    printf 'Module dir:  %s\n' "$HOME/.bashrc.d"
    printf 'Bash:        %s\n' "$BASH_VERSION"
    printf '\nModules:\n'

    local modules_ok=0

    for module in aliases.bash functions.bash git.bash docker.bash optional-tools.bash; do
        if [[ -r "$HOME/.bashrc.d/$module" ]]; then
            status='OK'
            ((modules_ok += 1))
        else
            status='MISSING'
        fi
        printf '  %-24s %s\n' "$module" "$status"
    done

    printf '\nModules present: %s/5\n' "$modules_ok"
}


# -----------------------------------------------------------------------------
# Process diagnostics
# -----------------------------------------------------------------------------

proc() {
    require_cmd ps 'proc requires procps/ps.' || return

    if [[ $# -eq 0 ]]; then
        ps aux
    else
        ps aux | grep -i -- "$*" | grep -v grep
    fi
}

proctree() {
    if has_cmd pstree; then
        pstree -p
    elif has_cmd ps; then
        ps auxf
    else
        echo 'ps or pstree is required.' >&2
        return 127
    fi
}

pidinfo() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: pidinfo <PID>'
        return 1
    }

    local pid="$1"
    [[ "$pid" =~ ^[0-9]+$ ]] || {
        echo 'PID must be numeric.'
        return 1
    }

    require_cmd ps 'ps is required.' || return
    ps -p "$pid" -o pid,ppid,user,%cpu,%mem,etime,stat,comm,args

    if [[ -r "/proc/$pid/status" ]]; then
        printf '\n--- /proc/%s/status ---\n' "$pid"
        grep -E '^(Name|State|Threads|VmRSS|VmSize):' "/proc/$pid/status" || true
    fi
}

procenv() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: procenv <PID>'
        return 1
    }

    local pid="$1"
    [[ "$pid" =~ ^[0-9]+$ ]] || {
        echo 'PID must be numeric.'
        return 1
    }

    [[ -r "/proc/$pid/environ" ]] || {
        echo "Cannot read environment for PID $pid. You may need elevated privileges."
        return 1
    }

    tr '\0' '\n' < "/proc/$pid/environ" | sort
}


# -----------------------------------------------------------------------------
# Networking diagnostics
# -----------------------------------------------------------------------------

netinfo() {
    printf '%s\n' '=== Interfaces ==='
    if has_cmd ip; then
        ip -brief address
    else
        echo 'ip command not found.'
    fi

    printf '\n%s\n' '=== Routes ==='
    if has_cmd ip; then
        ip route
    fi

    printf '\n%s\n' '=== DNS ==='
    if has_cmd resolvectl; then
        resolvectl status
    elif [[ -r /etc/resolv.conf ]]; then
        cat /etc/resolv.conf
    else
        echo 'DNS configuration unavailable.'
    fi
}

localips() {
    require_cmd ip 'iproute2 is required.' || return
    ip -brief address
}

gateway() {
    require_cmd ip 'iproute2 is required.' || return

    local gw
    gw="$(ip route show default 2>/dev/null | awk 'NR==1 {print $3}')"

    if [[ -n "$gw" ]]; then
        printf '%s\n' "$gw"
    else
        echo 'No default gateway found.'
        return 1
    fi
}

ports() {
    require_cmd ss 'ss from iproute2 is required.' || return
    ss -tulpen
}

tcpports() {
    require_cmd ss 'ss from iproute2 is required.' || return
    ss -tlpn
}

udpports() {
    require_cmd ss 'ss from iproute2 is required.' || return
    ss -ulpn
}

portcheck() {
    [[ $# -eq 2 ]] || {
        echo 'Usage: portcheck <host> <port>'
        return 1
    }

    local host="$1"
    local port="$2"

    if has_cmd nc; then
        nc -zvw 3 "$host" "$port"
    elif has_cmd timeout; then
        if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            printf 'OPEN: %s:%s\n' "$host" "$port"
        else
            printf 'CLOSED/UNREACHABLE: %s:%s\n' "$host" "$port"
            return 1
        fi
    else
        echo 'netcat or timeout is required.' >&2
        return 127
    fi
}

routeinfo() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: routeinfo <host>'
        return 1
    }

    if has_cmd ip; then
        ip route get "$1"
    elif has_cmd route; then
        route -n
    else
        echo 'iproute2 is required.' >&2
        return 127
    fi
}

dns() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: dns <domain>'
        return 1
    }

    if has_cmd dig; then
        dig "$1"
    elif has_cmd nslookup; then
        nslookup "$1"
    else
        echo 'dig or nslookup is required.' >&2
        return 127
    fi
}

dnsrecord() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: dnsrecord <domain> [record]'
        return 1
    }

    require_cmd dig 'dig is required for dnsrecord.' || return
    dig +short "$1" "${2:-A}"
}

dnscheck() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: dnscheck <domain>'
        return 1
    }

    local domain="$1"
    local result

    if has_cmd dig; then
        result="$(dig +short "$domain" A 2>/dev/null)"
    elif has_cmd getent; then
        result="$(getent ahosts "$domain" | awk '{print $1}' | sort -u)"
    else
        echo 'dig or getent is required.' >&2
        return 127
    fi

    if [[ -n "$result" ]]; then
        printf 'DNS OK: %s\n%s\n' "$domain" "$result"
    else
        printf 'DNS FAILED: %s\n' "$domain"
        return 1
    fi
}

httpstatus() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: httpstatus <URL>'
        return 1
    }

    require_cmd curl 'curl is required.' || return
    curl -L -o /dev/null -sS -w 'HTTP: %{http_code}\n' -- "$1"
}

headers() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: headers <URL>'
        return 1
    }

    require_cmd curl 'curl is required.' || return
    curl -I -L -- "$1"
}

httpcheck() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: httpcheck <URL>'
        return 1
    }

    require_cmd curl 'curl is required.' || return
    curl -L -o /dev/null -sS \
        -w $'URL:        %{url_effective}\nHTTP:       %{http_code}\nDNS:        %{time_namelookup}s\nConnect:    %{time_connect}s\nTLS:        %{time_appconnect}s\nTTFB:       %{time_starttransfer}s\nTotal:      %{time_total}s\nSize:       %{size_download} bytes\n' \
        -- "$1"
}

myip() {
    require_cmd curl 'curl is required to determine the public IP.' || return
    curl -fsS https://api.ipify.org && echo
}

netcheck() {
    local host="${1:-1.1.1.1}"

    printf 'Testing network path to %s\n\n' "$host"

    if has_cmd ip; then
        printf '%s\n' '--- Route ---'
        ip route get "$host" 2>/dev/null || true
    fi

    if has_cmd ping; then
        printf '\n%s\n' '--- Ping ---'
        ping -c 3 -W 2 "$host"
    else
        echo 'ping not found.'
    fi
}


# -----------------------------------------------------------------------------
# System resources and storage
# -----------------------------------------------------------------------------

cpu() {
    if has_cmd lscpu; then
        lscpu
    elif [[ -r /proc/cpuinfo ]]; then
        cat /proc/cpuinfo
    else
        echo 'CPU information unavailable.'
        return 1
    fi
}

mem() {
    require_cmd free 'free from procps is required.' || return
    free -h
}

ram() {
    mem
}

load() {
    if [[ -r /proc/loadavg ]]; then
        cat /proc/loadavg
    elif has_cmd uptime; then
        uptime
    else
        echo 'Load information unavailable.'
        return 1
    fi
}

diskfree() {
    df -hT
}

diskusage() {
    du -h --max-depth=1 "${1:-.}" 2>/dev/null | sort -h
}

big() {
    local path="${1:-.}"

    printf 'Largest files under: %s\n' "$path"

    if find "$path" -type f -printf '%s\t%p\n' >/dev/null 2>&1; then
        find "$path" -type f -printf '%s\t%p\n' 2>/dev/null |
            sort -nr |
            head -n 20 |
            if has_cmd numfmt; then
                numfmt --field=1 --to=iec
            else
                cat
            fi
    else
        echo 'GNU find is required for big.' >&2
        return 1
    fi
}

mounts() {
    if has_cmd findmnt; then
        findmnt
    else
        mount
    fi
}


# -----------------------------------------------------------------------------
# Monitoring helpers
# -----------------------------------------------------------------------------

watchcpu() {
    if has_cmd btop; then
        btop
    elif has_cmd htop; then
        htop
    elif has_cmd top; then
        top
    else
        echo 'Install btop, htop, or procps/top.' >&2
        return 127
    fi
}

watchmem() {
    if has_cmd watch; then
        watch -n 1 'free -h'
    else
        while true; do
            clear
            free -h
            sleep 1
        done
    fi
}


# -----------------------------------------------------------------------------
# Hardware
# -----------------------------------------------------------------------------

hardware() {
    printf '%s\n' '=== CPU ==='
    if has_cmd lscpu; then
        lscpu | grep -E 'Model name|CPU\(s\)|Architecture' || true
    fi

    printf '\n%s\n' '=== Memory ==='
    free -h 2>/dev/null || true

    printf '\n%s\n' '=== Storage ==='
    if has_cmd lsblk; then
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
    fi

    printf '\n%s\n' '=== PCI ==='
    if has_cmd lspci; then
        lspci
    fi

    printf '\n%s\n' '=== USB ==='
    if has_cmd lsusb; then
        lsusb
    fi
}


# -----------------------------------------------------------------------------
# Checksum / file debugging
# -----------------------------------------------------------------------------

checksum() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: checksum <algorithm> <file> [file...]'
        echo 'Example: checksum sha256 file.iso'
        return 1
    }

    local algorithm="$1"
    shift

    case "$algorithm" in
        md5) require_cmd md5sum 'md5sum is required.' || return; md5sum -- "$@" ;;
        sha1) require_cmd sha1sum 'sha1sum is required.' || return; sha1sum -- "$@" ;;
        sha256) require_cmd sha256sum 'sha256sum is required.' || return; sha256sum -- "$@" ;;
        sha512) require_cmd sha512sum 'sha512sum is required.' || return; sha512sum -- "$@" ;;
        *) echo 'Supported algorithms: md5, sha1, sha256, sha512'; return 1 ;;
    esac
}


# -----------------------------------------------------------------------------
# systemd / journal diagnostics
# -----------------------------------------------------------------------------

failed() {
    require_cmd systemctl 'systemctl is required on systemd systems.' || return
    systemctl --failed
}

svc() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: svc <service>'
        return 1
    }

    require_cmd systemctl 'systemctl is required on systemd systems.' || return
    systemctl status --no-pager "$1"
}

srestart() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: srestart <service>'
        return 1
    }

    require_cmd systemctl 'systemctl is required on systemd systems.' || return
    sudo systemctl restart "$1"
}

jlog() {
    require_cmd journalctl 'journalctl is required on systemd systems.' || return
    journalctl -b "$@"
}

jerrors() {
    require_cmd journalctl 'journalctl is required on systemd systems.' || return
    journalctl -b -p err..alert "$@"
}

jerrors-prev() {
    require_cmd journalctl 'journalctl is required on systemd systems.' || return
    journalctl -b -1 -p err..alert "$@"
}

jboot() {
    require_cmd journalctl 'journalctl is required on systemd systems.' || return
    journalctl -b "$@"
}

journalgrep() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: journalgrep <pattern>'
        return 1
    }

    require_cmd journalctl 'journalctl is required on systemd systems.' || return
    journalctl -b --no-pager | grep -i -- "$*"
}

errors() {
    printf '%s\n' '=== Kernel messages ==='
    if has_cmd dmesg; then
        dmesg --level=err,warn 2>/dev/null | tail -n 100
    else
        echo 'dmesg unavailable.'
    fi

    printf '\n%s\n' '=== systemd journal ==='
    if has_cmd journalctl; then
        journalctl -b -p warning..alert --no-pager -n 100
    else
        echo 'journalctl unavailable.'
    fi
}


# -----------------------------------------------------------------------------
# Full diagnostics
# -----------------------------------------------------------------------------

diagnose() {
    printf '%s\n' '=============================================='
    printf '%s\n' ' System Diagnostics'
    printf '%s\n' '=============================================='

    printf '\n%s\n' '--- OS ---'
    if [[ -r /etc/os-release ]]; then
        grep -E '^(NAME|VERSION|PRETTY_NAME)=' /etc/os-release
    fi

    printf '\n%s\n' '--- Kernel ---'
    uname -a

    printf '\n%s\n' '--- Host ---'
    if has_cmd hostnamectl; then
        hostnamectl
    elif has_cmd hostname; then
        hostname
    fi

    printf '\n%s\n' '--- Uptime ---'
    uptime 2>/dev/null || true

    printf '\n%s\n' '--- CPU ---'
    if has_cmd lscpu; then
        lscpu | grep -E 'Model name|CPU\(s\)|Architecture' || true
    fi

    printf '\n%s\n' '--- Memory ---'
    free -h 2>/dev/null || true

    printf '\n%s\n' '--- Disk ---'
    df -hT

    printf '\n%s\n' '--- Network ---'
    if has_cmd ip; then
        ip -brief address
        printf '\n'
        ip route
    fi

    printf '\n%s\n' '--- Listening Ports ---'
    if has_cmd ss; then
        ss -tulpen
    fi

    printf '\n%s\n' '--- Failed Services ---'
    if has_cmd systemctl; then
        systemctl --failed --no-pager
    fi

    printf '\n%s\n' '--- Recent Boot Errors ---'
    if has_cmd journalctl; then
        journalctl -b -p err..alert --no-pager -n 30
    fi

    printf '\n%s\n' '=============================================='
    printf '%s\n' ' Diagnostics complete'
    printf '%s\n' '=============================================='
}


# -----------------------------------------------------------------------------
# Dependency / configuration checks
# -----------------------------------------------------------------------------

bashcheck() {
    local missing=0
    local cmd

    printf '%s\n' 'Bash configuration check'
    printf '%s\n\n' '========================'

    printf '%s\n' 'Modules:'
    local modules_ok=0

    for module in aliases.bash functions.bash git.bash docker.bash optional-tools.bash; do
        if [[ -r "$HOME/.bashrc.d/$module" ]]; then
            printf '  [OK]      %s\n' "$module"
        else
            printf '  [MISSING] %s\n' "$module"
            missing=1
        fi
    done

    printf '\n%s\n' 'Commands:'
    for cmd in bash grep sed awk find tar ip ss ps free df; do
        if has_cmd "$cmd"; then
            printf '  [OK]      %s\n' "$cmd"
        else
            printf '  [MISSING] %s\n' "$cmd"
            missing=1
        fi
    done

    printf '\n'
    if ((missing == 0)); then
        echo 'Status: OK'
        return 0
    fi

    echo 'Status: some dependencies are missing.'
    return 1
}


# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

bashhelp() {
    cat <<'HELP'

Universal Bash Configuration
============================

Navigation:
  ..              Go up one directory
  ...             Go up two directories
  ....            Go up three directories
  up              Go up N directories
  mkcd            Create a directory and enter it
  croot           Go to Git repository root
  ll              Detailed directory listing
  lt              Directory tree (eza)
  md              mkdir -p shortcut

Files:
  fileinfo        Detailed file metadata
  findfile        Find files/directories by name
  fdall           Find files (fd/fdfind fallback)
  findtext        Search text (rg/grep fallback)
  extract         Extract common archives
  compress        Create a tar.gz archive
  backup          Create timestamped backup
  serve           Start a simple Python HTTP server
  checksum        Calculate md5/sha1/sha256/sha512
  sha256          Calculate SHA-256 checksums

Search / FZF:
  fe              Find and edit a file
  fh              Search shell history
  cdf             Find and enter a directory
  aliases         Search aliases

JSON:
  json            Pretty-print JSON
  jsonpipe        Validate JSON from stdin

Networking:
  myip            Show public IP
  localips        Show local addresses
  netinfo         Interfaces, routes and DNS
  gateway         Show default gateway
  routeinfo       Show route to a host
  ports           Listening TCP/UDP ports
  tcpports        TCP listening ports
  udpports        UDP listening ports
  portcheck       Test a TCP port
  dns             DNS lookup
  dnsrecord       Query a DNS record
  dnscheck        Quick DNS A-record check
  headers         HTTP headers
  httpstatus      HTTP status
  httpcheck       HTTP timing information
  netcheck        Ping + route test

Processes / debugging:
  proc            Search running processes
  proctree        Process tree
  pidinfo         Detailed process information
  procenv         Process environment
  portprocess     Process using a network port
  connections     Network connections
  openfiles       Open files
  trace           Trace system calls
  tracefiles      Trace file-related syscalls
  tracenet        Trace network-related syscalls
  sniff           Capture packets with tcpdump

System:
  cpu             CPU information
  mem             Memory usage
  ram             Memory usage shortcut
  load            System load
  diskfree        Filesystem usage
  diskusage       Directory sizes
  big             Find largest files
  mounts          Mounted filesystems
  hardware        Hardware information
  watchcpu        Interactive CPU/process monitor
  watchmem        Live memory monitor
  errors          Kernel + journal warnings/errors
  diagnose        Full system diagnostics

systemd:
  failed          Failed services
  svc             Service status
  srestart        Restart service
  jlog            Current boot journal
  jerrors         Current boot errors
  jerrors-prev    Previous boot errors
  jboot           Current boot journal
  journalgrep     Search current boot journal

Docker:
  dps             Running containers
  dpsa            All containers
  di              Images
  dlog            Container logs
  dlogf           Follow container logs
  dexec           Execute command in container
  dstats          Container resource usage
  dspace          Docker disk usage
  dinspect        Inspect container
  drestart        Restart container
  dstop           Stop container
  dstart          Start container
  dclean          Remove stopped containers
  dprune          Show Docker cleanup command

Git:
  gitbranch       Show branches
  gitroot         Repository root
  gitremote       Show remotes
  gitignored      Show ignored files
  gitconfig       Show Git configuration
  gitwhere        Repository information
  gitsummary      Compact repository summary
  gitlast         Show recent commits
  gituntracked    Show untracked files
  lazyg           Add changes to repo fast

Environment / shell:
  envgrep         Search environment variables
  path            Show PATH entries
  pathgrep        Search PATH
  where           Locate a command
  whichall        Show all command locations
  cmdinfo         Inspect a command
  shellinfo       Shell information
  bashcheck       Check config and core dependencies
  bashrc_status   Show module status
  reload          Reload .bashrc
  aliasinfo       Show aliases and functions
  cmdtime         Measure command execution time

HELP
}
