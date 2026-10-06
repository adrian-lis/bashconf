# =============================================================================
# Universal Bash Configuration
# =============================================================================
# Portable, modular Bash configuration for Linux.
#
# Supported package-manager families:
#   Debian / Ubuntu
#   Fedora / RHEL-family
#   Arch / Arch-based
#
# The main file loads the repository modules in a fixed order. This prevents
# accidental dependency/order problems caused by wildcard loading.
# =============================================================================

# Do not load the interactive configuration from non-interactive shells.
[[ $- != *i* ]] && return


# =============================================================================
# 01. SYSTEM INTEGRATION
# =============================================================================

# Load distribution-provided Bash configuration when available.
if [[ -r /etc/bash.bashrc ]]; then
    source /etc/bash.bashrc
elif [[ -r /etc/bashrc ]]; then
    source /etc/bashrc
fi

# Load Bash completion when available.
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
elif [[ -r /etc/bash_completion ]]; then
    source /etc/bash_completion
fi


# =============================================================================
# 02. SHELL OPTIONS
# =============================================================================

shopt -s histappend
shopt -s cmdhist
shopt -s lithist
shopt -s cdspell


# =============================================================================
# 03. HISTORY
# =============================================================================

HISTCONTROL="ignoreboth:erasedups"
HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history"
HISTSIZE=10000
HISTFILESIZE=20000
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

# Persist commands immediately without destroying existing PROMPT_COMMAND hooks.
case ";${PROMPT_COMMAND:-};" in
    *";history -a;"*) ;;
    *) PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND};}history -a" ;;
esac


# =============================================================================
# 04. READLINE
# =============================================================================

bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"
bind "set menu-complete-display-prefix on"


# =============================================================================
# 05. ENVIRONMENT
# =============================================================================

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

for dir in "$HOME/.local/bin" "$HOME/bin"; do
    if [[ -d "$dir" && ":$PATH:" != *":$dir:"* ]]; then
        PATH="$dir:$PATH"
    fi
done
export PATH

# Select the best available editor.
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim"
    export VISUAL="vim"
elif command -v nano >/dev/null 2>&1; then
    export EDITOR="nano"
    export VISUAL="nano"
fi

# Use less when available.
if command -v less >/dev/null 2>&1; then
    export PAGER="less"
    export LESS="-FRX"
fi


# =============================================================================
# 06. MODULE LOADER
# =============================================================================

readonly BASHRC_MODULE_DIR="${BASHRC_MODULE_DIR:-$HOME/.bashrc.d}"
readonly BASHRC_MODULES=(
    aliases.bash
    functions.bash
    git.bash
    docker.bash
    optional-tools.bash
)

if [[ -d "$BASHRC_MODULE_DIR" ]]; then
    for module in "${BASHRC_MODULES[@]}"; do
        module_path="$BASHRC_MODULE_DIR/$module"

        if [[ -r "$module_path" ]]; then
            # shellcheck disable=SC1090
            source "$module_path" ||
                printf 'Bashrc warning: failed to load %s\n' "$module_path" >&2
        fi
    done
else
    printf 'Bashrc warning: module directory not found: %s\n' "$BASHRC_MODULE_DIR" >&2
fi

unset module module_path
