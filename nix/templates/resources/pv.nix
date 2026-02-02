{ lib, labels, name, persistence }:

{
  metadata = {
    inherit labels;
  };
  spec = {
    accessModes = persistence.${name}.config.accessMode;
    persistentVolumeReclaimPolicy = "Retain";
    storageClassName = "nfs-static";
    capacity.storage = persistence.${name}.config.size;
    nfs = {
      server = persistence.${name}.config.nfs.server;
      path = persistence.${name}.config.nfs.path;
    };
  };
}
