{ lib }:

{
  kube-prometheus-stack = {
    alertmanager.alertmanagerSpec = {
      useExistingSecret = true;
      configSecret = "alertmanager";
    };
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
      additionalDataSources = [
        {
          name = "loki";
          type = "loki";
          url = "http://loki-gateway.monitoring";
        }
      ];
    };
    prometheus = {
      prometheusSpec = {
        podMonitorSelectorNilUsesHelmValues = false;
        serviceMonitorSelectorNilUsesHelmValues = false;
      };
    };
  };

  loki = {
    global = {
      extraArgs = ["-config.expand-env=true"];
      extraEnvFrom = [
        { configMapRef.name = "loki"; }
        { secretRef.name = "loki"; }
      ];
    };
    loki = {
      auth_enabled = false;
      schemaConfig.configs = [
        {
          from = "2024-04-01";
          store = "tsdb";
          object_store = "s3";
          schema = "v13";
          index = {
            prefix = "loki_index_";
            period = "24h";
          };
        }
      ];
      ingester.chunk_encoding = "snappy";
      querier.max_concurrent = 4;
      pattern_ingester.enabled = true;
      limits_config = {
        allow_structured_metadata = true;
        volume_enabled = true;
      };
      storage = {
        s3 = {
          endpoint = ''''${BUCKET_HOST}'';
          insecure = true;
          s3ForcePathStyle = true;
        };
        bucketNames = {
          chunks = ''''${BUCKET_NAME}'';
          ruler = ''''${BUCKET_NAME}'';
          admin = ''''${BUCKET_NAME}'';
        };
      };
    };

    deploymentMode = "SimpleScalable";

    backend.replicas = 2;
    read.replicas = 2;
    write.replicas = 3;
  };
}
