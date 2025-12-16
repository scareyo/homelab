# This file was generated with nixidy resource generator, do not edit.
{
  lib,
  options,
  config,
  ...
}:

with lib;

let
  hasAttrNotNull = attr: set: hasAttr attr set && set.${attr} != null;

  attrsToList =
    values:
    if values != null then
      sort (
        a: b:
        if (hasAttrNotNull "_priority" a && hasAttrNotNull "_priority" b) then
          a._priority < b._priority
        else
          false
      ) (mapAttrsToList (n: v: v) values)
    else
      values;

  getDefaults =
    resource: group: version: kind:
    catAttrs "default" (
      filter (
        default:
        (default.resource == null || default.resource == resource)
        && (default.group == null || default.group == group)
        && (default.version == null || default.version == version)
        && (default.kind == null || default.kind == kind)
      ) config.defaults
    );

  types = lib.types // rec {
    str = mkOptionType {
      name = "str";
      description = "string";
      check = isString;
      merge = mergeEqualOption;
    };

    # Either value of type `finalType` or `coercedType`, the latter is
    # converted to `finalType` using `coerceFunc`.
    coercedTo =
      coercedType: coerceFunc: finalType:
      mkOptionType rec {
        inherit (finalType) getSubOptions getSubModules;

        name = "coercedTo";
        description = "${finalType.description} or ${coercedType.description}";
        check = x: finalType.check x || coercedType.check x;
        merge =
          loc: defs:
          let
            coerceVal =
              val:
              if finalType.check val then
                val
              else
                let
                  coerced = coerceFunc val;
                in
                assert finalType.check coerced;
                coerced;

          in
          finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
        substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
        typeMerge = t1: t2: null;
        functor = (defaultFunctor name) // {
          wrapped = finalType;
        };
      };
  };

  mkOptionDefault = mkOverride 1001;

  mergeValuesByKey =
    attrMergeKey: listMergeKeys: values:
    listToAttrs (
      imap0 (
        i: value:
        nameValuePair (
          if hasAttr attrMergeKey value then
            if isAttrs value.${attrMergeKey} then
              toString value.${attrMergeKey}.content
            else
              (toString value.${attrMergeKey})
          else
            # generate merge key for list elements if it's not present
            "__kubenix_list_merge_key_"
            + (concatStringsSep "" (
              map (
                key: if isAttrs value.${key} then toString value.${key}.content else (toString value.${key})
              ) listMergeKeys
            ))
        ) (value // { _priority = i; })
      ) values
    );

  submoduleOf =
    ref:
    types.submodule (
      { name, ... }:
      {
        options = definitions."${ref}".options or { };
        config = definitions."${ref}".config or { };
      }
    );

  globalSubmoduleOf =
    ref:
    types.submodule (
      { name, ... }:
      {
        options = config.definitions."${ref}".options or { };
        config = config.definitions."${ref}".config or { };
      }
    );

  submoduleWithMergeOf =
    ref: mergeKey:
    types.submodule (
      { name, ... }:
      let
        convertName =
          name: if definitions."${ref}".options.${mergeKey}.type == types.int then toInt name else name;
      in
      {
        options = definitions."${ref}".options // {
          # position in original array
          _priority = mkOption {
            type = types.nullOr types.int;
            default = null;
            internal = true;
          };
        };
        config = definitions."${ref}".config // {
          ${mergeKey} = mkOverride 1002 (
            # use name as mergeKey only if it is not coming from mergeValuesByKey
            if (!hasPrefix "__kubenix_list_merge_key_" name) then convertName name else null
          );
        };
      }
    );

  submoduleForDefinition =
    ref: resource: kind: group: version:
    let
      apiVersion = if group == "core" then version else "${group}/${version}";
    in
    types.submodule (
      { name, ... }:
      {
        inherit (definitions."${ref}") options;

        imports = getDefaults resource group version kind;
        config = mkMerge [
          definitions."${ref}".config
          {
            kind = mkOptionDefault kind;
            apiVersion = mkOptionDefault apiVersion;

            # metdata.name cannot use option default, due deep config
            metadata.name = mkOptionDefault name;
          }
        ];
      }
    );

  coerceAttrsOfSubmodulesToListByKey =
    ref: attrMergeKey: listMergeKeys:
    (types.coercedTo (types.listOf (submoduleOf ref)) (mergeValuesByKey attrMergeKey listMergeKeys) (
      types.attrsOf (submoduleWithMergeOf ref attrMergeKey)
    ));

  definitions = {
    "cilium.io.v2.CiliumBGPAdvertisement" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "";
          type = (submoduleOf "cilium.io.v2.CiliumBGPAdvertisementSpec");
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPAdvertisementSpec" = {

      options = {
        "advertisements" = mkOption {
          description = "Advertisements is a list of BGP advertisements.";
          type = (types.listOf (submoduleOf "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisements"));
        };
      };

      config = { };

    };
    "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisements" = {

      options = {
        "advertisementType" = mkOption {
          description = "AdvertisementType defines type of advertisement which has to be advertised.";
          type = types.str;
        };
        "attributes" = mkOption {
          description = "Attributes defines additional attributes to set to the advertised routes.\nIf not specified, no additional attributes are set.";
          type = (
            types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsAttributes")
          );
        };
        "selector" = mkOption {
          description = "Selector is a label selector to select objects of the type specified by AdvertisementType.\nFor the PodCIDR AdvertisementType it is not applicable. For other advertisement types,\nif not specified, no objects of the type specified by AdvertisementType are selected for advertisement.";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsSelector"));
        };
        "service" = mkOption {
          description = "Service defines configuration options for advertisementType service.";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsService"));
        };
      };

      config = {
        "attributes" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsAttributes" = {

      options = {
        "communities" = mkOption {
          description = "Communities sets the community attributes in the route.\nIf not specified, no community attribute is set.";
          type = (
            types.nullOr (
              submoduleOf "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsAttributesCommunities"
            )
          );
        };
        "localPreference" = mkOption {
          description = "LocalPreference sets the local preference attribute in the route.\nIf not specified, no local preference attribute is set.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "communities" = mkOverride 1002 null;
        "localPreference" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsAttributesCommunities" = {

      options = {
        "large" = mkOption {
          description = "Large holds a list of the BGP Large Communities Attribute (RFC 8092) values.";
          type = (types.nullOr (types.listOf types.str));
        };
        "standard" = mkOption {
          description = "Standard holds a list of \"standard\" 32-bit BGP Communities Attribute (RFC 1997) values defined as numeric values.";
          type = (types.nullOr (types.listOf types.str));
        };
        "wellKnown" = mkOption {
          description = "WellKnown holds a list \"standard\" 32-bit BGP Communities Attribute (RFC 1997) values defined as\nwell-known string aliases to their numeric values.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "large" = mkOverride 1002 null;
        "standard" = mkOverride 1002 null;
        "wellKnown" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsSelectorMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPAdvertisementSpecAdvertisementsService" = {

      options = {
        "addresses" = mkOption {
          description = "Addresses is a list of service address types which needs to be advertised via BGP.";
          type = (types.listOf types.str);
        };
        "aggregationLengthIPv4" = mkOption {
          description = "IPv4 mask to aggregate BGP route advertisements of service";
          type = (types.nullOr types.int);
        };
        "aggregationLengthIPv6" = mkOption {
          description = "IPv6 mask to aggregate BGP route advertisements of service";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "aggregationLengthIPv4" = mkOverride 1002 null;
        "aggregationLengthIPv6" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfig" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec defines the desired cluster configuration of the BGP control plane.";
          type = (submoduleOf "cilium.io.v2.CiliumBGPClusterConfigSpec");
        };
        "status" = mkOption {
          description = "Status is a running status of the cluster configuration";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPClusterConfigStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfigSpec" = {

      options = {
        "bgpInstances" = mkOption {
          description = "A list of CiliumBGPInstance(s) which instructs\nthe BGP control plane how to instantiate virtual BGP routers.";
          type = (
            coerceAttrsOfSubmodulesToListByKey "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstances" "name" [
              "name"
            ]
          );
          apply = attrsToList;
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector selects a group of nodes where this BGP Cluster\nconfig applies.\nIf empty / nil this config applies to all nodes.";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPClusterConfigSpecNodeSelector"));
        };
      };

      config = {
        "nodeSelector" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstances" = {

      options = {
        "localASN" = mkOption {
          description = "LocalASN is the ASN of this BGP instance.\nSupports extended 32bit ASNs.";
          type = (types.nullOr types.int);
        };
        "localPort" = mkOption {
          description = "LocalPort is the port on which the BGP daemon listens for incoming connections.\n\nIf not specified, BGP instance will not listen for incoming connections.";
          type = (types.nullOr types.int);
        };
        "name" = mkOption {
          description = "Name is the name of the BGP instance. It is a unique identifier for the BGP instance\nwithin the cluster configuration.";
          type = types.str;
        };
        "peers" = mkOption {
          description = "Peers is a list of neighboring BGP peers for this virtual router";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstancesPeers" "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "localASN" = mkOverride 1002 null;
        "localPort" = mkOverride 1002 null;
        "peers" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstancesPeers" = {

      options = {
        "autoDiscovery" = mkOption {
          description = "AutoDiscovery is the configuration for auto-discovery of the peer address.";
          type = (
            types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstancesPeersAutoDiscovery")
          );
        };
        "name" = mkOption {
          description = "Name is the name of the BGP peer. It is a unique identifier for the peer within the BGP instance.";
          type = types.str;
        };
        "peerASN" = mkOption {
          description = "PeerASN is the ASN of the peer BGP router.\nSupports extended 32bit ASNs.\n\nIf peerASN is 0, the BGP OPEN message validation of ASN will be disabled and\nASN will be determined based on peer's OPEN message.";
          type = (types.nullOr types.int);
        };
        "peerAddress" = mkOption {
          description = "PeerAddress is the IP address of the neighbor.\nSupports IPv4 and IPv6 addresses.";
          type = (types.nullOr types.str);
        };
        "peerConfigRef" = mkOption {
          description = "PeerConfigRef is a reference to a peer configuration resource.\nIf not specified, the default BGP configuration is used for this peer.";
          type = (
            types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstancesPeersPeerConfigRef")
          );
        };
      };

      config = {
        "autoDiscovery" = mkOverride 1002 null;
        "peerASN" = mkOverride 1002 null;
        "peerAddress" = mkOverride 1002 null;
        "peerConfigRef" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstancesPeersAutoDiscovery" = {

      options = {
        "defaultGateway" = mkOption {
          description = "defaultGateway is the configuration for auto-discovery of the default gateway.";
          type = (
            types.nullOr (
              submoduleOf "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstancesPeersAutoDiscoveryDefaultGateway"
            )
          );
        };
        "mode" = mkOption {
          description = "mode is the mode of the auto-discovery.";
          type = types.str;
        };
      };

      config = {
        "defaultGateway" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstancesPeersAutoDiscoveryDefaultGateway" = {

      options = {
        "addressFamily" = mkOption {
          description = "addressFamily is the address family of the default gateway.";
          type = types.str;
        };
      };

      config = { };

    };
    "cilium.io.v2.CiliumBGPClusterConfigSpecBgpInstancesPeersPeerConfigRef" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the peer config resource.\nName refers to the name of a Kubernetes object (typically a CiliumBGPPeerConfig).";
          type = types.str;
        };
      };

      config = { };

    };
    "cilium.io.v2.CiliumBGPClusterConfigSpecNodeSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "cilium.io.v2.CiliumBGPClusterConfigSpecNodeSelectorMatchExpressions")
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfigSpecNodeSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfigStatus" = {

      options = {
        "conditions" = mkOption {
          description = "The current conditions of the CiliumBGPClusterConfig";
          type = (
            types.nullOr (types.listOf (submoduleOf "cilium.io.v2.CiliumBGPClusterConfigStatusConditions"))
          );
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPClusterConfigStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = (types.nullOr types.int);
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfig" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec is the specification of the desired behavior of the CiliumBGPPeerConfig.";
          type = (submoduleOf "cilium.io.v2.CiliumBGPPeerConfigSpec");
        };
        "status" = mkOption {
          description = "Status is the running status of the CiliumBGPPeerConfig";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPPeerConfigStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigSpec" = {

      options = {
        "authSecretRef" = mkOption {
          description = "AuthSecretRef is the name of the secret to use to fetch a TCP\nauthentication password for this peer.\n\nIf not specified, no authentication is used.";
          type = (types.nullOr types.str);
        };
        "ebgpMultihop" = mkOption {
          description = "EBGPMultihopTTL controls the multi-hop feature for eBGP peers.\nIts value defines the Time To Live (TTL) value used in BGP\npackets sent to the peer.\n\nIf not specified, EBGP multihop is disabled. This field is ignored for iBGP neighbors.";
          type = (types.nullOr types.int);
        };
        "families" = mkOption {
          description = "Families, if provided, defines a set of AFI/SAFIs the speaker will\nnegotiate with it's peer.\n\nIf not specified, the default families of IPv6/unicast and IPv4/unicast will be created.";
          type = (types.nullOr (types.listOf (submoduleOf "cilium.io.v2.CiliumBGPPeerConfigSpecFamilies")));
        };
        "gracefulRestart" = mkOption {
          description = "GracefulRestart defines graceful restart parameters which are negotiated\nwith this peer.\n\nIf not specified, the graceful restart capability is disabled.";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPPeerConfigSpecGracefulRestart"));
        };
        "timers" = mkOption {
          description = "Timers defines the BGP timers for the peer.\n\nIf not specified, the default timers are used.";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPPeerConfigSpecTimers"));
        };
        "transport" = mkOption {
          description = "Transport defines the BGP transport parameters for the peer.\n\nIf not specified, the default transport parameters are used.";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPPeerConfigSpecTransport"));
        };
      };

      config = {
        "authSecretRef" = mkOverride 1002 null;
        "ebgpMultihop" = mkOverride 1002 null;
        "families" = mkOverride 1002 null;
        "gracefulRestart" = mkOverride 1002 null;
        "timers" = mkOverride 1002 null;
        "transport" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigSpecFamilies" = {

      options = {
        "advertisements" = mkOption {
          description = "Advertisements selects group of BGP Advertisement(s) to advertise for this family.\n\nIf not specified, no advertisements are sent for this family.\n\nThis field is ignored in CiliumBGPNeighbor which is used in CiliumBGPPeeringPolicy.\nUse CiliumBGPPeeringPolicy advertisement options instead.";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumBGPPeerConfigSpecFamiliesAdvertisements"));
        };
        "afi" = mkOption {
          description = "Afi is the Address Family Identifier (AFI) of the family.";
          type = types.str;
        };
        "safi" = mkOption {
          description = "Safi is the Subsequent Address Family Identifier (SAFI) of the family.";
          type = types.str;
        };
      };

      config = {
        "advertisements" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigSpecFamiliesAdvertisements" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "cilium.io.v2.CiliumBGPPeerConfigSpecFamiliesAdvertisementsMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigSpecFamiliesAdvertisementsMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigSpecGracefulRestart" = {

      options = {
        "enabled" = mkOption {
          description = "Enabled flag, when set enables graceful restart capability.";
          type = types.bool;
        };
        "restartTimeSeconds" = mkOption {
          description = "RestartTimeSeconds is the estimated time it will take for the BGP\nsession to be re-established with peer after a restart.\nAfter this period, peer will remove stale routes. This is\ndescribed RFC 4724 section 4.2.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "restartTimeSeconds" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigSpecTimers" = {

      options = {
        "connectRetryTimeSeconds" = mkOption {
          description = "ConnectRetryTimeSeconds defines the initial value for the BGP ConnectRetryTimer (RFC 4271, Section 8).\n\nIf not specified, defaults to 120 seconds.";
          type = (types.nullOr types.int);
        };
        "holdTimeSeconds" = mkOption {
          description = "HoldTimeSeconds defines the initial value for the BGP HoldTimer (RFC 4271, Section 4.2).\nUpdating this value will cause a session reset.\n\nIf not specified, defaults to 90 seconds.";
          type = (types.nullOr types.int);
        };
        "keepAliveTimeSeconds" = mkOption {
          description = "KeepaliveTimeSeconds defines the initial value for the BGP KeepaliveTimer (RFC 4271, Section 8).\nIt can not be larger than HoldTimeSeconds. Updating this value will cause a session reset.\n\nIf not specified, defaults to 30 seconds.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "connectRetryTimeSeconds" = mkOverride 1002 null;
        "holdTimeSeconds" = mkOverride 1002 null;
        "keepAliveTimeSeconds" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigSpecTransport" = {

      options = {
        "peerPort" = mkOption {
          description = "PeerPort is the peer port to be used for the BGP session.\n\nIf not specified, defaults to TCP port 179.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "peerPort" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigStatus" = {

      options = {
        "conditions" = mkOption {
          description = "The current conditions of the CiliumBGPPeerConfig";
          type = (
            types.nullOr (types.listOf (submoduleOf "cilium.io.v2.CiliumBGPPeerConfigStatusConditions"))
          );
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumBGPPeerConfigStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = (types.nullOr types.int);
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumLoadBalancerIPPool" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec is a human readable description for a BGP load balancer\nip pool.";
          type = (submoduleOf "cilium.io.v2.CiliumLoadBalancerIPPoolSpec");
        };
        "status" = mkOption {
          description = "Status is the status of the IP Pool.\n\nIt might be possible for users to define overlapping IP Pools, we can't validate or enforce non-overlapping pools\nduring object creation. The Cilium operator will do this validation and update the status to reflect the ability\nto allocate IPs from this pool.";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumLoadBalancerIPPoolStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumLoadBalancerIPPoolSpec" = {

      options = {
        "allowFirstLastIPs" = mkOption {
          description = "AllowFirstLastIPs, if set to `Yes` or undefined means that the first and last IPs of each CIDR will be allocatable.\nIf `No`, these IPs will be reserved. This field is ignored for /{31,32} and /{127,128} CIDRs since\nreserving the first and last IPs would make the CIDRs unusable.";
          type = (types.nullOr types.str);
        };
        "blocks" = mkOption {
          description = "Blocks is a list of CIDRs comprising this IP Pool";
          type = (
            types.nullOr (types.listOf (submoduleOf "cilium.io.v2.CiliumLoadBalancerIPPoolSpecBlocks"))
          );
        };
        "disabled" = mkOption {
          description = "Disabled, if set to true means that no new IPs will be allocated from this pool.\nExisting allocations will not be removed from services.";
          type = (types.nullOr types.bool);
        };
        "serviceSelector" = mkOption {
          description = "ServiceSelector selects a set of services which are eligible to receive IPs from this";
          type = (types.nullOr (submoduleOf "cilium.io.v2.CiliumLoadBalancerIPPoolSpecServiceSelector"));
        };
      };

      config = {
        "allowFirstLastIPs" = mkOverride 1002 null;
        "blocks" = mkOverride 1002 null;
        "disabled" = mkOverride 1002 null;
        "serviceSelector" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumLoadBalancerIPPoolSpecBlocks" = {

      options = {
        "cidr" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "start" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "stop" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "cidr" = mkOverride 1002 null;
        "start" = mkOverride 1002 null;
        "stop" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumLoadBalancerIPPoolSpecServiceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "cilium.io.v2.CiliumLoadBalancerIPPoolSpecServiceSelectorMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumLoadBalancerIPPoolSpecServiceSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumLoadBalancerIPPoolStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Current service state";
          type = (
            types.nullOr (types.listOf (submoduleOf "cilium.io.v2.CiliumLoadBalancerIPPoolStatusConditions"))
          );
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2.CiliumLoadBalancerIPPoolStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = (types.nullOr types.int);
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumGatewayClassConfig" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec is a human-readable of a GatewayClass configuration.";
          type = (types.nullOr (submoduleOf "cilium.io.v2alpha1.CiliumGatewayClassConfigSpec"));
        };
        "status" = mkOption {
          description = "Status is the status of the policy.";
          type = (types.nullOr (submoduleOf "cilium.io.v2alpha1.CiliumGatewayClassConfigStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumGatewayClassConfigSpec" = {

      options = {
        "description" = mkOption {
          description = "Description helps describe a GatewayClass configuration with more details.";
          type = (types.nullOr types.str);
        };
        "service" = mkOption {
          description = "Service specifies the configuration for the generated Service.\nNote that not all fields from upstream Service.Spec are supported";
          type = (types.nullOr (submoduleOf "cilium.io.v2alpha1.CiliumGatewayClassConfigSpecService"));
        };
      };

      config = {
        "description" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumGatewayClassConfigSpecService" = {

      options = {
        "allocateLoadBalancerNodePorts" = mkOption {
          description = "Sets the Service.Spec.AllocateLoadBalancerNodePorts in generated Service objects to the given value.";
          type = (types.nullOr types.bool);
        };
        "externalTrafficPolicy" = mkOption {
          description = "Sets the Service.Spec.ExternalTrafficPolicy in generated Service objects to the given value.";
          type = (types.nullOr types.str);
        };
        "ipFamilies" = mkOption {
          description = "Sets the Service.Spec.IPFamilies in generated Service objects to the given value.";
          type = (types.nullOr (types.listOf types.str));
        };
        "ipFamilyPolicy" = mkOption {
          description = "Sets the Service.Spec.IPFamilyPolicy in generated Service objects to the given value.";
          type = (types.nullOr types.str);
        };
        "loadBalancerClass" = mkOption {
          description = "Sets the Service.Spec.LoadBalancerClass in generated Service objects to the given value.";
          type = (types.nullOr types.str);
        };
        "loadBalancerSourceRanges" = mkOption {
          description = "Sets the Service.Spec.LoadBalancerSourceRanges in generated Service objects to the given value.";
          type = (types.nullOr (types.listOf types.str));
        };
        "loadBalancerSourceRangesPolicy" = mkOption {
          description = "LoadBalancerSourceRangesPolicy defines the policy for the LoadBalancerSourceRanges if the incoming traffic\nis allowed or denied.";
          type = (types.nullOr types.str);
        };
        "trafficDistribution" = mkOption {
          description = "Sets the Service.Spec.TrafficDistribution in generated Service objects to the given value.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Sets the Service.Spec.Type in generated Service objects to the given value.\nOnly LoadBalancer and NodePort are supported.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "allocateLoadBalancerNodePorts" = mkOverride 1002 null;
        "externalTrafficPolicy" = mkOverride 1002 null;
        "ipFamilies" = mkOverride 1002 null;
        "ipFamilyPolicy" = mkOverride 1002 null;
        "loadBalancerClass" = mkOverride 1002 null;
        "loadBalancerSourceRanges" = mkOverride 1002 null;
        "loadBalancerSourceRangesPolicy" = mkOverride 1002 null;
        "trafficDistribution" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumGatewayClassConfigStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Current service state";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "cilium.io.v2alpha1.CiliumGatewayClassConfigStatusConditions")
            )
          );
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumGatewayClassConfigStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = (types.nullOr types.int);
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumLoadBalancerIPPool" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "spec" = mkOption {
          description = "Spec is a human readable description for a BGP load balancer\nip pool.";
          type = (submoduleOf "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolSpec");
        };
        "status" = mkOption {
          description = "Status is the status of the IP Pool.\n\nIt might be possible for users to define overlapping IP Pools, we can't validate or enforce non-overlapping pools\nduring object creation. The Cilium operator will do this validation and update the status to reflect the ability\nto allocate IPs from this pool.";
          type = (types.nullOr (submoduleOf "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolSpec" = {

      options = {
        "allowFirstLastIPs" = mkOption {
          description = "AllowFirstLastIPs, if set to `Yes` or undefined means that the first and last IPs of each CIDR will be allocatable.\nIf `No`, these IPs will be reserved. This field is ignored for /{31,32} and /{127,128} CIDRs since\nreserving the first and last IPs would make the CIDRs unusable.";
          type = (types.nullOr types.str);
        };
        "blocks" = mkOption {
          description = "Blocks is a list of CIDRs comprising this IP Pool";
          type = (
            types.nullOr (types.listOf (submoduleOf "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolSpecBlocks"))
          );
        };
        "disabled" = mkOption {
          description = "Disabled, if set to true means that no new IPs will be allocated from this pool.\nExisting allocations will not be removed from services.";
          type = (types.nullOr types.bool);
        };
        "serviceSelector" = mkOption {
          description = "ServiceSelector selects a set of services which are eligible to receive IPs from this";
          type = (
            types.nullOr (submoduleOf "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolSpecServiceSelector")
          );
        };
      };

      config = {
        "allowFirstLastIPs" = mkOverride 1002 null;
        "blocks" = mkOverride 1002 null;
        "disabled" = mkOverride 1002 null;
        "serviceSelector" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolSpecBlocks" = {

      options = {
        "cidr" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "start" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "stop" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "cidr" = mkOverride 1002 null;
        "start" = mkOverride 1002 null;
        "stop" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolSpecServiceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolSpecServiceSelectorMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolSpecServiceSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Current service state";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolStatusConditions")
            )
          );
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "cilium.io.v2alpha1.CiliumLoadBalancerIPPoolStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = (types.nullOr types.int);
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "cilium.io"."v2"."CiliumBGPAdvertisement" = mkOption {
        description = "CiliumBGPAdvertisement is the Schema for the ciliumbgpadvertisements API";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2.CiliumBGPAdvertisement" "ciliumbgpadvertisements"
              "CiliumBGPAdvertisement"
              "cilium.io"
              "v2"
          )
        );
        default = { };
      };
      "cilium.io"."v2"."CiliumBGPClusterConfig" = mkOption {
        description = "CiliumBGPClusterConfig is the Schema for the CiliumBGPClusterConfig API";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2.CiliumBGPClusterConfig" "ciliumbgpclusterconfigs"
              "CiliumBGPClusterConfig"
              "cilium.io"
              "v2"
          )
        );
        default = { };
      };
      "cilium.io"."v2"."CiliumBGPPeerConfig" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2.CiliumBGPPeerConfig" "ciliumbgppeerconfigs"
              "CiliumBGPPeerConfig"
              "cilium.io"
              "v2"
          )
        );
        default = { };
      };
      "cilium.io"."v2"."CiliumLoadBalancerIPPool" = mkOption {
        description = "CiliumLoadBalancerIPPool is a Kubernetes third-party resource which\nis used to defined pools of IPs which the operator can use to to allocate\nand advertise IPs for Services of type LoadBalancer.";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2.CiliumLoadBalancerIPPool" "ciliumloadbalancerippools"
              "CiliumLoadBalancerIPPool"
              "cilium.io"
              "v2"
          )
        );
        default = { };
      };
      "cilium.io"."v2alpha1"."CiliumGatewayClassConfig" = mkOption {
        description = "CiliumGatewayClassConfig is a Kubernetes third-party resource which\nis used to configure Gateways owned by GatewayClass.";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2alpha1.CiliumGatewayClassConfig" "ciliumgatewayclassconfigs"
              "CiliumGatewayClassConfig"
              "cilium.io"
              "v2alpha1"
          )
        );
        default = { };
      };
      "cilium.io"."v2alpha1"."CiliumLoadBalancerIPPool" = mkOption {
        description = "CiliumLoadBalancerIPPool is a Kubernetes third-party resource which\nis used to defined pools of IPs which the operator can use to to allocate\nand advertise IPs for Services of type LoadBalancer.";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2alpha1.CiliumLoadBalancerIPPool" "ciliumloadbalancerippools"
              "CiliumLoadBalancerIPPool"
              "cilium.io"
              "v2alpha1"
          )
        );
        default = { };
      };

    }
    // {
      "ciliumBGPAdvertisements" = mkOption {
        description = "CiliumBGPAdvertisement is the Schema for the ciliumbgpadvertisements API";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2.CiliumBGPAdvertisement" "ciliumbgpadvertisements"
              "CiliumBGPAdvertisement"
              "cilium.io"
              "v2"
          )
        );
        default = { };
      };
      "ciliumBGPClusterConfigs" = mkOption {
        description = "CiliumBGPClusterConfig is the Schema for the CiliumBGPClusterConfig API";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2.CiliumBGPClusterConfig" "ciliumbgpclusterconfigs"
              "CiliumBGPClusterConfig"
              "cilium.io"
              "v2"
          )
        );
        default = { };
      };
      "ciliumBGPPeerConfigs" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2.CiliumBGPPeerConfig" "ciliumbgppeerconfigs"
              "CiliumBGPPeerConfig"
              "cilium.io"
              "v2"
          )
        );
        default = { };
      };
      "ciliumGatewayClassConfigs" = mkOption {
        description = "CiliumGatewayClassConfig is a Kubernetes third-party resource which\nis used to configure Gateways owned by GatewayClass.";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2alpha1.CiliumGatewayClassConfig" "ciliumgatewayclassconfigs"
              "CiliumGatewayClassConfig"
              "cilium.io"
              "v2alpha1"
          )
        );
        default = { };
      };
      "ciliumLoadBalancerIPPools" = mkOption {
        description = "CiliumLoadBalancerIPPool is a Kubernetes third-party resource which\nis used to defined pools of IPs which the operator can use to to allocate\nand advertise IPs for Services of type LoadBalancer.";
        type = (
          types.attrsOf (
            submoduleForDefinition "cilium.io.v2.CiliumLoadBalancerIPPool" "ciliumloadbalancerippools"
              "CiliumLoadBalancerIPPool"
              "cilium.io"
              "v2"
          )
        );
        default = { };
      };

    };
  };

  config = {
    # expose resource definitions
    inherit definitions;

    # register resource types
    types = [
      {
        name = "ciliumbgpadvertisements";
        group = "cilium.io";
        version = "v2";
        kind = "CiliumBGPAdvertisement";
        attrName = "ciliumBGPAdvertisements";
      }
      {
        name = "ciliumbgpclusterconfigs";
        group = "cilium.io";
        version = "v2";
        kind = "CiliumBGPClusterConfig";
        attrName = "ciliumBGPClusterConfigs";
      }
      {
        name = "ciliumbgppeerconfigs";
        group = "cilium.io";
        version = "v2";
        kind = "CiliumBGPPeerConfig";
        attrName = "ciliumBGPPeerConfigs";
      }
      {
        name = "ciliumloadbalancerippools";
        group = "cilium.io";
        version = "v2";
        kind = "CiliumLoadBalancerIPPool";
        attrName = "ciliumLoadBalancerIPPools";
      }
      {
        name = "ciliumgatewayclassconfigs";
        group = "cilium.io";
        version = "v2alpha1";
        kind = "CiliumGatewayClassConfig";
        attrName = "ciliumGatewayClassConfigs";
      }
      {
        name = "ciliumloadbalancerippools";
        group = "cilium.io";
        version = "v2alpha1";
        kind = "CiliumLoadBalancerIPPool";
        attrName = "ciliumLoadBalancerIPPools";
      }
    ];

    resources = {
      "cilium.io"."v2"."CiliumBGPAdvertisement" =
        mkAliasDefinitions
          options.resources."ciliumBGPAdvertisements";
      "cilium.io"."v2"."CiliumBGPClusterConfig" =
        mkAliasDefinitions
          options.resources."ciliumBGPClusterConfigs";
      "cilium.io"."v2"."CiliumBGPPeerConfig" =
        mkAliasDefinitions
          options.resources."ciliumBGPPeerConfigs";
      "cilium.io"."v2alpha1"."CiliumGatewayClassConfig" =
        mkAliasDefinitions
          options.resources."ciliumGatewayClassConfigs";
      "cilium.io"."v2"."CiliumLoadBalancerIPPool" =
        mkAliasDefinitions
          options.resources."ciliumLoadBalancerIPPools";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "cilium.io";
        version = "v2alpha1";
        kind = "CiliumGatewayClassConfig";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
