{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.gitlab;
  namespace = "gitlab";
in
{
  options = {
    vegapunk.gitlab.enable = lib.mkEnableOption "Enable GitLab";
  };

  config = lib.mkIf cfg.enable {
    applications.gitlab = {
      namespace = namespace;
      createNamespace = true;

      helm.releases.gitlab = {
        chart = charts.gitlab;
        values = import ./values.nix;
      };

      #templates.app.gitlab = {
      #  inherit namespace;

      #  route = {
      #    hostname = "dev.vegapunk.cloud";
      #    serviceName = "gitlab-http";
      #    servicePort = 3000;
      #    anubis.enable = true;
      #  };

      #  backup = {
      #    daily = {
      #      restore = true;
      #      schedule = "0 4 * * *";
      #      ttl = "168h0m0s"; # 1 week
      #    };
      #    quarterly = {
      #      schedule = "0 0 1 1,4,7,10 *";
      #      ttl = "8760h0m0s"; # 1 year
      #    };
      #  };
      #};

      templates.postgres.gitlab-pg = {
        instances = 3;
        size = "16Gi";
      };

      templates.valkey.gitlab-vk = {
        instances = 1;
        replicas = 2;
        size = "2Gi";
      };

      resources."gateway.networking.k8s.io".v1.Gateway.gitlab-gw = {
        metadata = {
          annotations = lib.mkForce {
            "cert-manager.io/cluster-issuer" = "letsencrypt-production";
          };
        };
      };

      #templates.externalSecret.admin = {
      #  keys = [
      #    { source = "/gitlab/ADMIN_USERNAME"; dest = "username"; }
      #    { source = "/gitlab/ADMIN_PASSWORD"; dest = "password"; }
      #  ];
      #};

      #templates.externalSecret.anubis = {
      #  keys = [
      #    { source = "/gitlab/ANUBIS_ED25519_PRIVATE_KEY_HEX"; dest = "key"; }
      #  ];
      #};

      #templates.externalSecret.oidc = {
      #  keys = [
      #    { source = "/gitlab/OIDC_CLIENT_ID"; dest = "key"; }
      #    { source = "/gitlab/OIDC_CLIENT_SECRET"; dest = "secret"; }
      #  ];
      #};

      #resources."gateway.networking.k8s.io".v1alpha2.TCPRoute.gitlab-ssh = {
      #  spec = {
      #    parentRefs = [
      #      {
      #        name = "internal";
      #        namespace = "gateway";
      #        sectionName = "cloud-vegapunk-dev-ssh";
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
