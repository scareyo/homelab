{ lib, name, namespace, route }:

let
  image = "quay.io/oauth2-proxy/oauth2-proxy";
  version = "v7.13.0";
  hostname = (if route.hostname == null then "${name}.vegapunk.cloud" else route.hostname);

  labels = {
    "app.kubernetes.io/name" = "oauth2-proxy";
    "app.kubernetes.io/instance" = "oauth2-proxy-${namespace}";
    "app.kubernetes.io/version" = version;
    "app.kubernetes.io/component" = "authentication-proxy";
    "app.kubernetes.io/part-of" = namespace;
  };

  persistence = {
    oauth2-proxy = {
      type = "cm";
      path = "/etc/oauth2_proxy";
      config = {
        data."oauth2_proxy.cfg" = ''
          upstreams="http://${name}.${namespace}.svc.cluster.local"
          email_domains="*"
          redirect_url="https://${hostname}/oauth2/callback"
          provider="oidc"
          scope="openid email profile groups"
          oidc_issuer_url="https://id.vegapunk.cloud"
          provider_display_name="Pocket ID"
          custom_sign_in_logo="${route.auth.logo}"
          banner="${route.auth.banner}"
          insecure_oidc_allow_unverified_email="true"
        '';
      };
    };
  };

  workload = {
    type = "deployment";
    component = "authentication-proxy";
    image = image;
    version = version;
    port = 8080;
    args = [
      "--http-address=0.0.0.0:8080"
      "--metrics-address=0.0.0.0:8081"
      "--config=/etc/oauth2_proxy/oauth2_proxy.cfg"
    ];
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
    dnsPolicy = null;
  };
in {
  deployment = (import ./deployment.nix {
    inherit lib;
    inherit labels;
    inherit persistence;
    inherit workload;

    name = "oauth2-proxy";
  });

  service = (import ./service.nix {
    inherit labels;
    name = "oauth2-proxy";
  });

  configMap = (import ./configmap.nix {
    inherit labels;
    persistence = persistence.oauth2-proxy;
  });
}
