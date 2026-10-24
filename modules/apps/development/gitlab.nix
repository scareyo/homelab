{
  flake.modules.apps.gitlab = { lib, ... }: let
    namespace = "gitlab";
    project = "development";
    charts.gitlab = {
      repo = "oci://registry.gitlab.com/charts/charts.gitlab.io/release";
      chart = "gitlab";
      version = "10.5.1";
      chartHash = "sha256-+FbamvH21SkR2cQM+avLJYhK8a+bcb3+2OQjt6UMzZ0=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;

    buckets = {
      artifacts = "gitlab-artifacts";
      lfs = "git-lfs";
      uploads = "gitlab-uploads";
      packages = "gitlab-packages";
      registry = "gitlab-registry";
    };
    endpoint = "http://rook-ceph-rgw-ceph-objectstore.rook-ceph.svc";
  in {
    applications.gitlab = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.gitlab = {
        chart = chart.gitlab;
        values = {
          installCertmanager = false;
          upgradeCheck.enabled = false;
          global = {
            edition = "ce";
            hosts.domain = "vegapunk.cloud";
            gatewayApi = {
              gatewayRef = {
                name = "internal";
                namespace = "gateway";
              };
              installEnvoy = false;
              configureCertmanager = false;
            };
            psql = {
              host = "gitlab-db-rw";
              port = 5432;
              username = "app";
              database = "app";
              password = {
                secret = "gitlab-db-app";
                key = "password";
              };
            };
            redis = {
              host = "gitlab-redis";
              auth.enabled = false;
            };
            appConfig = lib.mapAttrs (type: bucket: {
              inherit bucket;
              connection = {
                secret = "gitlab-${type}-storage";
                key = "connection";
              };
            }) (removeAttrs buckets [ "registry" ]);
            registry.bucket = buckets.registry;
          };
          registry.storage = {
            secret = "gitlab-registry-storage";
            key = "config";
          };
          gitlab.webservice.gatewayRoute.sectionName = "";
          gitlab.kas.gatewayRoute.sectionName = "";
          registry.gatewayRoute.sectionName = "";
          gitlab.toolbox.backups.objectStorage.config = {
            secret = "gitlab-backups-placeholder";
            key = "config";
          };
        };
      };

      templates.postgres.gitlab-db = {
        instances = 3;
        size = "256Gi";
      };

      templates.redis.gitlab-redis.size = "8Gi";

      #templates.backup.daily = {
      #  restore = true;
      #  schedule = "0 6 * * *"; # At 06:00 daily
      #  ttl = "360h";           # 15 days
      #};

      #templates.externalSecret.admin.secrets = {
      #  username.key = "/gitlab/ADMIN_USERNAME";
      #  password.key = "/gitlab/ADMIN_PASSWORD";
      #};

      resources.secrets.gitlab-backups-placeholder.stringData.config = "";

      resources.agentgatewayPolicies.gitlab.spec = {
        targetRefs = [
          { group = "gateway.networking.k8s.io"; kind = "HTTPRoute"; name = "gitlab-gitlab"; }
        ];
        traffic.transformation.request.set = [ { name = "x-forwarded-proto"; value = "request.scheme"; } ];
      };

      resources.objectBucketClaims = lib.mapAttrs' (type: bucket: lib.nameValuePair "gitlab-${type}" {
        spec = {
          bucketName = bucket;
          storageClassName = "ceph-bucket";
        };
      }) buckets;

      # Pushes each bucket's generated credentials to Infisical so they can be templated back below
      resources.pushSecrets = lib.mapAttrs' (type: _: lib.nameValuePair "gitlab-${type}" {
        spec = {
          secretStoreRefs = [ { kind = "ClusterSecretStore"; name = "infisical"; } ];
          selector.secret.name = "gitlab-${type}";
          data = [ { match.remoteRef.remoteKey = "/gitlab/${lib.toUpper type}_BUCKET"; } ];
        };
      }) buckets;

      # Renders each bucket's credentials into the format GitLab expects
      templates.externalSecret = lib.mapAttrs' (type: bucket: lib.nameValuePair "gitlab-${type}-storage" {
        secrets = lib.genAttrs [ "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" ] (property: {
          key = "/gitlab/${lib.toUpper type}_BUCKET";
          inherit property;
        });
        templates = if type == "registry" then {
          config = ''
            s3:
              bucket: ${bucket}
              accesskey: {{ .AWS_ACCESS_KEY_ID }}
              secretkey: {{ .AWS_SECRET_ACCESS_KEY }}
              region: us-east-1
              regionendpoint: ${endpoint}
              v4auth: true
          '';
        } else {
          connection = ''
            provider: AWS
            region: us-east-1
            aws_access_key_id: {{ .AWS_ACCESS_KEY_ID }}
            aws_secret_access_key: {{ .AWS_SECRET_ACCESS_KEY }}
            endpoint: ${endpoint}
            path_style: true
          '';
        };
      }) buckets;

      #resources.pocketIDOIDCClients.gitlab = {
      #  spec = {
      #    name = "Forgejo";
      #    description = "A self-hosted lightweight software forge";
      #    launchUrl = "https://scarey.dev";
      #    callbackUrls = [ "https://scarey.dev/user/oauth2/Pocket%20ID/callback" ];
      #    secret = {
      #      keys.clientID = "key";
      #      keys.clientSecret = "secret";
      #    };
      #  };
      #};

      #resources.tcpRoutes.gitlab-ssh = {
      #  spec = {
      #    parentRefs = [
      #      {
      #        name = "internal";
      #        namespace = "gateway";
      #        sectionName = "dev-scarey-tcp";
      #      }
      #    ];
      #    rules = [
      #      {
      #        backendRefs = [
      #          { group = ""; kind = "Service"; name = "gitlab-ssh"; port = 22; }
      #        ];
      #      }
      #    ];
      #  };
      #};
    };
  };
}
