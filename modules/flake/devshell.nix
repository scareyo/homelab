{ inputs, ... }:

{
  perSystem = { pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        claude-code
        gitleaks
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
