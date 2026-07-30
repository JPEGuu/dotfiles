#!/usr/bin/env bash
# Run a tmux popup command and keep error output visible.
set -u

always_hold=false
if [[ "${1:-}" == "--always-hold" ]]; then
    always_hold=true
    shift
fi

if [[ $# -eq 0 ]]; then
    printf 'popup-run.sh: no command specified\n' >&2
    exit 2
fi

"$@"
status=$?

if [[ "$always_hold" == true || ( "$status" -ne 0 && "$status" -ne 130 ) ]]; then
    printf '\nPress Enter to close...'
    read -r _
fi

exit "$status"
