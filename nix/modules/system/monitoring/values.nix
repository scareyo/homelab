{ lib }:
{
  victoria-metrics-k8s-stack = {
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
          api_url = "https://id.vegapunk.cloud/api/oidc/user(info|INFO)";
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
      plugins = [
        "victoriametrics-logs-datasource"
      ];
      datasources = {
        "victoria-logs.yaml" = {
          apiVersion = 1;
          datasources = [
            {
              name = "VictoriaLogs";
              type = "victoriametrics-logs-datasource";
              url = "http://vlsingle-victoria-logs:9428";
              jsonData = let
                rule = let
                  base = field: value: level: {
                    field = field; value = value; level = level; operator = "regex"; enabled = true;
                  };
                in label: level: [
                  (base "message.level" label level)
                  (base "_msg" (lib.strings.concatStrings ["^(" label ")\\s"]) level)
                  (base "_msg" (lib.strings.concatStrings ["level=(" label ")"]) level)
                  (base "_msg" (lib.strings.concatStrings ["\\s(" label ")\\s"]) level)
                  (base "_msg" (lib.strings.concatStrings ["\\t(" label ")\\t"]) level)

                  # warning -> WARNING -> W: for log patterns matching W1234
                  (base "_msg" (lib.strings.concatStrings ["^" (builtins.substring 0 1 (lib.toUpper level)) "\\d{4}\\s"]) level)
                ];
              in {
                logLevelRules = []
                  ++ rule "crit|critical|CRIT|CRITICAL"           "critical"
                  ++ rule "warn|warning|WARN|WARNING"             "warning"
                  ++ rule "err|error|ERR|ERROR"                   "error"
                  ++ rule "info|information|audit|cluster|I|INFO" "info"
                  ++ rule "debug|DEBUG"                           "debug"
                  ++ rule "trace|TRACE"                           "trace";
              };
            }
          ];
        };
      };
    };
    victoria-metrics-operator = {
      admissionWebhooks.certManager.enabled = true;
    };
  };
  victoria-logs-collector = {
    remoteWrite = [
      { url = "http://vlsingle-victoria-logs:9428"; }
    ];
    timeField = [
      "message.time"
      "message.ts"
      "message.timestamp"
      "m"
      "time"
      "ts"
      "timestamp"
    ];
    msgField = [
      "message.msg"
      "message"
      "msg"
    ];
  };
}
