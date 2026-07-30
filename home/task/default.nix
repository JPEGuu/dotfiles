# dstask: lightweight task management.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.dstask
  ];

  # tmux popup and aliases both call the shared picker by command name.
  home.sessionPath = [
    "$HOME/.config/task"
  ];

  xdg.configFile."task/dstask-fzf.sh" = {
    source = ./dstask-fzf.sh;
    executable = true;
  };

  programs.zsh.shellAliases = {
    dn = "dstask-fzf.sh note";
    ds = "dstask-fzf.sh start";
    dp = "dstask-fzf.sh stop";
    dd = "dstask-fzf.sh done";
    dr = "dstask-fzf.sh resume";
    dl = "dstask-fzf.sh link";
  };
}
