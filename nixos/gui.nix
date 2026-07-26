# GUI 環境（niri / Wayland）のシステムレベル設定。
#
# my.gui.enable を true にしたホストでのみ有効化される（既定 false）。
# このモジュールは flake.nix で全ホストに読み込むが、WSL では enable=false の
# ままなので config ブロックは空になり、一切影響しない。
#
# 検証メモ: 各オプション名は nixos-unstable (nixpkgs rev 9ae611a / 26.11) の
# ソースに対して確認済み。
#   - programs.niri.enable        … nixos/modules/programs/wayland/niri.nix
#   - services.displayManager.ly  … nixos/modules/services/display-managers/ly.nix
#                                    （services.ly ではない点に注意）
#   - services.pipewire / pulseaudio.enable=false / sound.enable は廃止
#   - fonts.packages / nerd-fonts.<name> 名前空間（旧 nerdfonts.override は廃止）
{ config, lib, pkgs, ... }:

{
  options.my.gui.enable = lib.mkEnableOption "niri ベースの GUI (Wayland) 環境";

  config = lib.mkIf config.my.gui.enable {
    # --- niri（スクロール式タイリング Wayland コンポジタ） ---
    # programs.niri.enable は以下を自動構成する:
    #   - wayland セッション登録 (services.displayManager.sessionPackages = [ niri ])
    #   - xdg.portal（gnome + gtk バックエンド、スクリーンショット等）
    #   - security.polkit.enable = true（ただし polkit エージェント本体は別途必要）
    #   - programs.dconf / services.graphical-desktop / gnome-keyring
    programs.niri.enable = true;

    # --- ログインマネージャー: ly（TUI） ---
    # オプションパスは services.displayManager.ly.*（旧 services.ly ではない / 26.x）。
    services.displayManager = {
      ly = {
        enable = true;
        settings = {
          animation = "matrix"; # "none" | "doom" | "matrix" 等
          clock = "%c"; # strftime 形式。"" で非表示
        };
      };
      # ly が niri セッションを既定で選択するように（.desktop の basename "niri"）
      defaultSession = "niri";
    };

    # --- グラフィック（Wayland コンポジタの動作に必須） ---
    # 旧 hardware.opengl.enable は hardware.graphics.enable にリネーム済み（24.11+）。
    hardware.graphics.enable = true;

    # --- 音声（PipeWire） ---
    security.rtkit.enable = true; # PipeWire がリアルタイム優先度を取得するため
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true; # PulseAudio 互換層（pavucontrol 等が参照）
    };
    # Noctalia のバッテリー/電源プロファイル/Bluetooth ウィジェット用。
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    hardware.bluetooth.enable = true;
    # PipeWire の pulse エミュレーションと衝突するため旧 PulseAudio デーモンは無効
    # （sound.enable は廃止 / hardware.pulseaudio は services.pulseaudio にリネーム）。
    services.pulseaudio.enable = false;

    # --- polkit 認証エージェント ---
    # niri モジュールは security.polkit を有効化するがエージェント本体は入れないため、
    # graphical-session 上で polkit-gnome を起動する。
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # swaylock がパスワード照合できるよう PAM サービスを定義（空セットで可）
    security.pam.services.swaylock = { };

    # --- フォント（GUI でのみ必要。WSL では Windows 側が描画するため不要） ---
    fonts = {
      # 旧 fonts.fonts は fonts.packages にリネーム済み。
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono # メイン等幅（family: "JetBrainsMono Nerd Font"）
        nerd-fonts.symbols-only # アイコン補完（family: "Symbols Nerd Font"）
        noto-fonts-cjk-sans # 日本語ゴシック（"Noto Sans CJK JP"）
        noto-fonts-cjk-serif # 日本語明朝（"Noto Serif CJK JP"）
        noto-fonts-color-emoji # 絵文字（"Noto Color Emoji"）
        noto-fonts # ラテン基本（"Noto Sans" / "Noto Serif"）
      ];
      fontconfig.defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "Noto Sans CJK JP" ];
        sansSerif = [ "Noto Sans" "Noto Sans CJK JP" ];
        serif = [ "Noto Serif" "Noto Serif CJK JP" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # --- システムレベルで必要な GUI 補助パッケージ ---
    environment.systemPackages = with pkgs; [
      polkit_gnome # 上の systemd user service が参照
      # X11 アプリ対応。niri 25.08+ は PATH 上にあれば DISPLAY を export し on-demand 起動。
      xwayland-satellite
    ];
  };
}
