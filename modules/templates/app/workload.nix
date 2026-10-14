{
  flake.modules.templates.app = { lib, ... }: {
    templates.app = {
      options.workload = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [
                "cronjob"
                "deployment"
              ];
              default = "deployment";
              description = "Workload type";
            };

            image = lib.mkOption {
              type = lib.types.str;
              description = "Workload container image";
            };

            version = lib.mkOption {
              type = lib.types.str;
              description = "Workload container image version";
            };

            port = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Workload container port";
            };

            command = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
              description = "Workload container command";
            };

            args = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
              description = "Workload container args";
            };

            env = lib.mkOption {
              type = lib.types.attrsOf (lib.types.oneOf [lib.types.str lib.types.attrs]);
              default = {};
              description = "Workload container env";
            };

            schedule = lib.mkOption {
              type = lib.types.str;
              default = "0 0 * * *";
              description = "Workload CronJob schedule";
            };

            strategy = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Workload Deployment strategy";
            };
          };
        });
        default = null;
      };

      output = { name, config, options, ...  }: let
        labels = import ./_labels.nix { inherit lib name config options; };
        template = {
          metadata = { inherit labels; };
          spec = {
            containers.${name} = {
              image = "${config.workload.image}:${config.workload.version}";

              command = config.workload.command;
              args = config.workload.args;

              env = builtins.mapAttrs
                (_: v: {
                  value = lib.mkIf (lib.isString v) v;
                  valueFrom = lib.mkIf (lib.isAttrs v) v;
                }) config.workload.env;

              ports.http = lib.mkIf (config.workload.port != null) {
                containerPort = config.workload.port;
              };

              securityContext = {
                allowPrivilegeEscalation = false;
                capabilities.drop = [ "ALL" ];
                readOnlyRootFilesystem = true;
              };

              volumeMounts = lib.mkIf (config.persistence != {})
                (lib.mapAttrsToList (name: volume: {
                  name = name;
                  mountPath = volume.path;
                }) config.persistence);
            };

            securityContext = {
              runAsUser = 1000;
              runAsGroup = 1000;
              fsGroup = 1000;
              fsGroupChangePolicy = "OnRootMismatch";
            };

            volumes = lib.mkIf (config.persistence != {})
              (lib.mapAttrsToList (vol: p: {
                name = vol;
              } // p.volume name) config.persistence);
          } // lib.optionalAttrs (config.workload.type == "cronjob") {
            restartPolicy = "OnFailure";
          };
        };
        workload = {
          metadata = { inherit labels; };
          spec = {
          } // lib.optionalAttrs (config.workload.type == "cronjob") {
            schedule = config.workload.schedule;
            jobTemplate = {
              spec.template = template;
            };
          } // lib.optionalAttrs (config.workload.type == "deployment") {
            replicas = 1;
            selector = {
              matchLabels = {
                "app.kubernetes.io/name" = name;
                "app.kubernetes.io/instance" = name;
              };
            };
            template = template;
            strategy = lib.mkIf (config.workload.strategy != null) {
              type = config.workload.strategy;
            };
          };
        };
      in {
        cronJobs.${name} = lib.mkIf (config.workload != null && config.workload.type == "cronjob") workload;
        deployments.${name} = lib.mkIf (config.workload != null && config.workload.type == "deployment") workload;
        services.${name} = lib.mkIf (config.workload != null && config.workload.port != null) {
          metadata = { inherit labels; };
          spec = {
            selector = {
              "app.kubernetes.io/name" = name;
            };
            ports = [
              {
                protocol = "TCP";
                port = 80;
                targetPort = "http";
              }
            ];
          };
        };
      };
    };
  };
}
