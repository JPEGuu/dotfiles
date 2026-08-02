{ pkgs, lib, ... }:

let
  kinds = [
    "設計"
    "調査"
    "ドキュメント整備"
    "コーディング"
    "単体テスト"
    "結合テスト準備"
    "結合テスト消化"
    "環境整備"
    "MTG"
    "連絡・相談対応"
    "タスク管理"
    "工数管理等"
    "朝会・作業報告"
    "日報作成"
    "その他"
  ];
in
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

  programs.zsh.initContent = lib.mkAfter ''
    _tt_kinds() {
      printf '%s\n' ${lib.escapeShellArgs kinds}
    }

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
      # 中断は ESC(130) のみ。一致なし(exit 1)は「tag 無し」として空で通す。
      out=$(fzf --prompt='tag> ' --height=40% --reverse \
            < <({ print -r -- "(none)"; _tt_kinds }))
      ec=$?
      (( ec == 130 )) && return 1
      [[ $out == "(none)" ]] && { print -r -- ""; return 0; }
      print -r -- "$out"
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
      local id=$1 uuid summary note rel nb="$HOME/notes"
      uuid=$(task _get "$id".uuid) || return 1
      summary=$(task _get "$id".description)
      [[ -d $nb/.zk ]] || { print -u2 "zk notebook 未初期化: $nb"; return 1; }
      note=$(zk new --notebook-dir "$nb" --working-dir "$nb" --no-input \
               --title "$summary" --extra "task=$uuid" --print-path) || return 1
      rel=''${note#"$nb"/}
      task "$id" annotate "related-note: $rel"
      ''${EDITOR:-nvim} "$note"
    }

    ta() {
      emulate -L zsh
      local desc="$*" proj kind id
      [[ -z $desc ]] && read "desc?description: "
      [[ -z $desc ]] && return 1
      proj=$(_tt_pick_project) || return 1
      kind=$(_tt_pick_kind) || return 1
      local -a args=(add "$desc")
      [[ -n $proj ]] && args+=(project:"$proj")
      [[ -n $kind ]] && args+=(+"$kind")
      # add した新規タスクの ID を拾い、その場で start（実行中は 1 本に絞るため既存を止める）
      id=$(task "''${args[@]}" 2>&1 | grep -oP 'Created task \K[0-9]+')
      [[ -n $id ]] || { print -u2 "task add failed"; return 1; }
      _tt_stop_active
      task "$id" start
    }

    t() {
      emulate -L zsh
      local id act dep
      id=$(_tt_pick_task status:pending) || return 1
      [[ -z $id ]] && return 1
      act=$(printf '%s\n' start stop done edit depends link delete \
            | fzf --prompt='action> ' --height=40% --reverse) || return 1
      case $act in
        start)   _tt_stop_active; task "$id" start ;;
        stop)    task "$id" stop ;;
        done)    task "$id" done ;;
        edit)    task "$id" edit ;;
        delete)  task rc.confirmation=off "$id" delete ;;
        depends) dep=$(_tt_pick_task status:pending)
                 [[ -n $dep ]] && task "$id" modify depends:"$(task _get "$dep".uuid)" ;;
        link)    _tt_link "$id" ;;
      esac
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
}
