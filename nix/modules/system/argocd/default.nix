{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.argocd;
  namespace = "argocd";
  project = "default";
in
{
  options = {
    vegapunk.argocd.enable = lib.mkEnableOption "Enable Argo CD";
  };

  config = lib.mkIf cfg.enable {
    applications.argocd = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.argocd = {
        chart = charts.argo-cd;
        values = import ./values.nix;
      };

      templates.app.argocd.route = {
        hostname = "argocd.vegapunk.cloud";
        serviceName = "argocd-server";
      };

      templates.externalSecret.argocd-secret = {
        merge = true;
        keys = [
          { source = "/argocd/OIDC_CLIENT_ID"; dest = "oauth_client_id"; }
          { source = "/argocd/OIDC_CLIENT_SECRET"; dest = "oauth_client_secret"; }
        ];
      };

      resources.appProjects = {
        development = {
          spec = {
            sourceRepos = [ "*" ];
            destinations = [{ namespace = "*"; server = "*"; }];
            clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
          };
        };
        general = {
          spec = {
            sourceRepos = [ "*" ];
            destinations = [{ namespace = "*"; server = "*"; }];
            clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
          };
        };
        media = {
          spec = {
            sourceRepos = [ "*" ];
            destinations = [{ namespace = "*"; server = "*"; }];
            clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
          };
        };
        system = {
          spec = {
            sourceRepos = [ "*" ];
            destinations = [{ namespace = "*"; server = "*"; }];
            clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
          };
        };
      };
    };
  };
}
