{
  flake.modules.apps.external-snapshotter = { generators, lib, ... }: let
    namespace = "external-snapshotter";
    project = "system";
    charts.snapshot-controller = {
      repo = "https://piraeus.io/helm-charts";
      chart = "snapshot-controller";
      version = "5.4.0";
      chartHash = "sha256-bp7OBFg9TWq3pn1ImNHN0Zwpi6bqjgAdJSUb7nAwSBY=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.external-snapshotter = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.snapshot-controller = {
        chart = chart.snapshot-controller;
        values = {
          webhook.tls = {
            autogenerate = false;
            certManagerIssuerRef = {
              kind = "Issuer";
              name = "selfsigned";
            };
          };
        };
      };

      resources.issuers.selfsigned = {
        spec.selfSigned = {};
      };
    };
  };
}
