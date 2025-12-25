{ lib, name, namespace, route }:

let
  workload = {
    image = "quay.io/oauth2-proxy/oauth2-proxy:v7.13.0";
    port = 4180;
    env = {
      OAUTH2_PROXY_CLIENT_ID = {
        secretKeyRef = {
          key = "client-id";
          name = "oidc";
        };
      };
      OAUTH2_PROXY_CLIENT_SECRET = {
        secretKeyRef = {
          key = "client-secret";
          name = "oidc";
        };
      };
      OAUTH2_PROXY_COOKIE_SECRET = {
        secretKeyRef = {
          key = "cookie-secret";
          name = "oidc";
        };
      };
    };
  };
in {
  deployment = lib.mkIf (route != null && route.enableAuth)
    (import ./deployment.nix {
      inherit lib;
      inherit workload;

      name = "oauth2-proxy";
      persistence = {};
    });

  service = lib.mkIf (route != null && route.enableAuth)
    (import ./service.nix {
      name = "oauth2-proxy";
    });

  configMap = let
    hostname = (if route.hostname == null then "${name}.vegapunk.cloud" else route.hostname);
  in lib.mkIf (route != null && route.enableAuth) {
    data."oauth2_proxy.cfg" = ''
      upstreams="http://${name}.${namespace}.svc.cluster.local"
      email_domains="*"
      redirect_url="https://${hostname}/oauth2/callback"
      provider="oidc"
      scope="openid email profile groups"
      oidc_issuer_url="https://id.vegapunk.cloud"
      provider_display_name="Pocket ID"
      custom_sign_in_logo="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg"
      banner="Prowlarr"
      insecure_oidc_allow_unverified_email="true"
    '';
  };
}
