{
  flake.modules.apps.attic = { lib, pkgs, ... }: let
    namespace = "attic";
    project = "development";
  in {
    applications.attic = {
      inherit namespace project;

      createNamespace = true;

      templates.app.attic = {
        workload = {
          image = "scarey.dev/scarey/attic";
          version = pkgs.attic-server.version;
          args = [ "-f" "/etc/attic/server.toml" ];
          port = 8080;
          env = {
            ATTIC_SERVER_DATABASE_URL = {
              secretKeyRef = {
                key = "uri";
                name = "attic-db-app";
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
          envSecret = "attic";
        };

        persistence = {
          config = {
            type = "cm";
            path = "/etc/attic";
            config.data."server.toml" = ''
              listen = "[::]:8080"
              allowed-hosts = ["attic.scarey.dev"]
              api-endpoint = "https://attic.scarey.dev/"

              [database]

              [storage]
              type = "s3"
              region = ""
              bucket = "attic"
              endpoint = "http://rook-ceph-rgw-ceph-objectstore.rook-ceph.svc"

              [chunking]
              nar-size-threshold = 65536  # chunk files that are 64 KiB or larger
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

        route.hostname = "attic.scarey.dev";
      };

      templates.postgres.attic-db = {
        instances = 3;
        size = "32Gi";
      };

      templates.externalSecret.attic = {
        passwords.secret = { length = 64; };
        templates.ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64 = "{{ .secret | b64enc }}";
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
