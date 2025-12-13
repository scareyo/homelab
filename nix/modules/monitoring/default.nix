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

      helm.releases.vm = {
        chart = charts.victoria-metrics-k8s-stack;
        values = (import ./values.nix { inherit lib; });
      };

      #helm.releases.oauth2-proxy-prometheus = {
      #  chart = charts.oauth2-proxy;
      #  values = {
      #    config = {
      #      existingSecret = "oidc-prometheus";
      #      configFile = ''
      #        upstreams="http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
      #        email_domains="*"
      #        redirect_url="https://prometheus.vegapunk.cloud/oauth2/callback"
      #        provider="oidc"
      #        scope="openid email profile groups"
      #        oidc_issuer_url="https://id.vegapunk.cloud"
      #        provider_display_name="Prometheus"
      #        custom_sign_in_logo="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prometheus.svg"
      #        banner="Prometheus"
      #        insecure_oidc_allow_unverified_email="true"
      #      '';
      #    };
      #  };
      #};

      templates.httpRoute.grafana = {
        hostname = "grafana.vegapunk.cloud";
        serviceName = "vm-grafana";
      };

      #templates.httpRoute.prometheus = {
      #  hostname = "prometheus.vegapunk.cloud";
      #  serviceName = "oauth2-proxy-prometheus";
      #};

      templates.externalSecret.oidc-grafana = {
        keys = [
          { source = "/monitoring/GRAFANA_OIDC_CLIENT_ID"; dest = "client_id"; }
          { source = "/monitoring/GRAFANA_OIDC_CLIENT_SECRET"; dest = "client_secret"; }
        ];
      };

      #templates.externalSecret.oidc-prometheus = {
      #  keys = [
      #    { source = "/monitoring/PROMETHEUS_OIDC_CLIENT_ID"; dest = "client-id"; }
      #    { source = "/monitoring/PROMETHEUS_OIDC_CLIENT_SECRET"; dest = "client-secret"; }
      #    { type = "password"; length = 32; dest = "cookie-secret"; }
      #  ];
      #};

      resources = {
        namespaces.monitoring = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
        #deployments.oauth2-proxy-prometheus = {
        #  spec = {
        #    template.metadata.annotations = lib.mkForce null;
        #  };
        #};
        #"objectbucket.io".v1alpha1.ObjectBucketClaim.loki = {
        #  spec = {
        #    generateBucketName = "loki";
        #    storageClassName = "ceph-bucket";
        #  };
        #};
      };
    };
  };
}
