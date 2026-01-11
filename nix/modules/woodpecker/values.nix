{
  metrics.enabled = true;
  prometheus.podmonitor.enabled = true;
  server = {
    createAgentSecret = false;
    env = {
      WOODPECKER_AGENT_SECRET = {
        valueFrom.secretKeyRef = {
          key = "agent-secret";
          name = "woodpecker";
        };
      };

      WOODPECKER_DATABASE_DRIVER = "postgres";
      WOODPECKER_DATABASE_DATASOURCE = {
        valueFrom.secretKeyRef = {
          key = "uri";
          name = "woodpecker-app";
        };
      };

      WOODPECKER_HOST = "https://ci.vegapunk.cloud";
      WOODPECKER_OPEN = "true";
      WOODPECKER_ADMIN = "administrator";

      WOODPECKER_FORGEJO = "true";
      WOODPECKER_FORGEJO_URL = "https://dev.vegapunk.cloud";
      WOODPECKER_FORGEJO_CLIENT = {
        valueFrom.secretKeyRef = {
          key = "client";
          name = "oidc";
        };
      };
      WOODPECKER_FORGEJO_SECRET = {
        valueFrom.secretKeyRef = {
          key = "secret";
          name = "oidc";
        };
      };
    };
  };
  agent = {
    mapAgentSecret = false;
    env = {
      WOODPECKER_AGENT_SECRET = {
        valueFrom.secretKeyRef = {
          key = "agent-secret";
          name = "woodpecker";
        };
      };
    };
  };
}
