{ config, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "inaho";
        "netbios name" = "inaho";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "inaba" = {
        "path" = config.services.syncthing.settings.folders."inaba".path;
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };
}
