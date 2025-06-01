{ config, pkgs, ... }:

{
  imports = [
    ../../modules/system/hypervisor.nix

    ../../modules/authentik
    ../../modules/newt
    ../../modules/sops

    ./hardware-configuration.nix
  ]; 

  networking = {
    hostName = "nami";
    useDHCP = false;
    bridges = {
      "br0" = {
        interfaces = [ "eno1" ];
      };
    };
    interfaces.br0.useDHCP = true;
    interfaces.eno1.useDHCP = false;
  };

  virtualisation.containers.enable = true;
  virtualisation.podman.enable = true;

  users.users.podman = {
    isSystemUser = true;
    description = "Podman system user";
    group = "podman";
    home = "/home/podman";
    shell = pkgs.bash;
    createHome = true;
    autoSubUidGidRange = true;
    linger = true;
  };
  users.groups.podman = {};

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.caddy = {
    enable = true;
    virtualHosts."sso.int.scarey.me:80".extraConfig = ''
      reverse_proxy http://localhost:9000
    '';
  };

  homelab.sops = {
    enable = true;
    file = ../../../sops/newt.env;
    format = "dotenv";
    owner = config.users.users.podman.name;
    group = config.users.users.podman.group;
    secrets = [ "newt.env" ];
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
