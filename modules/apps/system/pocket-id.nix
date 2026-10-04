{
  flake.modules.apps.pocket-id = { generators, lib, ... }: let
    namespace = "pocket-id";
    project = "system";
    chart = lib.helm.downloadHelmChart {
      repo = "oci://ghcr.io/aclerici38/charts";
      chart = "pocket-id-operator";
      version = "0.15.0";
      chartHash = "sha256-YjNpcT2OLVCO2KdnDH9FhhWqva4SWbuiV7oN+RCTvUc=";
    };
  in {
    applications.pocket-id = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.pocket-id-operator = {
        inherit chart;
        values = {
          pocket-id-instance.instance = {
            enabled = true;
            spec = {
              appUrl = "https://id.vegapunk.cloud";
              ui.appName = "id.vegapunk.cloud";
              encryptionKey.valueFrom.secretKeyRef = {
                name = "pocket-id";
                key = "encryption-key";
              };
              databaseUrl.valueFrom.secretKeyRef = {
                name = "pocket-id-db-app";
                key = "uri";
              };
            };
          };
        };
      };

      templates.app.pocket-id.route = {
        hostname = "id.vegapunk.cloud";
        servicePort = 1411;
      };

      templates.externalSecret.pocket-id = {
        keys = [
          { source-key = "pocket-id"; source-property = "encryption-key"; }
        ];
      };

      templates.postgres.pocket-id-db = {
        instances = 3;
        size = "32Gi";
      };
    };
  };
}

