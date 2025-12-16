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

      templates.httpRoute.grafana = {
        hostname = "grafana.vegapunk.cloud";
        serviceName = "vm-grafana";
      };

      templates.httpRoute.vmagent = {
        hostname = "vm.vegapunk.cloud";
        serviceName = "vmagent-vm-victoria-metrics-k8s-stack";
        servicePort = 8429;
      };

      templates.externalSecret.oidc-grafana = {
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
