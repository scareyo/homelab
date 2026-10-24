let
  images = {
    boxmon = {
      image = "ghcr.io/scareyo/boxmon";
      version = "8c1b6db";
    };
    busybox = {
      image = "docker.io/library/busybox";
      version = "1.38.0";
    };
  };
in {
  flake.modules.apps.boxmon = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.boxmon = {
      inherit namespace project;

      templates.app.boxmon = {
        workload = {
          inherit (images.boxmon) image version;
          port = 4000;
          env = {
            CATEGORIES = "radarr,sonarr";
            LANG = "C.UTF-8";
            PHX_HOST = "boxmon.vegapunk.cloud";
            PHX_PORT = "443";
            PHX_SERVER = "true";
            RELEASE_DISTRIBUTION = "none";
            DOWNLOAD_DIR = "/media/downloads";
          };
          envSecret = "boxmon";
          initContainers = [
            {
              name = "init-directories";
              inherit (images.busybox) image version;
              command = [ "mkdir" "-p" "/media/downloads" "/media/shows" "/media/movies" ];
            }
          ];
        };
        persistence.media = {
          type = "pvc";
          path = "/media";
          config = {
            existingClaim = "media";
          };
        };
        route = {};
      };

      templates.externalSecret.boxmon = {
        secrets.QBIT_URL.key = "/boxmon/QBIT_URL";
        secrets.QBIT_API_KEY.key = "/boxmon/QBIT_API_KEY";
        secrets.HTTP_URL.key = "/boxmon/HTTP_URL";
        secrets.HTTP_USER.key = "/boxmon/HTTP_USER";
        secrets.HTTP_PASS.key = "/boxmon/HTTP_PASS";
        secrets.REMOTE_ROOT.key = "/boxmon/REMOTE_ROOT";
        passwords.RELEASE_COOKIE = {};
        passwords.SECRET_KEY_BASE = { length = 64; };
      };

      resources.agentgatewayPolicies.boxmon.spec = {
        targetRefs = [
          { group = "gateway.networking.k8s.io"; kind = "HTTPRoute"; name = "boxmon"; }
        ];
        traffic.transformation.request.set = [ { name = "x-forwarded-proto"; value = "request.scheme"; } ];
      };
    };
  };
}
