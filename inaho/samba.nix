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
      };
      "inaba" = {
        "path" = config.services.syncthing.settings.folders."inaba".path;
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "kiyurica";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
