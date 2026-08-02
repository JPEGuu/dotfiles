# tmux 設定（設定ファイル主体のため programs.tmux は使わず raw を参照）。
{ ... }:

{
  xdg.configFile."tmux/tmux.conf".source = ./tmux.conf;

  # tmux-sessionizer（zoxide + fzf の Bash 実装）。tmux.conf から M-f で呼ぶ。
  xdg.configFile."tmux/sessionizer.sh" = {
    source = ./sessionizer.sh;
    executable = true;
  };

  # Popup command wrapper. Keeps short-lived output and errors visible.
  xdg.configFile."tmux/popup-run.sh" = {
    source = ./popup-run.sh;
    executable = true;
  };

  # 実行中の timewarrior 区間をステータスバー右に表示する（tmux.conf の status-right から呼ぶ）。
  xdg.configFile."tmux/tmux-timetrack-status.sh" = {
    source = ./tmux-timetrack-status.sh;
    executable = true;
  };
}
