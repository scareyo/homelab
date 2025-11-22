{ lib, ... }:

{
  templates.httpRoute = {
    options = with lib; {
      gateway = mkOption {
        type = lib.types.str;
        default = "internal";
        description = "Gateway of the HTTPRoute";
      };
      hostname = mkOption {
        type = lib.types.str;
        description = "Hostname of the HTTPRoute";
      };
      serviceName = mkOption {
        type = lib.types.str;
        description = "Name of the referenced service";
      };
      servicePort = mkOption {
        type = lib.types.int;
        default = 80;
        description = "Port of the referenced service";
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
