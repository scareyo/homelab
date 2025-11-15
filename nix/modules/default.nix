{
  imports = [
    ./argocd
    ./cert-manager
    ./cilium
    ./external-secrets
    ./gateway
  ];

  nixidy.applicationImports = [
    ../generated/certmanager.nix
    ../generated/cilium.nix
    ../generated/externalsecrets.nix
    ../generated/gatewayapi.nix
  ];
}
