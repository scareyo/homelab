{
  flake.modules.apps.sonarr = { generators, lib, ... }: let
    namespace = "media";
    project = "media";
  in {
    applications.sonarr = {
      inherit namespace project;

      templates.app.sonarr = {
        workload = {
          image = "ghcr.io/home-operations/sonarr";
          version = "5.0.0.2635";
          port = 8989;
          env = {
            SONARR__AUTH__METHOD = "Oidc";
            SONARR__AUTH__OIDCUSERIDENTIFIER = "sam@scarey.me";
            SONARR__SERVER__TRUSTEDNETWORKS = "10.244.0.0/16";
          };
          envSecret = "sonarr-oidc-credentials";
        };
        persistence = {
          config = {
            type = "emptyDir";
            path = "/config";
          };
          tmp = {
            type = "emptyDir";
            path = "/tmp";
          };
          media = {
            type = "pvc";
            path = "/media";
            config = {
              existingClaim = "boxmon-media";
            };
          };
        };
        route = {};
      };

      resources.pocketIDOIDCClients.sonarr = {
        spec = {
          name = "Sonarr"; 
          description = "Monitor TV shows";
          launchUrl = "https://sonarr.vegapunk.cloud";
          callbackUrls = [ "https://sonarr.vegapunk.cloud/signin-oidc" ];
          logoutCallbackUrls = [ "https://sonarr.vegapunk.cloud/signout-callback-oidc" ];
          secret = {
            keys.issuerUrl = "SONARR__AUTH__OIDCAUTHORITY";
            keys.clientID = "SONARR__AUTH__OIDCCLIENTID";
            keys.clientSecret = "SONARR__AUTH__OIDCCLIENTSECRET";
          };
        };
      };

      resources.agentgatewayPolicies.sonarr.spec = {
        targetRefs = [
          { group = "gateway.networking.k8s.io"; kind = "HTTPRoute"; name = "sonarr"; }
        ];
        traffic.transformation.request.set = [ { name = "x-forwarded-proto"; value = "request.scheme"; } ];
      };
    };
  };
}
