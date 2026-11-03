{
  flake.modules.apps.garage = { lib, pkgs, ... }: let
    namespace = "garage";
    project = "system";
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
            existingRpcSecret = "garage";
            kubernetesSkipCrd = true;

            s3 = {
              api.rootDomain = ".garage.vegapunk.cloud";
              web.rootDomain = ".web.vegapunk.cloud";
            };
          };

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

      templates.app.garage-s3.route = {
        hostname = "garage.vegapunk.cloud";
        serviceName = "garage";
        servicePort = 3900;
      };

      templates.app.garage-web.route = {
        hostname = "web.vegapunk.cloud";
        serviceName = "garage";
        servicePort = 3902;
      };

      templates.externalSecret.garage = {
        passwords.rpcSecret = { length = 32; encoding = "hex"; };
      };
    };
  };
}
