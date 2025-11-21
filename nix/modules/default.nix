{
  imports = [
    ./argocd
    ./cert-manager
    ./cilium
    ./external-secrets
    ./external-snapshotter
    ./gateway
    ./monitoring
    ./rook
    ./velero

    ../templates
  ];

  nixidy.chartsDir = ../charts;

  nixidy.applicationImports = [
    ../generated/cert-manager.nix
    ../generated/cilium.nix
    ../generated/external-secrets.nix
    ../generated/gateway-api.nix
    ../generated/velero.nix
  ];
}
