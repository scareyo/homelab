{
  flake.modules.apps.external-snapshotter = { generators, lib, ... }: let
    namespace = "external-snapshotter";
    project = "system";
    charts.snapshot-controller = {
      repo = "https://piraeus.io/helm-charts";
      chart = "snapshot-controller";
      version = "5.3.0";
      chartHash = "sha256-FU4qnEI90aRidjgpLYSF1rudD+GmolEld8BjQbvu7GQ=";
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
