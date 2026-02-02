{
  immich.persistence.library.existingClaim = "library";

  controllers.main.containers.main.env = {
    REDIS_HOSTNAME = "valkey";
    DB_HOSTNAME = {
      valueFrom.secretKeyRef = {
        name = "immich-pg-app";
        key = "host";
      };
    };
    DB_USERNAME = {
      valueFrom.secretKeyRef = {
        name = "immich-pg-app";
        key = "username";
      };
    };
    DB_PASSWORD = {
      valueFrom.secretKeyRef = {
        name = "immich-pg-app";
        key = "password";
      };
    };
    DB_DATABASE_NAME = {
      valueFrom.secretKeyRef = {
        name = "immich-pg-app";
        key = "dbname";
      };
    };
  };
}
