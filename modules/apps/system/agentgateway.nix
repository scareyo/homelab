{
  flake.modules.apps.agentgateway = { lib, ... }: let
    namespace = "agentgateway-system";
    project = "system";
    charts.agentgateway = {
      repo = "oci://cr.agentgateway.dev/charts";
      chart = "agentgateway";
      version = "v1.6.0";
      chartHash = "sha256-kQ3uxnCYD46z5JyWmIbn36McyZhG4yKijaUzDEen9Y0=";
    };
    charts.agentgateway-crds = {
      repo = "oci://cr.agentgateway.dev/charts";
      chart = "agentgateway-crds";
      version = "v1.6.0";
      chartHash = "sha256-SdC857K31mJ0dw9yyhn3XAVmG4ZyLQgsGzmH5WPG79c=";
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
