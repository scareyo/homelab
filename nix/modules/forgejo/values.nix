{
  gitea = {
    admin.existingSecret = "admin";
    config = {
      server.ROOT_URL = "https://dev.vegapunk.cloud";
      server.DOMAIN = "dev.vegapunk.cloud";
      server.SSH_DOMAIN = "dev.vegapunk.cloud";
      service.DISABLE_REGISTRATION = true;

      oauth2_client.ENABLE_AUTO_REGISTRATION = true;
      oauth2_client.UPDATE_AVATAR = true;

      database = {
        DB_TYPE = "postgres";
      };

      webhook.ALLOWED_HOST_LIST = "ci.vegapunk.cloud";
    };
    oauth = [
      {
        name = "Pocket ID";
        provider = "openidConnect";
        existingSecret = "oidc";
        autoDiscoverUrl = "https://id.vegapunk.cloud/.well-known/openid-configuration";
        iconUrl = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pocket-id-light.svg";
        scopes = "email profile";
      }
    ];
    additionalConfigFromEnvs = [
      {
        name = "FORGEJO__DATABASE__HOST";
        valueFrom.secretKeyRef = {
          key = "host";
          name = "forgejo-app";
        };
      }
      {
        name = "FORGEJO__DATABASE__NAME";
        valueFrom.secretKeyRef = {
          key = "dbname";
          name = "forgejo-app";
        };
      }
      {
        name = "FORGEJO__DATABASE__USER";
        valueFrom.secretKeyRef = {
          key = "username";
          name = "forgejo-app";
        };
      }
      {
        name = "FORGEJO__DATABASE__PASSWD";
        valueFrom.secretKeyRef = {
          key = "password";
          name = "forgejo-app";
        };
      }
    ];
  };
}
