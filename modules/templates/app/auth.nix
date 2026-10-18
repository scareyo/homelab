let
  images = {
    oauth2-proxy = {
      image = "quay.io/oauth2-proxy/oauth2-proxy";
      version = "v7.15.5";
    };
  };
in {
  flake.modules.templates.app = { lib, ... }: {
    templates.app = {
      options.auth = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "OAuth2-Proxy application name";
            };

            description = lib.mkOption {
              type = lib.types.str;
              description = "OAuth2-Proxy application description";
            };

            logo = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "OAuth2-Proxy application logo";
            };
          };
        });
        default = null;
      };

      output = { name, config, options, ...  }: let
        enabled = config.auth != null && lib.assertMsg (config.route != null && config.workload != null)
          "templates.app.${name}: auth requires route and workload to be set";
        hostname = (if config.route.hostname == null then "${name}.vegapunk.cloud" else config.route.hostname);
        upstream = if config.route.serviceName == null then name else config.route.serviceName;
        proxyConfig = ''
          upstreams="http://${upstream}.${options.namespace.value}.svc.cluster.local:${toString config.route.servicePort}"
          email_domains="*"
          redirect_url="https://${hostname}/oauth2/callback"
          provider="oidc"
          scope="openid email profile groups"
          provider_display_name="Pocket ID"
          custom_sign_in_logo="${config.auth.logo}"
          banner="${config.auth.name}"
          insecure_oidc_allow_unverified_email="true"
        '';
        labels = {
          "app.kubernetes.io/name" = "oauth2-proxy";
          "app.kubernetes.io/instance" = "oauth2-proxy-${name}";
          "app.kubernetes.io/version" = images.oauth2-proxy.version;
          "app.kubernetes.io/component" = "authentication-proxy";
          "app.kubernetes.io/part-of" = options.namespace.value;
        };
      in {
        configMaps."${name}-oauth2-proxy" = lib.mkIf enabled {
          data."oauth2_proxy.cfg" = proxyConfig;
        };

        deployments."${name}-oauth2-proxy" = lib.mkIf enabled {
          metadata = { inherit labels; };
          spec = {
            replicas = 1;
            selector = {
              matchLabels = {
                "app.kubernetes.io/name" = "oauth2-proxy";
                "app.kubernetes.io/instance" = "oauth2-proxy-${name}";
              };
            };
            template = {
              metadata = {
                inherit labels;
                annotations."checksum/config" = builtins.hashString "sha256" proxyConfig;
              };
              spec = {
                containers.oauth2-proxy = {
                  image = "${images.oauth2-proxy.image}:${images.oauth2-proxy.version}";
                  args = [
                    "--http-address=0.0.0.0:8080"
                    "--metrics-address=0.0.0.0:8081"
                    "--config=/etc/oauth2_proxy/oauth2_proxy.cfg"
                  ];

                  envFrom = [
                    { secretRef.name = "${name}-oauth2-proxy"; }
                    { secretRef.name = "${name}-oauth2-proxy-oidc-credentials"; }
                  ];

                  ports.http.containerPort = 8080;

                  securityContext = {
                    allowPrivilegeEscalation = false;
                    capabilities.drop = [ "ALL" ];
                    readOnlyRootFilesystem = true;
                  };

                  volumeMounts = [
                    { name = "config"; mountPath = "/etc/oauth2_proxy"; }
                  ];
                };

                securityContext = {
                  runAsUser = 1000;
                  runAsGroup = 1000;
                  fsGroup = 1000;
                  fsGroupChangePolicy = "OnRootMismatch";
                };

                volumes = [
                  { name = "config"; configMap.name = "${name}-oauth2-proxy"; }
                ];
              };
            };
          };
        };

        services."${name}-oauth2-proxy" = lib.mkIf enabled {
          metadata = { inherit labels; };
          spec = {
            selector = {
              "app.kubernetes.io/name" = "oauth2-proxy";
              "app.kubernetes.io/instance" = "oauth2-proxy-${name}";
            };
            ports = [
              {
                protocol = "TCP";
                port = 80;
                targetPort = "http";
              }
            ];
          };
        };

        passwords."${name}-oauth2-proxy" = lib.mkIf enabled {
          spec = {
            length = 32;
            noUpper = false;
            allowRepeat = true;
            secretKeys = [ "OAUTH2_PROXY_COOKIE_SECRET" ];
          };
        };

        externalSecrets."${name}-oauth2-proxy" = lib.mkIf enabled {
          spec = {
            target.name = "${name}-oauth2-proxy";
            dataFrom = [
              {
                sourceRef.generatorRef = {
                  apiVersion = "generators.external-secrets.io/v1alpha1";
                  kind = "Password";
                  name = "${name}-oauth2-proxy";
                };
              }
            ];
          };
        };

        pocketIDOIDCClients."${name}-oauth2-proxy" = lib.mkIf enabled {
          spec = {
            name = config.auth.name;
            description = config.auth.description;
            launchUrl = "https://${hostname}";
            callbackUrls = [ "https://${hostname}/oauth2/callback" ];
            allowedUserGroups = [ { name = "${name}-user"; } ];
            secret = {
              keys.issuerUrl = "OAUTH2_PROXY_OIDC_ISSUER_URL";
              keys.clientID = "OAUTH2_PROXY_CLIENT_ID";
              keys.clientSecret = "OAUTH2_PROXY_CLIENT_SECRET";
            };
          };
        };

        pocketIDUserGroups."${name}-user" = lib.mkIf enabled {};

        networkPolicies."${name}-oauth2-proxy" = lib.mkIf enabled {
          metadata = { inherit labels; };
          spec = {
            podSelector.matchLabels = {
              "app.kubernetes.io/name" = name;
              "app.kubernetes.io/instance" = name;
              "app.kubernetes.io/component" = "main";
            };
            policyTypes = [ "Ingress" ];
            ingress = [
              {
                from = [
                  {
                    podSelector.matchLabels = {
                      "app.kubernetes.io/name" = "oauth2-proxy";
                      "app.kubernetes.io/instance" = "oauth2-proxy-${name}";
                    };
                  }
                ];
                ports = [ { protocol = "TCP"; port = config.workload.port; } ];
              }
            ];
          };
        };
      };
    };
  };
}
