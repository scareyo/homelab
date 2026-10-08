{
  flake.modules.apps.pocket-id = { generators, lib, ... }: let
    namespace = "pocket-id";
    project = "system";
    charts.pocket-id-operator = {
      repo = "oci://ghcr.io/aclerici38/charts";
      chart = "pocket-id-operator";
      version = "0.15.0";
      chartHash = "sha256-YjNpcT2OLVCO2KdnDH9FhhWqva4SWbuiV7oN+RCTvUc=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    nixidy.applicationImports = [
      (generators.fromChartCRDModule {
        chart = chart.pocket-id-operator;
        name = "pocket-id-operator";
        kindFilter = [ "PocketIDOIDCClient" "PocketIDUserGroup" ];
      })
    ];

    applications.pocket-id = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.pocket-id-operator = {
        chart = chart.pocket-id-operator;
        values = {
          pocket-id-instance.instance = {
            enabled = true;
            spec = {
              appUrl = "https://id.vegapunk.cloud";
              ui.appName = "id.vegapunk.cloud";
              fileBackend = "database";
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
        data.encryption-key.sourceKey = "pocket-id";
      };

      templates.postgres.pocket-id-db = {
        instances = 3;
        size = "32Gi";
      };
    };
  };
}

