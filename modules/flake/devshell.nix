{ inputs, ... }:

{
  perSystem = { pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        attic-client
        claude-code
        gitleaks
        infisical
        just
        pre-commit
        trufflehog
        yq-go

        # Kubernetes
        argocd
        cilium-cli
        k9s
        kubectl
        kubelogin-oidc
        kubernetes-helm
        talosctl
        velero

        omnictl

        inputs.nixidy.packages.${system}.default
      ];
    };
  };
}
