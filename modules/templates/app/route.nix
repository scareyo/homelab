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

            auth = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkEnableOption "Enable OAuth2-Proxy";

                  banner = lib.mkOption {
                    type = lib.types.str;
                    default = "OAuth2-Proxy";
                    description = "OAuth2-Proxy application banner";
                  };

                  logo = lib.mkOption {
                    type = lib.types.str;
                    default = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/oauth2-proxy.svg";
                    description = "OAuth2-Proxy application icon";
                  };

                  skipAuthRoutes = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [];
                    description = "List of path regex that will bypass authentication";
                  };
                };
              };
              default = {};
              description = "Auth settings";
            };

            anubis = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkEnableOption "Enable Anubis";

                  secret = lib.mkOption {
                    type = lib.types.str;
                    default = "anubis";
                    description = "Secret containing Anubis signing key";
                  };
                };
              };
              default = {};
              description = "Anubis settings";
            };
          };
        });
      };
      output = { name, config, ...  }: {
        httpRoutes."${name}" = {
          metadata = {
            #inherit labels;

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
                    name = name;
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
