# tmux 設定（設定ファイル主体のため programs.tmux は使わず raw を参照）。
{ ... }:

{
  xdg.configFile."tmux/tmux.conf".source = ./tmux.conf;

  # tmux-sessionizer（zoxide + fzf の Bash 実装）。tmux.conf から M-f で呼ぶ。
  xdg.configFile."tmux/sessionizer.sh" = {
    source = ./sessionizer.sh;
    executable = true;
  };
}
