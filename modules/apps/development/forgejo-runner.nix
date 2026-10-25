{
  flake.modules.apps.forgejo-runner = { lib, ... }: let
    namespace = "forgejo-runner";
    project = "development";
    charts.forgejo-runner = {
      repo = "oci://git.erwanleboucher.dev/eleboucher/charts";
      chart = "forgejo-runner";
      version = "13.2.1";
      chartHash = "sha256-0JYD+DufwJ9yQ9QTfw11nB81cjDgGDhSC8SkHNF2j+s=";
    };
    chart = lib.mapAttrs (_: lib.helm.downloadHelmChart) charts;
  in {
    applications.forgejo-runner = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.forgejo-runner = {
        chart = chart.forgejo-runner;
        values = {
          forgejo = {
            url = "http://forgejo-http.forgejo:3000";
            existingSecret = "forgejo-runner";
          };
          runnerConfig = ''
            cache:
              enabled: true
              dir: /data/cache
              port: 8088
              proxy_port: 8089
            container:
              docker_host: "-"
              workdir_parent: shared/workdir
            host:
              workdir_parent: /data/act
            log:
              level: info
            plugins:
              k8s:
                address: "unix:///plugin/forgejo-runner-k8s.sock"
                options:
                  namespace: forgejo-runner
                  poll_timeout: 10m
                  labels: "app.kubernetes.io/name=forgejo-runner-instance"
                  resources: |
                    requests:
                      cpu: 100m
                      memory: 256Mi
                    limits:
                      memory: 1Gi
            runner:
              capacity: 3
              labels:
                - ubuntu-latest:k8s:///config/podspec-default.yaml
                - default:k8s:///config/podspec-default.yaml
              timeout: 3h
              shutdown_timeout: 3m
          '';
          podSpecs."podspec-default.yaml" = ''
            containers:
              - name: main
                image: ghcr.io/bjw-s-labs/forgejo-runner:ubuntu-24.04
                imagePullPolicy: IfNotPresent
                env:
                  - name: DEBIAN_FRONTEND
                    value: noninteractive
                resources:
                  requests:
                    cpu: 100m
                    memory: 1Gi
                  limits:
                    cpu: 500m
                    memory: 4Gi
            restartPolicy: Never
          '';
        };
      };

      templates.externalSecret.forgejo-runner.secrets = {
        uuid.key = "/forgejo-runner/RUNNER_UUID";
        token.key = "/forgejo-runner/RUNNER_TOKEN";
      };
    };
  };
}
