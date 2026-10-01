{
  flake.modules.apps.openebs = { lib, ... }: let
    namespace = "openebs";
    project = "system";
    chart = lib.helm.downloadHelmChart {
      repo = "https://openebs.github.io/openebs";
      chart = "openebs";
      version = "4.6.1";
      chartHash = "sha256-cHd2Vz4eqX40Uhuxoum1F+JQF8T8m2tsskJUzlhhpLo=";
    };
  in {
    applications.openebs = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.openebs = {
        inherit chart;

        values = {
          alloy.enabled = false;
          loki.enabled = false;
          engines = {
            local.lvm.enabled = false;
            replicated.mayastor.enabled = false;
          };
          zfs-localpv.zfsNode.encrKeysDir = "/var/openebs/keys";
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
