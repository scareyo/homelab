{
  flake.modules.apps.renovate = { generators, lib, pkgs, ... }: let
    namespace = "renovate";
    project = "system";
    charts.renovate = {
      repo = "oci://ghcr.io/renovatebot/charts";
      chart = "renovate";
      version = "46.376.2";
      chartHash = "sha256-nt9ZfGT385XDi5jX+/JAgZEavJuFZfCOLo0H9t8epGQ=";
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

