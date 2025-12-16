{
  "cert-manager.io".v1.ClusterIssuer.letsencrypt-staging = {
    metadata = {
      name = "letsencrypt-staging";
      annotations = {
        "argocd.argoproj.io/sync-wave" = "10";
      };
    };
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory";
        email = "sam@scarey.me";
        privateKeySecretRef.name = "letsencrypt-staging";
        solvers = [
          {
            dns01.cloudflare.apiTokenSecretRef = {
              name = "cloudflare";
              key = "token";
            };
          }
        ];
      };
    };
  };

  "cert-manager.io".v1.ClusterIssuer.letsencrypt-production = {
    metadata = {
      name = "letsencrypt-production";
      annotations = {
        "argocd.argoproj.io/sync-wave" = "10";
      };
    };
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory";
        email = "sam@scarey.me";
        privateKeySecretRef.name = "letsencrypt-production";
        solvers = [
          {
            dns01.cloudflare.apiTokenSecretRef = {
              name = "cloudflare";
              key = "token";
            };
          }
        ];
      };
    };
  };
}
