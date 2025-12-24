{ config, name }:

{
  metadata = {
    name = "${config.namespace}-${name}";
    namespace = config.backup.${name}.namespace;
    annotations = {
      "argocd.argoproj.io/sync-wave" = "-10";
    };
  };
  spec = {
    scheduleName = "${config.namespace}-${name}";
    restorePVs = true;
    includedResources = [
      "pvc"
    ];
  };
}
