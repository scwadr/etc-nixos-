{ config, lib, ... }:
{
  imports = [ ./home-manager.nix ];

  kiyurica.home-manager.enable = true;

  services.syncthing = {
    enable = true;
    dataDir = "/home/kiyurica";
    openDefaultPorts = true; # not include web
    configDir = "/home/kiyurica/.config/syncthing";
    user = "kiyurica";
    group = "users";
    guiAddress = "127.0.0.1:8384";

    overrideDevices = true;
    overrideFolders = true;
    settings.devices = {
      "minato".id = "6ROWFH5-WMAJ5JO-TDJA22O-AOQYET7-SCRIF6T-Q6A3HMA-VP7263N-JMIIRQO";
      "suzaku".id = "5DES2YX-7XTFTK7-SGP4VRD-KVS5DAO-VPMXEC7-RDAGYKE-QDRZDDD-NS5ANAZ";
      "inaho".id = "THGLO7L-TJ4Q4UF-BE2ZERW-AXHKKSY-CAZTUJY-W5T24JT-VC7WCTR-GJPPMAH";
      "DELL-Maker-Faire".id = "CLRJ7EG-DOL5KYF-B4U5NTI-74J647Y-QITQVKQ-OYPZP5N-KBCTLMR-6R7L3AI";
      "minamo".id = "6P75Z4H-VY2VBWM-NE3FYVF-UY7PMCV-6KOOQHD-MHB3AWR-BDAVEJI-6GBLIQA";
    };
    settings.folders = {
      "inaba" = {
        id = "pugdv-kmejz";
        path = "/home/kiyurica/inaba";
        devices = [
          "makura"
          "minato"
          "yagoto"
          "suzaku"
          "inaho"
          "minamo"
        ];
        versioning.type = "staggered";
        versioning.params = {
          cleanInterval = "86400";
          maxAge = "31536000";
        };
      };
      "geofront" = {
        id = "e2kwg-rebhd";
        label = "GF-01";
        path = "/home/kiyurica/inaba/geofront";
        devices = [
          "makura"
          "yagoto"
          "suzaku"
          "inaho"
          "Pixel 6a"
          "minamo"
        ];
        versioning.type = "trashcan";
        versioning.params.cleanoutDays = "0"; # never
        ignoreDelete = true;
      };
      "hisame" = {
        id = "fzewo-z2hef";
        label = "hisame";
        path = "/home/kiyurica/inaba/hisame";
        devices = [
          "yagoto"
          "suzaku"
        ];
      };
      "3d-spool" = {
        id = "qcj7e-rviwt";
        label = "3D spool";
        path = "/home/kiyurica/3d-spool";
        devices = [
          "suzaku"
          "inaho"
          "strawberry"
        ];
      };
    };
  };

  # Syncthing
  networking.firewall = {
    allowedUDPPorts = [
      22000
      21027
    ];
    allowedTCPPorts = [
      22
      22000
    ];
  };

  home-manager.users.kiyurica =
    { lib, ... }:
    {
      home.file."${config.services.syncthing.settings.folders.inaba.path}/.stignore".text =
        lib.mkDefault ''
          .direnv
          /hisame
          __pycache__
        '';
    };

  systemd.services.syncthing = {
    environment.GOMAXPROCS = "1";
    serviceConfig = {
      CPUWeight = 20;
      CPUQuota = "50%";
      IOWeight = 20;
    };
  };
}
