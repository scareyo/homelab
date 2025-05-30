{ config, inputs, lib, pkgs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  options = {
    homelab.authentik.enable = lib.mkEnableOption "Authentik";
    homelab.authentik.user = lib.mkOption {
      type = lib.types.str;
      description = "User to run Authentik";
    };
  };

  config = lib.mkIf config.homelab.authentik.enable {
    home-manager.users.${config.homelab.authentik.user} = { pkgs, config, lib, ... }: let 
      dataDir = "/home/podman/authentik";
    in {
      imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];
      systemd.user.startServices = "sd-switch";

      home.activation.createDataDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p "${dataDir}/certs"
        mkdir -p "${dataDir}/custom-templates"
        mkdir -p "${dataDir}/media"
      '';

      virtualisation.quadlet.containers = {
        authentik-postgresql = {
          autoStart = true;
          serviceConfig = {
            RestartSec = "10";
            Restart = "always";
          };
          containerConfig = {
            image = "public.ecr.aws/docker/library/postgres:16-alpine";
            userns = "auto";
            environments = {
              POSTGRES_USER = "authentik";
              POSTGRES_PASSWORD = "test123";
              POSTGRES_DB = "authentik";
            };
            volumes = [
              "authentik-pgsql:/var/lib/postgresql/data:U"
            ];
            networks = [ config.virtualisation.quadlet.networks.authentik.ref ];
            healthCmd = "pg_isready -d $POSTGRES_DB -U $POSTGRES_USER";
          };
        };
        authentik-redis = {
          autoStart = true;
          serviceConfig = {
            RestartSec = "10";
            Restart = "always";
          };
          containerConfig = {
            image = "public.ecr.aws/docker/library/redis:7-alpine";
            userns = "auto";
            exec = [
              "--save 60 1"
              "--loglevel warning"
            ];
            volumes = [
              "authentik-redis:/data:U"
            ];
            networks = [ config.virtualisation.quadlet.networks.authentik.ref ];
            healthCmd = "redis-cli ping | grep PONG";
          };
        };
        authentik-server = {
          autoStart = true;
          serviceConfig = {
            RestartSec = "10";
            Restart = "always";
          };
          unitConfig = {
            Requires = [ "authentik-redis" "authentik-pgsql" ];
            After = [ "authentik-redis" "authentik-pgsql" ];
          };
          containerConfig = {
            image = "ghcr.io/goauthentik/server:2025.4.1";
            userns = "auto";
            exec = "server";
            environments = {
              AUTHENTIK_SECRET_KEY = "abcdef1234567890";
              AUTHENTIK_REDIS__HOST = "authentik-redis";
              AUTHENTIK_POSTGRESQL__HOST = "authentik-postgresql";
              AUTHENTIK_POSTGRESQL__USER = "authentik";
              AUTHENTIK_POSTGRESQL__NAME = "authentik";
              AUTHENTIK_POSTGRESQL__PASSWORD = "test123";
            };
            volumes = [
              "${dataDir}/media:/media:U"
              "${dataDir}/custom-templates:/templates:U"
            ];
            publishPorts = [
              "9000:9000"
              "9443:9443"
            ];
            networks = [ config.virtualisation.quadlet.networks.authentik.ref ];
          };
        };
        authentik-worker = {
          autoStart = true;
          serviceConfig = {
            RestartSec = "10";
            Restart = "always";
          };
          unitConfig = {
            Requires = [ "authentik-redis" "authentik-pgsql" ];
            After = [ "authentik-redis" "authentik-pgsql" ];
          };
          containerConfig = {
            image = "ghcr.io/goauthentik/server:2025.4.1";
            userns = "auto";
            exec = "worker";
            environments = {
              AUTHENTIK_SECRET_KEY = "abcdef1234567890";
              AUTHENTIK_REDIS__HOST = "authentik-redis";
              AUTHENTIK_POSTGRESQL__HOST = "authentik-postgresql";
              AUTHENTIK_POSTGRESQL__USER = "authentik";
              AUTHENTIK_POSTGRESQL__NAME = "authentik";
              AUTHENTIK_POSTGRESQL__PASSWORD = "test123";
            };
            volumes = [
              "${dataDir}/media:/media:U"
              "${dataDir}/custom-templates:/templates:U"
              "${dataDir}/certs:/certs:U"
            ];
            networks = [ config.virtualisation.quadlet.networks.authentik.ref ];
          };
        };
      };

      virtualisation.quadlet.networks.authentik = {};

      home.stateVersion = "24.11";
    };
  };
}
