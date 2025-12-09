{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kiyurica.firefox.enable = lib.mkEnableOption "firejailed Firefox";

  config = lib.mkIf config.kiyurica.firefox.enable {
    programs.firejail = {
      enable = true;
      wrappedBinaries = {
        firefox = {
          executable = "/run/current-system/sw/bin/firefox";
          profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
        };
      };
    };
    programs.firefox = {
      enable = true;
    };

    environment.etc."firejail/firefox.local".text = ''
      # Enable native notifications
      dbus-user.talk org.freedesktop.Notifications
      # Allow screensharing under Wayland
      dbus-user.talk org.freedesktop.portal.Desktop
    '';
  };
}
