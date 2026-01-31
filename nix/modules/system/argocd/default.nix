{ charts, config, lib, ... }:

let
  cfg = config.vegapunk.argocd;
  namespace = "argocd";
  project = "default";
in
{
  options = {
    vegapunk.argocd.enable = lib.mkEnableOption "Enable Argo CD";
  };

  config = lib.mkIf cfg.enable {
    applications.argocd = {
      inherit namespace project;

      createNamespace = true;

      helm.releases.argocd = {
        chart = charts.argo-cd;
        values = import ./values.nix;
      };

      templates.app.argocd.route = {
        hostname = "argocd.vegapunk.cloud";
        serviceName = "argocd-server";
      };

      templates.externalSecret.argocd-secret = {
        merge = true;
        keys = [
          { source = "/argocd/OIDC_CLIENT_ID"; dest = "oauth_client_id"; }
          { source = "/argocd/OIDC_CLIENT_SECRET"; dest = "oauth_client_secret"; }
        ];
      };

      resources.appProjects = {
        development = {
          spec = {
            sourceRepos = [ "*" ];
            destinations = [{ namespace = "*"; server = "*"; }];
            clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
          };
        };
        general = {
          spec = {
            sourceRepos = [ "*" ];
            destinations = [{ namespace = "*"; server = "*"; }];
            clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
          };
        };
        media = {
          spec = {
            sourceRepos = [ "*" ];
            destinations = [{ namespace = "*"; server = "*"; }];
            clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
          };
        };
        system = {
          spec = {
            sourceRepos = [ "*" ];
            destinations = [{ namespace = "*"; server = "*"; }];
            clusterResourceWhitelist = [{ group = "*"; kind = "*"; }];
          };
        };
      };

      resources.configMaps = {
        argocd-cm = {
          data = {
            # TODO: remove once https://github.com/argoproj/argo-cd/pull/24111 is released 
            "resource.customizations.health.ceph.rook.io_CephCluster" = ''
              local hs = {
                  status = "Progressing",
                  message = ""
              }

              function append_to_message(message)
                  if message ~= "" then
                      if hs.message ~= "" then
                          hs.message = hs.message .. " - " .. message
                      else
                          hs.message = message
                      end
                  end
              end

              if obj.status == nil then
                  append_to_message("Waiting for status to be reported")
                  return hs
              end

              -- Check the main Ceph health status first - https://github.com/ceph/ceph/blob/v20.3.0/src/include/health.h#L12
              if obj.status.ceph ~= nil and obj.status.ceph.health ~= nil then
                  local ceph_health = obj.status.ceph.health
                  local details_message = ""

                  -- Build details message from status.ceph.details if available
                  if obj.status.ceph.details ~= nil then
                      local detail_parts = {}
                      for detail_type, detail_info in pairs(obj.status.ceph.details) do
                          if detail_info.message ~= nil then
                              table.insert(detail_parts, detail_info.message)
                          end
                      end
                      if #detail_parts > 0 then
                          details_message =  " (" .. table.concat(detail_parts, "; ") .. ")"
                      end
                  end

                  if ceph_health == "HEALTH_ERR" or ceph_health == "HEALTH_WARN" then
                      hs.status = "Degraded"
                  elseif ceph_health == "HEALTH_OK" then
                      hs.status = "Healthy"
                  end
                  append_to_message("Ceph health is " .. ceph_health .. details_message)
              end

              -- Check state - https://github.com/rook/rook/blob/v1.17.7/pkg/apis/ceph.rook.io/v1/types.go#L621
              if obj.status.state ~= nil then
                  if hs.status == "Healthy" then
                      append_to_message("Ceph cluster state is " .. obj.status.state)
                      if obj.status.state == "Created" or obj.status.state == "Connected" then
                          hs.status = "Healthy"
                      elseif obj.status.state == "Error" then
                          hs.status = "Degraded"
                      else
                          hs.status = "Progressing"
                      end
                  end
              end

              if obj.status.message ~= nil then
                  append_to_message(obj.status.message)
              end

              return hs
            '';
            "resource.customizations.health.ceph.rook.io_CephObjectStore" = ''
              local hs = {
                  status = "Progressing",
                  message = "Waiting for status to be reported"
              }

              if obj.status == nil then
                  return hs
              end

              -- phase status check - https://github.com/rook/rook/blob/v1.17.7/pkg/apis/ceph.rook.io/v1/types.go#L596
              if obj.status.phase ~= nil then
                  hs.message = "Ceph object store phase is " .. obj.status.phase
                  if obj.status.phase == "Ready" then
                      hs.status = "Healthy"
                  elseif obj.status.phase == "Failure" then
                      hs.status = "Degraded"
                  end
              end

              if obj.status.info ~= nil and obj.status.info.endpoint ~= nil and obj.status.info.endpoint ~= "" then
                  hs.message = hs.message .. " - endpoint: " .. obj.status.info.endpoint
              end

              return hs
            '';
            "resource.customizations.health.objectbucket.io_ObjectBucketClaim" = ''
              local hs = {
                  status = "Progressing",
                  message = "Waiting for status to be reported"
              }

              -- phase status check - https://github.com/kube-object-storage/lib-bucket-provisioner/blob/ffa47d5/pkg/apis/objectbucket.io/v1alpha1/objectbucketclaim_types.go#L58
              if obj.status ~= nil then
                  if obj.status.phase ~= nil then
                      hs.message = "Object bucket claim phase is " .. obj.status.phase
                      if obj.status.phase == "Bound" then
                          hs.status = "Healthy"
                      elseif obj.status.phase == "Failed" then
                          hs.status = "Degraded"
                      end
                  else
                      hs.message = "Waiting for phase to be reported"
                  end
              end

              return hs
            '';
          };
        };
      };
    };
  };
}
