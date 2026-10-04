{
  flake.modules.apps.argocd = { lib, ... }: let
    namespace = "argocd";
    project = "system";
    charts.argocd = {
      repo = "https://argoproj.github.io/argo-helm";
      chart = "argo-cd";
      version = "10.9.2";
      chartHash = "sha256-OA7qeOnu6I8q7p1WL5XA0jXdZ+RMb9xQgyvzpJAuDQ0=";
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
          callbackUrls = [ "https://argocd.vegapunk.cloud/auth/callback" ];
          secret.additionalLabels."app.kubernetes.io/part-of" = "argocd";
        };
      };

      resources.pocketIDUserGroups.argocd-admin = {};
      resources.pocketIDUserGroups.argocd-viewer = {};
    };
  };
}
