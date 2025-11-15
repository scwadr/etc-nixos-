{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.kiyurica.proxy-server.enable = lib.mkEnableOption "proxy server";
  options.kiyurica.proxy-server.listen-host = lib.mkOption {
    type = lib.types.str;
    default = "0.0.0.0";
    description = "Host address to listen on";
  };
  options.kiyurica.proxy-server.port = lib.mkOption {
    type = lib.types.port;
    default = 1080;
    description = "Port to listen on";
  };
  options.kiyurica.proxy-server.external-interfaces = lib.mkOption {
    type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
    description = "External network interface(s) to use";
  };
  options.kiyurica.proxy-server.username = lib.mkOption {
    type = lib.types.str;
    default = "dante-user";
    description = "Username for authentication";
  };

  config = lib.mkIf config.kiyurica.proxy-server.enable (
    let
      externalInterfaces =
        if builtins.isList config.kiyurica.proxy-server.external-interfaces then
          config.kiyurica.proxy-server.external-interfaces
        else
          [ config.kiyurica.proxy-server.external-interfaces ];
      externalConfig = lib.concatMapStringsSep "\n        " (
        iface: "external: ${iface}"
      ) externalInterfaces;
    in
    {
      services.dante = {
        enable = true;
        config = ''
          logoutput: syslog

          internal: ${config.kiyurica.proxy-server.listen-host} port = ${toString config.kiyurica.proxy-server.port}
          ${externalConfig}

          clientmethod: none
          socksmethod: username

          client pass {
            from: 0.0.0.0/0 to: 0.0.0.0/0
            log: error
          }

          socks pass {
            from: 0.0.0.0/0 to: 0.0.0.0/0
            log: error
          }
        '';
      };

      users.users.${config.kiyurica.proxy-server.username} = {
        isSystemUser = true;
        group = "dante-users";
        description = "Dante proxy user";
      };

      users.groups.dante-users = { };

      systemd.services.dante.serviceConfig = {
        IPAddressDeny = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "169.254.0.0/16"
          "127.0.0.0/8"
        ];

        CapabilityBoundingSet = "";
        LockPersonality = "true";
        MemoryDenyWriteExecute = "yes";
        NoNewPrivileges = "true";
        PrivateDevices = "true";
        PrivateTmp = true;
        PrivateUsers = "true";
        ProtectClock = "true";
        ProtectControlGroups = "true";
        ProtectHome = "true";
        ProtectHostname = "true";
        ProtectKernelLogs = "true";
        ProtectKernelModules = "true";
        ProtectKernelTunables = "true";
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = "true";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = "yes";
        RestrictRealtime = "true";
        RestrictSUIDSGID = "true";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
        ];
      };

      networking.firewall.allowedTCPPorts = [ config.kiyurica.proxy-server.port ];
    }
  );
}
