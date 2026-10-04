{
  flake.modules.templates.app = { lib, ... }: {
    templates.app = {
      options.route = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            gateway = lib.mkOption {
              type = lib.types.str;
              default = "internal";
              description = "Gateway of the HTTPRoute";
            };

            hostname = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Hostname of the HTTPRoute";
            };

            serviceName = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Name of the referenced service";
            };

            servicePort = lib.mkOption {
              type = lib.types.int;
              default = 80;
              description = "Port of the referenced service";
            };

            requestTimeout = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Duration before requests timeout";
            };

            # TODO: move to a separate auth module
            auth = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkEnableOption "OAuth2-Proxy";
                };
              };
              default = {};
              description = "Auth settings";
            };
          };
        });
      };
      output = { name, config, ...  }: {
        httpRoutes."${name}" = {
          metadata = {
            annotations = {
              "argocd.argoproj.io/sync-wave" = "10";
            };
          };
          spec = {
            parentRefs = [
              {
                group = "gateway.networking.k8s.io";
                kind = "Gateway";
                name = config.route.gateway;
                namespace = "gateway";
              }
            ];
            hostnames = [
              (if config.route.hostname == null then "${name}.vegapunk.cloud" else config.route.hostname)
            ];
            rules = [
              ({
                matches = [
                  {
                    path = {
                      type = "PathPrefix";
                      value = "/";
                    };
                  }
                ];
                backendRefs = [
                  ({
                    group = "";
                    kind = "Service";
                    name = config.route.serviceName;
                    port = config.route.servicePort;
                    weight = 1;
                  } // lib.optionalAttrs (config.route.serviceName == null) {
                    inherit name;
                  } // lib.optionalAttrs config.route.auth.enable {
                    name = "oauth2-proxy";
                    port = 80;
                  })
                ];
              } // lib.optionalAttrs (config.route.requestTimeout != null) {
                timeouts.request = config.route.requestTimeout;
              })
            ];
          };
        };
      };
    };
  };
}
