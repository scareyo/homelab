{ lib }:

lib.types.submodule {
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
}
