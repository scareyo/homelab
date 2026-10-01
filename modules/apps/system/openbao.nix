{
  flake.modules.apps.openbao = { lib, ... }: let
    namespace = "openbao";
    project = "system";
    chart = lib.helm.downloadHelmChart {
      repo = "https://openbao.github.io/openbao-helm";
      chart = "openbao";
      version = "0.30.0";
      chartHash = "sha256-R6qWSFTtsbpdlu3mDLZCJfk1qLKUTidYOmM+QVxyRoY=";
    };
  in {
    applications.openbao = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.openbao = {
        inherit chart;
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

      templates.postgres.openbao-db = {};
    };
  };
}
