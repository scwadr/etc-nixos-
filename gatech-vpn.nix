{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./home-manager.nix ];

  options.kiyurica.gatech-vpn.enable = lib.mkEnableOption "Georgia Tech (GlobalProtect) VPN via proxy";
  options.kiyurica.gatech-vpn.user =
    with lib;
    with types;
    mkOption {
      description = "Linux user the VPN proxy will run as";
      default = "gatech-vpn";
      type = str;
    };
  options.kiyurica.gatech-vpn.group =
    with lib;
    with types;
    mkOption {
      description = "Linux group the VPN proxy will run as";
      default = "gatech-vpn";
      type = str;
    };
  options.kiyurica.gatech-vpn.server =
    with lib;
    with types;
    mkOption {
      description = "VPN server";
      default = "vpn.gatech.edu";
      type = str;
    };
  options.kiyurica.gatech-vpn.gateway =
    with lib;
    with types;
    mkOption {
      description = "gateway to use";
      default = "DC Gateway";
      example = "NI Gateway";
      type = str;
    };
  options.kiyurica.gatech-vpn.username =
    with lib;
    with types;
    mkOption {
      description = "username for VPN";
      example = "gburdell3";
      type = str;
    };
  options.kiyurica.gatech-vpn.password-file =
    with lib;
    with types;
    mkOption {
      description = "path to file containing the password that is encrypted for systemd";
      type = path;
    };
  options.kiyurica.gatech-vpn.socks-port =
    with lib;
    with types;
    mkOption {
      description = "run SOCKS5 proxy server on this port";
      type = port;
      default = 11080;
    };

  config = lib.mkIf config.kiyurica.gatech-vpn.enable {
    users.groups.${config.kiyurica.gatech-vpn.group} = { };
    users.users.${config.kiyurica.gatech-vpn.user} = {
      isSystemUser = true;
      description = "Georgia Tech VPN";
      group = config.kiyurica.gatech-vpn.group;
    };
    systemd.services.gatech-vpn = {
      description = "Georgia Tech VPN";
      path = with pkgs; [
        openconnect
        ocproxy
      ];
      # confinement = {
      #   enable = true;
      #   packages = with pkgs; [
      #     openconnect
      #     ocproxy
      #   ];
      # };
      enableStrictShellChecks = true;
      serviceConfig = {
        LoadCredentialEncrypted = "password:${config.kiyurica.gatech-vpn.password-file}";
        User = config.kiyurica.gatech-vpn.user;

        # CapabilityBoundingSet = "";
        # RestrictNamespaces = "yes";
        # RestrictAddressFamilies = [
        #   "AF_UNIX"
        #   "AF_INET"
        #   "AF_INET6"
        # ];
        # SystemCallFilter = [
        #   "@system-service"
        # ];
        # PrivateDevices = "true";
        # PrivateTmp = true;
        # ProtectClock = "true";
        # ProtectControlGroups = "true";
        # ProtectHome = "true";
        # ProtectHostname = "true";
        # ProtectKernelLogs = "true";
        # ProtectKernelModules = "true";
        # ProtectKernelTunables = "true";
        # ProtectProc = "invisible";
        # ProtectSystem = "strict";
        # RemoveIPC = "true";
        # NoNewPrivileges = "true";
      };
      script = ''
        set -eu

        export PASSWORD_FILE_PATH="$CREDENTIALS_DIRECTORY/password"
        { cat "$PASSWORD_FILE_PATH"; echo 'push1'; } | \
        openconnect \
          --verbose \
          --protocol=gp \
          --user='${config.kiyurica.gatech-vpn.username}' \
          --authgroup='${config.kiyurica.gatech-vpn.gateway}' \
          --script-tun --script 'ocproxy -D ${builtins.toString config.kiyurica.gatech-vpn.socks-port}' \
          '${config.kiyurica.gatech-vpn.server}'
      '';
      wantedBy = [ "multi-user.target" ];
    };
  };
}
