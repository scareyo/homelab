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

        ((pkgs.omnictl.override {
          buildGoModule = pkgs.buildGo127Module;
        }).overrideAttrs (finalAttrs: previousAttrs: rec {
          version = "1.12.1";

          src = fetchFromGitHub {
            owner = "siderolabs";
            repo = "omni";
            rev = "v${version}";
            hash = "sha256-nERNdWZLCw/7o03MH7y+PpglA72Yf/llKvSJNQeLS1k=";
          };

          vendorHash = "sha256-2bHYQdNMZPNpw7DzYBSHU044dx9cWU95Cwf5zev4Aqg=";
        }))

        inputs.nixidy.packages.${system}.default
      ];
    };
  };
}
