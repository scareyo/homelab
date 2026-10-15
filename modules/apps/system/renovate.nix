{
  flake.modules.apps.renovate = { generators, lib, pkgs, ... }: let
    namespace = "renovate";
    project = "system";
    charts.renovate = {
      repo = "oci://ghcr.io/renovatebot/charts";
      chart = "renovate";
      version = "46.363.1";
      chartHash = "sha256-jupedjG+13CK66AclXdA5hxZ0wPc/FS7e3QasvGVvqM=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.renovate = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.renovate = {
        chart = chart.renovate;
        values = {
          renovate.config = ''
            {
              "platform": "forgejo",
              "endpoint": "https://scarey.dev",
              "autodiscover": true,
              "allowedCommands": [
                "nix"
              ]
            }
          '';
          existingSecret = "renovate";

          image = {
            registry = "scarey.dev";
            repository = "scarey/renovate";
            tag = pkgs.renovate.version;
          };
        };
      };

      templates.externalSecret.renovate.secrets = {
        RENOVATE_TOKEN.key = "/renovate/FORGEJO_TOKEN";
        RENOVATE_GITHUB_COM_TOKEN.key = "/renovate/GITHUB_TOKEN";
      };
    };
  };
}

