{
  flake.modules.apps.rook = { generators, lib, ... }: let
    namespace = "rook-ceph";
    project = "system";
    charts.rook-ceph = {
      repo = "https://charts.rook.io/release";
      chart = "rook-ceph";
      version = "v1.21.0";
      chartHash = "sha256-IEpexd64Jk6BYkaZDLWz+eeT+7W3nevUOfR6RpwrUGY=";
    };
    charts.rook-ceph-cluster = {
      repo = "https://charts.rook.io/release";
      chart = "rook-ceph-cluster";
      version = "v1.21.0";
      chartHash = "sha256-fRfCoyYU620uAquE/XjjCDtWvZkobYbTmV8uyJq72Dc=";
    };
    charts.ceph-csi-drivers = {
      repo = "https://ceph.github.io/ceph-csi-operator";
      chart = "ceph-csi-drivers";
      version = "1.1.0";
      chartHash = "sha256-7zQzYpHrkj8KJpbkBCo5+bTXYsapt30lrujqfFSve6c=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.rook-ceph;
        name = "rook-ceph";
        kindFilter = [ "ObjectBucketClaim" ];
      })
    ];

    applications.rook = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.rook-ceph = {
        chart = chart.rook-ceph;
        # FIXME: Chart v1.21.0 templates this without a default, rendering null
        values.csi.createCsiOperatorResources = true;
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
              # FIXME: remove these once on Linux kernel 7+ and using AES256K
              muteHealthWarning = {
                AUTH_INSECURE_ROTATING_SERVICE_KEY_TYPE.policy = "mute";
                AUTH_INSECURE_CLIENT_KEY_TYPE.policy = "mute";
                AUTH_INSECURE_KEYS_ALLOWED.policy = "mute";
                AUTH_INSECURE_KEYS_CREATABLE.policy = "mute";
              };
            };
          };
          cephBlockPoolsVolumeSnapshotClass = {
            enabled = true;
            labels."velero.io/csi-volumesnapshot-class" = "true";
          };
        };
      };

      helm.releases.ceph-csi-drivers = {
        chart = chart.ceph-csi-drivers;
        values = {
          drivers = {
            rbd = {
              name = "${namespace}.rbd.csi.ceph.com";
              snapshotPolicy = "volumeSnapshot";
            };
            cephfs.name = "${namespace}.cephfs.csi.ceph.com";
            nvmeof.enabled = false;
            nfs.enabled = false;
          };
        };
      };

      templates.app.ceph.route = {
        serviceName = "rook-ceph-mgr-dashboard";
        servicePort = 7000;
      };

      templates.privileged.rook-ceph = {};
    };
  };
}
