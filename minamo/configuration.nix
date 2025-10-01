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
    ../secureboot.nix
    specialArgs.disko.nixosModules.disko
    ../autoUpgrade-git.nix
    ../tpm.nix
    ../common.nix
    ../syncthing.nix
    ../vlc.nix
    ../adb.nix
    ../virt.nix
  ];

  boot.initrd.systemd.enable = true;

  boot.initrd.availableKernelModules = [
    "nvme"
  ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

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

  system.stateVersion = "25.05";

  networking.hostName = "minamo";
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/New_York";
  services.getty.autologinUser = "kiyurica";

  security.sudo.wheelNeedsPassword = false;

  autoUpgrade.directFlake = true;
  boot.initrd.systemd.emergencyAccess = true; # or set to a password hash
}
