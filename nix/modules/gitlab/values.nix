{
  global = {
    ingress = {
      enabled = false;
      configureCertmanager = false;
    };
    gatewayApi = {
      enabled = true;
      class.name = "internal";
    };
  };

  installCertmanager = false;

  nginx-ingress.enabled = false;
}
