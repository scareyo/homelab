{
  flake.modules.apps.openbao = { generators, lib, ... }: let
    namespace = "openbao";
    project = "system";
    charts.openbao = {
      repo = "https://openbao.github.io/openbao-helm";
      chart = "openbao";
      version = "0.30.0";
      chartHash = "sha256-R6qWSFTtsbpdlu3mDLZCJfk1qLKUTidYOmM+QVxyRoY=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.openbao = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.openbao = {
        chart = chart.openbao;
        values = {
          injector.enabled = false;
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

      templates.app.openbao.route = {
        servicePort = 8200;
      };

      templates.postgres.openbao-db = {};

      templates.externalSecret.oidc.data.client_secret = {
        sourceKey = "openbao";
      };

      resources.pocketIDOIDCClients.openbao = {
        spec = {
          name = "OpenBao"; 
          description = "Manage, store, and distribute sensitive data";
          callbackUrls = [ "https://openbao.vegapunk.cloud/ui/vault/auth/oidc/oidc/callback" ];
          clientID = "88f36e70-0c62-4d5e-8777-b3bbebae50db";
          clientSecretRef = {
            name = "oidc";
            key = "client_secret";
          };
        };
      };

      resources.pocketIDUserGroups.openbao-admin = {};
    };
  };
}
