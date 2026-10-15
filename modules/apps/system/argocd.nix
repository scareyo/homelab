{
  flake.modules.apps.argocd = { lib, ... }: let
    namespace = "argocd";
    project = "system";
    charts.argocd = {
      repo = "oci://ghcr.io/argoproj/argo-helm";
      chart = "argo-cd";
      version = "10.10.3";
      chartHash = "sha256-EDznXwB3sIl86sl7vRAOOZOUDrEkKrfvMjaK0t3erDw=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.argocd = {
      inherit namespace project;

      createNamespace = true;

      syncPolicy.syncOptions.serverSideApply = true;

      helm.releases.argocd = {
        chart = chart.argocd;
        values = {
          global.domain = "argocd.vegapunk.cloud";
          configs = {
            params."server.insecure" = true;
            cm = {
              "oidc.config" = ''
                name: SSO
                issuer: $argocd-oidc-credentials:issuer_url
                clientID: $argocd-oidc-credentials:client_id
                clientSecret: $argocd-oidc-credentials:client_secret
                requestedScopes: ["openid", "profile", "email", "groups"]
              '';
              "resource.exclusions" = ''
                - apiGroups:
                  - "velero.io"
                  kinds:
                  - Backup
                  clusters:
                  - "*"
              '';
              "accounts.readonly" = "apiKey";
            };
            rbac."policy.csv" = ''
              g, argocd-admin, role:admin
              g, argocd-viewer, role:readonly
            '';
          };
        };
      };

      resources.appProjects = {
        development.spec = {
          sourceRepos = [ "*" ];
          destinations = [{ namespace = "*"; server = "*"; }];
          clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
        };
        media.spec = {
          sourceRepos = [ "*" ];
          destinations = [{ namespace = "*"; server = "*"; }];
          clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
        };
        system.spec = {
          sourceRepos = [ "*" ];
          destinations = [{ namespace = "*"; server = "*"; }];
          clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
        };
      };

      templates.app.argocd.route = {
        serviceName = "argocd-server";
      };

      resources.pocketIDOIDCClients.argocd = {
        spec = {
          name = "Argo CD"; 
          logo.nameOverride = "argo-cd";
          description = "Declarative GitOps continuous deployment";
          launchUrl = "https://argocd.vegapunk.cloud";
          callbackUrls = [ "https://argocd.vegapunk.cloud/auth/callback" ];
          secret.additionalLabels."app.kubernetes.io/part-of" = "argocd";
        };
      };

      resources.pocketIDUserGroups.argocd-admin = {};
      resources.pocketIDUserGroups.argocd-viewer = {};
    };
  };
}
