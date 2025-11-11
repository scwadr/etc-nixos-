{
  config,
  specialArgs,
  ...
}:
{
  imports = [ ./home-manager.nix ];

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
        github-copilot-cli
      ];
    };
}
