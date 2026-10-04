{
  flake.modules.apps.agentgateway = { lib, ... }: let
    namespace = "agentgateway-system";
    project = "system";
    charts.agentgateway = {
      repo = "oci://cr.agentgateway.dev/charts";
      chart = "agentgateway";
      version = "1.5.0";
      chartHash = "sha256-2qVtdYgaVn7JQIJkbuXkePfUsyjlLE8PZFIMmc2SC+A=";
    };
    charts.agentgateway-crds = {
      repo = "oci://cr.agentgateway.dev/charts";
      chart = "agentgateway-crds";
      version = "1.5.0";
      chartHash = "sha256-9ftxoqzikHFhIXESiBQlrQgGmzamqb4HnSl7cVuD3AI=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.agentgateway = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.agentgateway = {
        chart = chart.agentgateway;
      };

      helm.releases.agentgateway-crds = {
        chart = chart.agentgateway-crds;
      };
    };
  };
}
