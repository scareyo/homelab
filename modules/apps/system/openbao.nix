{
  flake.modules.apps.openbao = { lib, ... }: let
    namespace = "openbao";
    project = "system";
    charts.openbao = {
      repo = "https://openbao.github.io/openbao-helm";
      chart = "openbao";
      version = "0.30.0";
      chartHash = "sha256-R6qWSFTtsbpdlu3mDLZCJfk1qLKUTidYOmM+QVxyRoY=";
    };
    charts.vault-config-operator = {
      repo = "https://redhat-cop.github.io/vault-config-operator";
      chart = "vault-config-operator";
      version = "v1.0.3";
      chartHash = "sha256-M5LyOFR2RSy+IGe7n3VPP+jEFvYnp6O0UBHUEVS07ic=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.openbao = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.openbao = {
        chart = chart.openbao;
        values = {
          server = {
            ha = {
              enabled = true;
              config = ''
                ui = true

                listener "tcp" {
                  tls_disable = 1
                  address = "[::]:8200"
                  cluster_address = "[::]:8201"
                }

                storage "postgresql" {
                  ha_enabled = true
                }

                service_registration "kubernetes" {}
              '';
            };
            extraEnvironmentVars = {
              PGSSLMODE = "verify-full";
              PGSSLROOTCERT = "/pgssl/ca.crt";
            };
            extraSecretEnvironmentVars = [
              { envName = "BAO_PG_CONNECTION_URL"; secretName = "openbao-db-app"; secretKey = "fqdn-uri"; }
            ];
            volumes = [
              { name = "openbao-db-ca"; secret.secretName = "openbao-db-ca"; }
            ];
            volumeMounts = [
              { name = "openbao-db-ca"; mountPath = "/pgssl"; readOnly = true; }
            ];
          };
        };
      };

      helm.releases.vault-config-operator = {
        chart = chart.vault-config-operator;
      };

      templates.app.openbao.route = {
        servicePort = 8200;
      };

      templates.postgres.openbao-db = {};
    };
  };
}
