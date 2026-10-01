{
  flake.modules.apps.agentgateway = { generators, lib, ... }: let
    namespace = "agentgateway-system";
    project = "system";
    chart.agentgateway = lib.helm.downloadHelmChart {
      repo = "oci://cr.agentgateway.dev/charts";
      chart = "agentgateway";
      version = "1.5.0";
      chartHash = "sha256-2qVtdYgaVn7JQIJkbuXkePfUsyjlLE8PZFIMmc2SC+A=";
    };
    chart.agentgateway-crds = lib.helm.downloadHelmChart {
      repo = "oci://cr.agentgateway.dev/charts";
      chart = "agentgateway-crds";
      version = "1.5.0";
      chartHash = "sha256-9ftxoqzikHFhIXESiBQlrQgGmzamqb4HnSl7cVuD3AI=";
    };
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
