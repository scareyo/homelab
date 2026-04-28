{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.obsidian;
  namespace = "obsidian";
  project = "general";
in
{
  options = {
    vegapunk.obsidian.enable = lib.mkEnableOption "Enable Obsidian LiveSync";
  };

  config = lib.mkIf cfg.enable {
    applications.obsidian = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.couchdb = {
        chart = charts.couchdb;
        values = {
          couchdbConfig.couchdb.uuid = "063521ad8331413ba49f017072cbd9d1";
          persistentVolume.enabled = true;
          createAdminSecret = false;
          extraSecretName = "couchdb";
        };
      };

      templates.externalSecret.couchdb = {
        keys = [
          { source = "/obsidian/ADMIN_USERNAME"; dest = "adminUsername"; }
          { source = "/obsidian/ADMIN_PASSWORD"; dest = "adminPassword"; }
          { source = "/obsidian/COOKIE_AUTH_SECRET"; dest = "cookieAuthSecret"; }
          { source = "/obsidian/ERLANG_COOKIE"; dest = "erlangCookie"; }
        ];
      };

      templates.app.obsidian.route = {
        serviceName = "couchdb-svc-couchdb";
        servicePort = 5984;
      };
    };
  };
}
