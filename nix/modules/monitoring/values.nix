{ lib }:

{
  grafana = {
    "grafana.ini" = {
      server.root_url = "https://grafana.vegapunk.cloud";
      "auth.generic_oauth" = {
        enabled = true;
        client_id = "$__file{/etc/secrets/oauth/client_id}";
        client_secret = "$__file{/etc/secrets/oauth/client_secret}";
        scopes = "openid email profile groups";
        auth_url = "https://id.vegapunk.cloud/authorize";
        token_url = "https://id.vegapunk.cloud/api/oidc/token";
        api_url = "https://id.vegapunk.cloud/api/oidc/userinfo";
        role_attribute_path = lib.concatStrings [
          "contains(groups, 'grafana_admin') && 'Admin' || "
          "contains(groups, 'grafana_editor') && 'Editor' || "
          "contains(groups, 'grafana_viewer') && 'Viewer' "
        ];
      };
    };
    env = {
      GF_SECURITY_DISABLE_INITIAL_ADMIN_CREATION = true;
    };
    extraSecretMounts = [
      {
        name = "oidc";
        secretName = "oidc-grafana";
        defaultMode = 0440;
        mountPath = "/etc/secrets/oauth";
        readOnly = true;
      }
    ];
  };
  victoria-metrics-operator = {
    admissionWebhooks.certManager.enabled = true;
  };
}
