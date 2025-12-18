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
              jsonData = {
                logLevelRules = [
                  { field = "message.level"; value = "(critical|CRITICAL)"; level = "critical"; operator = "regex"; enabled = true; }
                  { field = "message.level"; value = "(error|ERROR)"; level = "error"; operator = "regex"; enabled = true; }
                  { field = "message.level"; value = "(warn|WARN)"; level = "warning"; operator = "regex"; enabled = true; }
                  { field = "message.level"; value = "(info|INFO)"; level = "info"; operator = "regex"; enabled = true; }
                  { field = "message.level"; value = "(debug|DEBUG)"; level = "debug"; operator = "regex"; enabled = true; }
                  { field = "message.level"; value = "(trace|TRACE)"; level = "trace"; operator = "regex"; enabled = true; }

                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(CRITICAL|CRIT)(?:\b|\]|\)|>|:|-)"; level = "critical"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(ERROR|ERR)(?:\b|\]|\)|>|:|-)"; level = "error"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(WARN|WARNING)(?:\b|\]|\)|>|:|-)"; level = "warning"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(INFO|INFORMATION)(?:\b|\]|\)|>|:|-)"; level = "info"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(DEBUG)(?:\b|\]|\)|>|:|-)"; level = "debug"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(TRACE)(?:\b|\]|\)|>|:|-)"; level = "trace"; operator = "regex"; enabled = true; }

                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(CRITICAL|CRIT)(?:\b|\]|\)|>|:|-)"; level = "critical"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(ERROR|ERR)(?:\b|\]|\)|>|:|-)"; level = "error"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(WARN|WARNING)(?:\b|\]|\)|>|:|-)"; level = "warning"; operator = "regex"; enabled = true; }
                  { field = "_msg"; value = "(^|[\s\[{(<]|level=)(INFO|INFORMATION|info|information)(?=\b|\]|[>)|:|-)"; level = "info"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(DEBUG)(?:\b|\]|\)|>|:|-)"; level = "debug"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "(?i)(?:^|\b|\[|\(|<|level=)(TRACE)(?:\b|\]|\)|>|:|-)"; level = "trace"; operator = "regex"; enabled = true; }

                  #{ field = "_msg"; value = "level=(critical|CRITICAL)"; level = "critical"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "level=(error|ERROR)"; level = "error"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "level=(warn|WARN)"; level = "warning"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "level=(info|INFO)"; level = "info"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "level=(debug|DEBUG)"; level = "debug"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "level=(trace|TRACE)"; level = "trace"; operator = "regex"; enabled = true; }

                  #{ field = "_msg"; value = "^(critical|CRITICAL)"; level = "critical"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "^(error|ERROR)"; level = "error"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "^(warn|WARN)"; level = "warning"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "^audit"; level = "info"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "^cluster"; level = "info"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "^(info|INFO)"; level = "info"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "^(debug|DEBUG)"; level = "debug"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "^(trace|TRACE)"; level = "trace"; operator = "regex"; enabled = true; }

                  #{ field = "_msg"; value = "\t(warn|WARN)\t"; level = "warn"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "\t(error|ERROR)\t"; level = "error"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "\t(warn|WARN)\t"; level = "warning"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "\t(info|INFO)\t"; level = "info"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "\t(debug|DEBUG)\t"; level = "debug"; operator = "regex"; enabled = true; }
                  #{ field = "_msg"; value = "\t(trace|TRACE)\t"; level = "trace"; operator = "regex"; enabled = true; }
                ];
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
