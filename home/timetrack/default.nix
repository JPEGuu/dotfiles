{ pkgs, lib, ... }:

{
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      confirmation = false;
      nag = "";
      "news.version" = "3.4.0";
      "report.list.sort" = "project+/,start-,urgency-";
      "report.list.columns" = "id,project,description,tags,start.active";
      "report.list.labels" = "ID,project,description,tag,active";
    };
  };

  home.packages = [
    pkgs.timewarrior
    pkgs.python3
  ];

  home.file.".local/share/task/hooks/on-modify.timewarrior" = {
    source = ./on-modify.timewarrior;
    executable = true;
  };

  home.file.".local/bin/twrep" = {
    source = ./twrep;
    executable = true;
  };

  xdg.configFile."timetrack/timetrack-popup.sh" = {
    source = ./timetrack-popup.sh;
    executable = true;
  };

  xdg.configFile."timetrack/panel.zsh".text = ''
    # fzf をプロセス置換で駆動し $? を直接取る（パイプだと pipestatus が不安定で、
    # ESC の終了コードを取りこぼすことがある）。$status は zsh 予約変数なので ec を使う。
    _tt_pick_project() {
      emulate -L zsh
      local out ec
      # 中断は ESC(130) のみ。fzf は新規入力/一致なしで exit 1 を返すが、
      # --print-query で入力値は取れているので新規 project として採用する。
      out=$(fzf --print-query --prompt='project (empty=none)> ' --height=40% --reverse \
            < <(task _unique project 2>/dev/null))
      ec=$?
      (( ec == 130 )) && return 1
      print -r -- "''${out##*$'\n'}"
    }

    _tt_pick_kind() {
      emulate -L zsh
      local out ec
      # 中断は ESC(130) のみ。fzf は新規入力/一致なしで exit 1 を返すが、
      # --print-query で入力値は取れているので新規 tag として採用する。
      out=$(fzf --print-query --prompt='tag (empty=none)> ' --height=40% --reverse \
            < <(task status.any: _unique tags 2>/dev/null))
      ec=$?
      (( ec == 130 )) && return 1
      print -r -- "''${out##*$'\n'}"
    }

    _tt_pick_task() {
      emulate -L zsh
      local out ec
      out=$(fzf --delimiter='\t' --with-nth=2.. --prompt='task> ' --height=70% --reverse \
                --preview='task {1} information' --preview-window='right:52%:wrap' \
            < <(task ''${1:-status:pending} export 2>/dev/null \
                  | jq -r '.[] | [(.id|tostring),
                      ((if .start then "▶ " else "  " end) + (.project // "-")
                       + "  [" + ((.tags // []) | join(",")) + "]  " + .description)] | @tsv'))
      ec=$?
      (( ec == 130 )) && return 1
      [[ -z $out ]] && return 1
      print -r -- "''${out%%$'\t'*}"
    }

    _tt_stop_active() {
      emulate -L zsh
      local -a active
      active=("''${(@f)$(task +ACTIVE _ids 2>/dev/null)}")
      [[ -n ''${active[1]} ]] && task "''${active[@]}" stop >/dev/null 2>&1
    }

    _tt_link() {
      emulate -L zsh
      local target=$1 uuid summary note rel nb="$HOME/notes"
      uuid=$(task _get "$target".uuid) || return 1
      summary=$(task _get "$target".description)
      [[ -d $nb/.zk ]] || { print -u2 "zk notebook 未初期化: $nb"; return 1; }
      note=$(zk new --notebook-dir "$nb" --working-dir "$nb" --no-input \
               --title "$summary" --extra "task=$uuid" --print-path) || return 1
      rel=''${note#"$nb"/}
      task "$target" annotate "related-note: $rel"
      ''${EDITOR:-nvim} "$note"
    }

    _tt_add() {
      emulate -L zsh
      local desc="$*" proj kind out id
      [[ -z $desc ]] && read "desc?description: "
      [[ -z $desc ]] && return 1
      proj=$(_tt_pick_project) || return 1
      kind=$(_tt_pick_kind) || return 1
      local -a args=(add "$desc")
      [[ -n $proj ]] && args+=(project:"$proj")
      [[ -n $kind ]] && args+=(+"$kind")
      out=$(task "''${args[@]}" 2>&1) || { print -u2 -- "$out"; return 1; }
      id=$(print -r -- "$out" | grep -oP 'Created task \K[0-9]+')
      [[ -n $id ]] || { print -u2 "task add failed"; return 1; }
      print -r -- "$id"
    }

    ta() {
      emulate -L zsh
      local id
      id=$(_tt_add "$@") || return 1
      _tt_stop_active
      task "$id" start
    }

    tn() {
      emulate -L zsh
      _tt_add "$@" >/dev/null
    }

    _tt_panel_filter_file() {
      emulate -L zsh
      print -r -- "''${XDG_RUNTIME_DIR:-/tmp}/tt-panel-donefilter"
    }

    _tt_panel_emit() {
      emulate -L zsh
      local icon=$1 color=$2 jq_filter=$3 reset=$'\033[0m'
      [[ -z $color ]] && reset=""
      jq -r --arg icon "$icon" --arg color "$color" --arg reset "$reset" "$jq_filter"'
        | .[]
        | select(.uuid != null)
        | "\(.uuid)\t\($color)\($icon)\($reset)  \(.project // "-")  [\((.tags // []) | join(","))]  \(.description // "")"
      '
    }

    _tt_panel_list() {
      emulate -L zsh
      local green=$'\033[32m' dim=$'\033[2m'
      local -a done_filter=(status:completed)
      [[ -e $(_tt_panel_filter_file) ]] || done_filter+=(end.after:today)

      task +ACTIVE status:pending export 2>/dev/null \
        | _tt_panel_emit "▶" "$green" '.'
      task status:pending -ACTIVE export 2>/dev/null \
        | _tt_panel_emit "○" "" 'sort_by(.urgency // 0) | reverse'
      task "''${done_filter[@]}" export 2>/dev/null \
        | _tt_panel_emit "✓" "$dim" 'sort_by(.end // "") | reverse'
    }

    _tt_panel_do() {
      emulate -L zsh
      local verb=$1 uuid=$2 task_status start id file
      case $verb in
        toggle)
          [[ -n $uuid ]] || return 1
          task_status=$(task _get "$uuid".status 2>/dev/null) || return 1
          start=$(task _get "$uuid".start 2>/dev/null || true)
          if [[ $task_status == completed ]]; then
            task "$uuid" modify status:pending >/dev/null || return 1
            _tt_stop_active
            task "$uuid" start >/dev/null
          elif [[ -n $start ]]; then
            task "$uuid" stop >/dev/null
          else
            _tt_stop_active
            task "$uuid" start >/dev/null
          fi
          ;;
        done)
          [[ -n $uuid ]] || return 1
          task "$uuid" done >/dev/null
          ;;
        edit)
          [[ -n $uuid ]] || return 1
          task "$uuid" edit
          ;;
        delete)
          [[ -n $uuid ]] || return 1
          task rc.confirmation=off "$uuid" delete >/dev/null
          ;;
        link)
          [[ -n $uuid ]] || return 1
          _tt_link "$uuid"
          ;;
        toggle-filter)
          file=$(_tt_panel_filter_file)
          if [[ -e $file ]]; then
            rm -f -- "$file"
          else
            : > "$file"
          fi
          ;;
        add)
          _tt_add >/dev/null
          ;;
        add-start)
          id=$(_tt_add) || return 1
          _tt_stop_active
          task "$id" start
          ;;
        *)
          print -u2 "unknown verb: $verb"
          return 1
          ;;
      esac
    }

    t() {
      emulate -L zsh
      local panel="''${XDG_CONFIG_HOME:-$HOME/.config}/timetrack/panel.zsh"
      local reload="zsh -c 'source \"\$1\"; _tt_panel_list' tt-panel ''${(q)panel}"
      _tt_panel_list | fzf --ansi --multi --delimiter='\t' --with-nth=2.. \
        --prompt='timetrack> ' --height=100% --reverse \
        --preview='task {1} information' --preview-window='right:52%:wrap' \
        --header-first \
        --header=$'Enter:開始/停止  C-a:追加のみ  C-g:追加&Start  C-d:完了  C-e:編集\nC-x:削除  C-l:ノート  C-t:done表示切替  ↑↓ / C-j C-k:移動  Esc:終了' \
        --bind "enter:execute-silent(zsh -c 'source \"\$1\"; _tt_panel_do toggle \"\$2\"' tt-panel ''${(q)panel} {1})+reload($reload)" \
        --bind "ctrl-a:execute(zsh -c 'source \"\$1\"; _tt_panel_do add' tt-panel ''${(q)panel})+reload($reload)" \
        --bind "ctrl-g:execute(zsh -c 'source \"\$1\"; _tt_panel_do add-start' tt-panel ''${(q)panel})+reload($reload)" \
        --bind "ctrl-d:execute-silent(zsh -c 'source \"\$1\"; _tt_panel_do done \"\$2\"' tt-panel ''${(q)panel} {1})+reload($reload)" \
        --bind "ctrl-e:execute(zsh -c 'source \"\$1\"; _tt_panel_do edit \"\$2\"' tt-panel ''${(q)panel} {1})+reload($reload)" \
        --bind "ctrl-x:execute-silent(zsh -c 'source \"\$1\"; _tt_panel_do delete \"\$2\"' tt-panel ''${(q)panel} {1})+reload($reload)" \
        --bind "ctrl-l:execute(zsh -c 'source \"\$1\"; _tt_panel_do link \"\$2\"' tt-panel ''${(q)panel} {1})+reload($reload)" \
        --bind "ctrl-t:execute-silent(zsh -c 'source \"\$1\"; _tt_panel_do toggle-filter' tt-panel ''${(q)panel})+reload($reload)" \
        >/dev/null
    }

    tfix() {
      emulate -L zsh
      local range="''${1:-:day}" lines proj kind
      local -a ids retag
      lines=$(timew export "$range" | ~/.local/bin/twrep --list-unclassified \
              | fzf --multi --with-nth=2.. --prompt='unclassified> ' --height=60% --reverse) || return 1
      [[ -z $lines ]] && return 0
      ids=("''${(@f)$(print -r -- "$lines" | awk '{print "@"$1}')}")
      proj=$(_tt_pick_project) || return 1
      kind=$(_tt_pick_kind) || return 1
      retag=(retag "''${ids[@]}")
      [[ -n $proj ]] && retag+=("project:$proj")
      [[ -n $kind ]] && retag+=("tag:$kind")
      timew "''${retag[@]}" :yes
    }
  '';

  programs.zsh.initContent = lib.mkAfter ''
    source ''${XDG_CONFIG_HOME:-$HOME/.config}/timetrack/panel.zsh
  '';
}
