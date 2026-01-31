{ config, lib, ... }:

let
  cfg = config.vegapunk.attic;
  namespace = "attic";
  project = "development";
in
{
  options = {
    vegapunk.attic.enable = lib.mkEnableOption "Enable Attic";
  };

  config = lib.mkIf cfg.enable {
    applications.attic = {
      inherit namespace project;

      createNamespace = true;

      templates.app.attic = {
        inherit namespace;

        workload = {
          image = "ghcr.io/zhaofengli/attic";
          version = "9736e87439be1b5d40cad1dff004e1d845f8b9e7";
          port = 8080;
          env = {
            ATTIC_SERVER_DATABASE_URL = {
              secretKeyRef = {
                key = "uri";
                name = "attic-app";
              };
            };
            ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 = {
              secretKeyRef = {
                key = "token";
                name = "attic";
              };
            };
            AWS_ACCESS_KEY_ID = {
              secretKeyRef = {
                key = "AWS_ACCESS_KEY_ID";
                name = "attic-obc";
              };
            };
            AWS_SECRET_ACCESS_KEY = {
              secretKeyRef = {
                key = "AWS_SECRET_ACCESS_KEY";
                name = "attic-obc";
              };
            };
          };
        };

        persistence = {
          config = {
            type = "cm";
            path = "/var/empty/.config/attic";
            config.data."server.toml" = ''
              # Socket address to listen on
              listen = "[::]:8080"

              allowed-hosts = ["cache.vegapunk.cloud"]
              api-endpoint = "https://cache.vegapunk.cloud/"

              [database]

              [storage]
              type = "s3"

              region = ""
              bucket = "attic"
              endpoint = "http://rook-ceph-rgw-ceph-objectstore.rook-ceph.svc"

              [chunking]
              nar-size-threshold = 65536 # chunk files that are 64 KiB or larger
              min-size = 16384            # 16 KiB
              avg-size = 65536            # 64 KiB
              max-size = 262144           # 256 KiB

              [compression]
              type = "zstd"

              [garbage-collection]
              interval = "12 hours"
            '';
          };
        };

        route = {
          hostname = "cache.vegapunk.cloud";
        };
      };

      templates.postgres.attic = {
        instances = 3;
        size = "32Gi";
      };

      templates.externalSecret.attic = {
        keys = [
          { source = "/attic/TOKEN"; dest = "token"; }
        ];
      };

      resources.deployments.attic.spec.template.spec.containers.attic.securityContext = lib.mkForce {};
      resources.deployments.attic.spec.template.spec.securityContext = lib.mkForce {};

      resources."objectbucket.io".v1alpha1.ObjectBucketClaim.attic-obc = {
        spec = {
          bucketName = "attic";
          storageClassName = "ceph-bucket";
        };
      };
    };
  };
}
