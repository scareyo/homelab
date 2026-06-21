{ charts, config, generators, lib, ... }:

let
  cfg = config.vegapunk.cluster-api;
  namespace = "capi-system";
  project = "system";
  chart = charts.cluster-api-operator;
in
{
  options = {
    vegapunk.cluster-api.enable = lib.mkEnableOption "Enable Cluster API";
  };

  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        inherit chart;
        name = "cluster-api";
        kindFilter = [ "CoreProvider" "ControlPlaneProvider" "InfrastructureProvider" "BootstrapProvider" ];
      })
    ];

    applications.cluster-api = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.cluster-api = {
        inherit chart;
      };

      resources.coreProviders.cluster-api = {
        #spec.manager.featureGates = {
        #  ClusterTopology = true;
        #};
      };
      resources.controlPlaneProviders.kamaji = {};
      resources.infrastructureProviders.kubevirt = {};
      resources.bootstrapProviders.kubeadm = {};
    };
  };
}
