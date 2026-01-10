{ lib, name, namespace, route }:

let
  image = "ghcr.io/techarohq/anubis";
  version = "v1.24.0";

  labels = {
    "app.kubernetes.io/name" = "anubis";
    "app.kubernetes.io/instance" = "anubis-${namespace}";
    "app.kubernetes.io/version" = version;
    "app.kubernetes.io/component" = "soul-weigher";
    "app.kubernetes.io/part-of" = namespace;
  };

  workload = {
    type = "deployment";
    image = image;
    version = version;
    port = 8080;
    command = null;
    args = null;
    env = {
      BIND = ":8080";
      DIFFICULTY = "4";
      METRICS_BIND = ":9090";
      SERVE_ROBOTS_TXT = "true";
      TARGET = "http://${route.serviceName}:${toString route.servicePort}";
      OG_PASSTHROUGH = "true";
      OG_EXPIRY_TIME = "24h";
      ED25519_PRIVATE_KEY_HEX = {
        secretKeyRef = {
          key = "key";
          name = "${route.anubis.secret}";
        };
      };
    };
    dnsPolicy = null;
  };
in {
  deployment = (import ./deployment.nix {
    inherit lib;
    inherit labels;
    inherit workload;

    persistence = null;

    name = "anubis";
  });

  service = (import ./service.nix {
    inherit labels;
    name = "anubis";
  });
}
