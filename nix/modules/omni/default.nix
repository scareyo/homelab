{ config, inputs, lib, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  options = {
    homelab.omni.enable = lib.mkEnableOption "Omni";
    homelab.omni.user = lib.mkOption {
      type = lib.types.str;
      description = "User to run Omni";
      default = "podman";
    };
    homelab.omni.network = lib.mkOption {
      type = lib.types.str;
      description = "Network to run Omni";
      default = "services";
    };
    homelab.omni.env = lib.mkOption {
      type = lib.types.str;
      description = "Path to env file";
    };
  };

  config = lib.mkIf config.homelab.omni.enable {
    home-manager.users.${config.homelab.omni.user} = let
      #env = config.homelab.omni.env;
      network = config.homelab.omni.network;
    in { pkgs, config, lib, ... }: {
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];
      systemd.user.startServices = "sd-switch";

      virtualisation.quadlet.autoEscape = true;

      virtualisation.quadlet.containers = {
        omni = {
          autoStart = true;
          serviceConfig = {
            RestartSec = "10";
            Restart = "always";
          };
          containerConfig = {
            image = "ghcr.io/siderolabs/omni:v0.50.1";
            userns = "keep-id";
            exec = [
              "--account-id=$(uuidgen)"
              "--name=onprem-omni"
              "--private-key-source=file:///omni.asc"
              "--event-sink-port=8091"
              "--bind-addr=0.0.0.0:443"
              "--siderolink-api-bind-addr=0.0.0.0:8090"
              "--k8s-proxy-bind-addr=0.0.0.0:8100"
              "--advertised-api-url=https://omni.scarey.me/"
              "--siderolink-api-advertised-url=https://omni.scarey.me:8090/"
              "--siderolink-wireguard-advertised-addr=10.10.20.51:50180"
              "--advertised-kubernetes-proxy-url=https://omni.scarey.me:8100/"
              "--auth-saml-enabled=true"
              "--auth-saml-url=https://sso.scarey.me/application/saml/omni/metadata/"
            ];
            environments = {
            };
            #environmentFiles = [ env ];
            networks = [ config.virtualisation.quadlet.networks.${network}.ref ];
          };
        };
      };

      virtualisation.quadlet.networks.${network} = {};

      home.stateVersion = "24.11";
    };
  };
}
