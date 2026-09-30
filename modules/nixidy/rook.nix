{
  flake.modules.nixidy.rook = { generators, lib, ... }: let
    chart.rook-ceph = lib.helm.downloadHelmChart {
      repo = "https://charts.rook.io/release";
      chart = "rook-ceph";
      version = "v1.20.8";
      chartHash = "sha256-FjYMB9/J7F9/z9+qIrPo709ED49J/PyDWIkEO1pBh+M=";
    };
    chart.rook-ceph-cluster = lib.helm.downloadHelmChart {
      repo = "https://charts.rook.io/release";
      chart = "rook-ceph-cluster";
      version = "v1.20.8";
      chartHash = "sha256-55Qf/20zr/CtzkOK2fm/KupZKyw/vZNagWMz/n84/8w=";
    };
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.rook-ceph;
        name = "rook-ceph";
        kindFilter = [ "ObjectBucketClaim" ];
      })
    ];

    applications.rook = {
      namespace = "rook-ceph";
      project = "default";

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.rook-ceph = {
        chart = chart.rook-ceph;
      };

      helm.releases.rook-ceph-cluster = {
        chart = chart.rook-ceph-cluster;
        values = {
          cephImage = {
            repository = "quay.io/ceph/ceph";
            tag = "v20.2.4";
            imagePullPolicy = "IfNotPresent";
          };
          cephClusterSpec = {
            mgr.modules = [
              {
                name = "rook";
                # The Rook mgr module is recommended to be disabled before upgrading to Ceph Tentacle (v20)
                # https://rook.io/docs/rook/latest-release/Upgrade/ceph-upgrade/#disable-the-rook-mgr-module
                enabled = false;
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

      #templates.app.ceph.route = {
      #  serviceName = "rook-ceph-mgr-dashboard";
      #  servicePort = 7000;
      #};

      resources = {
        namespaces.rook-ceph = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
