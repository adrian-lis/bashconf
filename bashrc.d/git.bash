# =============================================================================
# Git Helpers
# =============================================================================

_git_required() {
    if ! command -v git >/dev/null 2>&1; then
        echo 'Git is required for this function.' >&2
        return 127
    fi
}

gitbranch() {
    _git_required || return
    git branch -a "$@"
}

gitroot() {
    _git_required || return
    git rev-parse --show-toplevel
}

gitremote() {
    _git_required || return
    git remote -v
}

gitignored() {
    _git_required || return
    git status --short --ignored
}

gitconfig() {
    _git_required || return
    git config --list --show-origin
}

gitwhere() {
    _git_required || return

    local root branch
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo 'Not inside a Git repository.'
        return 1
    }

    branch="$(git branch --show-current)"

    printf 'Repository: %s\n' "$root"
    printf 'Branch:    %s\n' "${branch:-DETACHED HEAD}"
    printf 'Remote:    %s\n' "$(git remote get-url origin 2>/dev/null || echo 'none')"
    printf '\n'
    git status --short --branch
}

gitsummary() {
    _git_required || return

    local root branch commit remote
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo 'Not inside a Git repository.'
        return 1
    }
    branch="$(git branch --show-current)"
    commit="$(git rev-parse --short HEAD 2>/dev/null || echo 'none')"
    remote="$(git remote get-url origin 2>/dev/null || echo 'none')"

    printf 'Root:    %s\n' "$root"
    printf 'Branch:  %s\n' "${branch:-DETACHED HEAD}"
    printf 'Commit:  %s\n' "$commit"
    printf 'Origin:  %s\n' "$remote"
    printf 'Changes: '
    git status --porcelain | wc -l
}

gitlast() {
    _git_required || return
    git log -n "${1:-10}" --oneline --decorate --graph
}

gituntracked() {
    _git_required || return
    git ls-files --others --exclude-standard
}

lazyg () {
  git add .
  git commit -m "$1"
  git push
}
