{ name, namespace, backup }:

{
  metadata = {
    name = "${namespace}-${name}";
    namespace = backup.namespace;
  };
  spec = {
    schedule = backup.schedule;
    template = {
      ttl = backup.ttl;
      includedNamespaces = [
        namespace
      ];
      includedResources = [
        "pv"
        "pvc"
      ];
      snapshotVolumes = true;
      snapshotMoveData = true;
    };
  };
}
