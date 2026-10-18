{
  flake.modules.apps.openebs = { lib, pkgs, ... }: let
    namespace = "openebs";
    project = "system";
    charts.openebs = {
      repo = "oci://ghcr.io/openebs/charts";
      chart = "openebs";
      version = "4.6.2";
      chartHash = "sha256-bBI964kD5e+r8QbRMvbwWD2FriUAmHtEjo1LxrCNEVo=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
    monitoring = pkgs.fetchFromGitHub {
      owner = "openebs";
      repo = "monitoring";
      rev = "openebs-monitoring-0.4.13";
      hash = "sha256-YMiVKmKfbidcteyrOxtdllAys0QSIhymLtYyTrahOk0=";
    };
  in {
    applications.openebs = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.openebs = {
        chart = chart.openebs;

        values = {
          alloy.enabled = false;
          loki.enabled = false;
          # Snapshot CRDs are owned by the external-snapshotter app
          openebs-crds.csi.volumeSnapshots.enabled = false;
          engines = {
            local.lvm.enabled = false;
            replicated.mayastor.enabled = false;
          };
          zfs-localpv.zfsNode = {
            encrKeysDir = "/var/openebs/keys";
            nodeSelector."kubernetes.io/hostname" = "s-flamingo";
          };
        };
      };

      resources.storageClasses.s-flamingo = {
        parameters = {
          recordsize = "128k";
          compression = "off";
          dedup = "off";
          fstype = "zfs";
          poolname = "s-flamingo";
          shared = "yes";
        };
        provisioner = "zfs.csi.openebs.io";
        allowedTopologies = [
          {
            matchLabelExpressions = [
              {
                key = "kubernetes.io/hostname";
                values = [ "s-flamingo" ];
              }
            ];
          }
        ];
      };

      resources.configMaps.openebs-zfslocalpv-dashboard = {
        metadata.labels.grafana_dashboard = "1";
        data."zfslocalpv.json" = builtins.readFile
          "${monitoring}/deploy/charts/dashboards/zfsLocalPV/zfslocalpv.json";
      };

      templates.privileged.openebs = {};
    };
  };
}
