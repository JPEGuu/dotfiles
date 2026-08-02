#!/usr/bin/env bash
# 実行中の timewarrior タスクの今日分累計を tmux ステータスバー用に整形する。
# 非稼働時は何も出力しない（区切りごと消える）。
# 出力例:  ▶ CSV出力機能 [コーディング] 2:30
#
# timew export :day を 1 回だけフォークし jq で同一 keyset の累計秒/tag/description を取り出す
# （毎秒 interval でも軽量に保つため #() フォークは 1 本に集約する）。
# start/end は UTC basic 形式(YYYYMMDDThhmmssZ)なので jq の strptime|mktime で epoch 化する。
set -euo pipefail

now=$(date +%s)

IFS=$'\t' read -r total tag desc < <(
  timew export :day 2>/dev/null | jq -r --argjson now "$now" '
    def epoch: strptime("%Y%m%dT%H%M%SZ") | mktime;
    def keyset: (.tags // []) | map(select(test("^(description|project|tag):"))) | sort;

    (map(select(has("end") | not)) | .[0]) as $act
    | if $act == null then
        empty
      else
        ($act | keyset) as $k
        | (($act.tags // []) | map(select(startswith("tag:")))[0]         // "" | ltrimstr("tag:"))         as $t
        | (($act.tags // []) | map(select(startswith("description:")))[0] // "" | ltrimstr("description:")) as $d
        | ([ .[]
              | select(keyset == $k)
              | (((if has("end") then (.end | epoch) else $now end) - (.start | epoch)))
            ] | add // 0) as $sum
        | [$sum, $t, $d] | @tsv
      end
  '
) || exit 0
[ -z "${total:-}" ] && exit 0

sec=$(( total ))
(( sec < 0 )) && sec=0
h=$(( sec / 3600 )); m=$(( (sec % 3600) / 60 )); s=$(( sec % 60 ))
if (( h > 0 )); then
  el=$(printf '%d:%02d:%02d' "$h" "$m" "$s")
else
  el=$(printf '%02d:%02d' "$m" "$s")
fi

[ -z "$desc" ] && desc="(no description)"
label="$desc"
[ -n "$tag" ] && label="$label [$tag]"

# 色は tmux.conf の配色に合わせる（accent 緑=#a6e3a1 / text=#cdd6f4 / 区切り=grey）。
printf '#[fg=#a6e3a1]▶ #[fg=#cdd6f4]%s #[fg=#a6e3a1]%s #[fg=#6c7086]│ ' "$label" "$el"
