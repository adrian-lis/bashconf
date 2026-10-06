# =============================================================================
# Aliases
# =============================================================================

# Navigation.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Shell.
alias c='clear'
alias q='exit'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias md='mkdir -p'

# Portable colorized grep.
alias grep='grep --color=auto'

# eza integration.
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -lah --group-directories-first'
    alias la='eza -a --group-directories-first'
    alias lt='eza --tree --level=2 --group-directories-first'
fi

# bat / batcat integration without replacing cat globally.
if command -v bat >/dev/null 2>&1; then
    alias catp='bat'
    alias batplain='bat --style=plain'
    alias batnum='bat --style=numbers'
elif command -v batcat >/dev/null 2>&1; then
    alias catp='batcat'
    alias batplain='batcat --style=plain'
    alias batnum='batcat --style=numbers'
fi
