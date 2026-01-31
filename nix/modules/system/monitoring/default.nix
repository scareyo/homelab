{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.monitoring;
  namespace = "monitoring";
  project = "system";
in
{
  options = {
    vegapunk.monitoring.enable = lib.mkEnableOption "Enable monitoring stack";
  };

  config = lib.mkIf cfg.enable {
    applications.monitoring = {
      inherit namespace project;

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

      helm.releases.prometheus-operator-crds = {
        chart = charts.prometheus-operator-crds;
      };

      templates.app.grafana.route = {
        serviceName = "vm-grafana";
      };

      templates.app.vmagent.route = {
        serviceName = "vmagent-vm-victoria-metrics-k8s-stack";
        servicePort = 8429;
      };

      templates.app.vm.route = {
        serviceName = "vmsingle-vm-victoria-metrics-k8s-stack";
        servicePort = 8428;
      };

      templates.app.vl.route = {
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
