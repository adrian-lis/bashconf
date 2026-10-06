#!/usr/bin/env bash
# =============================================================================
# Universal Bash Configuration Installer
# =============================================================================
# Supported families:
#   Debian / Ubuntu
#   Fedora / RHEL-family
#   Arch / Arch-based
#
# The installer is deliberately dependency-light: it uses Bash and common
# terminal utilities for the TUI and package-manager calls.
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly TARGET_BASHRC="$HOME/.bashrc"
readonly TARGET_MODULE_DIR="$HOME/.bashrc.d"

DISTRO_FAMILY=""
DISTRO_NAME=""
DISTRO_VERSION=""
SUDO=()

BACKUP_BASHRC=""


# =============================================================================
# 01. UI
# =============================================================================

if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
    C_RESET="$(tput sgr0)"
    C_BOLD="$(tput bold)"
    C_DIM="$(tput dim 2>/dev/null || true)"
    C_CYAN="$(tput setaf 6)"
    C_GREEN="$(tput setaf 2)"
    C_YELLOW="$(tput setaf 3)"
    C_RED="$(tput setaf 1)"
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_CYAN=""
    C_GREEN=""
    C_YELLOW=""
    C_RED=""
fi

say() { printf '%b\n' "$*"; }
info() { say "${C_CYAN}INFO${C_RESET}  $*"; }
success() { say "${C_GREEN}OK${C_RESET}    $*"; }
warn() { say "${C_YELLOW}WARN${C_RESET}  $*"; }
error() { say "${C_RED}ERROR${C_RESET} $*" >&2; }

hr() {
    printf '%b\n' "${C_DIM}────────────────────────────────────────────────────────────${C_RESET}"
}

banner() {
    clear 2>/dev/null || true
    printf '\n'
    say "${C_CYAN}${C_BOLD}Universal Bash Configuration${C_RESET}"
    say "${C_DIM}Portable modular Bash setup and package installer${C_RESET}"
    hr
}

pause_screen() {
    printf '\nPress Enter to continue... '
    read -r _
}

ask_yes_no() {
    local prompt="$1"
    local answer

    while true; do
        printf '%s [Y/n] ' "$prompt"
        read -r answer
        case "${answer:-y}" in
            y|Y|yes|YES) return 0 ;;
            n|N|no|NO) return 1 ;;
            *) printf 'Please answer y or n.\n' ;;
        esac
    done
}


# =============================================================================
# 02. Distribution detection
# =============================================================================

detect_distro() {
    [[ -r /etc/os-release ]] || {
        error '/etc/os-release was not found.'
        return 1
    }

    # shellcheck disable=SC1091
    source /etc/os-release

    DISTRO_NAME="${PRETTY_NAME:-${NAME:-Unknown Linux}}"
    DISTRO_VERSION="${VERSION_ID:-unknown}"

    case "${ID:-}" in
        debian|ubuntu|linuxmint|pop|elementary|kali)
            DISTRO_FAMILY='debian'
            ;;
        fedora|rhel|centos|rocky|almalinux)
            DISTRO_FAMILY='fedora'
            ;;
        arch|manjaro|endeavouros|garuda)
            DISTRO_FAMILY='arch'
            ;;
        *)
            DISTRO_FAMILY=''
            ;;
    esac

    [[ -n "$DISTRO_FAMILY" ]] || {
        error "Unsupported distribution: $DISTRO_NAME"
        error 'Supported families: Debian/Ubuntu, Fedora/RHEL-family, Arch-based.'
        return 1
    }
}


# =============================================================================
# 03. Privilege handling
# =============================================================================

setup_privilege() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=()
        return 0
    fi

    command -v sudo >/dev/null 2>&1 || {
        error 'sudo is required to install system packages as a non-root user.'
        return 1
    }

    SUDO=(sudo)
}


# =============================================================================
# 04. Package sets
# =============================================================================

get_packages() {
    local profile="$1"

    case "$DISTRO_FAMILY:$profile" in
        # ---------------------------------------------------------------------
        # Debian / Ubuntu
        # ---------------------------------------------------------------------
        debian:core)
            printf '%s\n' \
                bash bash-completion coreutils findutils grep sed gawk \
                tar gzip bzip2 xz-utils util-linux procps iproute2 hostname \
                iputils-ping
            ;;
        debian:recommended)
            printf '%s\n' \
                curl wget less file unzip 7zip tree fzf ripgrep bat fd-find \
                zoxide jq git python3
            ;;
        debian:full)
            printf '%s\n' \
                eza starship fastfetch lsof strace tcpdump psmisc \
                netcat-openbsd dnsutils traceroute mtr-tiny sysstat htop btop \
                iotop pciutils usbutils lshw docker.io
            ;;

        # ---------------------------------------------------------------------
        # Fedora / RHEL-family
        # ---------------------------------------------------------------------
        fedora:core)
            printf '%s\n' \
                bash bash-completion coreutils findutils grep sed gawk \
                tar gzip bzip2 xz util-linux procps-ng iproute hostname iputils
            ;;
        fedora:recommended)
            printf '%s\n' \
                curl wget less file unzip 7zip tree fzf ripgrep bat fd-find \
                zoxide jq git python3
            ;;
        fedora:full)
            printf '%s\n' \
                eza starship fastfetch lsof strace tcpdump psmisc nmap-ncat \
                bind-utils traceroute mtr sysstat procps-ng htop btop iotop \
                pciutils usbutils lshw moby-engine
            ;;

        # ---------------------------------------------------------------------
        # Arch / Arch-based
        # ---------------------------------------------------------------------
        arch:core)
            printf '%s\n' \
                bash bash-completion coreutils findutils grep sed gawk \
                tar gzip bzip2 xz util-linux procps iproute2 iputils
            ;;
        arch:recommended)
            printf '%s\n' \
                curl wget less file unzip 7zip tree fzf ripgrep bat fd zoxide \
                jq git python
            ;;
        arch:full)
            printf '%s\n' \
                eza starship fastfetch lsof strace tcpdump psmisc openbsd-netcat \
                bind traceroute mtr sysstat htop btop iotop pciutils usbutils \
                lshw docker
            ;;
        *)
            return 1
            ;;
    esac
}

profile_packages() {
    local profile="$1"

    get_packages core

    case "$profile" in
        recommended|full)
            get_packages recommended
            ;;
    esac

    [[ "$profile" == 'full' ]] && get_packages full
}


# =============================================================================
# 05. Package installation
# =============================================================================

install_packages() {
    local profile="$1"
    local -a packages=()
    local -a install_cmd=()
    local package

    while IFS= read -r package; do
        [[ -n "$package" ]] && packages+=("$package")
    done < <(profile_packages "$profile" | awk '!seen[$0]++')

    info "Profile: $profile"
    info "Distribution: $DISTRO_NAME"
    info "Packages: ${#packages[@]}"

    printf '\nPackages:\n\n'
    printf '  %s\n' "${packages[@]}"
    printf '\n'

    ask_yes_no 'Install these packages now?' || {
        warn 'Package installation skipped.'
        return 0
    }

    case "$DISTRO_FAMILY" in
        debian)
            info 'Updating APT package index...'
            "${SUDO[@]}" apt-get update
            install_cmd=("${SUDO[@]}" apt-get install -y "${packages[@]}")
            ;;
        fedora)
            install_cmd=("${SUDO[@]}" dnf install -y "${packages[@]}")
            ;;
        arch)
            # Never use `pacman -Sy` alone. Keep the package database and
            # system upgrade synchronized to avoid partial-upgrade problems.
            install_cmd=("${SUDO[@]}" pacman -S --needed "${packages[@]}")
            ;;
        *)
            error 'Unsupported package-manager family.'
            return 1
            ;;
    esac

    "${install_cmd[@]}"
    success 'Package installation completed.'
}


# =============================================================================
# 06. Configuration validation
# =============================================================================

validate_config() {
    local file
    local -a files=(
        "$SCRIPT_DIR/.bashrc"
        "$SCRIPT_DIR/bashrc.d/aliases.bash"
        "$SCRIPT_DIR/bashrc.d/functions.bash"
        "$SCRIPT_DIR/bashrc.d/git.bash"
        "$SCRIPT_DIR/bashrc.d/docker.bash"
        "$SCRIPT_DIR/bashrc.d/optional-tools.bash"
    )

    info 'Validating Bash configuration...'

    for file in "${files[@]}"; do
        [[ -r "$file" ]] || {
            error "Missing configuration file: $file"
            return 1
        }

        bash -n "$file" || {
            error "Syntax error: $file"
            return 1
        }
    done
}


# =============================================================================
# 07. Backup and configuration installation
# =============================================================================

create_backup_path() {
    local stamp base candidate index=1

    stamp="$(date '+%Y%m%d-%H%M%S')"
    base="$HOME/.bashrc.backup-$stamp"
    candidate="$base"

    while [[ -e "$candidate" ]]; do
        candidate="${base}-${index}"
        ((index += 1))
    done

    BACKUP_BASHRC="$candidate"
}

backup_bashrc() {
    [[ -e "$TARGET_BASHRC" ]] || {
        info 'No existing ~/.bashrc found. Backup not required.'
        return 0
    }

    create_backup_path
    cp -a -- "$TARGET_BASHRC" "$BACKUP_BASHRC"
    success "Backup created: $BACKUP_BASHRC"
}

install_config() {
    validate_config

    info 'Installing modules to ~/.bashrc.d ...'
    mkdir -p "$TARGET_MODULE_DIR"

    backup_bashrc

    cp -a -- "$SCRIPT_DIR/.bashrc" "$TARGET_BASHRC"

    for module in aliases.bash functions.bash git.bash docker.bash optional-tools.bash; do
        cp -a -- "$SCRIPT_DIR/bashrc.d/$module" "$TARGET_MODULE_DIR/$module"
    done

    success "Installed: $TARGET_BASHRC"
    success "Installed modules: $TARGET_MODULE_DIR"
}


# =============================================================================
# 08. Post-install validation
# =============================================================================

validate_installation() {
    local failed=0
    local module

    printf '\n%s\n' 'Post-install check'
    printf '%s\n' '------------------'

    if [[ -r "$TARGET_BASHRC" ]]; then
        printf '[OK]      ~/.bashrc\n'
    else
        printf '[MISSING] ~/.bashrc\n'
        failed=1
    fi

    for module in aliases.bash functions.bash git.bash docker.bash optional-tools.bash; do
        if [[ -r "$TARGET_MODULE_DIR/$module" ]]; then
            printf '[OK]      ~/.bashrc.d/%s\n' "$module"
        else
            printf '[MISSING] ~/.bashrc.d/%s\n' "$module"
            failed=1
        fi
    done

    if ((failed == 0)); then
        success 'Configuration files are installed correctly.'
        return 0
    fi

    error 'One or more configuration files are missing.'
    return 1
}


# =============================================================================
# 09. TUI
# =============================================================================

show_status() {
    banner

    say "${C_BOLD}System${C_RESET}"
    printf '  Distribution : %s\n' "$DISTRO_NAME"
    printf '  Version      : %s\n' "$DISTRO_VERSION"
    printf '  Family       : %s\n' "$DISTRO_FAMILY"
    printf '  Bash         : %s\n' "${BASH_VERSION%% *}"
    printf '  Target       : %s\n' "$TARGET_BASHRC"
    printf '  Modules      : %s\n' "$TARGET_MODULE_DIR"
    printf '\n'
}

main_menu() {
    local choice

    while true; do
        show_status
        hr
        say "${C_BOLD}Installation profiles${C_RESET}"
        printf '\n'
        printf '  1) Core        - base Bash environment\n'
        printf '  2) Recommended - productivity + development tools\n'
        printf '  3) Full        - all supported tools + Docker\n'
        printf '  4) Config only - no package installation\n'
        printf '  5) Exit\n'
        printf '\n'
        read -rp 'Select [1-5]: ' choice

        case "$choice" in
            1)
                install_config
                install_packages core
                validate_installation || true
                pause_screen
                ;;
            2)
                install_config
                install_packages recommended
                validate_installation || true
                pause_screen
                ;;
            3)
                install_config
                install_packages full
                validate_installation || true
                pause_screen
                ;;
            4)
                install_config
                validate_installation || true
                pause_screen
                ;;
            5)
                printf '\n'
                success 'Installer closed.'
                return 0
                ;;
            *)
                warn 'Invalid selection.'
                sleep 1
                ;;
        esac
    done
}


# =============================================================================
# 10. Entry point
# =============================================================================

main() {
    detect_distro
    setup_privilege
    main_menu
}

main "$@"
