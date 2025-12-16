{
  nodeSelector."kubernetes.io/hostname" = "zeus";
  additionalTolerations = [
    {
      key = "hcloud";
      operator = "Equal";
      effect = "NoSchedule";
    }
  ];
  monitoring.podMonitor.enabled = true;
}
