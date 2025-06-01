{ config, pkgs, ... }:

{
  imports = [
    ../../modules/system

    ../../modules/authentik
    ../../modules/newt
    ../../modules/sops

    ./hardware-configuration.nix
  ]; 

  networking.hostName = "nami";

  virtualisation = {
    containers.enable = true;
    podman.enable = true;
  };

  users.users.podman = {
    isNormalUser = true;
    description = "Podman user";
    autoSubUidGidRange = true;
    linger = true;
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.caddy = {
    enable = true;
    virtualHosts."sso.int.scarey.me:80".extraConfig = ''
      reverse_proxy http://localhost:9000
    '';
  };

  homelab.sops = {
    enable = true;
    secrets = [
      {
        name = "newt.env";
        file = ../../../sops/newt.env;
        format = "dotenv";
        owner = config.users.users.podman.name;
        group = config.users.users.podman.group;
      }
      {
        name = "authentik.env";
        file = ../../../sops/authentik.env;
        format = "dotenv";
        owner = config.users.users.podman.name;
        group = config.users.users.podman.group;
      }
      {
        name = "restic.env";
        file = ../../../sops/restic.env;
        format = "dotenv";
        owner = config.users.users.podman.name;
        group = config.users.users.podman.group;
      }
    ];
  };

  homelab.authentik = {
    enable = true;
    env = "/run/secrets/authentik.env";
  };

  homelab.newt = {
    enable = true;
    env = "/run/secrets/newt.env";
  };
    
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
