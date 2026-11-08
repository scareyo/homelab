{
  flake.modules.apps.garage = { lib, pkgs, ... }: let
    namespace = "garage";
    project = "system";
    charts.garage-ui = {
      repo = "oci://ghcr.io/noooste/charts";
      chart = "garage-ui";
      version = "0.14.0";
      chartHash = "sha256-fZm/3ahrp9vBn5E3erUhdjhc4scEmipHZVH+GsnS0b4=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
    src = pkgs.fetchgit {
      url = "https://git.deuxfleurs.fr/Deuxfleurs/garage.git";
      rev = "v2.5.0";
      hash = "sha256-5jWgH+hi0Ouqszapw00KOBHFjxlV/y4T7IB22IRaEHE=";
    };
  in {
    applications.garage = {
      inherit namespace project;

      createNamespace = true;

      yamls = [ (builtins.readFile "${src}/script/k8s/crd/garagenodes.deuxfleurs.fr.yaml") ];

      helm.releases.garage = {
        chart = "${src}/script/helm/garage";
        values = {
          garage = {
            dbEngine = "sqlite";
            singleNode = true;
            compressionLevel = ''"none"'';
            existingRpcSecret = "garage";
            kubernetesSkipCrd = true;

            s3 = {
              api.rootDomain = ".garage.vegapunk.cloud";
              web.rootDomain = ".web.vegapunk.cloud";
            };
          };

          service.admin.enabled = true;

          environment = [
            {
              name = "GARAGE_ADMIN_TOKEN";
              valueFrom.secretKeyRef = { name = "garage"; key = "adminToken"; };
            }
          ];

          nodeSelector."kubernetes.io/hostname" = "s-flamingo";

          persistence = {
            meta = {
              storageClass = "ceph-block";
              size = "2Gi";
            };
            data = {
              storageClass = "openebs-zfs-dataset";
              size = "2Ti";
            };
          };

          monitoring.metrics = {
            enabled = true;
            serviceMonitor.enabled = true;
          };
        };
      };

      helm.releases.garage-ui = {
        chart = chart.garage-ui;
        values = {
          config = {
            server = {
              root_url = "https://garage.vegapunk.cloud";
            };
            garage = {
              endpoint = "http://garage:3900";
              admin_endpoint = "http://garage-admin:3903";
              existingSecret = {
                name = "garage";
                key = "adminToken";
              };
            };
            auth = {
              jwt_private_key_secret = {
                name = "garage";
                key = "jwtSecret";
              };
              admin.enabled = false;
              oidc = {
                enabled = true;
                provider_name = "Pocket ID";
                scopes = [ "openid" "email" "profile" "groups" ];
                role_attribute_path = "groups";
                admin_role = "garage-admin";
                existingSecret = {
                  name = "garage-oidc-credentials";
                  key = "client_secret";
                };
              };
            };
          };
          extraEnvs = [
            {
              name = "GARAGE_UI_AUTH_OIDC_ISSUER_URL";
              valueFrom.secretKeyRef.name = "garage-oidc-credentials";
              valueFrom.secretKeyRef.key = "issuer_url";
            }
            {
              name = "GARAGE_UI_AUTH_OIDC_CLIENT_ID";
              valueFrom.secretKeyRef.name = "garage-oidc-credentials";
              valueFrom.secretKeyRef.key = "client_id";
            }
          ];
        };
      };

      templates.app.garage.route = {
        serviceName = "garage-ui";
      };

      templates.externalSecret.garage = {
        passwords.adminToken = { length = 32; encoding = "base64"; };
        passwords.rpcSecret = { length = 32; encoding = "hex"; };
        templates = {
          adminToken = "{{ .adminToken }}";
          rpcSecret = "{{ .rpcSecret }}";
          jwtSecret = ''{{ genPrivateKey "ed25519" }}'';
        };
      };

      resources.pocketIDOIDCClients.garage = {
        spec = {
          name = "Garage"; 
          logo.nameOverride = "garage";
          description = "Object storage";
          launchUrl = "https://garage.vegapunk.cloud";
          callbackUrls = [ "https://garage.vegapunk.cloud/auth/oidc/callback" ];
        };
      };

      resources.pocketIDUserGroups.garage-admin = {};
    };
  };
}
