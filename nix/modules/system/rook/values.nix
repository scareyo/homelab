{
  cephImage = {
    repository = "quay.io/ceph/ceph";
    tag = "v19.2.3";
    imagePullPolicy = "IfNotPresent";
  };
  cephClusterSpec = {
    mgr.modules = [
      {
        name = "rook";
        enabled = true;
      }
    ];
    dashboard.ssl = false;
    storage = {
      allowDeviceClassUpdate = false;
      allowOsdCrushWeightUpdate = false;
      scheduleAlways = false;
      onlyApplyOSDPlacement = false;
    };
    csi = {
      readAffinity.enabled = false;
      cephfs = {};
    };
    healthCheck = {
      daemonHealth = {};
      startupProbe = {
        mon.disabled = false;
        mgr.disabled = false;
        osd.disabled = false;
      };
    };
  };
  cephBlockPoolsVolumeSnapshotClass = {
    enabled = true;
    labels."velero.io/csi-volumesnapshot-class" = "true";
  };
}
