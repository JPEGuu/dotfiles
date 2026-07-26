#!/usr/bin/env bash
# tmux-sessionizer: zoxide の frecency から作業ディレクトリを選び、
# そのディレクトリ名の tmux セッションを開く（無ければ作成）。
# tmux プラグインは使わず、fzf + zoxide + tmux の CLI だけで実装する。
#
# 起動方法:
#   - 引数あり  : そのパスを直接使う
#   - 引数なし  : `zoxide query -l` の候補を fzf で選択
# tmux.conf から `display-popup -E` 経由で M-f にバインドしている。
set -euo pipefail

if [[ $# -eq 1 ]]; then
    selected="$1"
else
    selected="$(zoxide query -l | fzf --reverse --prompt='session> ')"
fi

# 選択キャンセル時は何もしない
[[ -z "${selected:-}" ]] && exit 0

# tmux はセッション名に '.' と ':' を使えないため置換する
selected_name="$(basename "$selected" | tr '.:' '__')"

# tmux 外から呼ばれ、サーバーも起動していない場合は新規セッションへアタッチ
if [[ -z "${TMUX:-}" ]] && ! pgrep -x tmux >/dev/null 2>&1; then
    exec tmux new-session -s "$selected_name" -c "$selected"
fi

# セッションが無ければ detached で作成
if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

# tmux 外ならアタッチ、内なら切り替え
if [[ -z "${TMUX:-}" ]]; then
    exec tmux attach -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
