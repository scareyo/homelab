{
  initContainers = [
    {
      name = "velero-plugin-for-aws";
      image = "velero/velero-plugin-for-aws:v1.12.0";
      imagePullPolicy = "IfNotPresent";
      volumeMounts = [
        {
          mountPath = "/target";
          name = "plugins";
        }
      ];
    }
  ];
  configuration = {
    backupSyncPeriod = "1h";
    backupStorageLocation = [
      {
        #name = "backblaze";
        provider = "aws";
        bucket = "cloud-vegapunk-velero";
        credential = {
          name = "backblaze";
          key = "key";
        };
        config = {
          region = "us-east-005";
          s3Url = "https://s3.us-east-005.backblazeb2.com";
          checksumAlgorithm = "";
        };
      }
      {
        name = "garage";
        provider = "aws";
        bucket = "cloud-vegapunk-velero";
        credential = {
          name = "garage";
          key = "key";
        };
        config = {
          region = "garage";
          s3Url = "http://nami.int.scarey.me:30188";
          checksumAlgorithm = "";
        };
      }
    ];
    features = "EnableCSI";
    volumeSnapshotLocation = [
      {
        #name = "backblaze";
        provider = "aws";
        credential = {
          name = "backblaze";
          key = "key";
        };
        config = {
          region = "us-east-005";
        };
      }
      {
        name = "garage";
        provider = "aws";
        credential = {
          name = "garage";
          key = "key";
        };
        config = {
          region = "garage";
        };
      }
    ];
  };
  deployNodeAgent = true;
  kubectl = {
    # TODO: https://github.com/vmware-tanzu/helm-charts/issues/698
    image.tag = "1.33.4";
  };
  credentials.useSecret = false;
}
