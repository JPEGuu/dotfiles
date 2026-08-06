# zk: Markdown notebook and journal settings.
# Home Manager creates ~/notes/.zk as the notebook marker. Local .zk/config.toml
# is intentionally not generated; global ~/.config/zk/config.toml is the source
# of truth for this setup.
{ config, lib, ... }:

{
  programs.zk = {
    enable = true;
    settings = {
      note = {
        filename = "{{format-date now '%Y%m%d%H%M'}}-{{title}}";
        extension = "md";
        template = "default.md";
        language = "ja";
      };

      format.markdown = {
        "link-format" = "wiki";
        hashtags = true;
      };

      group.daily = {
        paths = [ "journal/daily" ];
        note = {
          filename = "{{format-date now '%Y-%m-%d'}}";
          template = "daily.md";
        };
      };

      alias = {
        daily = ''zk --notebook-dir "${config.home.homeDirectory}/notes" --working-dir "${config.home.homeDirectory}/notes" new --no-input "${config.home.homeDirectory}/notes/journal/daily"'';
        edit-recent = ''zk --notebook-dir "${config.home.homeDirectory}/notes" --working-dir "${config.home.homeDirectory}/notes" edit --interactive --sort modified-'';
      };
    };
  };

  home.sessionVariables.ZK_NOTEBOOK_DIR = "${config.home.homeDirectory}/notes";

  home.activation.ensureZkNotebookDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/notes/.zk" "${config.home.homeDirectory}/notes/journal/daily"
  '';

  xdg.configFile."zk/templates/default.md".source = ./templates/default.md;
  xdg.configFile."zk/templates/daily.md".source = ./templates/daily.md;
  xdg.configFile."zk/zk-popup.sh" = {
    source = ./zk-popup.sh;
    executable = true;
  };

  # Unified notes management panel (tmux M-m). Mirrors the timetrack `t()`
  # panel: list -> open/add/delete/daily via fzf keybindings.
  xdg.configFile."zk/notes-panel.zsh".text = ''
    _zk_panel_list() {
      emulate -L zsh
      zk --notebook-dir "$HOME/notes" list --quiet --no-pager --format jsonl --sort modified \
        | jq -r '[.absPath,
            ("  " + .title + "  [" + ((.tags // []) | join(",")) + "]  " + (.modified | .[0:10]))] | @tsv'
    }

    _zk_panel_do() {
      emulate -L zsh
      # NOTE: do not name this `path` — zsh ties `path` to `$PATH`, so
      # assigning a note path to it clobbers PATH and breaks nvim lookup.
      local verb=$1 notepath=$2 ans title
      case $verb in
        open)
          [[ -n $notepath ]] || return 1
          ''${EDITOR:-nvim} "$notepath"
          ;;
        delete)
          [[ -n $notepath ]] || return 1
          read "ans?削除しますか? $notepath [y/N] "
          [[ $ans == (y|Y) ]] && rm -f -- "$notepath"
          ;;
        add)
          read "title?title: "
          [[ -z $title ]] && return 0
          zk --notebook-dir "$HOME/notes" --working-dir "$HOME/notes" new --title "$title"
          ;;
        daily)
          zk daily
          ;;
        *)
          print -u2 "unknown verb: $verb"
          return 1
          ;;
      esac
    }

    zn() {
      emulate -L zsh
      local panel="''${XDG_CONFIG_HOME:-$HOME/.config}/zk/notes-panel.zsh"
      local reload="zsh -c 'source \"\$1\"; _zk_panel_list' zk-panel ''${(q)panel}"
      _zk_panel_list | fzf --ansi --delimiter='\t' --with-nth=2.. \
        --prompt='notes> ' --height=100% --reverse \
        --preview='zk list --quiet --format full --limit 1 {1} 2>/dev/null || cat {1}' \
        --preview-window='right:55%:wrap' \
        --header-first \
        --header=$'Enter:開く/編集  C-a:新規  C-d:削除  C-i:日記  Esc:終了' \
        --bind "enter:execute(zsh -c 'source \"\$1\"; _zk_panel_do open \"\$2\"' zk-panel ''${(q)panel} {1})+reload($reload)" \
        --bind "ctrl-a:execute(zsh -c 'source \"\$1\"; _zk_panel_do add' zk-panel ''${(q)panel})+reload($reload)" \
        --bind "ctrl-d:execute(zsh -c 'source \"\$1\"; _zk_panel_do delete \"\$2\"' zk-panel ''${(q)panel} {1})+reload($reload)" \
        --bind "ctrl-i:execute(zsh -c 'source \"\$1\"; _zk_panel_do daily' zk-panel ''${(q)panel})+reload($reload)" \
        >/dev/null
    }
  '';

  programs.zsh.shellAliases = {
    zkd = "zk daily";
    zke = "zk edit-recent";
  };

  programs.zsh.initContent = lib.mkAfter ''
    source ''${XDG_CONFIG_HOME:-$HOME/.config}/zk/notes-panel.zsh
  '';
}
