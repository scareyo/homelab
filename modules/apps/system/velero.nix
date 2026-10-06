{
  flake.modules.apps.velero = { generators, lib, ... }: let
    namespace = "velero";
    project = "system";
    charts.velero = {
      repo = "https://vmware-tanzu.github.io/helm-charts";
      chart = "velero";
      version = "12.2.0";
      chartHash = "sha256-4BBNaNc8QFjeIUdCtJdqzWTFeEfX76PwkS2w1BGh6j4=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.velero;
        name = "velero";
        kindFilter = [ "Restore" "Schedule" ];
      })
    ];

    applications.velero = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.velero = {
        chart = chart.velero;
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
                default = true;
                bucket = "seraphim-velero";
                credential = {
                  name = "backblaze";
                  key = "api-key";
                };
                config = {
                  region = "us-east-005";
                  s3Url = "https://s3.us-east-005.backblazeb2.com";
                  checksumAlgorithm = "";
                };
              }
            ];
            features = "EnableCSI";
            volumeSnapshotLocation = [];
          };
          deployNodeAgent = true;
          credentials.useSecret = false;
        };
      };

      templates.externalSecret.backblaze = {
        data = {
          key_id = {
            sourceKey = "velero";
            sourceProperty = "backblaze-key-id";
          };
          application_key = {
            sourceKey = "velero";
            sourceProperty = "backblaze-application-key";
          };
        };
        templates.api-key = ''
          [default]
          aws_access_key_id={{ .key_id }}
          aws_secret_access_key={{ .application_key }}
        '';
      };

      templates.privileged.velero = {};
    };
  };
}
