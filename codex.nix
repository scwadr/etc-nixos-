{
  pkgs,
  config,
  specialArgs,
  ...
}:
{
  imports = [ ./home-manager.nix ];
  environment.systemPackages = [
    pkgs.github-copilot-cli
  ];

  home-manager.users.kiyurica =
    let
      systemconfig = config;
    in
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          codex = specialArgs.nixpkgs-unstable.legacyPackages.${prev.system}.codex;
        })
        (final: prev: {
          github-copilot-cli = specialArgs.nixpkgs-unstable.legacyPackages.${prev.system}.github-copilot-cli;
        })
      ];
      home.packages = with pkgs; [
        codex
      ];
    };
}
