{ config, inputs, lib, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  options = {
    homelab.newt.enable = lib.mkEnableOption "Newt";
    homelab.newt.user = lib.mkOption {
      type = lib.types.str;
      description = "User to run Newt";
      default = "podman";
    };
    homelab.newt.network = lib.mkOption {
      type = lib.types.str;
      description = "Network to run Newt";
      default = "services";
    };
    homelab.newt.env = lib.mkOption {
      type = lib.types.str;
      description = "Path to env file";
    };
  };

  config = lib.mkIf config.homelab.newt.enable {
    home-manager.users.${config.homelab.newt.user} = let
      env = config.homelab.newt.env;
      network = config.homelab.newt.network;
    in { pkgs, config, lib, ... }: {
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];
      systemd.user.startServices = "sd-switch";

      virtualisation.quadlet.autoEscape = true;

      virtualisation.quadlet.containers = {
        newt = {
          autoStart = true;
          serviceConfig = {
            RestartSec = "10";
            Restart = "always";
          };
          containerConfig = {
            image = "docker.io/fosrl/newt";
            userns = "keep-id";
            environments = {
              PANGOLIN_ENDPOINT = "https://pangolin.scarey.me";
            };
            environmentFiles = [ env ];
            networks = [ config.virtualisation.quadlet.networks.${network}.ref ];
          };
        };
      };

      virtualisation.quadlet.networks.${network} = {};

      home.stateVersion = "24.11";
    };
  };
}
