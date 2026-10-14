{
  flake.modules.apps.boxmon = { generators, lib, ... }: let
    namespace = "boxmon";
    project = "media";
  in {
    applications.boxmon = {
      inherit namespace project;

      createNamespace = true;

      templates.app.boxmon = {
        workload = {
          image = "scarey.dev/scarey/boxmon";
          version = "f9c300b";
          port = 4000;
          env = {
            CATEGORIES = "movies,tv";
            LANG = "C.UTF-8";
            PHX_HOST = "boxmon.vegapunk.cloud";
            PHX_PORT = "443";
            PHX_SERVER = "true";
            RELEASE_DISTRIBUTION = "none";
          };
          envSecret = "boxmon";
        };
        route = {};
      };

      templates.externalSecret.boxmon = {
        secrets.QBIT_URL.key = "/boxmon/QBIT_URL";
        secrets.QBIT_API_KEY.key = "/boxmon/QBIT_API_KEY";
        secrets.HTTP_URL.key = "/boxmon/HTTP_URL";
        secrets.HTTP_USER.key = "/boxmon/HTTP_USER";
        secrets.HTTP_PASS.key = "/boxmon/HTTP_PASS";
        passwords.RELEASE_COOKIE = {};
        passwords.SECRET_KEY_BASE = { length = 64; };
      };

      resources.agentgatewayPolicies.boxmon.spec = {
        targetRefs = [
          { group = "gateway.networking.k8s.io"; kind = "HTTPRoute"; name = "boxmon"; }
        ];
        traffic.transformation.request.set = [ { name = "x-forwarded-proto"; value = "request.scheme"; } ];
      };
    };
  };
}
