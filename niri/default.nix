{
  config,
  pkgs,
  lib,
  nixpkgs-unstable,
  ...
}:
{
  imports = [
    ../home-manager.nix
    ./uwsm.nix
    ./set-default.nix
  ];

  options.kiyurica.desktop.niri.enable = lib.mkEnableOption "a Niri-based desktop environment";
  options.kiyurica.desktop.niri.enableUWSM = lib.mkEnableOption "UWSM support";
  options.kiyurica.desktop.niri.default = lib.mkOption {
    default = false;
    type = lib.types.bool;
    description = "set this as the default desktop environment";
  };
  options.kiyurica.desktop.niri.config = lib.mkOption {
    type = lib.types.lines;
    description = "Niri config file contents";
  };

  config = lib.mkIf config.kiyurica.desktop.niri.enable {
    kiyurica.desktop.niri.config = builtins.readFile ./config.kdl;
    nixpkgs.overlays = [
      (
        final: prev:
        let
          unstable = import nixpkgs-unstable { system = prev.system; };
        in
        {
          niri = unstable.niri;
        }
      )
    ];
    home-manager.users.kiyurica = {
      imports = [
        ../home-manager/graphical.nix
        {
          imports = [
            ../home-manager/fuzzel.nix
            ../home-manager/wlsunset.nix
            ../home-manager/wayland.nix
          ];
          config = {
            xdg.configFile."niri/config.kdl" = {
              text = config.kiyurica.desktop.niri.config;
            };
            systemd.user.services.swaybg = {
              Unit = {
                Description = "swaywm background";
                PartOf = [ "graphical-session.target" ];
                StartLimitIntervalSec = 350;
                StartLimitBurst = 30;
              };
              Service = {
                ExecStart = "${pkgs.swaybg}/bin/swaybg -mfill -i ${../wallpapers/takamatsu.jpg}";
                Restart = "on-failure";
                RestartSec = 3;
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };
            systemd.user.services.import-environment = {
              Unit = {
                Description = "Import environment variables to systemd";
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                Type = "oneshot";
                ExecStart = "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
                RemainAfterExit = true;
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };

            # GTK input method configuration for fcitx
            home.file.".gtkrc-2.0".text = ''
              gtk-im-module="fcitx"
            '';

            xdg.configFile."gtk-3.0/settings.ini".text = ''
              [Settings]
              gtk-im-module=fcitx
            '';

            xdg.configFile."gtk-4.0/settings.ini".text = ''
              [Settings]
              gtk-im-module=fcitx
            '';
          };
        }
      ];
    };

    programs.niri.enable = true;
    environment.etc."greetd/environments".text = "/run/current-system/sw/bin/niri";
    environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
    services.systemd-lock-handler.enable = true;
  };
}
