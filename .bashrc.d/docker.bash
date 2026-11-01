# =============================================================================
# Docker Helpers
# =============================================================================

_docker_required() {
    if ! command -v docker >/dev/null 2>&1; then
        echo 'Docker CLI is required for this function.' >&2
        return 127
    fi
}

dps() {
    _docker_required || return
    docker ps "$@"
}

dpsa() {
    _docker_required || return
    docker ps -a "$@"
}

di() {
    _docker_required || return
    docker images "$@"
}

dlog() {
    _docker_required || return
    [[ $# -ge 1 ]] || {
        echo 'Usage: dlog <container> [docker-log-options]'
        return 1
    }
    docker logs --tail 100 "$@"
}

dlogf() {
    _docker_required || return
    [[ $# -ge 1 ]] || {
        echo 'Usage: dlogf <container> [docker-log-options]'
        return 1
    }
    docker logs -f --tail 100 "$@"
}

dexec() {
    _docker_required || return
    [[ $# -ge 1 ]] || {
        echo 'Usage: dexec <container> [command...]'
        return 1
    }

    local container="$1"
    shift

    if [[ $# -gt 0 ]]; then
        docker exec -it "$container" "$@"
    else
        docker exec -it "$container" /bin/sh
    fi
}

dstats() {
    _docker_required || return
    docker stats "$@"
}

dspace() {
    _docker_required || return
    docker system df "$@"
}

dinspect() {
    _docker_required || return
    [[ $# -ge 1 ]] || {
        echo 'Usage: dinspect <container-or-object>'
        return 1
    }
    docker inspect "$@"
}

drestart() {
    _docker_required || return
    [[ $# -ge 1 ]] || {
        echo 'Usage: drestart <container> [container...]'
        return 1
    }
    docker restart "$@"
}

dstop() {
    _docker_required || return
    [[ $# -ge 1 ]] || {
        echo 'Usage: dstop <container> [container...]'
        return 1
    }
    docker stop "$@"
}

dstart() {
    _docker_required || return
    [[ $# -ge 1 ]] || {
        echo 'Usage: dstart <container> [container...]'
        return 1
    }
    docker start "$@"
}

dclean() {
    _docker_required || return
    docker container prune
}

dprune() {
    _docker_required || return
    cat <<'HELP'
Docker cleanup commands:

  docker container prune     Remove stopped containers
  docker image prune         Remove dangling images
  docker volume prune        Remove unused volumes
  docker network prune       Remove unused networks
  docker system prune        Remove unused Docker data

Review the command before running it. Cleanup operations can delete data.
HELP
}
