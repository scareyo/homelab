{ charts, config, lib, ... }:

let
  cfg = config.scarey.k8s.velero;
in
{
  options = with lib; {
    scarey.k8s.velero.enable = mkEnableOption "Enable Velero";
  };
  
  config = lib.mkIf cfg.enable {
    applications.velero = {
      namespace = "velero";
      createNamespace = true;

      helm.releases.velero = {
        chart = charts.vmware-tanzu.velero;
        values = {
          initContainers = [
            {
              name = "velero-plugin-for-aws";
              image = "velero/velero-plugin-for-aws:v1.12.0";
              imagePullPolicy = "IfNotPresent";
              volumeMounts = [
                {
                  mountPath = "/target";
                  name = "plugins";
                }
              ];
            }
          ];
          configuration = {
            backupSyncPeriod = "1h";
            backupStorageLocation = [
              {
                provider = "aws";
                bucket = "me-scarey-velero";
                credential = {
                  name = "backblaze";
                  key = "key";
                };
                config = {
                  region = "us-east-005";
                  s3Url = "https://s3.us-east-005.backblazeb2.com";
                  checksumAlgorithm = "";
                };
              }
            ];
            features = "EnableCSI";
            volumeSnapshotLocation = [
              {
                provider = "aws";
                credential = {
                  name = "backblaze";
                  key = "key";
                };
                config = {
                  region = "us-east-005";
                };
              }
            ];
          };
          deployNodeAgent = true;
          kubectl = {
            # TODO: https://github.com/vmware-tanzu/helm-charts/issues/698
            image.tag = "1.33.4";
          };
        };
      };

      templates.externalSecret.backblaze = {
        keys = [
          { source = "/velero/BACKBLAZE_KEY"; dest = "key"; }
        ];
      };

      resources = {
        namespaces.velero = {
          metadata.labels."pod-security.kubernetes.io/enforce" = lib.mkForce "privileged";
        };
      };
    };
  };
}
