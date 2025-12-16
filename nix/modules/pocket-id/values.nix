{
  host = "id.vegapunk.cloud";
  timeZone = "America/New_York";
  database = {
    provider = "postgres";
    connectionString = "postgres://";
  };
  persistence.data.enabled = true;
}
