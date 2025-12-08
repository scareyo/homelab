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
    "velero.io.v1.Restore" = {

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
          description = "RestoreSpec defines the specification for a Velero restore.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpec"));
        };
        "status" = mkOption {
          description = "RestoreStatus captures the current status of a Velero restore";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreStatus"));
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
    "velero.io.v1.RestoreSpec" = {

      options = {
        "backupName" = mkOption {
          description = "BackupName is the unique name of the Velero backup to restore\nfrom.";
          type = (types.nullOr types.str);
        };
        "excludedNamespaces" = mkOption {
          description = "ExcludedNamespaces contains a list of namespaces that are not\nincluded in the restore.";
          type = (types.nullOr (types.listOf types.str));
        };
        "excludedResources" = mkOption {
          description = "ExcludedResources is a slice of resource names that are not\nincluded in the restore.";
          type = (types.nullOr (types.listOf types.str));
        };
        "existingResourcePolicy" = mkOption {
          description = "ExistingResourcePolicy specifies the restore behavior for the Kubernetes resource to be restored";
          type = (types.nullOr types.str);
        };
        "hooks" = mkOption {
          description = "Hooks represent custom behaviors that should be executed during or post restore.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpecHooks"));
        };
        "includeClusterResources" = mkOption {
          description = "IncludeClusterResources specifies whether cluster-scoped resources\nshould be included for consideration in the restore. If null, defaults\nto true.";
          type = (types.nullOr types.bool);
        };
        "includedNamespaces" = mkOption {
          description = "IncludedNamespaces is a slice of namespace names to include objects\nfrom. If empty, all namespaces are included.";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedResources" = mkOption {
          description = "IncludedResources is a slice of resource names to include\nin the restore. If empty, all resources in the backup are included.";
          type = (types.nullOr (types.listOf types.str));
        };
        "itemOperationTimeout" = mkOption {
          description = "ItemOperationTimeout specifies the time used to wait for RestoreItemAction operations\nThe default value is 4 hour.";
          type = (types.nullOr types.str);
        };
        "labelSelector" = mkOption {
          description = "LabelSelector is a metav1.LabelSelector to filter with\nwhen restoring individual objects from the backup. If empty\nor nil, all objects are included. Optional.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpecLabelSelector"));
        };
        "namespaceMapping" = mkOption {
          description = "NamespaceMapping is a map of source namespace names\nto target namespace names to restore into. Any source\nnamespaces not included in the map will be restored into\nnamespaces of the same name.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "orLabelSelectors" = mkOption {
          description = "OrLabelSelectors is list of metav1.LabelSelector to filter with\nwhen restoring individual objects from the backup. If multiple provided\nthey will be joined by the OR operator. LabelSelector as well as\nOrLabelSelectors cannot co-exist in restore request, only one of them\ncan be used";
          type = (types.nullOr (types.listOf (submoduleOf "velero.io.v1.RestoreSpecOrLabelSelectors")));
        };
        "preserveNodePorts" = mkOption {
          description = "PreserveNodePorts specifies whether to restore old nodePorts from backup.";
          type = (types.nullOr types.bool);
        };
        "resourceModifier" = mkOption {
          description = "ResourceModifier specifies the reference to JSON resource patches that should be applied to resources before restoration.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpecResourceModifier"));
        };
        "restorePVs" = mkOption {
          description = "RestorePVs specifies whether to restore all included\nPVs from snapshot";
          type = (types.nullOr types.bool);
        };
        "restoreStatus" = mkOption {
          description = "RestoreStatus specifies which resources we should restore the status\nfield. If nil, no objects are included. Optional.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpecRestoreStatus"));
        };
        "scheduleName" = mkOption {
          description = "ScheduleName is the unique name of the Velero schedule to restore\nfrom. If specified, and BackupName is empty, Velero will restore\nfrom the most recent successful backup created from this schedule.";
          type = (types.nullOr types.str);
        };
        "uploaderConfig" = mkOption {
          description = "UploaderConfig specifies the configuration for the restore.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpecUploaderConfig"));
        };
      };

      config = {
        "backupName" = mkOverride 1002 null;
        "excludedNamespaces" = mkOverride 1002 null;
        "excludedResources" = mkOverride 1002 null;
        "existingResourcePolicy" = mkOverride 1002 null;
        "hooks" = mkOverride 1002 null;
        "includeClusterResources" = mkOverride 1002 null;
        "includedNamespaces" = mkOverride 1002 null;
        "includedResources" = mkOverride 1002 null;
        "itemOperationTimeout" = mkOverride 1002 null;
        "labelSelector" = mkOverride 1002 null;
        "namespaceMapping" = mkOverride 1002 null;
        "orLabelSelectors" = mkOverride 1002 null;
        "preserveNodePorts" = mkOverride 1002 null;
        "resourceModifier" = mkOverride 1002 null;
        "restorePVs" = mkOverride 1002 null;
        "restoreStatus" = mkOverride 1002 null;
        "scheduleName" = mkOverride 1002 null;
        "uploaderConfig" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreSpecHooks" = {

      options = {
        "resources" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "velero.io.v1.RestoreSpecHooksResources" "name" [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "resources" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreSpecHooksResources" = {

      options = {
        "excludedNamespaces" = mkOption {
          description = "ExcludedNamespaces specifies the namespaces to which this hook spec does not apply.";
          type = (types.nullOr (types.listOf types.str));
        };
        "excludedResources" = mkOption {
          description = "ExcludedResources specifies the resources to which this hook spec does not apply.";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedNamespaces" = mkOption {
          description = "IncludedNamespaces specifies the namespaces to which this hook spec applies. If empty, it applies\nto all namespaces.";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedResources" = mkOption {
          description = "IncludedResources specifies the resources to which this hook spec applies. If empty, it applies\nto all resources.";
          type = (types.nullOr (types.listOf types.str));
        };
        "labelSelector" = mkOption {
          description = "LabelSelector, if specified, filters the resources to which this hook spec applies.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpecHooksResourcesLabelSelector"));
        };
        "name" = mkOption {
          description = "Name is the name of this hook.";
          type = types.str;
        };
        "postHooks" = mkOption {
          description = "PostHooks is a list of RestoreResourceHooks to execute during and after restoring a resource.";
          type = (
            types.nullOr (types.listOf (submoduleOf "velero.io.v1.RestoreSpecHooksResourcesPostHooks"))
          );
        };
      };

      config = {
        "excludedNamespaces" = mkOverride 1002 null;
        "excludedResources" = mkOverride 1002 null;
        "includedNamespaces" = mkOverride 1002 null;
        "includedResources" = mkOverride 1002 null;
        "labelSelector" = mkOverride 1002 null;
        "postHooks" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreSpecHooksResourcesLabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "velero.io.v1.RestoreSpecHooksResourcesLabelSelectorMatchExpressions")
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
    "velero.io.v1.RestoreSpecHooksResourcesLabelSelectorMatchExpressions" = {

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
    "velero.io.v1.RestoreSpecHooksResourcesPostHooks" = {

      options = {
        "exec" = mkOption {
          description = "Exec defines an exec restore hook.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpecHooksResourcesPostHooksExec"));
        };
        "init" = mkOption {
          description = "Init defines an init restore hook.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreSpecHooksResourcesPostHooksInit"));
        };
      };

      config = {
        "exec" = mkOverride 1002 null;
        "init" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreSpecHooksResourcesPostHooksExec" = {

      options = {
        "command" = mkOption {
          description = "Command is the command and arguments to execute from within a container after a pod has been restored.";
          type = (types.listOf types.str);
        };
        "container" = mkOption {
          description = "Container is the container in the pod where the command should be executed. If not specified,\nthe pod's first container is used.";
          type = (types.nullOr types.str);
        };
        "execTimeout" = mkOption {
          description = "ExecTimeout defines the maximum amount of time Velero should wait for the hook to complete before\nconsidering the execution a failure.";
          type = (types.nullOr types.str);
        };
        "onError" = mkOption {
          description = "OnError specifies how Velero should behave if it encounters an error executing this hook.";
          type = (types.nullOr types.str);
        };
        "waitForReady" = mkOption {
          description = "WaitForReady ensures command will be launched when container is Ready instead of Running.";
          type = (types.nullOr types.bool);
        };
        "waitTimeout" = mkOption {
          description = "WaitTimeout defines the maximum amount of time Velero should wait for the container to be Ready\nbefore attempting to run the command.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "container" = mkOverride 1002 null;
        "execTimeout" = mkOverride 1002 null;
        "onError" = mkOverride 1002 null;
        "waitForReady" = mkOverride 1002 null;
        "waitTimeout" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreSpecHooksResourcesPostHooksInit" = {

      options = {
        "initContainers" = mkOption {
          description = "InitContainers is list of init containers to be added to a pod during its restore.";
          type = (types.nullOr (types.listOf types.attrs));
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum amount of time Velero should wait for the initContainers to complete.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "initContainers" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreSpecLabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (types.listOf (submoduleOf "velero.io.v1.RestoreSpecLabelSelectorMatchExpressions"))
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
    "velero.io.v1.RestoreSpecLabelSelectorMatchExpressions" = {

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
    "velero.io.v1.RestoreSpecOrLabelSelectors" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (types.listOf (submoduleOf "velero.io.v1.RestoreSpecOrLabelSelectorsMatchExpressions"))
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
    "velero.io.v1.RestoreSpecOrLabelSelectorsMatchExpressions" = {

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
    "velero.io.v1.RestoreSpecResourceModifier" = {

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
    "velero.io.v1.RestoreSpecRestoreStatus" = {

      options = {
        "excludedResources" = mkOption {
          description = "ExcludedResources specifies the resources to which will not restore the status.";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedResources" = mkOption {
          description = "IncludedResources specifies the resources to which will restore the status.\nIf empty, it applies to all resources.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "excludedResources" = mkOverride 1002 null;
        "includedResources" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreSpecUploaderConfig" = {

      options = {
        "parallelFilesDownload" = mkOption {
          description = "ParallelFilesDownload is the concurrency number setting for restore.";
          type = (types.nullOr types.int);
        };
        "writeSparseFiles" = mkOption {
          description = "WriteSparseFiles is a flag to indicate whether write files sparsely or not.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "parallelFilesDownload" = mkOverride 1002 null;
        "writeSparseFiles" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreStatus" = {

      options = {
        "completionTimestamp" = mkOption {
          description = "CompletionTimestamp records the time the restore operation was completed.\nCompletion time is recorded even on failed restore.\nThe server's time is used for StartTimestamps";
          type = (types.nullOr types.str);
        };
        "errors" = mkOption {
          description = "Errors is a count of all error messages that were generated during\nexecution of the restore. The actual errors are stored in object storage.";
          type = (types.nullOr types.int);
        };
        "failureReason" = mkOption {
          description = "FailureReason is an error that caused the entire restore to fail.";
          type = (types.nullOr types.str);
        };
        "hookStatus" = mkOption {
          description = "HookStatus contains information about the status of the hooks.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreStatusHookStatus"));
        };
        "phase" = mkOption {
          description = "Phase is the current state of the Restore";
          type = (types.nullOr types.str);
        };
        "progress" = mkOption {
          description = "Progress contains information about the restore's execution progress. Note\nthat this information is best-effort only -- if Velero fails to update it\nduring a restore for any reason, it may be inaccurate/stale.";
          type = (types.nullOr (submoduleOf "velero.io.v1.RestoreStatusProgress"));
        };
        "restoreItemOperationsAttempted" = mkOption {
          description = "RestoreItemOperationsAttempted is the total number of attempted\nasync RestoreItemAction operations for this restore.";
          type = (types.nullOr types.int);
        };
        "restoreItemOperationsCompleted" = mkOption {
          description = "RestoreItemOperationsCompleted is the total number of successfully completed\nasync RestoreItemAction operations for this restore.";
          type = (types.nullOr types.int);
        };
        "restoreItemOperationsFailed" = mkOption {
          description = "RestoreItemOperationsFailed is the total number of async\nRestoreItemAction operations for this restore which ended with an error.";
          type = (types.nullOr types.int);
        };
        "startTimestamp" = mkOption {
          description = "StartTimestamp records the time the restore operation was started.\nThe server's time is used for StartTimestamps";
          type = (types.nullOr types.str);
        };
        "validationErrors" = mkOption {
          description = "ValidationErrors is a slice of all validation errors (if\napplicable)";
          type = (types.nullOr (types.listOf types.str));
        };
        "warnings" = mkOption {
          description = "Warnings is a count of all warning messages that were generated during\nexecution of the restore. The actual warnings are stored in object storage.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "completionTimestamp" = mkOverride 1002 null;
        "errors" = mkOverride 1002 null;
        "failureReason" = mkOverride 1002 null;
        "hookStatus" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "progress" = mkOverride 1002 null;
        "restoreItemOperationsAttempted" = mkOverride 1002 null;
        "restoreItemOperationsCompleted" = mkOverride 1002 null;
        "restoreItemOperationsFailed" = mkOverride 1002 null;
        "startTimestamp" = mkOverride 1002 null;
        "validationErrors" = mkOverride 1002 null;
        "warnings" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreStatusHookStatus" = {

      options = {
        "hooksAttempted" = mkOption {
          description = "HooksAttempted is the total number of attempted hooks\nSpecifically, HooksAttempted represents the number of hooks that failed to execute\nand the number of hooks that executed successfully.";
          type = (types.nullOr types.int);
        };
        "hooksFailed" = mkOption {
          description = "HooksFailed is the total number of hooks which ended with an error";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "hooksAttempted" = mkOverride 1002 null;
        "hooksFailed" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.RestoreStatusProgress" = {

      options = {
        "itemsRestored" = mkOption {
          description = "ItemsRestored is the number of items that have actually been restored so far";
          type = (types.nullOr types.int);
        };
        "totalItems" = mkOption {
          description = "TotalItems is the total number of items to be restored. This number may change\nthroughout the execution of the restore due to plugins that return additional related\nitems to restore";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "itemsRestored" = mkOverride 1002 null;
        "totalItems" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.Schedule" = {

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
          description = "ScheduleSpec defines the specification for a Velero schedule";
          type = (types.nullOr (submoduleOf "velero.io.v1.ScheduleSpec"));
        };
        "status" = mkOption {
          description = "ScheduleStatus captures the current state of a Velero schedule";
          type = (types.nullOr (submoduleOf "velero.io.v1.ScheduleStatus"));
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
    "velero.io.v1.ScheduleSpec" = {

      options = {
        "paused" = mkOption {
          description = "Paused specifies whether the schedule is paused or not";
          type = (types.nullOr types.bool);
        };
        "schedule" = mkOption {
          description = "Schedule is a Cron expression defining when to run\nthe Backup.";
          type = types.str;
        };
        "skipImmediately" = mkOption {
          description = "SkipImmediately specifies whether to skip backup if schedule is due immediately from `schedule.status.lastBackup` timestamp when schedule is unpaused or if schedule is new.\nIf true, backup will be skipped immediately when schedule is unpaused if it is due based on .Status.LastBackupTimestamp or schedule is new, and will run at next schedule time.\nIf false, backup will not be skipped immediately when schedule is unpaused, but will run at next schedule time.\nIf empty, will follow server configuration (default: false).";
          type = (types.nullOr types.bool);
        };
        "template" = mkOption {
          description = "Template is the definition of the Backup to be run\non the provided schedule";
          type = (submoduleOf "velero.io.v1.ScheduleSpecTemplate");
        };
        "useOwnerReferencesInBackup" = mkOption {
          description = "UseOwnerReferencesBackup specifies whether to use\nOwnerReferences on backups created by this Schedule.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "paused" = mkOverride 1002 null;
        "skipImmediately" = mkOverride 1002 null;
        "useOwnerReferencesInBackup" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.ScheduleSpecTemplate" = {

      options = {
        "csiSnapshotTimeout" = mkOption {
          description = "CSISnapshotTimeout specifies the time used to wait for CSI VolumeSnapshot status turns to\nReadyToUse during creation, before returning error as timeout.\nThe default value is 10 minute.";
          type = (types.nullOr types.str);
        };
        "datamover" = mkOption {
          description = "DataMover specifies the data mover to be used by the backup.\nIf DataMover is \"\" or \"velero\", the built-in data mover will be used.";
          type = (types.nullOr types.str);
        };
        "defaultVolumesToFsBackup" = mkOption {
          description = "DefaultVolumesToFsBackup specifies whether pod volume file system backup should be used\nfor all volumes by default.";
          type = (types.nullOr types.bool);
        };
        "defaultVolumesToRestic" = mkOption {
          description = "DefaultVolumesToRestic specifies whether restic should be used to take a\nbackup of all pod volumes by default.\n\nDeprecated: this field is no longer used and will be removed entirely in future. Use DefaultVolumesToFsBackup instead.";
          type = (types.nullOr types.bool);
        };
        "excludedClusterScopedResources" = mkOption {
          description = "ExcludedClusterScopedResources is a slice of cluster-scoped\nresource type names to exclude from the backup.\nIf set to \"*\", all cluster-scoped resource types are excluded.\nThe default value is empty.";
          type = (types.nullOr (types.listOf types.str));
        };
        "excludedNamespaceScopedResources" = mkOption {
          description = "ExcludedNamespaceScopedResources is a slice of namespace-scoped\nresource type names to exclude from the backup.\nIf set to \"*\", all namespace-scoped resource types are excluded.\nThe default value is empty.";
          type = (types.nullOr (types.listOf types.str));
        };
        "excludedNamespaces" = mkOption {
          description = "ExcludedNamespaces contains a list of namespaces that are not\nincluded in the backup.";
          type = (types.nullOr (types.listOf types.str));
        };
        "excludedResources" = mkOption {
          description = "ExcludedResources is a slice of resource names that are not\nincluded in the backup.";
          type = (types.nullOr (types.listOf types.str));
        };
        "hooks" = mkOption {
          description = "Hooks represent custom behaviors that should be executed at different phases of the backup.";
          type = (types.nullOr (submoduleOf "velero.io.v1.ScheduleSpecTemplateHooks"));
        };
        "includeClusterResources" = mkOption {
          description = "IncludeClusterResources specifies whether cluster-scoped resources\nshould be included for consideration in the backup.";
          type = (types.nullOr types.bool);
        };
        "includedClusterScopedResources" = mkOption {
          description = "IncludedClusterScopedResources is a slice of cluster-scoped\nresource type names to include in the backup.\nIf set to \"*\", all cluster-scoped resource types are included.\nThe default value is empty, which means only related\ncluster-scoped resources are included.";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedNamespaceScopedResources" = mkOption {
          description = "IncludedNamespaceScopedResources is a slice of namespace-scoped\nresource type names to include in the backup.\nThe default value is \"*\".";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedNamespaces" = mkOption {
          description = "IncludedNamespaces is a slice of namespace names to include objects\nfrom. If empty, all namespaces are included.";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedResources" = mkOption {
          description = "IncludedResources is a slice of resource names to include\nin the backup. If empty, all resources are included.";
          type = (types.nullOr (types.listOf types.str));
        };
        "itemOperationTimeout" = mkOption {
          description = "ItemOperationTimeout specifies the time used to wait for asynchronous BackupItemAction operations\nThe default value is 4 hour.";
          type = (types.nullOr types.str);
        };
        "labelSelector" = mkOption {
          description = "LabelSelector is a metav1.LabelSelector to filter with\nwhen adding individual objects to the backup. If empty\nor nil, all objects are included. Optional.";
          type = (types.nullOr (submoduleOf "velero.io.v1.ScheduleSpecTemplateLabelSelector"));
        };
        "metadata" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "velero.io.v1.ScheduleSpecTemplateMetadata"));
        };
        "orLabelSelectors" = mkOption {
          description = "OrLabelSelectors is list of metav1.LabelSelector to filter with\nwhen adding individual objects to the backup. If multiple provided\nthey will be joined by the OR operator. LabelSelector as well as\nOrLabelSelectors cannot co-exist in backup request, only one of them\ncan be used.";
          type = (
            types.nullOr (types.listOf (submoduleOf "velero.io.v1.ScheduleSpecTemplateOrLabelSelectors"))
          );
        };
        "orderedResources" = mkOption {
          description = "OrderedResources specifies the backup order of resources of specific Kind.\nThe map key is the resource name and value is a list of object names separated by commas.\nEach resource name has format \"namespace/objectname\".  For cluster resources, simply use \"objectname\".";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "resourcePolicy" = mkOption {
          description = "ResourcePolicy specifies the referenced resource policies that backup should follow";
          type = (types.nullOr (submoduleOf "velero.io.v1.ScheduleSpecTemplateResourcePolicy"));
        };
        "snapshotMoveData" = mkOption {
          description = "SnapshotMoveData specifies whether snapshot data should be moved";
          type = (types.nullOr types.bool);
        };
        "snapshotVolumes" = mkOption {
          description = "SnapshotVolumes specifies whether to take snapshots\nof any PV's referenced in the set of objects included\nin the Backup.";
          type = (types.nullOr types.bool);
        };
        "storageLocation" = mkOption {
          description = "StorageLocation is a string containing the name of a BackupStorageLocation where the backup should be stored.";
          type = (types.nullOr types.str);
        };
        "ttl" = mkOption {
          description = "TTL is a time.Duration-parseable string describing how long\nthe Backup should be retained for.";
          type = (types.nullOr types.str);
        };
        "uploaderConfig" = mkOption {
          description = "UploaderConfig specifies the configuration for the uploader.";
          type = (types.nullOr (submoduleOf "velero.io.v1.ScheduleSpecTemplateUploaderConfig"));
        };
        "volumeGroupSnapshotLabelKey" = mkOption {
          description = "VolumeGroupSnapshotLabelKey specifies the label key to group PVCs under a VGS.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotLocations" = mkOption {
          description = "VolumeSnapshotLocations is a list containing names of VolumeSnapshotLocations associated with this backup.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "csiSnapshotTimeout" = mkOverride 1002 null;
        "datamover" = mkOverride 1002 null;
        "defaultVolumesToFsBackup" = mkOverride 1002 null;
        "defaultVolumesToRestic" = mkOverride 1002 null;
        "excludedClusterScopedResources" = mkOverride 1002 null;
        "excludedNamespaceScopedResources" = mkOverride 1002 null;
        "excludedNamespaces" = mkOverride 1002 null;
        "excludedResources" = mkOverride 1002 null;
        "hooks" = mkOverride 1002 null;
        "includeClusterResources" = mkOverride 1002 null;
        "includedClusterScopedResources" = mkOverride 1002 null;
        "includedNamespaceScopedResources" = mkOverride 1002 null;
        "includedNamespaces" = mkOverride 1002 null;
        "includedResources" = mkOverride 1002 null;
        "itemOperationTimeout" = mkOverride 1002 null;
        "labelSelector" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "orLabelSelectors" = mkOverride 1002 null;
        "orderedResources" = mkOverride 1002 null;
        "resourcePolicy" = mkOverride 1002 null;
        "snapshotMoveData" = mkOverride 1002 null;
        "snapshotVolumes" = mkOverride 1002 null;
        "storageLocation" = mkOverride 1002 null;
        "ttl" = mkOverride 1002 null;
        "uploaderConfig" = mkOverride 1002 null;
        "volumeGroupSnapshotLabelKey" = mkOverride 1002 null;
        "volumeSnapshotLocations" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.ScheduleSpecTemplateHooks" = {

      options = {
        "resources" = mkOption {
          description = "Resources are hooks that should be executed when backing up individual instances of a resource.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "velero.io.v1.ScheduleSpecTemplateHooksResources" "name" [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "resources" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.ScheduleSpecTemplateHooksResources" = {

      options = {
        "excludedNamespaces" = mkOption {
          description = "ExcludedNamespaces specifies the namespaces to which this hook spec does not apply.";
          type = (types.nullOr (types.listOf types.str));
        };
        "excludedResources" = mkOption {
          description = "ExcludedResources specifies the resources to which this hook spec does not apply.";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedNamespaces" = mkOption {
          description = "IncludedNamespaces specifies the namespaces to which this hook spec applies. If empty, it applies\nto all namespaces.";
          type = (types.nullOr (types.listOf types.str));
        };
        "includedResources" = mkOption {
          description = "IncludedResources specifies the resources to which this hook spec applies. If empty, it applies\nto all resources.";
          type = (types.nullOr (types.listOf types.str));
        };
        "labelSelector" = mkOption {
          description = "LabelSelector, if specified, filters the resources to which this hook spec applies.";
          type = (types.nullOr (submoduleOf "velero.io.v1.ScheduleSpecTemplateHooksResourcesLabelSelector"));
        };
        "name" = mkOption {
          description = "Name is the name of this hook.";
          type = types.str;
        };
        "post" = mkOption {
          description = "PostHooks is a list of BackupResourceHooks to execute after storing the item in the backup.\nThese are executed after all \"additional items\" from item actions are processed.";
          type = (
            types.nullOr (types.listOf (submoduleOf "velero.io.v1.ScheduleSpecTemplateHooksResourcesPost"))
          );
        };
        "pre" = mkOption {
          description = "PreHooks is a list of BackupResourceHooks to execute prior to storing the item in the backup.\nThese are executed before any \"additional items\" from item actions are processed.";
          type = (
            types.nullOr (types.listOf (submoduleOf "velero.io.v1.ScheduleSpecTemplateHooksResourcesPre"))
          );
        };
      };

      config = {
        "excludedNamespaces" = mkOverride 1002 null;
        "excludedResources" = mkOverride 1002 null;
        "includedNamespaces" = mkOverride 1002 null;
        "includedResources" = mkOverride 1002 null;
        "labelSelector" = mkOverride 1002 null;
        "post" = mkOverride 1002 null;
        "pre" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.ScheduleSpecTemplateHooksResourcesLabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "velero.io.v1.ScheduleSpecTemplateHooksResourcesLabelSelectorMatchExpressions"
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
    "velero.io.v1.ScheduleSpecTemplateHooksResourcesLabelSelectorMatchExpressions" = {

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
    "velero.io.v1.ScheduleSpecTemplateHooksResourcesPost" = {

      options = {
        "exec" = mkOption {
          description = "Exec defines an exec hook.";
          type = (submoduleOf "velero.io.v1.ScheduleSpecTemplateHooksResourcesPostExec");
        };
      };

      config = { };

    };
    "velero.io.v1.ScheduleSpecTemplateHooksResourcesPostExec" = {

      options = {
        "command" = mkOption {
          description = "Command is the command and arguments to execute.";
          type = (types.listOf types.str);
        };
        "container" = mkOption {
          description = "Container is the container in the pod where the command should be executed. If not specified,\nthe pod's first container is used.";
          type = (types.nullOr types.str);
        };
        "onError" = mkOption {
          description = "OnError specifies how Velero should behave if it encounters an error executing this hook.";
          type = (types.nullOr types.str);
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum amount of time Velero should wait for the hook to complete before\nconsidering the execution a failure.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "container" = mkOverride 1002 null;
        "onError" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.ScheduleSpecTemplateHooksResourcesPre" = {

      options = {
        "exec" = mkOption {
          description = "Exec defines an exec hook.";
          type = (submoduleOf "velero.io.v1.ScheduleSpecTemplateHooksResourcesPreExec");
        };
      };

      config = { };

    };
    "velero.io.v1.ScheduleSpecTemplateHooksResourcesPreExec" = {

      options = {
        "command" = mkOption {
          description = "Command is the command and arguments to execute.";
          type = (types.listOf types.str);
        };
        "container" = mkOption {
          description = "Container is the container in the pod where the command should be executed. If not specified,\nthe pod's first container is used.";
          type = (types.nullOr types.str);
        };
        "onError" = mkOption {
          description = "OnError specifies how Velero should behave if it encounters an error executing this hook.";
          type = (types.nullOr types.str);
        };
        "timeout" = mkOption {
          description = "Timeout defines the maximum amount of time Velero should wait for the hook to complete before\nconsidering the execution a failure.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "container" = mkOverride 1002 null;
        "onError" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.ScheduleSpecTemplateLabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "velero.io.v1.ScheduleSpecTemplateLabelSelectorMatchExpressions")
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
    "velero.io.v1.ScheduleSpecTemplateLabelSelectorMatchExpressions" = {

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
    "velero.io.v1.ScheduleSpecTemplateMetadata" = {

      options = {
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "labels" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.ScheduleSpecTemplateOrLabelSelectors" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "velero.io.v1.ScheduleSpecTemplateOrLabelSelectorsMatchExpressions")
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
    "velero.io.v1.ScheduleSpecTemplateOrLabelSelectorsMatchExpressions" = {

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
    "velero.io.v1.ScheduleSpecTemplateResourcePolicy" = {

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
    "velero.io.v1.ScheduleSpecTemplateUploaderConfig" = {

      options = {
        "parallelFilesUpload" = mkOption {
          description = "ParallelFilesUpload is the number of files parallel uploads to perform when using the uploader.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "parallelFilesUpload" = mkOverride 1002 null;
      };

    };
    "velero.io.v1.ScheduleStatus" = {

      options = {
        "lastBackup" = mkOption {
          description = "LastBackup is the last time a Backup was run for this\nSchedule schedule";
          type = (types.nullOr types.str);
        };
        "lastSkipped" = mkOption {
          description = "LastSkipped is the last time a Schedule was skipped";
          type = (types.nullOr types.str);
        };
        "phase" = mkOption {
          description = "Phase is the current phase of the Schedule";
          type = (types.nullOr types.str);
        };
        "validationErrors" = mkOption {
          description = "ValidationErrors is a slice of all validation errors (if\napplicable)";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "lastBackup" = mkOverride 1002 null;
        "lastSkipped" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "validationErrors" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "velero.io"."v1"."Restore" = mkOption {
        description = "Restore is a Velero resource that represents the application of\nresources from a Velero backup to a target Kubernetes cluster.";
        type = (
          types.attrsOf (submoduleForDefinition "velero.io.v1.Restore" "restores" "Restore" "velero.io" "v1")
        );
        default = { };
      };
      "velero.io"."v1"."Schedule" = mkOption {
        description = "Schedule is a Velero resource that represents a pre-scheduled or\nperiodic Backup that should be run.";
        type = (
          types.attrsOf (
            submoduleForDefinition "velero.io.v1.Schedule" "schedules" "Schedule" "velero.io" "v1"
          )
        );
        default = { };
      };

    }
    // {
      "restores" = mkOption {
        description = "Restore is a Velero resource that represents the application of\nresources from a Velero backup to a target Kubernetes cluster.";
        type = (
          types.attrsOf (submoduleForDefinition "velero.io.v1.Restore" "restores" "Restore" "velero.io" "v1")
        );
        default = { };
      };
      "schedules" = mkOption {
        description = "Schedule is a Velero resource that represents a pre-scheduled or\nperiodic Backup that should be run.";
        type = (
          types.attrsOf (
            submoduleForDefinition "velero.io.v1.Schedule" "schedules" "Schedule" "velero.io" "v1"
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
        name = "restores";
        group = "velero.io";
        version = "v1";
        kind = "Restore";
        attrName = "restores";
      }
      {
        name = "schedules";
        group = "velero.io";
        version = "v1";
        kind = "Schedule";
        attrName = "schedules";
      }
    ];

    resources = {
      "velero.io"."v1"."Restore" = mkAliasDefinitions options.resources."restores";
      "velero.io"."v1"."Schedule" = mkAliasDefinitions options.resources."schedules";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "velero.io";
        version = "v1";
        kind = "Restore";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "velero.io";
        version = "v1";
        kind = "Schedule";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
