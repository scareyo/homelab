{
  database = {
    type = "postgresql";
  };
  env = {
    TZ = "America/New_York";
    AUTH_PROVIDERS = "credentials,oidc";
    AUTH_OIDC_ISSUER = "https://id.vegapunk.cloud";
    AUTH_OIDC_CLIENT_NAME = "Pocket ID";
  };
  envSecrets = {
    dbCredentials = {
      existingSecret = "homarr-app";
      dbUrlKey = "uri";
    };
  };
}
