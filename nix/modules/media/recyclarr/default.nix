{ config, lib, ... }:

let
  cfg = config.vegapunk.recyclarr;
  namespace = "recyclarr";
  project = "media";
in
{
  options = {
    vegapunk.recyclarr.enable = lib.mkEnableOption "Enable Recyclarr";
  };

  config = lib.mkIf cfg.enable {
    applications.recyclarr = {
      inherit namespace project;

      createNamespace = true;

      templates.app.recyclarr = {
        inherit namespace;

        workload = {
          type = "cronjob";
          image = "ghcr.io/recyclarr/recyclarr";
          version = "7.5.2";
          args = [
            "sync"
            "--config"
            "/cfg/recyclarr.yaml"
          ];
          env = {
            SONARR_API_KEY = {
              secretKeyRef = {
                key = "sonarr-api-key";
                name = "recyclarr";
              };
            };
            RADARR_API_KEY = {
              secretKeyRef = {
                key = "radarr-api-key";
                name = "recyclarr";
              };
            };
          };
        };

        persistence = {
          config = {
            type = "cm";
            path = "/cfg";
            config = {
              data = {
                "recyclarr.yaml" = ''
                  radarr:
                    uhd-bluray-web:
                      base_url: http://radarr.radarr
                      api_key: !env_var RADARR_API_KEY

                      include:
                        - template: radarr-quality-definition-movie
                        - template: radarr-quality-profile-uhd-bluray-web
                        - template: radarr-custom-formats-uhd-bluray-web
                        - template: radarr-quality-profile-remux-web-1080p
                        - template: radarr-custom-formats-remux-web-1080p

                      custom_formats:
                        # Movie Versions
                        - trash_ids:
                            - 570bc9ebecd92723d2d21500f4be314c # Remaster
                            - eca37840c13c6ef2dd0262b141a5482f # 4K Remaster
                            - 9f6cbff8cfe4ebbc1bde14c7b7bec0de # IMAX Enhanced
                          assign_scores_to:
                            - name: UHD Bluray + WEB
                            - name: Remux + WEB 1080p

                        - trash_ids:
                            - 923b6abef9b17f937fab56cfcf89e1f1 # DV (w/o HDR fallback)
                            - b337d6812e06c200ec9a2d3cfa9d20a7 # DV Boost
                            - caa37d0df9c348912df1fb1d88f9273a # HDR10+ Boost
                          assign_scores_to:
                            - name: UHD Bluray + WEB

                        - trash_ids:
                            - 25c12f78430a3a23413652cbd1d48d77 # SDR (no WEBDL)
                          assign_scores_to:
                            - name: UHD Bluray + WEB
                            - name: Remux + WEB 1080p
                  sonarr:
                    web-2160p-v4:
                      base_url: http://sonarr.sonarr
                      api_key: !env_var SONARR_API_KEY

                      include:
                        - template: sonarr-quality-definition-series
                        - template: sonarr-v4-custom-formats-web-2160p
                        - template: sonarr-quality-definition-anime
                        - template: sonarr-v4-quality-profile-anime
                        - template: sonarr-v4-custom-formats-anime

                      quality_profiles:
                        - name: WEB-2160p
                          reset_unmatched_scores:
                            enabled: true
                          upgrade:
                            allowed: true
                            until_quality: WEB 2160p
                            until_score: 10000
                          min_format_score: 0
                          quality_sort: top
                          qualities:
                            - name: WEB 2160p
                              qualities:
                                - WEBDL-2160p
                                - WEBRip-2160p
                            - name: WEB 1080p
                              qualities:
                                - WEBDL-1080p
                                - WEBRip-1080p

                      custom_formats:
                        # HDR Formats
                        - trash_ids:
                            - 9b27ab6498ec0f31a3353992e19434ca # DV (w/o HDR fallback)
                            - 0c4b99df9206d2cfac3c05ab897dd62a # HDR10+ Boost
                            - 7c3a61a9c6cb04f52f1544be6d44a026 # DV Boost
                          assign_scores_to:
                            - name: WEB-2160p
                '';
              };
            };
          };
          data = {
            type = "pvc";
            path = "/config";
            config = {
              size = "4Gi";
            };
          };
        };

        backup = {
          daily = {
            restore = true;
            schedule = "0 4 * * *";
            ttl = "168h0m0s"; # 1 week
          };
        };
      };

      templates.externalSecret.recyclarr = {
        keys = [
          { source = "/sonarr/API_KEY"; dest = "sonarr-api-key"; }
          { source = "/radarr/API_KEY"; dest = "radarr-api-key"; }
        ];
      };
    };
  };
}
