{
  config,
  lib,
  specialArgs,
  ...
}:
{
  options.kiyurica.ollama.enableServer = lib.mkEnableOption "ollama server";

  config = lib.mkIf config.kiyurica.ollama.enableServer {
    nixpkgs.overlays = [
      (final: prev: {
        ollama = specialArgs.nixpkgs-unstable.legacyPackages.${prev.system}.ollama;
      })
    ];
    services.ollama = {
      enable = true;
      loadModels = [
        "llama3.2"
        "nomic-embed-text"
        "qwen3:8b"
        "qwen2.5-coder:7b"
      ];
      host = "0.0.0.0";
    };
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
      config.services.ollama.port
    ];
  };
}
