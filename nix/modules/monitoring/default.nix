{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.monitoring;
in
{
  options = {
    vegapunk.monitoring.enable = lib.mkEnableOption "Enable monitoring stack";
  };

  config = lib.mkIf cfg.enable {
    applications.monitoring = {
      namespace = "monitoring";
      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.kube-prometheus-stack = {
        chart = charts.kube-prometheus-stack;
        values = (import ./values.nix { inherit lib; }).kube-prometheus-stack;
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

      helm.releases.oauth2-proxy-prometheus = {
        chart = charts.oauth2-proxy;
        values = {
          config = {
            existingSecret = "oidc-prometheus";
            configFile = ''
              upstreams="http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
              email_domains="*"
              redirect_url="https://prometheus.vegapunk.cloud/oauth2/callback"
              provider="oidc"
              scope="openid email profile groups"
              oidc_issuer_url="https://id.vegapunk.cloud"
              provider_display_name="Prometheus"
              custom_sign_in_logo="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prometheus.svg"
              banner="Prometheus"
              insecure_oidc_allow_unverified_email="true"
            '';
          };
        };
      };

      templates.httpRoute.grafana = {
        hostname = "grafana.vegapunk.cloud";
        serviceName = "kube-prometheus-stack-grafana";
      };

      templates.httpRoute.prometheus = {
        hostname = "prometheus.vegapunk.cloud";
        serviceName = "oauth2-proxy-prometheus";
      };

      templates.externalSecret.oidc-grafana = {
        keys = [
          { source = "/monitoring/GRAFANA_OIDC_CLIENT_ID"; dest = "client_id"; }
          { source = "/monitoring/GRAFANA_OIDC_CLIENT_SECRET"; dest = "client_secret"; }
        ];
      };

      templates.externalSecret.oidc-prometheus = {
        keys = [
          { source = "/monitoring/PROMETHEUS_OIDC_CLIENT_ID"; dest = "client-id"; }
          { source = "/monitoring/PROMETHEUS_OIDC_CLIENT_SECRET"; dest = "client-secret"; }
          { type = "password"; length = 32; dest = "cookie-secret"; }
        ];
      };

      resources = {
        namespaces.monitoring = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
        deployments.oauth2-proxy-prometheus = {
          spec = {
            template.metadata.annotations = lib.mkForce null;
          };
        };
      };
    };
  };
}
