#!/usr/bin/env bash
# Shared dstask picker for zsh aliases and tmux popup bindings.
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: dstask-fzf.sh <action> [filter...]

Actions:
  note      Pick a task and open its dstask note
  start     Pick a task and mark it active
  stop      Pick a task and mark it pending
  done      Pick a task and resolve it
  resume    Pick from paused tasks and start it
  toggle    Pick a task, then choose start/stop/done
  add       Prompt for a task summary and add it
  link      Create a zk note linked to the task UUID and open it
USAGE
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'dstask-fzf.sh: required command not found: %s\n' "$cmd" >&2
        exit 127
    fi
}

pick_task() {
    local source="$1"
    shift || true

    local json selected
    json="$(dstask "$source" "$@")"
    selected="$(
        jq -r '
          .[]
          | [
              (.id | tostring),
              (.uuid // ""),
              (.priority // ""),
              (.project // ""),
              (.summary // "")
            ]
          | @tsv
        ' <<<"$json" |
            fzf --reverse --with-nth=3.. --delimiter=$'\t' --prompt='task> ' || true
    )"

    [[ -n "${selected:-}" ]] || return 1
    printf '%s\n' "$selected"
}

read_task() {
    local selected="$1"
    TASK_ID="$(printf '%s\n' "$selected" | cut -f1)"
    TASK_UUID="$(printf '%s\n' "$selected" | cut -f2)"
    TASK_PRIORITY="$(printf '%s\n' "$selected" | cut -f3)"
    TASK_PROJECT="$(printf '%s\n' "$selected" | cut -f4)"
    TASK_SUMMARY="$(printf '%s\n' "$selected" | cut -f5-)"
}

run_task_action() {
    local action="$1"
    local selected="$2"

    read_task "$selected"
    case "$action" in
        note)
            exec dstask note "$TASK_ID"
            ;;
        start|stop|done)
            dstask "$TASK_ID" "$action"
            ;;
        *)
            printf 'dstask-fzf.sh: unknown task action: %s\n' "$action" >&2
            exit 2
            ;;
    esac
}

add_task() {
    local line
    read -r -p 'task: ' line || exit 0
    [[ -n "${line:-}" ]] || exit 0

    local -a args
    read -r -a args <<<"$line"
    [[ "${#args[@]}" -gt 0 ]] || exit 0

    dstask add "${args[@]}"
}

link_task_to_note() {
    local selected="$1"
    read_task "$selected"

    require_command zk

    if [[ -z "${TASK_UUID:-}" ]]; then
        printf 'dstask-fzf.sh: selected task has no uuid field\n' >&2
        exit 1
    fi

    local notebook_dir="$HOME/notes"
    if [[ ! -d "$notebook_dir/.zk" ]]; then
        printf 'dstask-fzf.sh: zk notebook is not initialized: %s\n' "$notebook_dir" >&2
        printf 'run: mkdir -p "%s/.zk"\n' "$notebook_dir" >&2
        exit 1
    fi

    local note_path related_path
    note_path="$(
        zk new \
            --notebook-dir "$notebook_dir" \
            --working-dir "$notebook_dir" \
            --no-input \
            --title "$TASK_SUMMARY" \
            --extra "dstask=$TASK_UUID" \
            --print-path
    )"
    related_path="${note_path#"$notebook_dir"/}"

    local related_line="related-note: $related_path"
    dstask note "$TASK_ID" "$related_line"
    if ! dstask note "$TASK_ID" | grep -Fq -- "$related_line"; then
        printf 'dstask-fzf.sh: warning: dstask note did not contain "%s"; task-side backlink may not have been recorded\n' "$related_line" >&2
    fi

    exec "${EDITOR:-nvim}" "$note_path"
}

main() {
    local action="${1:-}"
    if [[ -z "$action" || "$action" == "-h" || "$action" == "--help" ]]; then
        usage
        exit 0
    fi
    shift || true

    require_command dstask

    local selected next_action
    case "$action" in
        add)
            add_task
            ;;
        note|start|stop|done)
            require_command jq
            require_command fzf
            selected="$(pick_task next "$@")" || exit 0
            run_task_action "$action" "$selected"
            ;;
        resume)
            require_command jq
            require_command fzf
            selected="$(pick_task show-paused "$@")" || exit 0
            run_task_action start "$selected"
            ;;
        toggle)
            require_command jq
            require_command fzf
            selected="$(pick_task next "$@")" || exit 0
            next_action="$(printf 'start\nstop\ndone\n' | fzf --reverse --prompt='action> ' || true)"
            [[ -n "${next_action:-}" ]] || exit 0
            run_task_action "$next_action" "$selected"
            ;;
        link)
            require_command jq
            require_command fzf
            selected="$(pick_task next "$@")" || exit 0
            link_task_to_note "$selected"
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
}

main "$@"
