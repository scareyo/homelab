{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.rook;
in
{
  options = with lib; {
    scarey.k8s.rook.enable = mkEnableOption "Enable Rook Ceph";
  };
  
  config = lib.mkIf cfg.enable {
    applications.rook = {
      namespace = "rook-ceph";
      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.rook-ceph = {
        chart = charts.rook-release.rook-ceph;
      };

      helm.releases.rook-ceph-cluster = {
        chart = charts.rook-release.rook-ceph-cluster;
        values = {
          cephClusterSpec = {
            cephVersion.image = "quay.io/ceph/ceph:v19.2.3";
            mgr.modules = [
              {
                name = "rook";
                enabled = true;
              }
            ];
            dashboard.ssl = false;
            storage = {
              allowDeviceClassUpdate = false;
              allowOsdCrushWeightUpdate = false;
              scheduleAlways = false;
              onlyApplyOSDPlacement = false;
            };
            csi = {
              readAffinity.enabled = false;
              cephfs = {};
            };
            healthCheck = {
              daemonHealth = {};
              startupProbe = {
                mon.disabled = false;
                mgr.disabled = false;
                osd.disabled = false;
              };
            };
          };
          cephBlockPoolsVolumeSnapshotClass = {
            enabled = true;
            labels."velero.io/csi-volumesnapshot-class" = "true";
          };
        };
      };

      templates.httpRoute.ceph = {
        hostname = "ceph.vegapunk.cloud";
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
