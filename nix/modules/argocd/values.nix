{
  global.domain = "argocd.vegapunk.cloud";
  configs = {
    params."server.insecure" = true;
    cm = {
      "oidc.config" = ''
        name: SSO
        issuer: https://id.vegapunk.cloud
        clientID: $oauth_client_id
        clientSecret: $oauth_client_secret
        requestedScopes: ["openid", "profile", "email", "groups"]
      '';
      "resource.exclusions" = ''
        - apiGroups:
          - "velero.io"
          kinds:
          - Backup
          clusters:
          - "*"
      '';
      "accounts.readonly" = "apiKey";
    };
    rbac."policy.csv" = ''
      g, argocd_admin, role:admin
      g, argocd_viewer, role:readonly
    '';
  };
}
