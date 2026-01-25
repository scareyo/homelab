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
    "hyperspike.io.v1.Valkey" = {

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
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "ValkeySpec defines the desired state of Valkey";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpec"));
        };
        "status" = mkOption {
          description = "ValkeyStatus defines the observed state of Valkey";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeyStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpec" = {

      options = {
        "anonymousAuth" = mkOption {
          description = "Anonymous Auth.\n\nIf true, clients can login without providing a password. If\nfalse, the the operator will configure the valkey server to use a password. It\nwill either create a Secret holding the password or, if ServicePassword is set,\nuse an existing secret.";
          type = types.bool;
        };
        "certIssuer" = mkOption {
          description = "Certificate Issuer";
          type = (types.nullOr types.str);
        };
        "certIssuerType" = mkOption {
          description = "Certificate Issuer Type";
          type = (types.nullOr types.str);
        };
        "clusterDomain" = mkOption {
          description = "Cluster Domain - used for DNS";
          type = types.str;
        };
        "clusterPreferredEndpointType" = mkOption {
          description = "Which endpoint is shown as the preferred endpoint valid values are 'ip', 'hostname', or 'unknown-endpoint'.";
          type = (types.nullOr types.str);
        };
        "exporterImage" = mkOption {
          description = "Exporter Image to use";
          type = (types.nullOr types.str);
        };
        "externalAccess" = mkOption {
          description = "External access configuration";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecExternalAccess"));
        };
        "image" = mkOption {
          description = "Image to use";
          type = (types.nullOr types.str);
        };
        "nodeSelector" = mkOption {
          description = "Node Selector";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "nodes" = mkOption {
          description = "Number of shards. Each node is a primary";
          type = (types.nullOr types.int);
        };
        "prometheus" = mkOption {
          description = "Enable prometheus";
          type = types.bool;
        };
        "prometheusLabels" = mkOption {
          description = "Extra prometheus labels for operator targeting";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "replicas" = mkOption {
          description = "Number of replicas for each node.\n\nNote: This field currently creates extra primary nodes.\nFollow  https://github.com/hyperspike/valkey-operator/issues/186 for details";
          type = (types.nullOr types.int);
        };
        "resources" = mkOption {
          description = "Resources requirements and limits for the Valkey Server container";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecResources"));
        };
        "serviceMonitor" = mkOption {
          description = "ServiceMonitor Enabled. The service monitor is a custom resource which tells\nother Prometheus components how to scrape metrics from the valkey cluster";
          type = types.bool;
        };
        "servicePassword" = mkOption {
          description = "Service Password is a SecretKeySelector that points to a data key in a Secret. Look for\nSecretKeySelector in [Kubernetes Pod Documentation] for details\n\nThis field is optional. If ServicePassword is not set and\n[ValkeySpec.AnonymousAuth] is false, then the operator will create a secret\nin with the same name and  namespace as the custom resource, with a \"password\" data key\nand a random 16-character password value.\n\nhttps://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#environment-variables";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecServicePassword"));
        };
        "storage" = mkOption {
          description = "Persistent volume claim. The kind and metadata can be omitted, but the spec\nis necessary.";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecStorage"));
        };
        "tls" = mkOption {
          description = "TLS Support";
          type = (types.nullOr types.bool);
        };
        "tolerations" = mkOption {
          description = "Tolerations";
          type = (types.nullOr (types.listOf (submoduleOf "hyperspike.io.v1.ValkeySpecTolerations")));
        };
        "volumePermissions" = mkOption {
          description = "Turn on an init container to set permissions on the persistent volume";
          type = types.bool;
        };
      };

      config = {
        "certIssuer" = mkOverride 1002 null;
        "certIssuerType" = mkOverride 1002 null;
        "clusterPreferredEndpointType" = mkOverride 1002 null;
        "exporterImage" = mkOverride 1002 null;
        "externalAccess" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "nodes" = mkOverride 1002 null;
        "prometheusLabels" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "servicePassword" = mkOverride 1002 null;
        "storage" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecExternalAccess" = {

      options = {
        "certIssuer" = mkOption {
          description = "Cert Issuer for external access TLS certificate";
          type = (types.nullOr types.str);
        };
        "certIssuerType" = mkOption {
          description = "Cert Issuer Type for external access TLS certificate";
          type = (types.nullOr types.str);
        };
        "enabled" = mkOption {
          description = "Enable external access";
          type = types.bool;
        };
        "externalDNS" = mkOption {
          description = "Support External DNS";
          type = (types.nullOr types.bool);
        };
        "loadBalancer" = mkOption {
          description = "LoadBalancer Settings";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecExternalAccessLoadBalancer"));
        };
        "proxy" = mkOption {
          description = "Proxy Settings";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecExternalAccessProxy"));
        };
        "type" = mkOption {
          description = "External access type\nLoadBalancer or Proxy, the LoadBalancer type will create a LoadBalancer service for each Valkey Shard (master node)\nThe Proxy type will create a single LoadBalancer service and use an envoy proxy to route traffic to the Valkey Shards";
          type = types.str;
        };
      };

      config = {
        "certIssuer" = mkOverride 1002 null;
        "certIssuerType" = mkOverride 1002 null;
        "externalDNS" = mkOverride 1002 null;
        "loadBalancer" = mkOverride 1002 null;
        "proxy" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecExternalAccessLoadBalancer" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations for the load balancer service";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecExternalAccessProxy" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations for the proxy service";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "extraConfig" = mkOption {
          description = "Extra Envoy configuration";
          type = (types.nullOr types.str);
        };
        "hostname" = mkOption {
          description = "External Hostname for the proxy";
          type = (types.nullOr types.str);
        };
        "image" = mkOption {
          description = "Image to use for the proxy";
          type = (types.nullOr types.str);
        };
        "replicas" = mkOption {
          description = "Replicas for the proxy";
          type = types.int;
        };
        "resources" = mkOption {
          description = "Resources requirements and limits for the proxy container";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecExternalAccessProxyResources"));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "extraConfig" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecExternalAccessProxyResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "hyperspike.io.v1.ValkeySpecExternalAccessProxyResourcesClaims"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "limits" = mkOption {
          description = "Limits describes the maximum amount of compute resources allowed.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "requests" = mkOption {
          description = "Requests describes the minimum amount of compute resources required.\nIf Requests is omitted for a container, it defaults to Limits if that is explicitly specified,\notherwise to an implementation-defined value. Requests cannot exceed Limits.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
      };

      config = {
        "claims" = mkOverride 1002 null;
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecExternalAccessProxyResourcesClaims" = {

      options = {
        "name" = mkOption {
          description = "Name must match the name of one entry in pod.spec.resourceClaims of\nthe Pod where this field is used. It makes that resource available\ninside a container.";
          type = types.str;
        };
        "request" = mkOption {
          description = "Request is the name chosen for a request in the referenced claim.\nIf empty, everything from the claim is made available, otherwise\nonly the result of this request.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "request" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "hyperspike.io.v1.ValkeySpecResourcesClaims" "name" [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "limits" = mkOption {
          description = "Limits describes the maximum amount of compute resources allowed.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "requests" = mkOption {
          description = "Requests describes the minimum amount of compute resources required.\nIf Requests is omitted for a container, it defaults to Limits if that is explicitly specified,\notherwise to an implementation-defined value. Requests cannot exceed Limits.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
      };

      config = {
        "claims" = mkOverride 1002 null;
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecResourcesClaims" = {

      options = {
        "name" = mkOption {
          description = "Name must match the name of one entry in pod.spec.resourceClaims of\nthe Pod where this field is used. It makes that resource available\ninside a container.";
          type = types.str;
        };
        "request" = mkOption {
          description = "Request is the name chosen for a request in the referenced claim.\nIf empty, everything from the claim is made available, otherwise\nonly the result of this request.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "request" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecServicePassword" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecStorage" = {

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
          description = "Standard object's metadata.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr types.attrs);
        };
        "spec" = mkOption {
          description = "spec defines the desired characteristics of a volume requested by a pod author.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecStorageSpec"));
        };
        "status" = mkOption {
          description = "status represents the current information/status of a persistent volume claim.\nRead-only.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecStorageStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecStorageSpec" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes contains the desired access modes the volume should have.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1";
          type = (types.nullOr (types.listOf types.str));
        };
        "dataSource" = mkOption {
          description = "dataSource field can be used to specify either:\n* An existing VolumeSnapshot object (snapshot.storage.k8s.io/VolumeSnapshot)\n* An existing PVC (PersistentVolumeClaim)\nIf the provisioner or an external controller can support the specified data source,\nit will create a new volume based on the contents of the specified data source.\nWhen the AnyVolumeDataSource feature gate is enabled, dataSource contents will be copied to dataSourceRef,\nand dataSourceRef contents will be copied to dataSource when dataSourceRef.namespace is not specified.\nIf the namespace is specified, then dataSourceRef will not be copied to dataSource.";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecStorageSpecDataSource"));
        };
        "dataSourceRef" = mkOption {
          description = "dataSourceRef specifies the object from which to populate the volume with data, if a non-empty\nvolume is desired. This may be any object from a non-empty API group (non\ncore object) or a PersistentVolumeClaim object.\nWhen this field is specified, volume binding will only succeed if the type of\nthe specified object matches some installed volume populator or dynamic\nprovisioner.\nThis field will replace the functionality of the dataSource field and as such\nif both fields are non-empty, they must have the same value. For backwards\ncompatibility, when namespace isn't specified in dataSourceRef,\nboth fields (dataSource and dataSourceRef) will be set to the same\nvalue automatically if one of them is empty and the other is non-empty.\nWhen namespace is specified in dataSourceRef,\ndataSource isn't set to the same value and must be empty.\nThere are three important differences between dataSource and dataSourceRef:\n* While dataSource only allows two specific types of objects, dataSourceRef\n  allows any non-core object, as well as PersistentVolumeClaim objects.\n* While dataSource ignores disallowed values (dropping them), dataSourceRef\n  preserves all values, and generates an error if a disallowed value is\n  specified.\n* While dataSource only allows local objects, dataSourceRef allows objects\n  in any namespaces.\n(Beta) Using this field requires the AnyVolumeDataSource feature gate to be enabled.\n(Alpha) Using the namespace field of dataSourceRef requires the CrossNamespaceVolumeDataSource feature gate to be enabled.";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecStorageSpecDataSourceRef"));
        };
        "resources" = mkOption {
          description = "resources represents the minimum resources the volume should have.\nIf RecoverVolumeExpansionFailure feature is enabled users are allowed to specify resource requirements\nthat are lower than previous value but must still be higher than capacity recorded in the\nstatus field of the claim.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#resources";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecStorageSpecResources"));
        };
        "selector" = mkOption {
          description = "selector is a label query over volumes to consider for binding.";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecStorageSpecSelector"));
        };
        "storageClassName" = mkOption {
          description = "storageClassName is the name of the StorageClass required by the claim.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#class-1";
          type = (types.nullOr types.str);
        };
        "volumeAttributesClassName" = mkOption {
          description = "volumeAttributesClassName may be used to set the VolumeAttributesClass used by this claim.\nIf specified, the CSI driver will create or update the volume with the attributes defined\nin the corresponding VolumeAttributesClass. This has a different purpose than storageClassName,\nit can be changed after the claim is created. An empty string or nil value indicates that no\nVolumeAttributesClass will be applied to the claim. If the claim enters an Infeasible error state,\nthis field can be reset to its previous value (including nil) to cancel the modification.\nIf the resource referred to by volumeAttributesClass does not exist, this PersistentVolumeClaim will be\nset to a Pending state, as reflected by the modifyVolumeStatus field, until such as a resource\nexists.\nMore info: https://kubernetes.io/docs/concepts/storage/volume-attributes-classes/";
          type = (types.nullOr types.str);
        };
        "volumeMode" = mkOption {
          description = "volumeMode defines what type of volume is required by the claim.\nValue of Filesystem is implied when not included in claim spec.";
          type = (types.nullOr types.str);
        };
        "volumeName" = mkOption {
          description = "volumeName is the binding reference to the PersistentVolume backing this claim.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "dataSource" = mkOverride 1002 null;
        "dataSourceRef" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeAttributesClassName" = mkOverride 1002 null;
        "volumeMode" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecStorageSpecDataSource" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced.\nIf APIGroup is not specified, the specified Kind must be in the core API group.\nFor any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
      };

      config = {
        "apiGroup" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecStorageSpecDataSourceRef" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced.\nIf APIGroup is not specified, the specified Kind must be in the core API group.\nFor any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of resource being referenced\nNote that when a namespace is specified, a gateway.networking.k8s.io/ReferenceGrant object is required in the referent namespace to allow that namespace's owner to accept the reference. See the ReferenceGrant documentation for details.\n(Alpha) This field requires the CrossNamespaceVolumeDataSource feature gate to be enabled.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "apiGroup" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecStorageSpecResources" = {

      options = {
        "limits" = mkOption {
          description = "Limits describes the maximum amount of compute resources allowed.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "requests" = mkOption {
          description = "Requests describes the minimum amount of compute resources required.\nIf Requests is omitted for a container, it defaults to Limits if that is explicitly specified,\notherwise to an implementation-defined value. Requests cannot exceed Limits.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
      };

      config = {
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecStorageSpecSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "hyperspike.io.v1.ValkeySpecStorageSpecSelectorMatchExpressions")
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
    "hyperspike.io.v1.ValkeySpecStorageSpecSelectorMatchExpressions" = {

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
    "hyperspike.io.v1.ValkeySpecStorageStatus" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes contains the actual access modes the volume backing the PVC has.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1";
          type = (types.nullOr (types.listOf types.str));
        };
        "allocatedResourceStatuses" = mkOption {
          description = "allocatedResourceStatuses stores status of resource being resized for the given PVC.\nKey names follow standard Kubernetes label syntax. Valid values are either:\n\t* Un-prefixed keys:\n\t\t- storage - the capacity of the volume.\n\t* Custom resources must use implementation-defined prefixed names such as \"example.com/my-custom-resource\"\nApart from above values - keys that are unprefixed or have kubernetes.io prefix are considered\nreserved and hence may not be used.\n\nClaimResourceStatus can be in any of following states:\n\t- ControllerResizeInProgress:\n\t\tState set when resize controller starts resizing the volume in control-plane.\n\t- ControllerResizeFailed:\n\t\tState set when resize has failed in resize controller with a terminal error.\n\t- NodeResizePending:\n\t\tState set when resize controller has finished resizing the volume but further resizing of\n\t\tvolume is needed on the node.\n\t- NodeResizeInProgress:\n\t\tState set when kubelet starts resizing the volume.\n\t- NodeResizeFailed:\n\t\tState set when resizing has failed in kubelet with a terminal error. Transient errors don't set\n\t\tNodeResizeFailed.\nFor example: if expanding a PVC for more capacity - this field can be one of the following states:\n\t- pvc.status.allocatedResourceStatus['storage'] = \"ControllerResizeInProgress\"\n     - pvc.status.allocatedResourceStatus['storage'] = \"ControllerResizeFailed\"\n     - pvc.status.allocatedResourceStatus['storage'] = \"NodeResizePending\"\n     - pvc.status.allocatedResourceStatus['storage'] = \"NodeResizeInProgress\"\n     - pvc.status.allocatedResourceStatus['storage'] = \"NodeResizeFailed\"\nWhen this field is not set, it means that no resize operation is in progress for the given PVC.\n\nA controller that receives PVC update with previously unknown resourceName or ClaimResourceStatus\nshould ignore the update for the purpose it was designed. For example - a controller that\nonly is responsible for resizing capacity of the volume, should ignore PVC updates that change other valid\nresources associated with PVC.\n\nThis is an alpha field and requires enabling RecoverVolumeExpansionFailure feature.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "allocatedResources" = mkOption {
          description = "allocatedResources tracks the resources allocated to a PVC including its capacity.\nKey names follow standard Kubernetes label syntax. Valid values are either:\n\t* Un-prefixed keys:\n\t\t- storage - the capacity of the volume.\n\t* Custom resources must use implementation-defined prefixed names such as \"example.com/my-custom-resource\"\nApart from above values - keys that are unprefixed or have kubernetes.io prefix are considered\nreserved and hence may not be used.\n\nCapacity reported here may be larger than the actual capacity when a volume expansion operation\nis requested.\nFor storage quota, the larger value from allocatedResources and PVC.spec.resources is used.\nIf allocatedResources is not set, PVC.spec.resources alone is used for quota calculation.\nIf a volume expansion capacity request is lowered, allocatedResources is only\nlowered if there are no expansion operations in progress and if the actual volume capacity\nis equal or lower than the requested capacity.\n\nA controller that receives PVC update with previously unknown resourceName\nshould ignore the update for the purpose it was designed. For example - a controller that\nonly is responsible for resizing capacity of the volume, should ignore PVC updates that change other valid\nresources associated with PVC.\n\nThis is an alpha field and requires enabling RecoverVolumeExpansionFailure feature.";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "capacity" = mkOption {
          description = "capacity represents the actual resources of the underlying volume.";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "conditions" = mkOption {
          description = "conditions is the current Condition of persistent volume claim. If underlying persistent volume is being\nresized then the Condition will be set to 'Resizing'.";
          type = (
            types.nullOr (types.listOf (submoduleOf "hyperspike.io.v1.ValkeySpecStorageStatusConditions"))
          );
        };
        "currentVolumeAttributesClassName" = mkOption {
          description = "currentVolumeAttributesClassName is the current name of the VolumeAttributesClass the PVC is using.\nWhen unset, there is no VolumeAttributeClass applied to this PersistentVolumeClaim";
          type = (types.nullOr types.str);
        };
        "modifyVolumeStatus" = mkOption {
          description = "ModifyVolumeStatus represents the status object of ControllerModifyVolume operation.\nWhen this is unset, there is no ModifyVolume operation being attempted.";
          type = (types.nullOr (submoduleOf "hyperspike.io.v1.ValkeySpecStorageStatusModifyVolumeStatus"));
        };
        "phase" = mkOption {
          description = "phase represents the current phase of PersistentVolumeClaim.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "allocatedResourceStatuses" = mkOverride 1002 null;
        "allocatedResources" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "currentVolumeAttributesClassName" = mkOverride 1002 null;
        "modifyVolumeStatus" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecStorageStatusConditions" = {

      options = {
        "lastProbeTime" = mkOption {
          description = "lastProbeTime is the time we probed the condition.";
          type = (types.nullOr types.str);
        };
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "message is the human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "reason is a unique, this should be a short, machine understandable string that gives the reason\nfor condition's last transition. If it reports \"Resizing\" that means the underlying\npersistent volume is being resized.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status is the status of the condition.\nCan be True, False, Unknown.\nMore info: https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/#:~:text=state%20of%20pvc-,conditions.status,-(string)%2C%20required";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type is the type of the condition.\nMore info: https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/#:~:text=set%20to%20%27ResizeStarted%27.-,PersistentVolumeClaimCondition,-contains%20details%20about";
          type = types.str;
        };
      };

      config = {
        "lastProbeTime" = mkOverride 1002 null;
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecStorageStatusModifyVolumeStatus" = {

      options = {
        "status" = mkOption {
          description = "status is the status of the ControllerModifyVolume operation. It can be in any of following states:\n - Pending\n   Pending indicates that the PersistentVolumeClaim cannot be modified due to unmet requirements, such as\n   the specified VolumeAttributesClass not existing.\n - InProgress\n   InProgress indicates that the volume is being modified.\n - Infeasible\n  Infeasible indicates that the request has been rejected as invalid by the CSI driver. To\n\t  resolve the error, a valid VolumeAttributesClass needs to be specified.\nNote: New statuses can be added in the future. Consumers should check for unknown statuses and fail appropriately.";
          type = types.str;
        };
        "targetVolumeAttributesClassName" = mkOption {
          description = "targetVolumeAttributesClassName is the name of the VolumeAttributesClass the PVC currently being reconciled";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "targetVolumeAttributesClassName" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeySpecTolerations" = {

      options = {
        "effect" = mkOption {
          description = "Effect indicates the taint effect to match. Empty means match all taint effects.\nWhen specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Key is the taint key that the toleration applies to. Empty means match all taint keys.\nIf the key is empty, operator must be Exists; this combination means to match all values and all keys.";
          type = (types.nullOr types.str);
        };
        "operator" = mkOption {
          description = "Operator represents a key's relationship to the value.\nValid operators are Exists and Equal. Defaults to Equal.\nExists is equivalent to wildcard for value, so that a pod can\ntolerate all taints of a particular category.";
          type = (types.nullOr types.str);
        };
        "tolerationSeconds" = mkOption {
          description = "TolerationSeconds represents the period of time the toleration (which must be\nof effect NoExecute, otherwise this field is ignored) tolerates the taint. By default,\nit is not set, which means tolerate the taint forever (do not evict). Zero and\nnegative values will be treated as 0 (evict immediately) by the system.";
          type = (types.nullOr types.int);
        };
        "value" = mkOption {
          description = "Value is the taint value the toleration matches to.\nIf the operator is Exists, the value should be empty, otherwise just a regular string.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "effect" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "tolerationSeconds" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeyStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Important: Run \"make\" to regenerate code after modifying this file";
          type = (types.nullOr (types.listOf (submoduleOf "hyperspike.io.v1.ValkeyStatusConditions")));
        };
        "ready" = mkOption {
          description = "";
          type = types.bool;
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "hyperspike.io.v1.ValkeyStatusConditions" = {

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
      "hyperspike.io"."v1"."Valkey" = mkOption {
        description = "Valkey is the Schema for the valkeys API";
        type = (
          types.attrsOf (
            submoduleForDefinition "hyperspike.io.v1.Valkey" "valkeys" "Valkey" "hyperspike.io" "v1"
          )
        );
        default = { };
      };

    }
    // {
      "valkeys" = mkOption {
        description = "Valkey is the Schema for the valkeys API";
        type = (
          types.attrsOf (
            submoduleForDefinition "hyperspike.io.v1.Valkey" "valkeys" "Valkey" "hyperspike.io" "v1"
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
        name = "valkeys";
        group = "hyperspike.io";
        version = "v1";
        kind = "Valkey";
        attrName = "valkeys";
      }
    ];

    resources = {
      "hyperspike.io"."v1"."Valkey" = mkAliasDefinitions options.resources."valkeys";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "hyperspike.io";
        version = "v1";
        kind = "Valkey";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
