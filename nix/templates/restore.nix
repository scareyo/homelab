{ lib, ... }:

{
  templates.restore = {
    options = with lib; {
      namespace = mkOption {
        type = lib.types.str;
        default = "velero";
        description = "";
      };
    };
    output = { name, config, ...  }: let
      cfg = config;
    in {
      "velero.io".v1.Restore.${name} = {
        metadata = {
          name = "${name}";
          namespace = "${cfg.namespace}";
          annotations = {
            "argocd.argoproj.io/sync-wave" = "-10";
          };
        };
        spec = {
          scheduleName = "${name}";
          restorePVs = true;
          includedResources = [
            "pvc"
          ];
        };
      };
    };
  };
}
