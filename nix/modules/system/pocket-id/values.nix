{
  host = "id.vegapunk.cloud";
  timeZone = "America/New_York";
  database = {
    provider = "postgres";
    connectionString = "postgres://";
  };

  secret.create = false;

  persistence.data.enabled = true;
}
