{
  cephClusterSpec = {
    cephVersion.image = "quay.io/ceph/ceph:v19.2.3";
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
