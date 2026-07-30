#!/usr/bin/env bash
# zk commands used from tmux popups. Avoids relying on stale tmux environment.
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: zk-popup.sh <daily|edit-recent> [args...]
USAGE
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'zk-popup.sh: required command not found: %s\n' "$cmd" >&2
        exit 127
    fi
}

notebook_dir="$HOME/notes"
action="${1:-}"

if [[ -z "$action" || "$action" == "-h" || "$action" == "--help" ]]; then
    usage
    exit 0
fi
shift || true

require_command zk

if [[ ! -d "$notebook_dir/.zk" ]]; then
    printf 'zk notebook is not initialized: %s\n\n' "$notebook_dir" >&2
    printf 'Run:\n  mkdir -p "%s/.zk"\n' "$notebook_dir" >&2
    exit 1
fi

case "$action" in
    daily)
        exec zk \
            --notebook-dir "$notebook_dir" \
            --working-dir "$notebook_dir" \
            daily "$@"
        ;;
    edit-recent)
        exec zk \
            --notebook-dir "$notebook_dir" \
            --working-dir "$notebook_dir" \
            edit --interactive --sort modified- "$@"
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
