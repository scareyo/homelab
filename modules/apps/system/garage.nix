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
            compressionLevel = "none";
            existingRpcSecret = "garage";
            kubernetesSkipCrd = true;

            s3 = {
              api.rootDomain = ".garage.vegapunk.cloud";
              web.rootDomain = ".web.vegapunk.cloud";
            };
          };

          service.admin.enabled = true;

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
            garage = {
              endpoint = "http://garage:3900";
              adminEndpoint = "http://garage-admin:3903";
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
              #oidc = {
              #  enabled = true;
              #  provider_name = "Pocket ID";
              #};
            };
          };
        };
      };

      templates.externalSecret.garage = {
        passwords.adminToken = { length = 32; encoding = "base64"; };
        passwords.rpcSecret = { length = 32; encoding = "hex"; };
        templates.jwtSecret = ''{{ genPrivateKey "ed25519" }}'';
      };
    };
  };
}
