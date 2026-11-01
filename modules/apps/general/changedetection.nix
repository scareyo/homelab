let
  images = {
    changedetection = {
      image = "ghcr.io/dgtlmoon/changedetection.io";
      version = "0.60.9";
    };
    sockpuppetbrowser = {
      image = "docker.io/dgtlmoon/sockpuppetbrowser";
      version = "latest@sha256:1d8f72d2ce2085faed4232e5ae1e65c02efe5b831a18e127829b267c260b4fb2";
    };
  };
in {
  flake.modules.apps.changedetection = { lib, ... }: let
    namespace = "changedetection";
    project = "development";
  in {
    applications.changedetection = {
      inherit namespace project;

      createNamespace = true;

      templates.app.changedetection = {
        workload = {
          inherit (images.changedetection) image version;
          port = 5000;
          env = {
            BASE_URL = "https://changedetection.vegapunk.cloud";
            PLAYWRIGHT_DRIVER_URL = "ws://browser";
          };
        };
        persistence = {
          datastore = {
            type = "pvc";
            path = "/datastore";
            config = {
              size = "5Gi";
            };
          };
          tmp = {
            type = "emptyDir";
            path = "/tmp";
          };
        };
        route = {};
        auth = {
          name = "changedetection.io";
          description = "Website change detection and monitoring";
          logo = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/changedetection.webp";
        };
      };

      templates.app.browser = {
        workload = {
          inherit (images.sockpuppetbrowser) image version;
          port = 3000;
        };
        persistence = {
          home = {
            type = "emptyDir";
            path = "/home/chrome";
          };
          tmp = {
            type = "emptyDir";
            path = "/tmp";
          };
        };
      };

      templates.backup.changedetection-daily = {
        restore = true;
        schedule = "0 6 * * *"; # At 06:00 daily
        ttl = "360h";           # 15 days
        selector."app.kubernetes.io/instance" = "changedetection";
      };
    };
  };
}
