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
        values = (import ./values.nix { inherit lib; }).victoria-metrics-k8s-stack;
      };

      helm.releases.vl-collector = {
        chart = charts.victoria-logs-collector;
        values = (import ./values.nix { inherit lib; }).victoria-logs-collector;
      };

      templates.httpRoute.grafana = {
        hostname = "grafana.vegapunk.cloud";
        serviceName = "vm-grafana";
      };

      templates.httpRoute.vmagent = {
        hostname = "vmagent.vegapunk.cloud";
        serviceName = "vmagent-vm-victoria-metrics-k8s-stack";
        servicePort = 8429;
      };

      templates.httpRoute.vm = {
        hostname = "vm.vegapunk.cloud";
        serviceName = "vmsingle-vm-victoria-metrics-k8s-stack";
        servicePort = 8428;
      };

      templates.httpRoute.vl = {
        hostname = "vl.vegapunk.cloud";
        serviceName = "vlsingle-victoria-logs";
        servicePort = 9428;
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
        "operator.victoriametrics.com".v1.VLSingle.victoria-logs = {
          spec = {
            storage = {
              resources.requests.storage = "100Gi";
            };
          };
        };
      };
    };
  };
}
