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
        chart = charts.prometheus-community.kube-prometheus-stack;
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
