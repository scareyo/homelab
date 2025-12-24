{ config, name }:

{
  metadata = {
    name = "${config.namespace}-${name}";
    namespace = config.backup.${name}.namespace;
  };
  spec = {
    schedule = config.backup.${name}.schedule;
    template = {
      ttl = config.backup.${name}.ttl;
      includedNamespaces = [
        config.namespace
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
