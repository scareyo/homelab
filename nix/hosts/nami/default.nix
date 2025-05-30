{ pkgs, ... }:

{
  imports = [
    ../../modules/system/hypervisor.nix
    ../../modules/authentik

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

  networking.firewall.allowedTCPPorts = [ 80 443];

  services.caddy = {
    enable = true;
    virtualHosts."sso.int.scarey.me:80".extraConfig = ''
      reverse_proxy http://localhost:9000
    '';
  };

  homelab.authentik = {
    enable = true;
    user = "podman";
  };

  #virtualisation.containers.enable = true;
  #virtualisation.podman.enable = true;

  #virtualisation.oci-containers.backend = "podman";
  #virtualisation.oci-containers.containers = {
  #  #authentik-server = {
  #  #  image = "ghcr.io/goauthentik/server:2025.4.1";
  #  #  cmd = [
  #  #    "server"
  #  #  ];
  #  #  environment = {
  #  #    AUTHENTIK_SECRET_KEY = "1234567890";
  #  #    AUTHENTIK_REDIS__HOST = "redis";
  #  #    AUTHENTIK_POSTGRESQL__HOST = "postgresql";
  #  #    AUTHENTIK_POSTGRESQL__USER = "authentik";
  #  #    AUTHENTIK_POSTGRESQL__NAME = "authentik";
  #  #    AUTHENTIK_POSTGRESQL__PASSWORD = "test123";
  #  #  };
  #  #  volumes = [
  #  #    "./media:/media"
  #  #    "./custom-templates:/templates"
  #  #  ];
  #  #  ports = [
  #  #    "9000:9000"
  #  #    "9443:9443"
  #  #  ];
  #  #  dependsOn = [
  #  #    "postgresql"
  #  #    "redis"
  #  #  ];
  #  #  podman.user = "authentik";
  #  #};
  #  #authentik-worker = {
  #  #  image = "ghcr.io/goauthentik/server:2025.4.1";
  #  #  cmd = [
  #  #    "worker"
  #  #  ];
  #  #  environment = {
  #  #    AUTHENTIK_SECRET_KEY = "1234567890";
  #  #    AUTHENTIK_REDIS__HOST = "redis";
  #  #    AUTHENTIK_POSTGRESQL__HOST = "postgresql";
  #  #    AUTHENTIK_POSTGRESQL__USER = "authentik";
  #  #    AUTHENTIK_POSTGRESQL__NAME = "authentik";
  #  #    AUTHENTIK_POSTGRESQL__PASSWORD = "test123";
  #  #  };
  #  #  volumes = [
  #  #    "./media:/media"
  #  #    "./certs:/certs"
  #  #    "./custom-templates:/templates"
  #  #  ];
  #  #  ports = [
  #  #    "9000:9000"
  #  #    "9443:9443"
  #  #  ];
  #  #  dependsOn = [
  #  #    "postgresql"
  #  #    "redis"
  #  #  ];
  #  #  podman.user = "authentik";
  #  #};
  #  #postgresql = {
  #  #  image = "public.ecr.aws/docker/library/postgres:16-alpine";
  #  #  environment = {
  #  #    POSTGRES_USER = "authentik";
  #  #    POSTGRES_PASSWORD = "test123";
  #  #    POSTGRES_DB = "authentik";
  #  #  };
  #  #  volumes = [
  #  #    "authentik-pgsql:/var/lib/postgresql/data"
  #  #  ];
  #  #  extraOptions = [
  #  #    "--health-cmd='pg_isready -d $POSTGRES_DB -U $POSTGRES_USER'"
  #  #  ];
  #  #  podman.user = "authentik";
  #  #};
  #  #redis = {
  #  #  image = "public.ecr.aws/docker/library/redis:7-alpine";
  #  #  cmd = [
  #  #    "--save 60 1"
  #  #    "--loglevel warning"
  #  #  ];
  #  #  volumes = [
  #  #    "authentik-redis:/data"
  #  #  ];
  #  #  extraOptions = [
  #  #    "--health-cmd='redis-cli ping | grep PONG'"
  #  #  ];
  #  #  podman.user = "authentik";
  #  #};
  #};
  
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
