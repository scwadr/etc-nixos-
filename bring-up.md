# Bring Up a New System

## Start a Live System

Start a live ISO from https://nixos.org/download/ and then `sudo passwd nixos` so we can SSH into the machine.

## Flash The Disk

Download the `disko-config.nix` file for the system beforehand.

Note! **The following command destroys preexisting data!**

```
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./hostname/disko-config.nix
```

## Install The System

```
sudo nixos-install --flake github:nyiyui/etc-nixos#minamo
```
