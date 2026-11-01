let
  images = {
    ntfy = {
      image = "docker.io/binwiederhier/ntfy";
      version = "v2.34.0";
    };
  };
in {
  flake.modules.apps.ntfy = { lib, ... }: let
    namespace = "ntfy";
    project = "development";
  in {
    applications.ntfy = {
      inherit namespace project;

      createNamespace = true;

      templates.app.ntfy = {
        workload = {
          inherit (images.ntfy) image version;
          args = [ "serve" ];
          port = 8080;
          env = {
            NTFY_BASE_URL = "https://ntfy.vegapunk.cloud";
            NTFY_LISTEN_HTTP = ":8080";
            NTFY_BEHIND_PROXY = "true";
            NTFY_UPSTREAM_BASE_URL = "https://ntfy.sh";
            NTFY_CACHE_FILE = "/var/lib/ntfy/cache.db";
            NTFY_AUTH_FILE = "/var/lib/ntfy/user.db";
            NTFY_AUTH_DEFAULT_ACCESS = "deny-all";
            NTFY_ENABLE_LOGIN = "true";
          };
          envSecret = "ntfy";
        };
        persistence.data = {
          type = "pvc";
          path = "/var/lib/ntfy";
          config.size = "1Gi";
        };
        route = {};
      };

      templates.externalSecret.ntfy.secrets = {
        NTFY_AUTH_USERS.key = "/ntfy/AUTH_USERS";
        NTFY_AUTH_TOKENS.key = "/ntfy/AUTH_TOKENS";
      };
    };
  };
}
