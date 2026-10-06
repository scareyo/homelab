{
  flake.modules.apps.openebs = { lib, ... }: let
    namespace = "openebs";
    project = "system";
    charts.openebs = {
      repo = "https://openebs.github.io/openebs";
      chart = "openebs";
      version = "4.6.1";
      chartHash = "sha256-cHd2Vz4eqX40Uhuxoum1F+JQF8T8m2tsskJUzlhhpLo=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.openebs = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.openebs = {
        chart = chart.openebs;

        values = {
          alloy.enabled = false;
          loki.enabled = false;
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

      templates.privileged.openebs = {};
    };
  };
}
