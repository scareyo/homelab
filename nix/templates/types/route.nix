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

    enableAuth = lib.mkEnableOption "Enable OAuth2-Proxy";
  };
}
