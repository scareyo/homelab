{ generators, lib, pkgs }:

let
  crds = {
    cert-manager = generators.fromCRD {
      name = "cert-manager";
      src = pkgs.fetchFromGitHub {
        owner = "cert-manager";
        repo = "cert-manager";
        rev = "v1.19.1";
        hash = "sha256-OK6U9QIRYolLBjcNBhzFmZZqfBFoJzY8aUHew2F0MAQ=";
      };
      crds = [
        "deploy/crds/cert-manager.io_clusterissuers.yaml"
      ];
    };

    cilium = generators.fromCRD {
      name = "cilium";
      src = pkgs.fetchFromGitHub {
        owner = "cilium";
        repo = "cilium";
        rev = "v1.18.4";
        hash = "sha256-m7RSxl5gVnPVkw0Ql9YuAl0kCvqnIV5yghFaO+Qje/A=";
      };
      crds = [
        "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpadvertisements.yaml"
        "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpclusterconfigs.yaml"
        "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgppeerconfigs.yaml"
        "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumloadbalancerippools.yaml"
        "pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumgatewayclassconfigs.yaml"
      ];
    };

    cnpg = generators.fromCRD {
      name = "cnpg";
      src = pkgs.fetchFromGitHub {
        owner = "cloudnative-pg";
        repo = "cloudnative-pg";
        rev = "v1.27.1";
        hash = "sha256-iEia3g3nxnVm4q5lpV9SFOSKgHJsZ7jdqE73vA2bPpI=";
      };
      crds = [
        "config/crd/bases/postgresql.cnpg.io_clusters.yaml"
        "config/crd/bases/postgresql.cnpg.io_databases.yaml"
      ];
    };

    external-secrets = generators.fromCRD {
      name = "external-secrets";
      src = pkgs.fetchFromGitHub {
        owner = "external-secrets";
        repo = "external-secrets";
        rev = "v1.0.0";
        hash = "sha256-BRNI2XRbvxn2syN9OaZ3Sgl3oD4g5E+rQR0Npq70IpQ=";
      };
      crds = [
        "config/crds/bases/external-secrets.io_clustersecretstores.yaml"
        "config/crds/bases/external-secrets.io_externalsecrets.yaml"
        "config/crds/bases/generators.external-secrets.io_passwords.yaml"
      ];
    };

    gateway-api = generators.fromCRD {
      name = "gateway-api";
      src = pkgs.fetchFromGitHub {
        owner = "kubernetes-sigs";
        repo = "gateway-api";
        rev = "v1.4.0";
        hash = "sha256-osM8BRqFw5he93yTTTQb/q9iVvT6oWkCb731n/C6bq4=";
      };
      crds = [
        "config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml"
        "config/crd/standard/gateway.networking.k8s.io_gateways.yaml"
        "config/crd/standard/gateway.networking.k8s.io_httproutes.yaml"
      ];
    };

    rook = generators.fromCRD {
      name = "rook";
      src = pkgs.fetchFromGitHub {
        owner = "rook";
        repo = "rook";
        rev = "v1.18.8";
        hash = "sha256-9hkHA89NCzLDS6pPfIS8UIfify5MnVSXzpuETgqD6j8=";
      };
      crds = [
        "deploy/olm/assemble/objectbucket.io_objectbucketclaims.yaml"
      ];
    };

    velero = generators.fromCRD {
      name = "velero";
      src = pkgs.fetchFromGitHub {
        owner = "vmware-tanzu";
        repo = "velero";
        rev = "v1.17.1";
        hash = "sha256-ZVnYHBcnYOCBFJ9wyvMDrRIf3NyDV1Zqqf7e6JbA+go=";
      };
      crds = [
        "config/crd/v1/bases/velero.io_restores.yaml"
        "config/crd/v1/bases/velero.io_schedules.yaml"
      ];
    };

    victoria-metrics = generators.fromCRD {
      name = "victoria-metrics";
      src = pkgs.fetchFromGitHub {
        owner = "VictoriaMetrics";
        repo = "helm-charts";
        rev = "victoria-metrics-operator-0.57.1";
        hash = "sha256-2ABmmlTpX5ypjaIvqYduz6hZAy8hN3DsnSfVTnyWm+w=";
      };
      crds = [
        "charts/victoria-metrics-operator/charts/crds/crds/crd.yaml"
      ];
    };

  };
  names = builtins.attrNames crds;
  values = builtins.attrValues crds;
in
pkgs.stdenv.mkDerivation {
  name = "crds";
  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out

    names="${lib.concatStringsSep " " names}"
    values="${lib.concatStringsSep " " values}"

    set -f
    set -- $names
    for crd in $values; do
      cp -r "$crd" "$out/$1.nix"
      shift
    done
  '';
}
