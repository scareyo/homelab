{ charts, config, generators, lib, ... }:

let
  cfg = config.vegapunk.rook;
  namespace = "rook-ceph";
  project = "system";
  chart = charts.rook-ceph;
in
{
  options = {
    vegapunk.rook.enable = lib.mkEnableOption "Enable Rook Ceph";
  };
  
  config = lib.mkIf cfg.enable {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        inherit chart;
        name = "rook-ceph";
        kindFilter = [ "ObjectBucketClaim" ];
      })
    ];

    applications.rook = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.rook-ceph = {
        inherit chart;
      };

      helm.releases.rook-ceph-cluster = {
        chart = charts.rook-ceph-cluster;
        values = import ./values.nix;
      };

      templates.app.ceph.route = {
        serviceName = "rook-ceph-mgr-dashboard";
        servicePort = 7000;
      };

      resources = {
        namespaces.rook-ceph = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
