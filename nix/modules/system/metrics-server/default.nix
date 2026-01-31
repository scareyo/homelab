{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.metrics-server;
  namespace = "kube-system";
  project = "system";
in
{
  options = {
    vegapunk.metrics-server.enable = lib.mkEnableOption "Enable Metrics Server";
  };

  config = lib.mkIf cfg.enable {
    applications.metrics-server = {
      inherit namespace project;

      helm.releases.metrics-server = {
        chart = charts.metrics-server;
        values = {
          args = [ "--kubelet-insecure-tls" ];
          apiService.insecureSkipTLSVerify = false;
          tls.type = "cert-manager";
        };
      };

      ignoreDifferences.insecureSkipTLSVerify = {
        group = "apiregistration.k8s.io";
        kind = "APIService";
        jqPathExpressions = [ ".spec.insecureSkipTLSVerify" ];
      };
    };
  };
}
