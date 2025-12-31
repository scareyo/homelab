{
  env.TZ = "America/New_York";
  envSecrets = {
    dbCredentials = {
      existingSecret = "homarr-app";
      dbUrlKey = "uri";
    };
  };
}
