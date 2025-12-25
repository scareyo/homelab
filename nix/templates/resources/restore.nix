{ name, namespace, backup }:

{
  metadata = {
    name = "${namespace}-${name}";
    namespace = backup.namespace;
    annotations = {
      "argocd.argoproj.io/sync-wave" = "-10";
    };
  };
  spec = {
    scheduleName = "${namespace}-${name}";
    restorePVs = true;
    includedResources = [
      "pvc"
    ];
  };
}
