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

    psql = {
      host = "gitlab-rw";
      username = "app";
      password = {
        useSecret = true;
        secret = "gitlab-app";
        key = "password";
      };
    };
  };

  installCertmanager = false;

  nginx-ingress.enabled = false;
  postgresql.install = false;
}
