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
        filename = "{{format-date now '%Y%m%d%H%M'}}-{{slug title}}";
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
  xdg.configFile."zk/templates/task.md".source = ./templates/task.md;
  xdg.configFile."zk/zk-popup.sh" = {
    source = ./zk-popup.sh;
    executable = true;
  };

  programs.zsh.shellAliases = {
    zkd = "zk daily";
    zke = "zk edit-recent";
  };
}
