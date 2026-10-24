{
  flake.modules.apps.monitoring = { lib, ... }: let
    namespace = "monitoring";
    project = "system";
    charts.vmks = {
      repo = "oci://ghcr.io/victoriametrics/helm-charts";
      chart = "victoria-metrics-k8s-stack";
      version = "0.96.0";
      chartHash = "sha256-wesVPJxkB50HIf9YzLi8zOEgfMmta0hJX4n9D9QMHjI=";
    };
    charts.prometheus-operator-crds = {
      repo = "oci://ghcr.io/prometheus-community/charts";
      chart = "prometheus-operator-crds";
      version = "32.0.2";
      chartHash = "sha256-hFk7NME6TmXaJClR4m1PFLzDVxTl/vSJIRxcoOZ0VJs=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.monitoring = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.vmks = {
        chart = chart.vmks;
        values = {
          nameOverride = "vmks";
          alertmanager.useManagedConfig = true;
          grafana = {
            env = {
              GF_SECURITY_DISABLE_INITIAL_ADMIN_CREATION = true;
            };
            "grafana.ini" = {
              server.root_url = "https://grafana.vegapunk.cloud";
              "auth.generic_oauth" = {
                enabled = true;
                client_id = "$__file{/etc/secrets/oauth/client_id}";
                client_secret = "$__file{/etc/secrets/oauth/client_secret}";
                scopes = "openid email profile groups";
                auth_url = "$__file{/etc/secrets/oauth/authorization_url}";
                token_url = "$__file{/etc/secrets/oauth/token_url}";
                role_attribute_path = lib.concatStrings [
                  "contains(groups, 'grafana-admin') && 'Admin' || "
                  "contains(groups, 'grafana-editor') && 'Editor' || "
                  "contains(groups, 'grafana-viewer') && 'Viewer' "
                ];
              };
            };
            extraSecretMounts = [
              {
                name = "oidc";
                secretName = "grafana-oidc-credentials";
                defaultMode = 0440;
                mountPath = "/etc/secrets/oauth";
                readOnly = true;
              }
            ];
            plugins = [
              "victoriametrics-logs-datasource"
            ];
            sidecar.dashboards.searchNamespace = "ALL";
          };
          victoria-metrics-operator = {
            admissionWebhooks.certManager.enabled = true;
          };
          vlagent.enabled = true;
          vlsingle = {
            enabled = true;
            spec = {
              retentionPeriod = "30d";
              storage.resources.requests.storage = "128Gi";
            };
          };
        };
      };

      helm.releases.prometheus-operator-crds = {
        chart = chart.prometheus-operator-crds;
      };

      templates.app.grafana.route = {
        serviceName = "vmks-grafana";
      };

      templates.privileged.monitoring = {};

      resources.pocketIDOIDCClients.grafana = {
        spec = {
          name = "Grafana"; 
          description = "Observability and data visualization";
          launchUrl = "https://grafana.vegapunk.cloud";
          callbackUrls = [ "https://grafana.vegapunk.cloud/login/generic_oauth" ];
        };
      };

      resources.pocketIDUserGroups.grafana-admin = {};
      resources.pocketIDUserGroups.grafana-editor = {};
      resources.pocketIDUserGroups.grafana-viewer = {};
    };
  };
}
