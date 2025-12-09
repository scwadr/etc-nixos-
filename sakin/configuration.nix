{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:

{
  imports = [
    ./disko-config.nix
    ./impermanence.nix
    specialArgs.disko.nixosModules.disko
    ../common.nix
  ];

  boot.initrd.systemd.enable = true;

  boot.initrd.availableKernelModules = [
    "nvme"
  ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  users.users.kiyurica = {
    hashedPassword = "$y$j9T$lNSNPobnQX.GuwkdK4m.g0$/ivj88dtnxodfbZ1gmjn6AkabMh32qzsYjHr5i7jjD/";
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  system.stateVersion = "25.11";

  networking.hostName = "sakin";
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/New_York";

  services.udisks2.enable = true;

  # Enable mDNS for LAN hostname resolution
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  home-manager.users.kiyurica =
    { lib, ... }:
    {
      kiyurica.services.seekback.enable = true;
      kiyurica.services.log-window-titles.enable = true;
      kiyurica.icsUrlPath = config.age.secrets.icsUrlPath.path;
      kiyurica.waybarPosition = "right";
      programs.waybar.style = ''
        window#waybar {
          background-color: rgba(0, 0, 0, 1);
        }
      '';
      programs.niri.settings.layout.default-column-width.proportion = lib.mkForce 0.3;
    };
}
