# =============================================================================
# Optional Tools
# =============================================================================
# Integrations are always defined. Missing dependencies are reported when the
# function is called instead of silently removing the command from bashhelp.
# =============================================================================

# -----------------------------------------------------------------------------
# Fastfetch / prompt tools
# -----------------------------------------------------------------------------

if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi


# -----------------------------------------------------------------------------
# FZF
# -----------------------------------------------------------------------------

fe() {
    command -v fzf >/dev/null 2>&1 || {
        echo 'fzf is required for fe.' >&2
        return 127
    }

    local file preview_cmd

    if command -v bat >/dev/null 2>&1; then
        preview_cmd='bat --color=always --style=numbers --line-range=:300 -- {}'
    elif command -v batcat >/dev/null 2>&1; then
        preview_cmd='batcat --color=always --style=numbers --line-range=:300 -- {}'
    else
        preview_cmd='sed -n "1,300p" -- {}'
    fi

    if command -v fd >/dev/null 2>&1; then
        file="$(fd --type f --hidden --exclude .git | fzf --preview="$preview_cmd")" || return
    elif command -v fdfind >/dev/null 2>&1; then
        file="$(fdfind --type f --hidden --exclude .git | fzf --preview="$preview_cmd")" || return
    else
        file="$(find . -type f -not -path './.git/*' | fzf --preview="$preview_cmd")" || return
    fi

    [[ -n "$file" ]] && "${EDITOR:-vi}" -- "$file"
}

fh() {
    command -v fzf >/dev/null 2>&1 || {
        echo 'fzf is required for fh.' >&2
        return 127
    }

    local selected
    selected="$(fc -ln 1 | fzf --tac --no-sort)" || return

    READLINE_LINE="$selected"
    READLINE_POINT=${#READLINE_LINE}
}

cdf() {
    command -v fzf >/dev/null 2>&1 || {
        echo 'fzf is required for cdf.' >&2
        return 127
    }

    local dir

    if command -v fd >/dev/null 2>&1; then
        dir="$(fd --type d --hidden --exclude .git | fzf)" || return
    elif command -v fdfind >/dev/null 2>&1; then
        dir="$(fdfind --type d --hidden --exclude .git | fzf)" || return
    else
        dir="$(find . -type d -not -path './.git/*' | fzf)" || return
    fi

    [[ -n "$dir" ]] && cd -- "$dir"
}

aliases() {
    command -v fzf >/dev/null 2>&1 || {
        alias
        return
    }

    alias | fzf
}


# -----------------------------------------------------------------------------
# ripgrep
# -----------------------------------------------------------------------------

rga() {
    [[ $# -ge 1 ]] || {
        echo 'Usage: rga <pattern> [path]'
        return 1
    }

    if command -v rg >/dev/null 2>&1; then
        rg --hidden --glob '!.git' "$@"
    else
        grep -RIn --exclude-dir=.git -- "$@" .
    fi
}

rgfiles() {
    if command -v rg >/dev/null 2>&1; then
        rg --files --hidden --glob '!.git' "$@"
    else
        find . -type f -not -path './.git/*' "$@"
    fi
}


# -----------------------------------------------------------------------------
# jq / JSON
# -----------------------------------------------------------------------------

json() {
    command -v jq >/dev/null 2>&1 || {
        echo 'jq is required for json.' >&2
        return 127
    }

    if [[ $# -eq 0 ]]; then
        jq .
    else
        jq . "$@"
    fi
}

jsonpipe() {
    command -v jq >/dev/null 2>&1 || {
        echo 'jq is required for jsonpipe.' >&2
        return 127
    }

    jq empty
}

jsoncheck() {
    command -v jq >/dev/null 2>&1 || {
        echo 'jq is required for jsoncheck.' >&2
        return 127
    }

    [[ $# -eq 1 ]] || {
        echo 'Usage: jsoncheck <file>'
        return 1
    }

    if jq empty "$1" 2>/dev/null; then
        echo "Valid JSON: $1"
    else
        echo "Invalid JSON: $1"
        return 1
    fi
}


# -----------------------------------------------------------------------------
# strace
# -----------------------------------------------------------------------------

trace() {
    command -v strace >/dev/null 2>&1 || {
        echo 'strace is required for trace.' >&2
        return 127
    }

    [[ $# -gt 0 ]] || {
        echo 'Usage: trace <command> [args...]'
        return 1
    }

    strace -f "$@"
}

tracefiles() {
    command -v strace >/dev/null 2>&1 || {
        echo 'strace is required for tracefiles.' >&2
        return 127
    }

    [[ $# -gt 0 ]] || {
        echo 'Usage: tracefiles <command> [args...]'
        return 1
    }

    strace -f -e trace=file "$@"
}

tracenet() {
    command -v strace >/dev/null 2>&1 || {
        echo 'strace is required for tracenet.' >&2
        return 127
    }

    [[ $# -gt 0 ]] || {
        echo 'Usage: tracenet <command> [args...]'
        return 1
    }

    strace -f -e trace=network "$@"
}


# -----------------------------------------------------------------------------
# lsof / socket inspection
# -----------------------------------------------------------------------------

portprocess() {
    [[ $# -eq 1 ]] || {
        echo 'Usage: portprocess <port>'
        return 1
    }

    if command -v lsof >/dev/null 2>&1; then
        sudo lsof -nP -i :"$1"
    elif command -v ss >/dev/null 2>&1; then
        ss -ltnup "sport = :$1"
    else
        echo 'lsof or ss is required.' >&2
        return 127
    fi
}

connections() {
    if command -v lsof >/dev/null 2>&1; then
        sudo lsof -nP -i
    elif command -v ss >/dev/null 2>&1; then
        ss -tunap
    else
        echo 'lsof or ss is required.' >&2
        return 127
    fi
}

openfiles() {
    command -v lsof >/dev/null 2>&1 || {
        echo 'lsof is required for openfiles.' >&2
        return 127
    }

    sudo lsof "$@"
}


# -----------------------------------------------------------------------------
# tcpdump
# -----------------------------------------------------------------------------

sniff() {
    command -v tcpdump >/dev/null 2>&1 || {
        echo 'tcpdump is required for sniff.' >&2
        return 127
    }

    echo 'Capturing packets. Press Ctrl+C to stop.'
    sudo tcpdump -i any -n "$@"
}
