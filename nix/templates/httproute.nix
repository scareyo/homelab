{ lib, ... }:

{
  templates.httpRoute = {
    options = with lib; {
      gateway = mkOption {
        type = lib.types.str;
        default = "internal";
        description = "";
      };
      hostname = mkOption {
        type = lib.types.str;
        description = "";
      };
      serviceName = mkOption {
        type = lib.types.str;
        description = "";
      };
      servicePort = mkOption {
        type = lib.types.int;
        default = 80;
        description = "";
      };
    };
    output = { name, config, ...  }: let
      cfg = config;
    in {
      "gateway.networking.k8s.io".v1.HTTPRoute.${name} = {
        metadata = {
          name = "${name}";
        };
        spec = {
          parentRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "Gateway";
              name = "${cfg.gateway}";
              namespace = "gateway";
            }
          ];
          hostnames = [
            "${cfg.hostname}"
          ];
          rules = [
            {
              matches = [
                {
                  path = {
                    type = "PathPrefix";
                    value = "/";
                  };
                }
              ];
              backendRefs = [
                {
                  group = "";
                  kind = "Service";
                  name = "${cfg.serviceName}";
                  port = cfg.servicePort;
                  weight = 1;
                }
              ];
            }
          ];
        };
      };
    };
  };
}
