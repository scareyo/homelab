{ lib, ... }:

{
  templates.postgres = {
    options = {
      instances = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "";
      };
      size = lib.mkOption {
        type = lib.types.str;
        default = "32Gi";
        description = "";
      };
    };
    output = { name, config, ...  }: let
      cfg = config;
    in {
      "postgresql.cnpg.io".v1.Cluster.${name} = {
        metadata = {
          name = "${name}";
        };
        spec = {
          instances = cfg.instances;
          storage.size = cfg.size;
          imageName = "ghcr.io/cloudnative-pg/postgresql:18";
        };
      };
    };
  };
}
