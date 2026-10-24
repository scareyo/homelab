let
  images = {
    jellyfin = {
      image = "ghcr.io/jellyfin/jellyfin";
      version = "12.3";
    };
    python = {
      image = "docker.io/library/python";
      version = "3.15-alpine";
    };
  };
in {
  flake.modules.apps.jellyfin = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.jellyfin = {
      inherit namespace project;

      templates.app.jellyfin = {
        workload = {
          inherit (images.jellyfin) image version;
          port = 8096;
          initContainers = [
            {
              name = "configure-sso";
              inherit (images.python) image version;
              command = [ "python3" "-c" (builtins.readFile ./jellyfin/configure-sso.py) ];
              envSecret = "jellyfin-oidc-credentials";
            }
          ];
        };
        persistence = {
          config = {
            type = "pvc";
            path = "/config";
            config = {
              size = "4Gi";
            };
          };
          cache = {
            type = "emptyDir";
            path = "/cache";
          };
          media = {
            type = "pvc";
            path = "/media";
            config = {
              existingClaim = "media";
            };
          };
        };
        route = {};
      };

      resources.pocketIDOIDCClients.jellyfin = {
        spec = {
          name = "Jellyfin";
          description = "The free software media system";
          launchUrl = "https://jellyfin.vegapunk.cloud";
          callbackUrls = [ "https://jellyfin.vegapunk.cloud/sso/OID/redirect/pocket-id" ];
          allowedUserGroups = [ { name = "jellyfin-user"; } { name = "jellyfin-admin"; } ];
        };
      };

      resources.pocketIDUserGroups.jellyfin-user = {};
      resources.pocketIDUserGroups.jellyfin-admin = {};

      templates.backup.jellyfin-daily = {
        restore = true;
        schedule = "0 6 * * *"; # At 06:00 daily
        ttl = "360h";           # 15 days
        selector."app.kubernetes.io/instance" = "jellyfin";
      };
    };
  };
}
