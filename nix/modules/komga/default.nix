{ config, lib, ... }:

let
  cfg = config.vegapunk.komga;
  namespace = "komga";
in
{
  options = {
    vegapunk.komga.enable = lib.mkEnableOption "Enable Komga";
  };

  config = lib.mkIf cfg.enable {
    applications.komga = {
      namespace = namespace;
      createNamespace = true;

      templates.app.komga = {
        inherit namespace;

        workload = {
          image = "ghcr.io/gotson/komga";
          version = "1.23.0";
          port = 25600;
          env = {
            KOMGA_OAUTH2ACCOUNTCREATION = "true";
            KOMGA_OIDCEMAILVERIFICATION = "false";
            SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_POCKETID_PROVIDER = "pocketid";
            SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_POCKETID_CLIENTID = {
              secretKeyRef = {
                key = "client-id";
                name = "oidc";
              };
            };
            SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_POCKETID_CLIENTSECRET = {
              secretKeyRef = {
                key = "client-secret";
                name = "oidc";
              };
            };
            SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_POCKETID_CLIENTNAME = "Pocket ID";
            SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_POCKETID_SCOPE = "openid,email,profile";
            SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_POCKETID_AUTHORIZATIONGRANTTYPE = "authorization_code";
            SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_POCKETID_REDIRECTURI = "{baseUrl}/{action}/oauth2/code/{registrationId}";
            SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_POCKETID_USERNAMEATTRIBUTE = "preferred_username";
            SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_POCKETID_ISSUERURI = "https://id.vegapunk.cloud";
          };
        };

        persistence = {
          config = {
            type = "pvc";
            path = "/config";
            config = {
              size = "4Gi";
            };
          };
          media = {
            type = "nfs";
            path = "/mnt/books";
            config = {
              server = "nami.int.scarey.me";
              path = "/mnt/nami-01/media/books";
              readOnly = false;
            };
          };
        };

        route = {};

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
        };
      };

      templates.externalSecret.oidc = {
        keys = [
          { source = "/komga/OIDC_CLIENT_ID"; dest = "client-id"; }
          { source = "/komga/OIDC_CLIENT_SECRET"; dest = "client-secret"; }
        ];
      };
    };
  };
}
