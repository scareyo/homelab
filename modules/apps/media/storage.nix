{
  flake.modules.apps.storage = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.storage = {
      inherit namespace project;

      createNamespace = true;

      resources.storageClasses.media = {
        parameters = {
          recordsize = "128k";
          compression = "off";
          dedup = "off";
          fstype = "zfs";
          poolname = "s-flamingo";
          shared = "yes";
        };
        provisioner = "zfs.csi.openebs.io";
        reclaimPolicy = "Retain";
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

      resources.persistentVolumeClaims.media = {
        metadata.annotations."argocd.argoproj.io/sync-options" = "Prune=false,Delete=false";
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = "2Ti";
          storageClassName = "media";
        };
      };
    };
  };
}
