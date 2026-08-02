#!/usr/bin/env bash
# Taskwarrior/Timewarrior commands used from tmux popups.
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: timetrack-popup.sh <add|manage|report> [args...]
USAGE
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'timetrack-popup.sh: required command not found: %s\n' "$cmd" >&2
        exit 127
    fi
}

action="${1:-}"

if [[ -z "$action" || "$action" == "-h" || "$action" == "--help" ]]; then
    usage
    exit 0
fi
shift || true

case "$action" in
    add)
        require_command zsh
        require_command task
        require_command fzf
        exec zsh -ic 'ta "$@"' timetrack-popup "$@"
        ;;
    manage)
        require_command zsh
        require_command task
        require_command jq
        require_command fzf
        exec zsh -ic 't "$@"' timetrack-popup "$@"
        ;;
    report)
        require_command twrep
        exec twrep :day "$@"
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
