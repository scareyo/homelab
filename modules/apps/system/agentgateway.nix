{
  flake.modules.apps.agentgateway = { generators, lib, ... }: let
    namespace = "agentgateway-system";
    project = "system";
    charts.agentgateway = {
      repo = "oci://cr.agentgateway.dev/charts";
      chart = "agentgateway";
      version = "1.6.0";
      chartHash = "sha256-QdsAlP9l6RZFaIAxXy9dJSiS+eOSTmQjaHBWNfHfcTE=";
    };
    charts.agentgateway-crds = {
      repo = "oci://cr.agentgateway.dev/charts";
      chart = "agentgateway-crds";
      version = "1.6.0";
      chartHash = "sha256-NBblrhGXioOJH9knsVD6ItZtJzXe2tcIwGFpHbAGy34=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.agentgateway-crds;
        name = "agentgateway";
        kindFilter = [ "AgentgatewayPolicy" ];
      })
    ];

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
