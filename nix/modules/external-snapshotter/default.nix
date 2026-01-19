{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.external-snapshotter;
in
{
  options = {
    vegapunk.external-snapshotter.enable = lib.mkEnableOption "Enable CSI Snapshotter";
  };
  
  config = lib.mkIf cfg.enable {
    applications.external-snapshotter = {
      namespace = "kube-system";

      helm.releases.snapshot-controller = {
        chart = charts.snapshot-controller;
        values = {
          webhook = {
            tls.certManagerIssuerRef = {
              kind = "Issuer";
              name = "external-snapshotter";
            };
          };
        };
      };

      resources."cert-manager.io".v1.Issuer.external-snapshotter = {
        metadata = {
          labels = {
            "app.kubernetes.io/instance" = "snapshot-controller";
            "app.kubernetes.io/name" = "snapshot-controller";
          };
        };
        spec.selfSigned = {};
      };
    };
  };
}
