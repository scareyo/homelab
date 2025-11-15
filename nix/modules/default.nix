{
  imports = [
    ./argocd
    ./cert-manager
    ./cilium
    ./external-secrets
    ./gateway

    ../templates
  ];

  nixidy.applicationImports = [
    ../generated/cert-manager.nix
    ../generated/cilium.nix
    ../generated/external-secrets.nix
    ../generated/gateway-api.nix
  ];
}
