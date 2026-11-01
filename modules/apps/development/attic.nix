{
  flake.modules.apps.attic = { lib, pkgs, ... }: let
    namespace = "attic";
    project = "development";
    charts.attic = {
      repo = "oci://ghcr.io/helmforgedev/helm";
      chart = "attic";
      version = "1.1.0";
      chartHash = "sha256-IynyrcmRNcvUjW/6QLXfmbAdRnLy/IzgzXvjC0NdSio=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.attic = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.attic = {
        chart = chart.attic;
        values = {
          mode = "distributed";
          replicaCount = 3;

          config = {
            apiEndpoint = "https://attic.scarey.dev/";
            allowedHosts = [
              "attic.scarey.dev"
            ];
          };

          database.type = "postgresql";

          storage = {
            type = "s3";
            s3 = {
              region = "default";
              bucket = "attic";
              endpoint = "http://rook-ceph-rgw-ceph-objectstore.rook-ceph.svc";
            };
          };

          auth = {
            generate = false;
            existingSecret = "attic";
          };

          pdb = {
            enabled = true;
            minAvailable = 2;
          };
        };
      };

      templates.app.attic = {
        route.hostname = "attic.scarey.dev";
      };

      templates.postgres.attic-db = {
        instances = 3;
        size = "32Gi";
      };

      templates.externalSecret.attic = {
        secrets = {
          aws-access-key-id = { provider = "kubernetes"; key = "attic-obc"; property = "AWS_ACCESS_KEY_ID"; };
          aws-secret-access-key = { provider = "kubernetes"; key = "attic-obc"; property = "AWS_SECRET_ACCESS_KEY"; };
          database-url = { provider = "kubernetes"; key = "attic-db-app"; property = "uri"; };
        };
        passwords.token-hs256-secret-base64 = { length = 64; encoding = "base64"; };
      };

      resources.objectBucketClaims.attic-obc = {
        spec = {
          bucketName = "attic";
          storageClassName = "ceph-bucket";
        };
      };
    };
  };
}
