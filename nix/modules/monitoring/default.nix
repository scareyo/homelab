{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.monitoring;
in
{
  options = with lib; {
    scarey.k8s.monitoring.enable = mkEnableOption "Enable monitoring stack";
  };

  config = lib.mkIf cfg.enable {
    applications.monitoring = {
      namespace = "monitoring";
      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.kube-prometheus-stack = {
        chart = charts.prometheus-community.kube-prometheus-stack;
        values = {
          grafana = {
            "grafana.ini" = {
              server.root_url = "https://grafana.vegapunk.cloud";
              "auth.generic_oauth" = {
                enabled = true;
                client_id = "$__file{/etc/secrets/oauth/client_id}";
                client_secret = "$__file{/etc/secrets/oauth/client_secret}";
                scopes = "openid email profile groups";
                auth_url = "https://id.scarey.me/authorize";
                token_url = "https://id.scarey.me/api/oidc/token";
                api_url = "https://id.scarey.me/api/oidc/userinfo";
                role_attribute_path = lib.concatStrings [
                  "contains(groups, 'grafana_admin') && 'Admin' || "
                  "contains(groups, 'grafana_editor') && 'Editor' || "
                  "contains(groups, 'grafana_viewer') && 'Viewer' "
                ];
              };
            };
            extraSecretMounts = [
              {
                name = "oidc";
                secretName = "oidc";
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
        };
      };

      #helm.releases.loki = {
      #  chart = charts.grafana.loki;
      #  values = {
      #    global = {
      #      extraArgs = ["-config.expand-env=true"];
      #      extraEnvFrom = [
      #        { configMapRef.name = "loki-bucket"; }
      #        { secretRef.name = "loki-bucket"; }
      #      ];
      #    };
      #    loki = {
      #      auth_enabled = false;
      #      schemaConfig.configs = [
      #        {
      #          from = "2024-04-01";
      #          store = "tsdb";
      #          object_store = "s3";
      #          schema = "v13";
      #          index = {
      #            prefix = "loki_index_";
      #            period = "24h";
      #          };
      #        }
      #      ];
      #      ingester.chunk_encoding = "snappy";
      #      querier.max_concurrent = 4;
      #      pattern_ingester.enabled = true;
      #      limits_config = {
      #        allow_structured_metadata = true;
      #        volume_enabled = true;
      #      };
      #      storage = {
      #        s3 = {
      #          endpoint = ''''${BUCKET_HOST}'';
      #          insecure = true;
      #          s3ForcePathStyle = true;
      #        };
      #        bucketNames = {
      #          chunks = ''''${BUCKET_NAME}'';
      #          ruler = ''''${BUCKET_NAME}'';
      #          admin = ''''${BUCKET_NAME}'';
      #        };
      #      };
      #    };

      #    deploymentMode = "SimpleScalable";

      #    backend.replicas = 2;
      #    read.replicas = 2;
      #    write.replicas = 3;
      #  };
      #};

      templates.httpRoute.grafana = {
        hostname = "grafana.vegapunk.cloud";
        serviceName = "kube-prometheus-stack-grafana";
      };

      templates.externalSecret.oidc = {
        keys = [
          { source = "/monitoring/GRAFANA_OIDC_CLIENT_ID"; dest = "client_id"; }
          { source = "/monitoring/GRAFANA_OIDC_CLIENT_SECRET"; dest = "client_secret"; }
        ];
      };

      resources = {
        namespaces.monitoring = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
