{ config, ... }:

{
  services.nfs.server = {
    enable = true;
    exports = ''
      ${
        config.services.syncthing.settings.folders."inaba".path
      } 100.64.0.0/10(rw,sync,no_subtree_check,fsid=0)
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
