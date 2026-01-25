{
  global = {
    ingress = {
      enabled = false;
      configureCertmanager = false;
    };
    gatewayApi = {
      enabled = true;
      class.name = "kgateway";
    };
    hosts.domain = "vegapunk.cloud";

    hpa.apiVersion = "autoscaling/v2";
    pdb.apiVersion = "policy/v1";

    psql = {
      host = "gitlab-pg-rw";
      database = "app";
      username = "app";
      password = {
        useSecret = true;
        secret = "gitlab-pg-app";
        key = "password";
      };
    };

    redis = {
      host = "gitlab-vk";
      auth = {
        secret = "gitlab-vk";
        key = "password";
      };
    };
  };

  installCertmanager = false;

  nginx-ingress.enabled = false;
  postgresql.install = false;
  redis.install = false;

  upgradeCheck.enabled = false;
}
