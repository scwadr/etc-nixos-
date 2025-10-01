{
  config,
  pkgs,
  lib,
  nixpkgs-unstable,
  ...
}:
{
  imports = [ ./home-manager.nix ];

  options.kiyurica.desktop.niri.enable = lib.mkEnableOption "Niri-based";

  config = lib.mkIf config.kiyurica.desktop.niri.enable {
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
        ./home-manager/graphical.nix
      ];
    };

    programs.niri.enable = true;
    environment.etc."greetd/environments".text = "/run/current-system/sw/bin/niri";
    environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
    services.systemd-lock-handler.enable = true;
  };
}
