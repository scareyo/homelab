{
  flake.modules.templates.app = { lib, ... }: let
    containerOptions = {
      image = lib.mkOption {
        type = lib.types.str;
        description = "Container image";
      };

      version = lib.mkOption {
        type = lib.types.str;
        description = "Container image version";
      };

      command = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Container command";
      };

      args = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Container args";
      };

      env = lib.mkOption {
        type = lib.types.attrsOf (lib.types.oneOf [lib.types.str lib.types.attrs]);
        default = {};
        description = "Container env";
      };

      envSecret = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Secret to load as container env";
      };
    };
  in {
    templates.app = {
      options.workload = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = containerOptions // {
            type = lib.mkOption {
              type = lib.types.enum [
                "cronjob"
                "deployment"
              ];
              default = "deployment";
              description = "Workload type";
            };

            port = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Workload container port";
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

            initContainers = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options = containerOptions // {
                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "Init container name";
                  };
                };
              });
              default = [];
              description = "Init containers, run in order before the workload container";
            };
          };
        });
        default = null;
      };

      output = { name, config, options, ...  }: let
        labels = import ./_labels.nix { inherit lib name config options; };
        container = c: {
          image = "${c.image}:${c.version}";

          command = c.command;
          args = c.args;

          env = builtins.mapAttrs
            (_: v: {
              value = lib.mkIf (lib.isString v) v;
              valueFrom = lib.mkIf (lib.isAttrs v) v;
            }) c.env;

          envFrom = lib.mkIf (c.envSecret != null) [
            { secretRef.name = c.envSecret; }
          ];

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
        template = {
          metadata = { inherit labels; };
          spec = {
            containers.${name} = container config.workload // {
              ports.http = lib.mkIf (config.workload.port != null) {
                containerPort = config.workload.port;
              };
            };

            initContainers = lib.mkIf (config.workload.initContainers != [])
              (map (c: container c // { inherit (c) name; }) config.workload.initContainers);

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
