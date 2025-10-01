{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./home-manager.nix ];

  options.kiyurica.desktop.niri.enable = lib.mkEnableOption "Niri-based";

  config = lib.mkIf config.kiyurica.desktop.niri.enable {
    home-manager.users.kiyurica = {
      imports = [
        ./home-manager/graphical.nix
      ];
    };

    programs.uwsm = {
      enable = true;
      waylandCompositors.theniri = {
        # becomes theniri-uwsm.desktop
        binPath = "/run/current-system/sw/bin/niri";
        prettyName = "Niri";
        comment = "Niri-based session managed by UWSM";
      };
    };
    programs.niri.enable = true;
    environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
    services.systemd-lock-handler.enable = true;
  };
}
