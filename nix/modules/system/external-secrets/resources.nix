{
  "external-secrets.io".v1.ClusterSecretStore.infisical = {
    metadata = {
      name = "infisical";
      annotations = {
        "argocd.argoproj.io/sync-wave" = "10";
      };
    };
    spec = {
      provider.infisical = {
        auth = {
          universalAuthCredentials = {
            clientId = {
              key = "clientId";
              namespace = "external-secrets";
              name = "infisical-credentials";
            };
            clientSecret = {
              key = "clientSecret";
              namespace = "external-secrets";
              name = "infisical-credentials";
            };
          };
        };
        secretsScope = {
          projectSlug = "homelab";
          environmentSlug = "prod";
        };
      };
    };
  };
}
