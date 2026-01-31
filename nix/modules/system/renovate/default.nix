{ config, lib, ... }:

let
  cfg = config.vegapunk.renovate;
  namespace = "renovate";
  project = "system";
in
{
  options = {
    vegapunk.renovate.enable = lib.mkEnableOption "Enable Renovate";
  };

  config = lib.mkIf cfg.enable {
    applications.renovate = {
      inherit namespace project;

      createNamespace = true;

      templates.externalSecret.renovate = {
        keys = [
          { source = "/renovate/GITHUB_TOKEN"; dest = "RENOVATE_TOKEN"; }
        ];
      };

      resources.configMaps.renovate = {
        data."config.json" = ''
          {
            "allowedCommands": [
              "nix"
            ]
          }
        '';
      };

      resources.cronJobs.renovate = {
        spec = {
          schedule = "@hourly";
          concurrencyPolicy = "Forbid";
          jobTemplate.spec.template.spec = {
            containers = [
              {
                name = "renovate";
                image = "nixos/nix:2.32.4";
                command = [
                  "/bin/sh" "-c"
                  ''
                    echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf && \
                    nix run github:scareyo/homelab#renovate -- scareyo/homelab
                  ''
                ];
                env = [
                  {
                    name = "RENOVATE_PLATFORM";
                    value = "github";
                  }
                  {
                    name = "RENOVATE_CONFIG_FILE";
                    value = "/opt/renovate/config.json";
                  }
                  {
                    name = "LOG_LEVEL";
                    value = "debug";
                  }
                ];
                envFrom = [{ secretRef.name = "renovate"; }];
                volumeMounts = [
                  {
                    name = "config-volume";
                    mountPath = "/opt/renovate/";
                  }
                ];
              }
            ];
            restartPolicy = "Never";
            volumes = [
              {
                name = "config-volume";
                configMap.name = "renovate";
              }
            ];
          };
        };
      };
    };
  };
}
