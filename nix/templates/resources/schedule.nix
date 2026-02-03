{ labels, name, namespace, backup }:

{
  metadata = {
    inherit labels;

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

      storageLocation = backup.location;
      volumeSnapshotLocations = [ backup.location ];
    };
  };
}
