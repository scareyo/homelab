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
    "external-secrets.io.v1.ClusterSecretStore" = {

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
          description = "SecretStoreSpec defines the desired state of SecretStore.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpec"));
        };
        "status" = mkOption {
          description = "SecretStoreStatus defines the observed state of the SecretStore.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreStatus"));
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
    "external-secrets.io.v1.ClusterSecretStoreSpec" = {

      options = {
        "conditions" = mkOption {
          description = "Used to constraint a ClusterSecretStore to specific namespaces. Relevant only to ClusterSecretStore";
          type = (
            types.nullOr (types.listOf (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecConditions"))
          );
        };
        "controller" = mkOption {
          description = "Used to select the correct ESO controller (think: ingress.ingressClassName)\nThe ESO controller is instantiated with a specific controller name and filters ES based on this property";
          type = (types.nullOr types.str);
        };
        "provider" = mkOption {
          description = "Used to configure the provider. Only one provider may be set";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProvider");
        };
        "refreshInterval" = mkOption {
          description = "Used to configure store refresh interval in seconds. Empty or 0 will default to the controller config.";
          type = (types.nullOr types.int);
        };
        "retrySettings" = mkOption {
          description = "Used to configure http retries if failed";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecRetrySettings"));
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "controller" = mkOverride 1002 null;
        "refreshInterval" = mkOverride 1002 null;
        "retrySettings" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecConditions" = {

      options = {
        "namespaceRegexes" = mkOption {
          description = "Choose namespaces by using regex matching";
          type = (types.nullOr (types.listOf types.str));
        };
        "namespaceSelector" = mkOption {
          description = "Choose namespace using a labelSelector";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecConditionsNamespaceSelector"
            )
          );
        };
        "namespaces" = mkOption {
          description = "Choose namespaces by name";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "namespaceRegexes" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecConditionsNamespaceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecConditionsNamespaceSelectorMatchExpressions"
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
    "external-secrets.io.v1.ClusterSecretStoreSpecConditionsNamespaceSelectorMatchExpressions" = {

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
    "external-secrets.io.v1.ClusterSecretStoreSpecProvider" = {

      options = {
        "akeyless" = mkOption {
          description = "Akeyless configures this store to sync secrets using Akeyless Vault provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeyless"));
        };
        "alibaba" = mkOption {
          description = "Alibaba configures this store to sync secrets using Alibaba Cloud provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibaba"));
        };
        "aws" = mkOption {
          description = "AWS configures this store to sync secrets using AWS Secret Manager provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAws"));
        };
        "azurekv" = mkOption {
          description = "AzureKV configures this store to sync secrets using Azure Key Vault provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekv"));
        };
        "beyondtrust" = mkOption {
          description = "Beyondtrust configures this store to sync secrets using Password Safe provider.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrust")
          );
        };
        "bitwardensecretsmanager" = mkOption {
          description = "BitwardenSecretsManager configures this store to sync secrets using BitwardenSecretsManager provider";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanager"
            )
          );
        };
        "chef" = mkOption {
          description = "Chef configures this store to sync secrets with chef server";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderChef"));
        };
        "cloudrusm" = mkOption {
          description = "CloudruSM configures this store to sync secrets using the Cloud.ru Secret Manager provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusm")
          );
        };
        "conjur" = mkOption {
          description = "Conjur configures this store to sync secrets using conjur provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjur"));
        };
        "delinea" = mkOption {
          description = "Delinea DevOps Secrets Vault\nhttps://docs.delinea.com/online-help/products/devops-secrets-vault/current";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelinea"));
        };
        "device42" = mkOption {
          description = "Device42 configures this store to sync secrets using the Device42 provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDevice42"));
        };
        "doppler" = mkOption {
          description = "Doppler configures this store to sync secrets using the Doppler provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDoppler"));
        };
        "fake" = mkOption {
          description = "Fake configures a store with static key/value pairs";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderFake"));
        };
        "fortanix" = mkOption {
          description = "Fortanix configures this store to sync secrets using the Fortanix provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderFortanix"));
        };
        "gcpsm" = mkOption {
          description = "GCPSM configures this store to sync secrets using Google Cloud Platform Secret Manager provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsm"));
        };
        "github" = mkOption {
          description = "Github configures this store to push GitHub Action secrets using GitHub API provider.\nNote: This provider only supports write operations (PushSecret) and cannot fetch secrets from GitHub";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGithub"));
        };
        "gitlab" = mkOption {
          description = "GitLab configures this store to sync secrets using GitLab Variables provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlab"));
        };
        "ibm" = mkOption {
          description = "IBM configures this store to sync secrets using IBM Cloud provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbm"));
        };
        "infisical" = mkOption {
          description = "Infisical configures this store to sync secrets using the Infisical provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisical")
          );
        };
        "keepersecurity" = mkOption {
          description = "KeeperSecurity configures this store to sync secrets using the KeeperSecurity provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKeepersecurity")
          );
        };
        "kubernetes" = mkOption {
          description = "Kubernetes configures this store to sync secrets using a Kubernetes cluster provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetes")
          );
        };
        "ngrok" = mkOption {
          description = "Ngrok configures this store to sync secrets using the ngrok provider.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrok"));
        };
        "onboardbase" = mkOption {
          description = "Onboardbase configures this store to sync secrets using the Onboardbase provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnboardbase")
          );
        };
        "onepassword" = mkOption {
          description = "OnePassword configures this store to sync secrets using the 1Password Cloud provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepassword")
          );
        };
        "onepasswordSDK" = mkOption {
          description = "OnePasswordSDK configures this store to use 1Password's new Go SDK to sync secrets.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordSDK")
          );
        };
        "oracle" = mkOption {
          description = "Oracle configures this store to sync secrets using Oracle Vault provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracle"));
        };
        "passbolt" = mkOption {
          description = "PassboltProvider provides access to Passbolt secrets manager.\nSee: https://www.passbolt.com.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassbolt"));
        };
        "passworddepot" = mkOption {
          description = "PasswordDepotProvider configures a store to sync secrets with a Password Depot instance.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassworddepot")
          );
        };
        "previder" = mkOption {
          description = "Previder configures this store to sync secrets using the Previder provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPrevider"));
        };
        "pulumi" = mkOption {
          description = "Pulumi configures this store to sync secrets using the Pulumi provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPulumi"));
        };
        "scaleway" = mkOption {
          description = "Scaleway";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderScaleway"));
        };
        "secretserver" = mkOption {
          description = "SecretServer configures this store to sync secrets using SecretServer provider\nhttps://docs.delinea.com/online-help/secret-server/start.htm";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserver")
          );
        };
        "senhasegura" = mkOption {
          description = "Senhasegura configures this store to sync secrets using senhasegura provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderSenhasegura")
          );
        };
        "vault" = mkOption {
          description = "Vault configures this store to sync secrets using Hashi provider";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVault"));
        };
        "volcengine" = mkOption {
          description = "Volcengine configures this store to sync secrets using the Volcengine provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengine")
          );
        };
        "webhook" = mkOption {
          description = "Webhook configures this store to sync secrets using a generic templated webhook";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhook"));
        };
        "yandexcertificatemanager" = mkOption {
          description = "YandexCertificateManager configures this store to sync secrets using Yandex Certificate Manager provider";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanager"
            )
          );
        };
        "yandexlockbox" = mkOption {
          description = "YandexLockbox configures this store to sync secrets using Yandex Lockbox provider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockbox")
          );
        };
      };

      config = {
        "akeyless" = mkOverride 1002 null;
        "alibaba" = mkOverride 1002 null;
        "aws" = mkOverride 1002 null;
        "azurekv" = mkOverride 1002 null;
        "beyondtrust" = mkOverride 1002 null;
        "bitwardensecretsmanager" = mkOverride 1002 null;
        "chef" = mkOverride 1002 null;
        "cloudrusm" = mkOverride 1002 null;
        "conjur" = mkOverride 1002 null;
        "delinea" = mkOverride 1002 null;
        "device42" = mkOverride 1002 null;
        "doppler" = mkOverride 1002 null;
        "fake" = mkOverride 1002 null;
        "fortanix" = mkOverride 1002 null;
        "gcpsm" = mkOverride 1002 null;
        "github" = mkOverride 1002 null;
        "gitlab" = mkOverride 1002 null;
        "ibm" = mkOverride 1002 null;
        "infisical" = mkOverride 1002 null;
        "keepersecurity" = mkOverride 1002 null;
        "kubernetes" = mkOverride 1002 null;
        "ngrok" = mkOverride 1002 null;
        "onboardbase" = mkOverride 1002 null;
        "onepassword" = mkOverride 1002 null;
        "onepasswordSDK" = mkOverride 1002 null;
        "oracle" = mkOverride 1002 null;
        "passbolt" = mkOverride 1002 null;
        "passworddepot" = mkOverride 1002 null;
        "previder" = mkOverride 1002 null;
        "pulumi" = mkOverride 1002 null;
        "scaleway" = mkOverride 1002 null;
        "secretserver" = mkOverride 1002 null;
        "senhasegura" = mkOverride 1002 null;
        "vault" = mkOverride 1002 null;
        "volcengine" = mkOverride 1002 null;
        "webhook" = mkOverride 1002 null;
        "yandexcertificatemanager" = mkOverride 1002 null;
        "yandexlockbox" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeyless" = {

      options = {
        "akeylessGWApiURL" = mkOption {
          description = "Akeyless GW API Url from which the secrets to be fetched from.";
          type = types.str;
        };
        "authSecretRef" = mkOption {
          description = "Auth configures how the operator authenticates with Akeyless.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRef");
        };
        "caBundle" = mkOption {
          description = "PEM/base64 encoded CA bundle used to validate Akeyless Gateway certificate. Only used\nif the AkeylessGWApiURL URL is using HTTPS protocol. If not set the system root certificates\nare used to validate the TLS connection.";
          type = (types.nullOr types.str);
        };
        "caProvider" = mkOption {
          description = "The provider for the CA bundle to use to validate Akeyless Gateway certificate.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessCaProvider")
          );
        };
      };

      config = {
        "caBundle" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRef" = {

      options = {
        "kubernetesAuth" = mkOption {
          description = "Kubernetes authenticates with Akeyless by passing the ServiceAccount\ntoken stored in the named Secret resource.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefKubernetesAuth"
            )
          );
        };
        "secretRef" = mkOption {
          description = "Reference to a Secret that contains the details\nto authenticate with Akeyless.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefSecretRef"
            )
          );
        };
      };

      config = {
        "kubernetesAuth" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefKubernetesAuth" = {

      options = {
        "accessID" = mkOption {
          description = "the Akeyless Kubernetes auth-method access-id";
          type = types.str;
        };
        "k8sConfName" = mkOption {
          description = "Kubernetes-auth configuration name in Akeyless-Gateway";
          type = types.str;
        };
        "secretRef" = mkOption {
          description = "Optional secret field containing a Kubernetes ServiceAccount JWT used\nfor authenticating with Akeyless. If a name is specified without a key,\n`token` is the default. If one is not specified, the one bound to\nthe controller will be used.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefKubernetesAuthSecretRef"
            )
          );
        };
        "serviceAccountRef" = mkOption {
          description = "Optional service account field containing the name of a kubernetes ServiceAccount.\nIf the service account is specified, the service account secret token JWT will be used\nfor authenticating with Akeyless. If the service account selector is not supplied,\nthe secretRef will be used instead.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefKubernetesAuthServiceAccountRef"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "serviceAccountRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefKubernetesAuthSecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefKubernetesAuthServiceAccountRef" =
      {

        options = {
          "audiences" = mkOption {
            description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
            type = (types.nullOr (types.listOf types.str));
          };
          "name" = mkOption {
            description = "The name of the ServiceAccount resource being referred to.";
            type = types.str;
          };
          "namespace" = mkOption {
            description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "audiences" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefSecretRef" = {

      options = {
        "accessID" = mkOption {
          description = "The SecretAccessID is used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefSecretRefAccessID"
            )
          );
        };
        "accessType" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefSecretRefAccessType"
            )
          );
        };
        "accessTypeParam" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefSecretRefAccessTypeParam"
            )
          );
        };
      };

      config = {
        "accessID" = mkOverride 1002 null;
        "accessType" = mkOverride 1002 null;
        "accessTypeParam" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefSecretRefAccessID" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefSecretRefAccessType" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessAuthSecretRefSecretRefAccessTypeParam" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAkeylessCaProvider" = {

      options = {
        "key" = mkOption {
          description = "The key where the CA certificate can be found in the Secret or ConfigMap.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the object located at the provider type.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "The namespace the Provider type is in.\nCan only be defined when used in a ClusterSecretStore.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "The type of provider to use such as \"Secret\", or \"ConfigMap\".";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibaba" = {

      options = {
        "auth" = mkOption {
          description = "AlibabaAuth contains a secretRef for credentials.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuth");
        };
        "regionID" = mkOption {
          description = "Alibaba Region to be used for the provider";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuth" = {

      options = {
        "rrsa" = mkOption {
          description = "AlibabaRRSAAuth authenticates against Alibaba using RRSA.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuthRrsa")
          );
        };
        "secretRef" = mkOption {
          description = "AlibabaAuthSecretRef holds secret references for Alibaba credentials.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuthSecretRef"
            )
          );
        };
      };

      config = {
        "rrsa" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuthRrsa" = {

      options = {
        "oidcProviderArn" = mkOption {
          description = "";
          type = types.str;
        };
        "oidcTokenFilePath" = mkOption {
          description = "";
          type = types.str;
        };
        "roleArn" = mkOption {
          description = "";
          type = types.str;
        };
        "sessionName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuthSecretRef" = {

      options = {
        "accessKeyIDSecretRef" = mkOption {
          description = "The AccessKeyID is used for authentication";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuthSecretRefAccessKeyIDSecretRef"
          );
        };
        "accessKeySecretSecretRef" = mkOption {
          description = "The AccessKeySecret is used for authentication";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuthSecretRefAccessKeySecretSecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuthSecretRefAccessKeyIDSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAlibabaAuthSecretRefAccessKeySecretSecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAws" = {

      options = {
        "additionalRoles" = mkOption {
          description = "AdditionalRoles is a chained list of Role ARNs which the provider will sequentially assume before assuming the Role";
          type = (types.nullOr (types.listOf types.str));
        };
        "auth" = mkOption {
          description = "Auth defines the information necessary to authenticate against AWS\nif not set aws sdk will infer credentials from your environment\nsee: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuth"));
        };
        "externalID" = mkOption {
          description = "AWS External ID set on assumed IAM roles";
          type = (types.nullOr types.str);
        };
        "prefix" = mkOption {
          description = "Prefix adds a prefix to all retrieved values.";
          type = (types.nullOr types.str);
        };
        "region" = mkOption {
          description = "AWS Region to be used for the provider";
          type = types.str;
        };
        "role" = mkOption {
          description = "Role is a Role ARN which the provider will assume";
          type = (types.nullOr types.str);
        };
        "secretsManager" = mkOption {
          description = "SecretsManager defines how the provider behaves when interacting with AWS SecretsManager";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsSecretsManager")
          );
        };
        "service" = mkOption {
          description = "Service defines which service should be used to fetch the secrets";
          type = types.str;
        };
        "sessionTags" = mkOption {
          description = "AWS STS assume role session tags";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsSessionTags")
            )
          );
        };
        "transitiveTagKeys" = mkOption {
          description = "AWS STS assume role transitive session tags. Required when multiple rules are used with the provider";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "additionalRoles" = mkOverride 1002 null;
        "auth" = mkOverride 1002 null;
        "externalID" = mkOverride 1002 null;
        "prefix" = mkOverride 1002 null;
        "role" = mkOverride 1002 null;
        "secretsManager" = mkOverride 1002 null;
        "sessionTags" = mkOverride 1002 null;
        "transitiveTagKeys" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuth" = {

      options = {
        "jwt" = mkOption {
          description = "AWSJWTAuth stores reference to Authenticate against AWS using service account tokens.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthJwt")
          );
        };
        "secretRef" = mkOption {
          description = "AWSAuthSecretRef holds secret references for AWS credentials\nboth AccessKeyID and SecretAccessKey must be defined in order to properly authenticate.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthSecretRef")
          );
        };
      };

      config = {
        "jwt" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthJwt" = {

      options = {
        "serviceAccountRef" = mkOption {
          description = "ServiceAccountSelector is a reference to a ServiceAccount resource.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthJwtServiceAccountRef"
            )
          );
        };
      };

      config = {
        "serviceAccountRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthJwtServiceAccountRef" = {

      options = {
        "audiences" = mkOption {
          description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The name of the ServiceAccount resource being referred to.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthSecretRef" = {

      options = {
        "accessKeyIDSecretRef" = mkOption {
          description = "The AccessKeyID is used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthSecretRefAccessKeyIDSecretRef"
            )
          );
        };
        "secretAccessKeySecretRef" = mkOption {
          description = "The SecretAccessKey is used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthSecretRefSecretAccessKeySecretRef"
            )
          );
        };
        "sessionTokenSecretRef" = mkOption {
          description = "The SessionToken used for authentication\nThis must be defined if AccessKeyID and SecretAccessKey are temporary credentials\nsee: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthSecretRefSessionTokenSecretRef"
            )
          );
        };
      };

      config = {
        "accessKeyIDSecretRef" = mkOverride 1002 null;
        "secretAccessKeySecretRef" = mkOverride 1002 null;
        "sessionTokenSecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthSecretRefAccessKeyIDSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthSecretRefSecretAccessKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsAuthSecretRefSessionTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsSecretsManager" = {

      options = {
        "forceDeleteWithoutRecovery" = mkOption {
          description = "Specifies whether to delete the secret without any recovery window. You\ncan't use both this parameter and RecoveryWindowInDays in the same call.\nIf you don't use either, then by default Secrets Manager uses a 30 day\nrecovery window.\nsee: https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_DeleteSecret.html#SecretsManager-DeleteSecret-request-ForceDeleteWithoutRecovery";
          type = (types.nullOr types.bool);
        };
        "recoveryWindowInDays" = mkOption {
          description = "The number of days from 7 to 30 that Secrets Manager waits before\npermanently deleting the secret. You can't use both this parameter and\nForceDeleteWithoutRecovery in the same call. If you don't use either,\nthen by default Secrets Manager uses a 30-day recovery window.\nsee: https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_DeleteSecret.html#SecretsManager-DeleteSecret-request-RecoveryWindowInDays";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "forceDeleteWithoutRecovery" = mkOverride 1002 null;
        "recoveryWindowInDays" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAwsSessionTags" = {

      options = {
        "key" = mkOption {
          description = "";
          type = types.str;
        };
        "value" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekv" = {

      options = {
        "authSecretRef" = mkOption {
          description = "Auth configures how the operator authenticates with Azure. Required for ServicePrincipal auth type. Optional for WorkloadIdentity.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRef"
            )
          );
        };
        "authType" = mkOption {
          description = "Auth type defines how to authenticate to the keyvault service.\nValid values are:\n- \"ServicePrincipal\" (default): Using a service principal (tenantId, clientId, clientSecret)\n- \"ManagedIdentity\": Using Managed Identity assigned to the pod (see aad-pod-identity)";
          type = (types.nullOr types.str);
        };
        "customCloudConfig" = mkOption {
          description = "CustomCloudConfig defines custom Azure Stack Hub or Azure Stack Edge endpoints.\nRequired when EnvironmentType is AzureStackCloud.\nIMPORTANT: This feature REQUIRES UseAzureSDK to be set to true. Custom cloud\nconfiguration is not supported with the legacy go-autorest SDK.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvCustomCloudConfig"
            )
          );
        };
        "environmentType" = mkOption {
          description = "EnvironmentType specifies the Azure cloud environment endpoints to use for\nconnecting and authenticating with Azure. By default it points to the public cloud AAD endpoint.\nThe following endpoints are available, also see here: https://github.com/Azure/go-autorest/blob/main/autorest/azure/environments.go#L152\nPublicCloud, USGovernmentCloud, ChinaCloud, GermanCloud, AzureStackCloud\nUse AzureStackCloud when you need to configure custom Azure Stack Hub or Azure Stack Edge endpoints.";
          type = (types.nullOr types.str);
        };
        "identityId" = mkOption {
          description = "If multiple Managed Identity is assigned to the pod, you can select the one to be used";
          type = (types.nullOr types.str);
        };
        "serviceAccountRef" = mkOption {
          description = "ServiceAccountRef specified the service account\nthat should be used when authenticating with WorkloadIdentity.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvServiceAccountRef"
            )
          );
        };
        "tenantId" = mkOption {
          description = "TenantID configures the Azure Tenant to send requests to. Required for ServicePrincipal auth type. Optional for WorkloadIdentity.";
          type = (types.nullOr types.str);
        };
        "useAzureSDK" = mkOption {
          description = "UseAzureSDK enables the use of the new Azure SDK for Go (azcore-based) instead of the legacy go-autorest SDK.\nThis is experimental and may have behavioral differences. Defaults to false (legacy SDK).";
          type = (types.nullOr types.bool);
        };
        "vaultUrl" = mkOption {
          description = "Vault Url from which the secrets to be fetched from.";
          type = types.str;
        };
      };

      config = {
        "authSecretRef" = mkOverride 1002 null;
        "authType" = mkOverride 1002 null;
        "customCloudConfig" = mkOverride 1002 null;
        "environmentType" = mkOverride 1002 null;
        "identityId" = mkOverride 1002 null;
        "serviceAccountRef" = mkOverride 1002 null;
        "tenantId" = mkOverride 1002 null;
        "useAzureSDK" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRef" = {

      options = {
        "clientCertificate" = mkOption {
          description = "The Azure ClientCertificate of the service principle used for authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRefClientCertificate"
            )
          );
        };
        "clientId" = mkOption {
          description = "The Azure clientId of the service principle or managed identity used for authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRefClientId"
            )
          );
        };
        "clientSecret" = mkOption {
          description = "The Azure ClientSecret of the service principle used for authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRefClientSecret"
            )
          );
        };
        "tenantId" = mkOption {
          description = "The Azure tenantId of the managed identity used for authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRefTenantId"
            )
          );
        };
      };

      config = {
        "clientCertificate" = mkOverride 1002 null;
        "clientId" = mkOverride 1002 null;
        "clientSecret" = mkOverride 1002 null;
        "tenantId" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRefClientCertificate" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRefClientId" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRefClientSecret" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvAuthSecretRefTenantId" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvCustomCloudConfig" = {

      options = {
        "activeDirectoryEndpoint" = mkOption {
          description = "ActiveDirectoryEndpoint is the AAD endpoint for authentication\nRequired when using custom cloud configuration";
          type = types.str;
        };
        "keyVaultDNSSuffix" = mkOption {
          description = "KeyVaultDNSSuffix is the DNS suffix for Key Vault URLs";
          type = (types.nullOr types.str);
        };
        "keyVaultEndpoint" = mkOption {
          description = "KeyVaultEndpoint is the Key Vault service endpoint";
          type = (types.nullOr types.str);
        };
        "resourceManagerEndpoint" = mkOption {
          description = "ResourceManagerEndpoint is the Azure Resource Manager endpoint";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "keyVaultDNSSuffix" = mkOverride 1002 null;
        "keyVaultEndpoint" = mkOverride 1002 null;
        "resourceManagerEndpoint" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderAzurekvServiceAccountRef" = {

      options = {
        "audiences" = mkOption {
          description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The name of the ServiceAccount resource being referred to.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrust" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how the operator authenticates with Beyondtrust.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuth");
        };
        "server" = mkOption {
          description = "Auth configures how API server works.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustServer");
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuth" = {

      options = {
        "apiKey" = mkOption {
          description = "APIKey If not provided then ClientID/ClientSecret become required.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthApiKey"
            )
          );
        };
        "certificate" = mkOption {
          description = "Certificate (cert.pem) for use when authenticating with an OAuth client Id using a Client Certificate.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthCertificate"
            )
          );
        };
        "certificateKey" = mkOption {
          description = "Certificate private key (key.pem). For use when authenticating with an OAuth client Id";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthCertificateKey"
            )
          );
        };
        "clientId" = mkOption {
          description = "ClientID is the API OAuth Client ID.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthClientId"
            )
          );
        };
        "clientSecret" = mkOption {
          description = "ClientSecret is the API OAuth Client Secret.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthClientSecret"
            )
          );
        };
      };

      config = {
        "apiKey" = mkOverride 1002 null;
        "certificate" = mkOverride 1002 null;
        "certificateKey" = mkOverride 1002 null;
        "clientId" = mkOverride 1002 null;
        "clientSecret" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthApiKey" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthApiKeySecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthApiKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthCertificate" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthCertificateSecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthCertificateKey" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthCertificateKeySecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthCertificateKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthCertificateSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthClientId" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthClientIdSecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthClientIdSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthClientSecret" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthClientSecretSecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustAuthClientSecretSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBeyondtrustServer" = {

      options = {
        "apiUrl" = mkOption {
          description = "";
          type = types.str;
        };
        "apiVersion" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "clientTimeOutSeconds" = mkOption {
          description = "Timeout specifies a time limit for requests made by this Client. The timeout includes connection time, any redirects, and reading the response body. Defaults to 45 seconds.";
          type = (types.nullOr types.int);
        };
        "retrievalType" = mkOption {
          description = "The secret retrieval type. SECRET = Secrets Safe (credential, text, file). MANAGED_ACCOUNT = Password Safe account associated with a system.";
          type = (types.nullOr types.str);
        };
        "separator" = mkOption {
          description = "A character that separates the folder names.";
          type = (types.nullOr types.str);
        };
        "verifyCA" = mkOption {
          description = "";
          type = types.bool;
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "clientTimeOutSeconds" = mkOverride 1002 null;
        "retrievalType" = mkOverride 1002 null;
        "separator" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanager" = {

      options = {
        "apiURL" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "auth" = mkOption {
          description = "Auth configures how secret-manager authenticates with a bitwarden machine account instance.\nMake sure that the token being used has permissions on the given secret.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanagerAuth"
          );
        };
        "bitwardenServerSDKURL" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "caBundle" = mkOption {
          description = "Base64 encoded certificate for the bitwarden server sdk. The sdk MUST run with HTTPS to make sure no MITM attack\ncan be performed.";
          type = (types.nullOr types.str);
        };
        "caProvider" = mkOption {
          description = "see: https://external-secrets.io/latest/spec/#external-secrets.io/v1alpha1.CAProvider";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanagerCaProvider"
            )
          );
        };
        "identityURL" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "organizationID" = mkOption {
          description = "OrganizationID determines which organization this secret store manages.";
          type = types.str;
        };
        "projectID" = mkOption {
          description = "ProjectID determines which project this secret store manages.";
          type = types.str;
        };
      };

      config = {
        "apiURL" = mkOverride 1002 null;
        "bitwardenServerSDKURL" = mkOverride 1002 null;
        "caBundle" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
        "identityURL" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanagerAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "BitwardenSecretsManagerSecretRef contains the credential ref to the bitwarden instance.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanagerAuthSecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanagerAuthSecretRef" = {

      options = {
        "credentials" = mkOption {
          description = "AccessToken used for the bitwarden instance.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanagerAuthSecretRefCredentials"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanagerAuthSecretRefCredentials" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderBitwardensecretsmanagerCaProvider" = {

      options = {
        "key" = mkOption {
          description = "The key where the CA certificate can be found in the Secret or ConfigMap.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the object located at the provider type.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "The namespace the Provider type is in.\nCan only be defined when used in a ClusterSecretStore.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "The type of provider to use such as \"Secret\", or \"ConfigMap\".";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderChef" = {

      options = {
        "auth" = mkOption {
          description = "Auth defines the information necessary to authenticate against chef Server";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderChefAuth");
        };
        "serverUrl" = mkOption {
          description = "ServerURL is the chef server URL used to connect to. If using orgs you should include your org in the url and terminate the url with a \"/\"";
          type = types.str;
        };
        "username" = mkOption {
          description = "UserName should be the user ID on the chef server";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderChefAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "ChefAuthSecretRef holds secret references for chef server login credentials.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderChefAuthSecretRef");
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderChefAuthSecretRef" = {

      options = {
        "privateKeySecretRef" = mkOption {
          description = "SecretKey is the Signing Key in PEM format, used for authentication.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderChefAuthSecretRefPrivateKeySecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderChefAuthSecretRefPrivateKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusm" = {

      options = {
        "auth" = mkOption {
          description = "CSMAuth contains a secretRef for credentials.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusmAuth");
        };
        "projectID" = mkOption {
          description = "ProjectID is the project, which the secrets are stored in.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "projectID" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusmAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "CSMAuthSecretRef holds secret references for Cloud.ru credentials.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusmAuthSecretRef"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusmAuthSecretRef" = {

      options = {
        "accessKeyIDSecretRef" = mkOption {
          description = "The AccessKeyID is used for authentication";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusmAuthSecretRefAccessKeyIDSecretRef"
          );
        };
        "accessKeySecretSecretRef" = mkOption {
          description = "The AccessKeySecret is used for authentication";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusmAuthSecretRefAccessKeySecretSecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusmAuthSecretRefAccessKeyIDSecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderCloudrusmAuthSecretRefAccessKeySecretSecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjur" = {

      options = {
        "auth" = mkOption {
          description = "Defines authentication settings for connecting to Conjur.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuth");
        };
        "caBundle" = mkOption {
          description = "CABundle is a PEM encoded CA bundle that will be used to validate the Conjur server certificate.";
          type = (types.nullOr types.str);
        };
        "caProvider" = mkOption {
          description = "Used to provide custom certificate authority (CA) certificates\nfor a secret store. The CAProvider points to a Secret or ConfigMap resource\nthat contains a PEM-encoded certificate.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurCaProvider")
          );
        };
        "url" = mkOption {
          description = "URL is the endpoint of the Conjur instance.";
          type = types.str;
        };
      };

      config = {
        "caBundle" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuth" = {

      options = {
        "apikey" = mkOption {
          description = "Authenticates with Conjur using an API key.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthApikey")
          );
        };
        "jwt" = mkOption {
          description = "Jwt enables JWT authentication using Kubernetes service account tokens.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthJwt")
          );
        };
      };

      config = {
        "apikey" = mkOverride 1002 null;
        "jwt" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthApikey" = {

      options = {
        "account" = mkOption {
          description = "Account is the Conjur organization account name.";
          type = types.str;
        };
        "apiKeyRef" = mkOption {
          description = "A reference to a specific 'key' containing the Conjur API key\nwithin a Secret resource. In some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthApikeyApiKeyRef"
          );
        };
        "userRef" = mkOption {
          description = "A reference to a specific 'key' containing the Conjur username\nwithin a Secret resource. In some instances, `key` is a required field.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthApikeyUserRef");
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthApikeyApiKeyRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthApikeyUserRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthJwt" = {

      options = {
        "account" = mkOption {
          description = "Account is the Conjur organization account name.";
          type = types.str;
        };
        "hostId" = mkOption {
          description = "Optional HostID for JWT authentication. This may be used depending\non how the Conjur JWT authenticator policy is configured.";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "Optional SecretRef that refers to a key in a Secret resource containing JWT token to\nauthenticate with Conjur using the JWT authentication method.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthJwtSecretRef"
            )
          );
        };
        "serviceAccountRef" = mkOption {
          description = "Optional ServiceAccountRef specifies the Kubernetes service account for which to request\na token for with the `TokenRequest` API.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthJwtServiceAccountRef"
            )
          );
        };
        "serviceID" = mkOption {
          description = "The conjur authn jwt webservice id";
          type = types.str;
        };
      };

      config = {
        "hostId" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "serviceAccountRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthJwtSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurAuthJwtServiceAccountRef" = {

      options = {
        "audiences" = mkOption {
          description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The name of the ServiceAccount resource being referred to.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderConjurCaProvider" = {

      options = {
        "key" = mkOption {
          description = "The key where the CA certificate can be found in the Secret or ConfigMap.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the object located at the provider type.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "The namespace the Provider type is in.\nCan only be defined when used in a ClusterSecretStore.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "The type of provider to use such as \"Secret\", or \"ConfigMap\".";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelinea" = {

      options = {
        "clientId" = mkOption {
          description = "ClientID is the non-secret part of the credential.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelineaClientId");
        };
        "clientSecret" = mkOption {
          description = "ClientSecret is the secret part of the credential.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelineaClientSecret");
        };
        "tenant" = mkOption {
          description = "Tenant is the chosen hostname / site name.";
          type = types.str;
        };
        "tld" = mkOption {
          description = "TLD is based on the server location that was chosen during provisioning.\nIf unset, defaults to \"com\".";
          type = (types.nullOr types.str);
        };
        "urlTemplate" = mkOption {
          description = "URLTemplate\nIf unset, defaults to \"https://%s.secretsvaultcloud.%s/v1/%s%s\".";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "tld" = mkOverride 1002 null;
        "urlTemplate" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelineaClientId" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelineaClientIdSecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelineaClientIdSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelineaClientSecret" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelineaClientSecretSecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDelineaClientSecretSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDevice42" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how secret-manager authenticates with a Device42 instance.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDevice42Auth");
        };
        "host" = mkOption {
          description = "URL configures the Device42 instance URL.";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDevice42Auth" = {

      options = {
        "secretRef" = mkOption {
          description = "Device42SecretRef contains the secret reference for accessing the Device42 instance.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDevice42AuthSecretRef");
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDevice42AuthSecretRef" = {

      options = {
        "credentials" = mkOption {
          description = "Username / Password is used for authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDevice42AuthSecretRefCredentials"
            )
          );
        };
      };

      config = {
        "credentials" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDevice42AuthSecretRefCredentials" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDoppler" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how the Operator authenticates with the Doppler API";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDopplerAuth");
        };
        "config" = mkOption {
          description = "Doppler config (required if not using a Service Token)";
          type = (types.nullOr types.str);
        };
        "format" = mkOption {
          description = "Format enables the downloading of secrets as a file (string)";
          type = (types.nullOr types.str);
        };
        "nameTransformer" = mkOption {
          description = "Environment variable compatible name transforms that change secret names to a different format";
          type = (types.nullOr types.str);
        };
        "project" = mkOption {
          description = "Doppler project (required if not using a Service Token)";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "config" = mkOverride 1002 null;
        "format" = mkOverride 1002 null;
        "nameTransformer" = mkOverride 1002 null;
        "project" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDopplerAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "DopplerAuthSecretRef contains the secret reference for accessing the Doppler API.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDopplerAuthSecretRef");
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDopplerAuthSecretRef" = {

      options = {
        "dopplerToken" = mkOption {
          description = "The DopplerToken is used for authentication.\nSee https://docs.doppler.com/reference/api#authentication for auth token types.\nThe Key attribute defaults to dopplerToken if not specified.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderDopplerAuthSecretRefDopplerToken"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderDopplerAuthSecretRefDopplerToken" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderFake" = {

      options = {
        "data" = mkOption {
          description = "";
          type = (types.listOf (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderFakeData"));
        };
        "validationResult" = mkOption {
          description = "ValidationResult is defined type for the number of validation results.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "validationResult" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderFakeData" = {

      options = {
        "key" = mkOption {
          description = "";
          type = types.str;
        };
        "value" = mkOption {
          description = "";
          type = types.str;
        };
        "version" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "version" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderFortanix" = {

      options = {
        "apiKey" = mkOption {
          description = "APIKey is the API token to access SDKMS Applications.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderFortanixApiKey")
          );
        };
        "apiUrl" = mkOption {
          description = "APIURL is the URL of SDKMS API. Defaults to `sdkms.fortanix.com`.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "apiKey" = mkOverride 1002 null;
        "apiUrl" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderFortanixApiKey" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef is a reference to a secret containing the SDKMS API Key.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderFortanixApiKeySecretRef"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderFortanixApiKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsm" = {

      options = {
        "auth" = mkOption {
          description = "Auth defines the information necessary to authenticate against GCP";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuth")
          );
        };
        "location" = mkOption {
          description = "Location optionally defines a location for a secret";
          type = (types.nullOr types.str);
        };
        "projectID" = mkOption {
          description = "ProjectID project where secret is located";
          type = (types.nullOr types.str);
        };
        "secretVersionSelectionPolicy" = mkOption {
          description = "SecretVersionSelectionPolicy specifies how the provider selects a secret version\nwhen \"latest\" is disabled or destroyed.\nPossible values are:\n- LatestOrFail: the provider always uses \"latest\", or fails if that version is disabled/destroyed.\n- LatestOrFetch: the provider falls back to fetching the latest version if the version is DESTROYED or DISABLED";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "auth" = mkOverride 1002 null;
        "location" = mkOverride 1002 null;
        "projectID" = mkOverride 1002 null;
        "secretVersionSelectionPolicy" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "GCPSMAuthSecretRef contains the secret references for GCP Secret Manager authentication.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthSecretRef")
          );
        };
        "workloadIdentity" = mkOption {
          description = "GCPWorkloadIdentity defines configuration for workload identity authentication to GCP.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentity"
            )
          );
        };
        "workloadIdentityFederation" = mkOption {
          description = "GCPWorkloadIdentityFederation holds the configurations required for generating federated access tokens.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederation"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "workloadIdentity" = mkOverride 1002 null;
        "workloadIdentityFederation" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthSecretRef" = {

      options = {
        "secretAccessKeySecretRef" = mkOption {
          description = "The SecretAccessKey is used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthSecretRefSecretAccessKeySecretRef"
            )
          );
        };
      };

      config = {
        "secretAccessKeySecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthSecretRefSecretAccessKeySecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentity" = {

      options = {
        "clusterLocation" = mkOption {
          description = "ClusterLocation is the location of the cluster\nIf not specified, it fetches information from the metadata server";
          type = (types.nullOr types.str);
        };
        "clusterName" = mkOption {
          description = "ClusterName is the name of the cluster\nIf not specified, it fetches information from the metadata server";
          type = (types.nullOr types.str);
        };
        "clusterProjectID" = mkOption {
          description = "ClusterProjectID is the project ID of the cluster\nIf not specified, it fetches information from the metadata server";
          type = (types.nullOr types.str);
        };
        "serviceAccountRef" = mkOption {
          description = "ServiceAccountSelector is a reference to a ServiceAccount resource.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityServiceAccountRef"
          );
        };
      };

      config = {
        "clusterLocation" = mkOverride 1002 null;
        "clusterName" = mkOverride 1002 null;
        "clusterProjectID" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederation" = {

      options = {
        "audience" = mkOption {
          description = "audience is the Secure Token Service (STS) audience which contains the resource name for the workload identity pool and the provider identifier in that pool.\nIf specified, Audience found in the external account credential config will be overridden with the configured value.\naudience must be provided when serviceAccountRef or awsSecurityCredentials is configured.";
          type = (types.nullOr types.str);
        };
        "awsSecurityCredentials" = mkOption {
          description = "awsSecurityCredentials is for configuring AWS region and credentials to use for obtaining the access token,\nwhen using the AWS metadata server is not an option.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederationAwsSecurityCredentials"
            )
          );
        };
        "credConfig" = mkOption {
          description = "credConfig holds the configmap reference containing the GCP external account credential configuration in JSON format and the key name containing the json data.\nFor using Kubernetes cluster as the identity provider, use serviceAccountRef instead. Operators mounted serviceaccount token cannot be used as the token source, instead\nserviceAccountRef must be used by providing operators service account details.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederationCredConfig"
            )
          );
        };
        "externalTokenEndpoint" = mkOption {
          description = "externalTokenEndpoint is the endpoint explicitly set up to provide tokens, which will be matched against the\ncredential_source.url in the provided credConfig. This field is merely to double-check the external token source\nURL is having the expected value.";
          type = (types.nullOr types.str);
        };
        "serviceAccountRef" = mkOption {
          description = "serviceAccountRef is the reference to the kubernetes ServiceAccount to be used for obtaining the tokens,\nwhen Kubernetes is configured as provider in workload identity pool.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederationServiceAccountRef"
            )
          );
        };
      };

      config = {
        "audience" = mkOverride 1002 null;
        "awsSecurityCredentials" = mkOverride 1002 null;
        "credConfig" = mkOverride 1002 null;
        "externalTokenEndpoint" = mkOverride 1002 null;
        "serviceAccountRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederationAwsSecurityCredentials" =
      {

        options = {
          "awsCredentialsSecretRef" = mkOption {
            description = "awsCredentialsSecretRef is the reference to the secret which holds the AWS credentials.\nSecret should be created with below names for keys\n- aws_access_key_id: Access Key ID, which is the unique identifier for the AWS account or the IAM user.\n- aws_secret_access_key: Secret Access Key, which is used to authenticate requests made to AWS services.\n- aws_session_token: Session Token, is the short-lived token to authenticate requests made to AWS services.";
            type = (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederationAwsSecurityCredentialsAwsCredentialsSecretRef"
            );
          };
          "region" = mkOption {
            description = "region is for configuring the AWS region to be used.";
            type = types.str;
          };
        };

        config = { };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederationAwsSecurityCredentialsAwsCredentialsSecretRef" =
      {

        options = {
          "name" = mkOption {
            description = "name of the secret.";
            type = types.str;
          };
          "namespace" = mkOption {
            description = "namespace in which the secret exists. If empty, secret will looked up in local namespace.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederationCredConfig" =
      {

        options = {
          "key" = mkOption {
            description = "key name holding the external account credential config.";
            type = types.str;
          };
          "name" = mkOption {
            description = "name of the configmap.";
            type = types.str;
          };
          "namespace" = mkOption {
            description = "namespace in which the configmap exists. If empty, configmap will looked up in local namespace.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityFederationServiceAccountRef" =
      {

        options = {
          "audiences" = mkOption {
            description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
            type = (types.nullOr (types.listOf types.str));
          };
          "name" = mkOption {
            description = "The name of the ServiceAccount resource being referred to.";
            type = types.str;
          };
          "namespace" = mkOption {
            description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "audiences" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGcpsmAuthWorkloadIdentityServiceAccountRef" =
      {

        options = {
          "audiences" = mkOption {
            description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
            type = (types.nullOr (types.listOf types.str));
          };
          "name" = mkOption {
            description = "The name of the ServiceAccount resource being referred to.";
            type = types.str;
          };
          "namespace" = mkOption {
            description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "audiences" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGithub" = {

      options = {
        "appID" = mkOption {
          description = "appID specifies the Github APP that will be used to authenticate the client";
          type = types.int;
        };
        "auth" = mkOption {
          description = "auth configures how secret-manager authenticates with a Github instance.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGithubAuth");
        };
        "environment" = mkOption {
          description = "environment will be used to fetch secrets from a particular environment within a github repository";
          type = (types.nullOr types.str);
        };
        "installationID" = mkOption {
          description = "installationID specifies the Github APP installation that will be used to authenticate the client";
          type = types.int;
        };
        "organization" = mkOption {
          description = "organization will be used to fetch secrets from the Github organization";
          type = types.str;
        };
        "repository" = mkOption {
          description = "repository will be used to fetch secrets from the Github repository within an organization";
          type = (types.nullOr types.str);
        };
        "uploadURL" = mkOption {
          description = "Upload URL for enterprise instances. Default to URL.";
          type = (types.nullOr types.str);
        };
        "url" = mkOption {
          description = "URL configures the Github instance URL. Defaults to https://github.com/.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "environment" = mkOverride 1002 null;
        "repository" = mkOverride 1002 null;
        "uploadURL" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGithubAuth" = {

      options = {
        "privateKey" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGithubAuthPrivateKey");
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGithubAuthPrivateKey" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlab" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how secret-manager authenticates with a GitLab instance.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlabAuth");
        };
        "caBundle" = mkOption {
          description = "Base64 encoded certificate for the GitLab server sdk. The sdk MUST run with HTTPS to make sure no MITM attack\ncan be performed.";
          type = (types.nullOr types.str);
        };
        "caProvider" = mkOption {
          description = "see: https://external-secrets.io/latest/spec/#external-secrets.io/v1alpha1.CAProvider";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlabCaProvider")
          );
        };
        "environment" = mkOption {
          description = "Environment environment_scope of gitlab CI/CD variables (Please see https://docs.gitlab.com/ee/ci/environments/#create-a-static-environment on how to create environments)";
          type = (types.nullOr types.str);
        };
        "groupIDs" = mkOption {
          description = "GroupIDs specify, which gitlab groups to pull secrets from. Group secrets are read from left to right followed by the project variables.";
          type = (types.nullOr (types.listOf types.str));
        };
        "inheritFromGroups" = mkOption {
          description = "InheritFromGroups specifies whether parent groups should be discovered and checked for secrets.";
          type = (types.nullOr types.bool);
        };
        "projectID" = mkOption {
          description = "ProjectID specifies a project where secrets are located.";
          type = (types.nullOr types.str);
        };
        "url" = mkOption {
          description = "URL configures the GitLab instance URL. Defaults to https://gitlab.com/.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "caBundle" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
        "environment" = mkOverride 1002 null;
        "groupIDs" = mkOverride 1002 null;
        "inheritFromGroups" = mkOverride 1002 null;
        "projectID" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlabAuth" = {

      options = {
        "SecretRef" = mkOption {
          description = "GitlabSecretRef contains the secret reference for GitLab authentication credentials.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlabAuthSecretRef");
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlabAuthSecretRef" = {

      options = {
        "accessToken" = mkOption {
          description = "AccessToken is used for authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlabAuthSecretRefAccessToken"
            )
          );
        };
      };

      config = {
        "accessToken" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlabAuthSecretRefAccessToken" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderGitlabCaProvider" = {

      options = {
        "key" = mkOption {
          description = "The key where the CA certificate can be found in the Secret or ConfigMap.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the object located at the provider type.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "The namespace the Provider type is in.\nCan only be defined when used in a ClusterSecretStore.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "The type of provider to use such as \"Secret\", or \"ConfigMap\".";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbm" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how secret-manager authenticates with the IBM secrets manager.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbmAuth");
        };
        "serviceUrl" = mkOption {
          description = "ServiceURL is the Endpoint URL that is specific to the Secrets Manager service instance";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "serviceUrl" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbmAuth" = {

      options = {
        "containerAuth" = mkOption {
          description = "IBMAuthContainerAuth defines container-based authentication with IAM Trusted Profile.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbmAuthContainerAuth"
            )
          );
        };
        "secretRef" = mkOption {
          description = "IBMAuthSecretRef contains the secret reference for IBM Cloud API key authentication.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbmAuthSecretRef")
          );
        };
      };

      config = {
        "containerAuth" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbmAuthContainerAuth" = {

      options = {
        "iamEndpoint" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "profile" = mkOption {
          description = "the IBM Trusted Profile";
          type = types.str;
        };
        "tokenLocation" = mkOption {
          description = "Location the token is mounted on the pod";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "iamEndpoint" = mkOverride 1002 null;
        "tokenLocation" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbmAuthSecretRef" = {

      options = {
        "secretApiKeySecretRef" = mkOption {
          description = "The SecretAccessKey is used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbmAuthSecretRefSecretApiKeySecretRef"
            )
          );
        };
      };

      config = {
        "secretApiKeySecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderIbmAuthSecretRefSecretApiKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisical" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how the Operator authenticates with the Infisical API";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuth");
        };
        "hostAPI" = mkOption {
          description = "HostAPI specifies the base URL of the Infisical API. If not provided, it defaults to \"https://app.infisical.com/api\".";
          type = (types.nullOr types.str);
        };
        "secretsScope" = mkOption {
          description = "SecretsScope defines the scope of the secrets within the workspace";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalSecretsScope");
        };
      };

      config = {
        "hostAPI" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuth" = {

      options = {
        "awsAuthCredentials" = mkOption {
          description = "AwsAuthCredentials represents the credentials for AWS authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAwsAuthCredentials"
            )
          );
        };
        "azureAuthCredentials" = mkOption {
          description = "AzureAuthCredentials represents the credentials for Azure authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAzureAuthCredentials"
            )
          );
        };
        "gcpIamAuthCredentials" = mkOption {
          description = "GcpIamAuthCredentials represents the credentials for GCP IAM authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIamAuthCredentials"
            )
          );
        };
        "gcpIdTokenAuthCredentials" = mkOption {
          description = "GcpIDTokenAuthCredentials represents the credentials for GCP ID token authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIdTokenAuthCredentials"
            )
          );
        };
        "jwtAuthCredentials" = mkOption {
          description = "JwtAuthCredentials represents the credentials for JWT authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthJwtAuthCredentials"
            )
          );
        };
        "kubernetesAuthCredentials" = mkOption {
          description = "KubernetesAuthCredentials represents the credentials for Kubernetes authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthKubernetesAuthCredentials"
            )
          );
        };
        "ldapAuthCredentials" = mkOption {
          description = "LdapAuthCredentials represents the credentials for LDAP authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthLdapAuthCredentials"
            )
          );
        };
        "ociAuthCredentials" = mkOption {
          description = "OciAuthCredentials represents the credentials for OCI authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentials"
            )
          );
        };
        "tokenAuthCredentials" = mkOption {
          description = "TokenAuthCredentials represents the credentials for access token-based authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthTokenAuthCredentials"
            )
          );
        };
        "universalAuthCredentials" = mkOption {
          description = "UniversalAuthCredentials represents the client credentials for universal authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthUniversalAuthCredentials"
            )
          );
        };
      };

      config = {
        "awsAuthCredentials" = mkOverride 1002 null;
        "azureAuthCredentials" = mkOverride 1002 null;
        "gcpIamAuthCredentials" = mkOverride 1002 null;
        "gcpIdTokenAuthCredentials" = mkOverride 1002 null;
        "jwtAuthCredentials" = mkOverride 1002 null;
        "kubernetesAuthCredentials" = mkOverride 1002 null;
        "ldapAuthCredentials" = mkOverride 1002 null;
        "ociAuthCredentials" = mkOverride 1002 null;
        "tokenAuthCredentials" = mkOverride 1002 null;
        "universalAuthCredentials" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAwsAuthCredentials" = {

      options = {
        "identityId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAwsAuthCredentialsIdentityId"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAwsAuthCredentialsIdentityId" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAzureAuthCredentials" = {

      options = {
        "identityId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAzureAuthCredentialsIdentityId"
          );
        };
        "resource" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAzureAuthCredentialsResource"
            )
          );
        };
      };

      config = {
        "resource" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAzureAuthCredentialsIdentityId" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthAzureAuthCredentialsResource" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIamAuthCredentials" = {

      options = {
        "identityId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIamAuthCredentialsIdentityId"
          );
        };
        "serviceAccountKeyFilePath" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIamAuthCredentialsServiceAccountKeyFilePath"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIamAuthCredentialsIdentityId" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIamAuthCredentialsServiceAccountKeyFilePath" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIdTokenAuthCredentials" = {

      options = {
        "identityId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIdTokenAuthCredentialsIdentityId"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthGcpIdTokenAuthCredentialsIdentityId" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthJwtAuthCredentials" = {

      options = {
        "identityId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthJwtAuthCredentialsIdentityId"
          );
        };
        "jwt" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthJwtAuthCredentialsJwt"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthJwtAuthCredentialsIdentityId" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthJwtAuthCredentialsJwt" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthKubernetesAuthCredentials" = {

      options = {
        "identityId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthKubernetesAuthCredentialsIdentityId"
          );
        };
        "serviceAccountTokenPath" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthKubernetesAuthCredentialsServiceAccountTokenPath"
            )
          );
        };
      };

      config = {
        "serviceAccountTokenPath" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthKubernetesAuthCredentialsIdentityId" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthKubernetesAuthCredentialsServiceAccountTokenPath" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthLdapAuthCredentials" = {

      options = {
        "identityId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthLdapAuthCredentialsIdentityId"
          );
        };
        "ldapPassword" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthLdapAuthCredentialsLdapPassword"
          );
        };
        "ldapUsername" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthLdapAuthCredentialsLdapUsername"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthLdapAuthCredentialsIdentityId" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthLdapAuthCredentialsLdapPassword" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthLdapAuthCredentialsLdapUsername" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentials" = {

      options = {
        "fingerprint" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsFingerprint"
          );
        };
        "identityId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsIdentityId"
          );
        };
        "privateKey" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsPrivateKey"
          );
        };
        "privateKeyPassphrase" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsPrivateKeyPassphrase"
            )
          );
        };
        "region" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsRegion"
          );
        };
        "tenancyId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsTenancyId"
          );
        };
        "userId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsUserId"
          );
        };
      };

      config = {
        "privateKeyPassphrase" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsFingerprint" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsIdentityId" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsPrivateKey" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsPrivateKeyPassphrase" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsRegion" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsTenancyId" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthOciAuthCredentialsUserId" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthTokenAuthCredentials" = {

      options = {
        "accessToken" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthTokenAuthCredentialsAccessToken"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthTokenAuthCredentialsAccessToken" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthUniversalAuthCredentials" = {

      options = {
        "clientId" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthUniversalAuthCredentialsClientId"
          );
        };
        "clientSecret" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthUniversalAuthCredentialsClientSecret"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthUniversalAuthCredentialsClientId" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalAuthUniversalAuthCredentialsClientSecret" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderInfisicalSecretsScope" = {

      options = {
        "environmentSlug" = mkOption {
          description = "EnvironmentSlug is the required slug identifier for the environment.";
          type = types.str;
        };
        "expandSecretReferences" = mkOption {
          description = "ExpandSecretReferences indicates whether secret references should be expanded. Defaults to true if not provided.";
          type = (types.nullOr types.bool);
        };
        "projectSlug" = mkOption {
          description = "ProjectSlug is the required slug identifier for the project.";
          type = types.str;
        };
        "recursive" = mkOption {
          description = "Recursive indicates whether the secrets should be fetched recursively. Defaults to false if not provided.";
          type = (types.nullOr types.bool);
        };
        "secretsPath" = mkOption {
          description = "SecretsPath specifies the path to the secrets within the workspace. Defaults to \"/\" if not provided.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "expandSecretReferences" = mkOverride 1002 null;
        "recursive" = mkOverride 1002 null;
        "secretsPath" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKeepersecurity" = {

      options = {
        "authRef" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKeepersecurityAuthRef");
        };
        "folderID" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKeepersecurityAuthRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetes" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how secret-manager authenticates with a Kubernetes instance.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuth")
          );
        };
        "authRef" = mkOption {
          description = "A reference to a secret that contains the auth information.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthRef")
          );
        };
        "remoteNamespace" = mkOption {
          description = "Remote namespace to fetch the secrets from";
          type = (types.nullOr types.str);
        };
        "server" = mkOption {
          description = "configures the Kubernetes server Address.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesServer")
          );
        };
      };

      config = {
        "auth" = mkOverride 1002 null;
        "authRef" = mkOverride 1002 null;
        "remoteNamespace" = mkOverride 1002 null;
        "server" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuth" = {

      options = {
        "cert" = mkOption {
          description = "has both clientCert and clientKey as secretKeySelector";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthCert")
          );
        };
        "serviceAccount" = mkOption {
          description = "points to a service account that should be used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthServiceAccount"
            )
          );
        };
        "token" = mkOption {
          description = "use static token to authenticate with";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthToken"
            )
          );
        };
      };

      config = {
        "cert" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthCert" = {

      options = {
        "clientCert" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthCertClientCert"
            )
          );
        };
        "clientKey" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthCertClientKey"
            )
          );
        };
      };

      config = {
        "clientCert" = mkOverride 1002 null;
        "clientKey" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthCertClientCert" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthCertClientKey" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthServiceAccount" = {

      options = {
        "audiences" = mkOption {
          description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The name of the ServiceAccount resource being referred to.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthToken" = {

      options = {
        "bearerToken" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthTokenBearerToken"
            )
          );
        };
      };

      config = {
        "bearerToken" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesAuthTokenBearerToken" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesServer" = {

      options = {
        "caBundle" = mkOption {
          description = "CABundle is a base64-encoded CA certificate";
          type = (types.nullOr types.str);
        };
        "caProvider" = mkOption {
          description = "see: https://external-secrets.io/v0.4.1/spec/#external-secrets.io/v1alpha1.CAProvider";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesServerCaProvider"
            )
          );
        };
        "url" = mkOption {
          description = "configures the Kubernetes server Address.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "caBundle" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderKubernetesServerCaProvider" = {

      options = {
        "key" = mkOption {
          description = "The key where the CA certificate can be found in the Secret or ConfigMap.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the object located at the provider type.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "The namespace the Provider type is in.\nCan only be defined when used in a ClusterSecretStore.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "The type of provider to use such as \"Secret\", or \"ConfigMap\".";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrok" = {

      options = {
        "apiUrl" = mkOption {
          description = "APIURL is the URL of the ngrok API.";
          type = (types.nullOr types.str);
        };
        "auth" = mkOption {
          description = "Auth configures how the ngrok provider authenticates with the ngrok API.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrokAuth");
        };
        "vault" = mkOption {
          description = "Vault configures the ngrok vault to sync secrets with.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrokVault");
        };
      };

      config = {
        "apiUrl" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrokAuth" = {

      options = {
        "apiKey" = mkOption {
          description = "APIKey is the API Key used to authenticate with ngrok. See https://ngrok.com/docs/api/#authentication";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrokAuthApiKey")
          );
        };
      };

      config = {
        "apiKey" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrokAuthApiKey" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef is a reference to a secret containing the ngrok API key.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrokAuthApiKeySecretRef"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrokAuthApiKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderNgrokVault" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the ngrok vault to sync secrets with.";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnboardbase" = {

      options = {
        "apiHost" = mkOption {
          description = "APIHost use this to configure the host url for the API for selfhosted installation, default is https://public.onboardbase.com/api/v1/";
          type = types.str;
        };
        "auth" = mkOption {
          description = "Auth configures how the Operator authenticates with the Onboardbase API";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnboardbaseAuth");
        };
        "environment" = mkOption {
          description = "Environment is the name of an environmnent within a project to pull the secrets from";
          type = types.str;
        };
        "project" = mkOption {
          description = "Project is an onboardbase project that the secrets should be pulled from";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnboardbaseAuth" = {

      options = {
        "apiKeyRef" = mkOption {
          description = "OnboardbaseAPIKey is the APIKey generated by an admin account.\nIt is used to recognize and authorize access to a project and environment within onboardbase";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnboardbaseAuthApiKeyRef"
          );
        };
        "passcodeRef" = mkOption {
          description = "OnboardbasePasscode is the passcode attached to the API Key";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnboardbaseAuthPasscodeRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnboardbaseAuthApiKeyRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnboardbaseAuthPasscodeRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepassword" = {

      options = {
        "auth" = mkOption {
          description = "Auth defines the information necessary to authenticate against OnePassword Connect Server";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordAuth");
        };
        "connectHost" = mkOption {
          description = "ConnectHost defines the OnePassword Connect Server to connect to";
          type = types.str;
        };
        "vaults" = mkOption {
          description = "Vaults defines which OnePassword vaults to search in which order";
          type = (types.attrsOf types.int);
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "OnePasswordAuthSecretRef holds secret references for 1Password credentials.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordAuthSecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordAuthSecretRef" = {

      options = {
        "connectTokenSecretRef" = mkOption {
          description = "The ConnectToken is used for authentication to a 1Password Connect Server.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordAuthSecretRefConnectTokenSecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordAuthSecretRefConnectTokenSecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordSDK" = {

      options = {
        "auth" = mkOption {
          description = "Auth defines the information necessary to authenticate against OnePassword API.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordSDKAuth");
        };
        "integrationInfo" = mkOption {
          description = "IntegrationInfo specifies the name and version of the integration built using the 1Password Go SDK.\nIf you don't know which name and version to use, use `DefaultIntegrationName` and `DefaultIntegrationVersion`, respectively.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordSDKIntegrationInfo"
            )
          );
        };
        "vault" = mkOption {
          description = "Vault defines the vault's name or uuid to access. Do NOT add op:// prefix. This will be done automatically.";
          type = types.str;
        };
      };

      config = {
        "integrationInfo" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordSDKAuth" = {

      options = {
        "serviceAccountSecretRef" = mkOption {
          description = "ServiceAccountSecretRef points to the secret containing the token to access 1Password vault.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordSDKAuthServiceAccountSecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordSDKAuthServiceAccountSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOnepasswordSDKIntegrationInfo" = {

      options = {
        "name" = mkOption {
          description = "Name defaults to \"1Password SDK\".";
          type = (types.nullOr types.str);
        };
        "version" = mkOption {
          description = "Version defaults to \"v1.0.0\".";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracle" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how secret-manager authenticates with the Oracle Vault.\nIf empty, use the instance principal, otherwise the user credentials specified in Auth.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleAuth")
          );
        };
        "compartment" = mkOption {
          description = "Compartment is the vault compartment OCID.\nRequired for PushSecret";
          type = (types.nullOr types.str);
        };
        "encryptionKey" = mkOption {
          description = "EncryptionKey is the OCID of the encryption key within the vault.\nRequired for PushSecret";
          type = (types.nullOr types.str);
        };
        "principalType" = mkOption {
          description = "The type of principal to use for authentication. If left blank, the Auth struct will\ndetermine the principal type. This optional field must be specified if using\nworkload identity.";
          type = (types.nullOr types.str);
        };
        "region" = mkOption {
          description = "Region is the region where vault is located.";
          type = types.str;
        };
        "serviceAccountRef" = mkOption {
          description = "ServiceAccountRef specified the service account\nthat should be used when authenticating with WorkloadIdentity.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleServiceAccountRef"
            )
          );
        };
        "vault" = mkOption {
          description = "Vault is the vault's OCID of the specific vault where secret is located.";
          type = types.str;
        };
      };

      config = {
        "auth" = mkOverride 1002 null;
        "compartment" = mkOverride 1002 null;
        "encryptionKey" = mkOverride 1002 null;
        "principalType" = mkOverride 1002 null;
        "serviceAccountRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef to pass through sensitive information.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleAuthSecretRef");
        };
        "tenancy" = mkOption {
          description = "Tenancy is the tenancy OCID where user is located.";
          type = types.str;
        };
        "user" = mkOption {
          description = "User is an access OCID specific to the account.";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleAuthSecretRef" = {

      options = {
        "fingerprint" = mkOption {
          description = "Fingerprint is the fingerprint of the API private key.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleAuthSecretRefFingerprint"
          );
        };
        "privatekey" = mkOption {
          description = "PrivateKey is the user's API Signing Key in PEM format, used for authentication.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleAuthSecretRefPrivatekey"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleAuthSecretRefFingerprint" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleAuthSecretRefPrivatekey" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderOracleServiceAccountRef" = {

      options = {
        "audiences" = mkOption {
          description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The name of the ServiceAccount resource being referred to.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassbolt" = {

      options = {
        "auth" = mkOption {
          description = "Auth defines the information necessary to authenticate against Passbolt Server";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassboltAuth");
        };
        "host" = mkOption {
          description = "Host defines the Passbolt Server to connect to";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassboltAuth" = {

      options = {
        "passwordSecretRef" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassboltAuthPasswordSecretRef"
          );
        };
        "privateKeySecretRef" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassboltAuthPrivateKeySecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassboltAuthPasswordSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassboltAuthPrivateKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassworddepot" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how secret-manager authenticates with a Password Depot instance.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassworddepotAuth");
        };
        "database" = mkOption {
          description = "Database to use as source";
          type = types.str;
        };
        "host" = mkOption {
          description = "URL configures the Password Depot instance URL.";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassworddepotAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "PasswordDepotSecretRef contains the secret reference for Password Depot authentication.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassworddepotAuthSecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassworddepotAuthSecretRef" = {

      options = {
        "credentials" = mkOption {
          description = "Username / Password is used for authentication.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassworddepotAuthSecretRefCredentials"
            )
          );
        };
      };

      config = {
        "credentials" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPassworddepotAuthSecretRefCredentials" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPrevider" = {

      options = {
        "auth" = mkOption {
          description = "PreviderAuth contains a secretRef for credentials.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPreviderAuth");
        };
        "baseUri" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "baseUri" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPreviderAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "PreviderAuthSecretRef holds secret references for Previder Vault credentials.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPreviderAuthSecretRef"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPreviderAuthSecretRef" = {

      options = {
        "accessToken" = mkOption {
          description = "The AccessToken is used for authentication";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPreviderAuthSecretRefAccessToken"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPreviderAuthSecretRefAccessToken" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPulumi" = {

      options = {
        "accessToken" = mkOption {
          description = "AccessToken is the access tokens to sign in to the Pulumi Cloud Console.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPulumiAccessToken");
        };
        "apiUrl" = mkOption {
          description = "APIURL is the URL of the Pulumi API.";
          type = (types.nullOr types.str);
        };
        "environment" = mkOption {
          description = "Environment are YAML documents composed of static key-value pairs, programmatic expressions,\ndynamically retrieved values from supported providers including all major clouds,\nand other Pulumi ESC environments.\nTo create a new environment, visit https://www.pulumi.com/docs/esc/environments/ for more information.";
          type = types.str;
        };
        "organization" = mkOption {
          description = "Organization are a space to collaborate on shared projects and stacks.\nTo create a new organization, visit https://app.pulumi.com/ and click \"New Organization\".";
          type = types.str;
        };
        "project" = mkOption {
          description = "Project is the name of the Pulumi ESC project the environment belongs to.";
          type = types.str;
        };
      };

      config = {
        "apiUrl" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPulumiAccessToken" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef is a reference to a secret containing the Pulumi API token.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderPulumiAccessTokenSecretRef"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderPulumiAccessTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderScaleway" = {

      options = {
        "accessKey" = mkOption {
          description = "AccessKey is the non-secret part of the api key.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderScalewayAccessKey");
        };
        "apiUrl" = mkOption {
          description = "APIURL is the url of the api to use. Defaults to https://api.scaleway.com";
          type = (types.nullOr types.str);
        };
        "projectId" = mkOption {
          description = "ProjectID is the id of your project, which you can find in the console: https://console.scaleway.com/project/settings";
          type = types.str;
        };
        "region" = mkOption {
          description = "Region where your secrets are located: https://developers.scaleway.com/en/quickstart/#region-and-zone";
          type = types.str;
        };
        "secretKey" = mkOption {
          description = "SecretKey is the non-secret part of the api key.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderScalewaySecretKey");
        };
      };

      config = {
        "apiUrl" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderScalewayAccessKey" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderScalewayAccessKeySecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderScalewayAccessKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderScalewaySecretKey" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderScalewaySecretKeySecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderScalewaySecretKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserver" = {

      options = {
        "domain" = mkOption {
          description = "Domain is the secret server domain.";
          type = (types.nullOr types.str);
        };
        "password" = mkOption {
          description = "Password is the secret server account password.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserverPassword");
        };
        "serverURL" = mkOption {
          description = "ServerURL\nURL to your secret server installation";
          type = types.str;
        };
        "username" = mkOption {
          description = "Username is the secret server account username.";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserverUsername");
        };
      };

      config = {
        "domain" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserverPassword" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserverPasswordSecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserverPasswordSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserverUsername" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef references a key in a secret that will be used as value.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserverUsernameSecretRef"
            )
          );
        };
        "value" = mkOption {
          description = "Value can be specified directly to set a value without using a secret.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderSecretserverUsernameSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderSenhasegura" = {

      options = {
        "auth" = mkOption {
          description = "Auth defines parameters to authenticate in senhasegura";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderSenhaseguraAuth");
        };
        "ignoreSslCertificate" = mkOption {
          description = "IgnoreSslCertificate defines if SSL certificate must be ignored";
          type = (types.nullOr types.bool);
        };
        "module" = mkOption {
          description = "Module defines which senhasegura module should be used to get secrets";
          type = types.str;
        };
        "url" = mkOption {
          description = "URL of senhasegura";
          type = types.str;
        };
      };

      config = {
        "ignoreSslCertificate" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderSenhaseguraAuth" = {

      options = {
        "clientId" = mkOption {
          description = "";
          type = types.str;
        };
        "clientSecretSecretRef" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderSenhaseguraAuthClientSecretSecretRef"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderSenhaseguraAuthClientSecretSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVault" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how secret-manager authenticates with the Vault server.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuth")
          );
        };
        "caBundle" = mkOption {
          description = "PEM encoded CA bundle used to validate Vault server certificate. Only used\nif the Server URL is using HTTPS protocol. This parameter is ignored for\nplain HTTP protocol connection. If not set the system root certificates\nare used to validate the TLS connection.";
          type = (types.nullOr types.str);
        };
        "caProvider" = mkOption {
          description = "The provider for the CA bundle to use to validate Vault server certificate.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultCaProvider")
          );
        };
        "checkAndSet" = mkOption {
          description = "CheckAndSet defines the Check-And-Set (CAS) settings for PushSecret operations.\nOnly applies to Vault KV v2 stores. When enabled, write operations must include\nthe current version of the secret to prevent unintentional overwrites.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultCheckAndSet")
          );
        };
        "forwardInconsistent" = mkOption {
          description = "ForwardInconsistent tells Vault to forward read-after-write requests to the Vault\nleader instead of simply retrying within a loop. This can increase performance if\nthe option is enabled serverside.\nhttps://www.vaultproject.io/docs/configuration/replication#allow_forwarding_via_header";
          type = (types.nullOr types.bool);
        };
        "headers" = mkOption {
          description = "Headers to be added in Vault request";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "namespace" = mkOption {
          description = "Name of the vault namespace. Namespaces is a set of features within Vault Enterprise that allows\nVault environments to support Secure Multi-tenancy. e.g: \"ns1\".\nMore about namespaces can be found here https://www.vaultproject.io/docs/enterprise/namespaces";
          type = (types.nullOr types.str);
        };
        "path" = mkOption {
          description = "Path is the mount path of the Vault KV backend endpoint, e.g:\n\"secret\". The v2 KV secret engine version specific \"/data\" path suffix\nfor fetching secrets from Vault is optional and will be appended\nif not present in specified path.";
          type = (types.nullOr types.str);
        };
        "readYourWrites" = mkOption {
          description = "ReadYourWrites ensures isolated read-after-write semantics by\nproviding discovered cluster replication states in each request.\nMore information about eventual consistency in Vault can be found here\nhttps://www.vaultproject.io/docs/enterprise/consistency";
          type = (types.nullOr types.bool);
        };
        "server" = mkOption {
          description = "Server is the connection address for the Vault server, e.g: \"https://vault.example.com:8200\".";
          type = types.str;
        };
        "tls" = mkOption {
          description = "The configuration used for client side related TLS communication, when the Vault server\nrequires mutual authentication. Only used if the Server URL is using HTTPS protocol.\nThis parameter is ignored for plain HTTP protocol connection.\nIt's worth noting this configuration is different from the \"TLS certificates auth method\",\nwhich is available under the `auth.cert` section.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultTls"));
        };
        "version" = mkOption {
          description = "Version is the Vault KV secret engine version. This can be either \"v1\" or\n\"v2\". Version defaults to \"v2\".";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "auth" = mkOverride 1002 null;
        "caBundle" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
        "checkAndSet" = mkOverride 1002 null;
        "forwardInconsistent" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "readYourWrites" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuth" = {

      options = {
        "appRole" = mkOption {
          description = "AppRole authenticates with Vault using the App Role auth mechanism,\nwith the role and secret stored in a Kubernetes Secret resource.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthAppRole")
          );
        };
        "cert" = mkOption {
          description = "Cert authenticates with TLS Certificates by passing client certificate, private key and ca certificate\nCert authentication method";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthCert")
          );
        };
        "iam" = mkOption {
          description = "Iam authenticates with vault by passing a special AWS request signed with AWS IAM credentials\nAWS IAM authentication method";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIam")
          );
        };
        "jwt" = mkOption {
          description = "Jwt authenticates with Vault by passing role and JWT token using the\nJWT/OIDC authentication method";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthJwt")
          );
        };
        "kubernetes" = mkOption {
          description = "Kubernetes authenticates with Vault by passing the ServiceAccount\ntoken stored in the named Secret resource to the Vault server.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthKubernetes"
            )
          );
        };
        "ldap" = mkOption {
          description = "Ldap authenticates with Vault by passing username/password pair using\nthe LDAP authentication method";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthLdap")
          );
        };
        "namespace" = mkOption {
          description = "Name of the vault namespace to authenticate to. This can be different than the namespace your secret is in.\nNamespaces is a set of features within Vault Enterprise that allows\nVault environments to support Secure Multi-tenancy. e.g: \"ns1\".\nMore about namespaces can be found here https://www.vaultproject.io/docs/enterprise/namespaces\nThis will default to Vault.Namespace field if set, or empty otherwise";
          type = (types.nullOr types.str);
        };
        "tokenSecretRef" = mkOption {
          description = "TokenSecretRef authenticates with Vault by presenting a token.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthTokenSecretRef"
            )
          );
        };
        "userPass" = mkOption {
          description = "UserPass authenticates with Vault by passing username/password pair";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthUserPass")
          );
        };
      };

      config = {
        "appRole" = mkOverride 1002 null;
        "cert" = mkOverride 1002 null;
        "iam" = mkOverride 1002 null;
        "jwt" = mkOverride 1002 null;
        "kubernetes" = mkOverride 1002 null;
        "ldap" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "tokenSecretRef" = mkOverride 1002 null;
        "userPass" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthAppRole" = {

      options = {
        "path" = mkOption {
          description = "Path where the App Role authentication backend is mounted\nin Vault, e.g: \"approle\"";
          type = types.str;
        };
        "roleId" = mkOption {
          description = "RoleID configured in the App Role authentication backend when setting\nup the authentication backend in Vault.";
          type = (types.nullOr types.str);
        };
        "roleRef" = mkOption {
          description = "Reference to a key in a Secret that contains the App Role ID used\nto authenticate with Vault.\nThe `key` field must be specified and denotes which entry within the Secret\nresource is used as the app role id.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthAppRoleRoleRef"
            )
          );
        };
        "secretRef" = mkOption {
          description = "Reference to a key in a Secret that contains the App Role secret used\nto authenticate with Vault.\nThe `key` field must be specified and denotes which entry within the Secret\nresource is used as the app role secret.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthAppRoleSecretRef"
          );
        };
      };

      config = {
        "roleId" = mkOverride 1002 null;
        "roleRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthAppRoleRoleRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthAppRoleSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthCert" = {

      options = {
        "clientCert" = mkOption {
          description = "ClientCert is a certificate to authenticate using the Cert Vault\nauthentication method";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthCertClientCert"
            )
          );
        };
        "path" = mkOption {
          description = "Path where the Certificate authentication backend is mounted\nin Vault, e.g: \"cert\"";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "SecretRef to a key in a Secret resource containing client private key to\nauthenticate with Vault using the Cert authentication method";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthCertSecretRef"
            )
          );
        };
      };

      config = {
        "clientCert" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthCertClientCert" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthCertSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIam" = {

      options = {
        "externalID" = mkOption {
          description = "AWS External ID set on assumed IAM roles";
          type = (types.nullOr types.str);
        };
        "jwt" = mkOption {
          description = "Specify a service account with IRSA enabled";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamJwt")
          );
        };
        "path" = mkOption {
          description = "Path where the AWS auth method is enabled in Vault, e.g: \"aws\"";
          type = (types.nullOr types.str);
        };
        "region" = mkOption {
          description = "AWS region";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "This is the AWS role to be assumed before talking to vault";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "Specify credentials in a Secret object";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamSecretRef"
            )
          );
        };
        "vaultAwsIamServerID" = mkOption {
          description = "X-Vault-AWS-IAM-Server-ID is an additional header used by Vault IAM auth method to mitigate against different types of replay attacks. More details here: https://developer.hashicorp.com/vault/docs/auth/aws";
          type = (types.nullOr types.str);
        };
        "vaultRole" = mkOption {
          description = "Vault Role. In vault, a role describes an identity with a set of permissions, groups, or policies you want to attach a user of the secrets engine";
          type = types.str;
        };
      };

      config = {
        "externalID" = mkOverride 1002 null;
        "jwt" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "region" = mkOverride 1002 null;
        "role" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "vaultAwsIamServerID" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamJwt" = {

      options = {
        "serviceAccountRef" = mkOption {
          description = "ServiceAccountSelector is a reference to a ServiceAccount resource.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamJwtServiceAccountRef"
            )
          );
        };
      };

      config = {
        "serviceAccountRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamJwtServiceAccountRef" = {

      options = {
        "audiences" = mkOption {
          description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The name of the ServiceAccount resource being referred to.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamSecretRef" = {

      options = {
        "accessKeyIDSecretRef" = mkOption {
          description = "The AccessKeyID is used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamSecretRefAccessKeyIDSecretRef"
            )
          );
        };
        "secretAccessKeySecretRef" = mkOption {
          description = "The SecretAccessKey is used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamSecretRefSecretAccessKeySecretRef"
            )
          );
        };
        "sessionTokenSecretRef" = mkOption {
          description = "The SessionToken used for authentication\nThis must be defined if AccessKeyID and SecretAccessKey are temporary credentials\nsee: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamSecretRefSessionTokenSecretRef"
            )
          );
        };
      };

      config = {
        "accessKeyIDSecretRef" = mkOverride 1002 null;
        "secretAccessKeySecretRef" = mkOverride 1002 null;
        "sessionTokenSecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamSecretRefAccessKeyIDSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamSecretRefSecretAccessKeySecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthIamSecretRefSessionTokenSecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthJwt" = {

      options = {
        "kubernetesServiceAccountToken" = mkOption {
          description = "Optional ServiceAccountToken specifies the Kubernetes service account for which to request\na token for with the `TokenRequest` API.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthJwtKubernetesServiceAccountToken"
            )
          );
        };
        "path" = mkOption {
          description = "Path where the JWT authentication backend is mounted\nin Vault, e.g: \"jwt\"";
          type = types.str;
        };
        "role" = mkOption {
          description = "Role is a JWT role to authenticate using the JWT/OIDC Vault\nauthentication method";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "Optional SecretRef that refers to a key in a Secret resource containing JWT token to\nauthenticate with Vault using the JWT/OIDC authentication method.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthJwtSecretRef"
            )
          );
        };
      };

      config = {
        "kubernetesServiceAccountToken" = mkOverride 1002 null;
        "role" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthJwtKubernetesServiceAccountToken" = {

      options = {
        "audiences" = mkOption {
          description = "Optional audiences field that will be used to request a temporary Kubernetes service\naccount token for the service account referenced by `serviceAccountRef`.\nDefaults to a single audience `vault` it not specified.\nDeprecated: use serviceAccountRef.Audiences instead";
          type = (types.nullOr (types.listOf types.str));
        };
        "expirationSeconds" = mkOption {
          description = "Optional expiration time in seconds that will be used to request a temporary\nKubernetes service account token for the service account referenced by\n`serviceAccountRef`.\nDeprecated: this will be removed in the future.\nDefaults to 10 minutes.";
          type = (types.nullOr types.int);
        };
        "serviceAccountRef" = mkOption {
          description = "Service account field containing the name of a kubernetes ServiceAccount.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthJwtKubernetesServiceAccountTokenServiceAccountRef"
          );
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
        "expirationSeconds" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthJwtKubernetesServiceAccountTokenServiceAccountRef" =
      {

        options = {
          "audiences" = mkOption {
            description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
            type = (types.nullOr (types.listOf types.str));
          };
          "name" = mkOption {
            description = "The name of the ServiceAccount resource being referred to.";
            type = types.str;
          };
          "namespace" = mkOption {
            description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "audiences" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthJwtSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthKubernetes" = {

      options = {
        "mountPath" = mkOption {
          description = "Path where the Kubernetes authentication backend is mounted in Vault, e.g:\n\"kubernetes\"";
          type = types.str;
        };
        "role" = mkOption {
          description = "A required field containing the Vault Role to assume. A Role binds a\nKubernetes ServiceAccount with a set of Vault policies.";
          type = types.str;
        };
        "secretRef" = mkOption {
          description = "Optional secret field containing a Kubernetes ServiceAccount JWT used\nfor authenticating with Vault. If a name is specified without a key,\n`token` is the default. If one is not specified, the one bound to\nthe controller will be used.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthKubernetesSecretRef"
            )
          );
        };
        "serviceAccountRef" = mkOption {
          description = "Optional service account field containing the name of a kubernetes ServiceAccount.\nIf the service account is specified, the service account secret token JWT will be used\nfor authenticating with Vault. If the service account selector is not supplied,\nthe secretRef will be used instead.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthKubernetesServiceAccountRef"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
        "serviceAccountRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthKubernetesSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthKubernetesServiceAccountRef" = {

      options = {
        "audiences" = mkOption {
          description = "Audience specifies the `aud` claim for the service account token\nIf the service account uses a well-known annotation for e.g. IRSA or GCP Workload Identity\nthen this audiences will be appended to the list";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "The name of the ServiceAccount resource being referred to.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace of the resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthLdap" = {

      options = {
        "path" = mkOption {
          description = "Path where the LDAP authentication backend is mounted\nin Vault, e.g: \"ldap\"";
          type = types.str;
        };
        "secretRef" = mkOption {
          description = "SecretRef to a key in a Secret resource containing password for the LDAP\nuser used to authenticate with Vault using the LDAP authentication\nmethod";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthLdapSecretRef"
            )
          );
        };
        "username" = mkOption {
          description = "Username is an LDAP username used to authenticate using the LDAP Vault\nauthentication method";
          type = types.str;
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthLdapSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthUserPass" = {

      options = {
        "path" = mkOption {
          description = "Path where the UserPassword authentication backend is mounted\nin Vault, e.g: \"userpass\"";
          type = types.str;
        };
        "secretRef" = mkOption {
          description = "SecretRef to a key in a Secret resource containing password for the\nuser used to authenticate with Vault using the UserPass authentication\nmethod";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthUserPassSecretRef"
            )
          );
        };
        "username" = mkOption {
          description = "Username is a username used to authenticate using the UserPass Vault\nauthentication method";
          type = types.str;
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultAuthUserPassSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultCaProvider" = {

      options = {
        "key" = mkOption {
          description = "The key where the CA certificate can be found in the Secret or ConfigMap.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the object located at the provider type.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "The namespace the Provider type is in.\nCan only be defined when used in a ClusterSecretStore.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "The type of provider to use such as \"Secret\", or \"ConfigMap\".";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultCheckAndSet" = {

      options = {
        "required" = mkOption {
          description = "Required when true, all write operations must include a check-and-set parameter.\nThis helps prevent unintentional overwrites of secrets.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "required" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultTls" = {

      options = {
        "certSecretRef" = mkOption {
          description = "CertSecretRef is a certificate added to the transport layer\nwhen communicating with the Vault server.\nIf no key for the Secret is specified, external-secret will default to 'tls.crt'.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultTlsCertSecretRef"
            )
          );
        };
        "keySecretRef" = mkOption {
          description = "KeySecretRef to a key in a Secret resource containing client private key\nadded to the transport layer when communicating with the Vault server.\nIf no key for the Secret is specified, external-secret will default to 'tls.key'.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultTlsKeySecretRef"
            )
          );
        };
      };

      config = {
        "certSecretRef" = mkOverride 1002 null;
        "keySecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultTlsCertSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVaultTlsKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengine" = {

      options = {
        "auth" = mkOption {
          description = "Auth defines the authentication method to use.\nIf not specified, the provider will try to use IRSA (IAM Role for Service Account).";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuth")
          );
        };
        "region" = mkOption {
          description = "Region specifies the Volcengine region to connect to.";
          type = types.str;
        };
      };

      config = {
        "auth" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuth" = {

      options = {
        "secretRef" = mkOption {
          description = "SecretRef defines the static credentials to use for authentication.\nIf not set, IRSA is used.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuthSecretRef"
            )
          );
        };
      };

      config = {
        "secretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuthSecretRef" = {

      options = {
        "accessKeyID" = mkOption {
          description = "AccessKeyID is the reference to the secret containing the Access Key ID.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuthSecretRefAccessKeyID"
          );
        };
        "secretAccessKey" = mkOption {
          description = "SecretAccessKey is the reference to the secret containing the Secret Access Key.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuthSecretRefSecretAccessKey"
          );
        };
        "token" = mkOption {
          description = "Token is the reference to the secret containing the STS(Security Token Service) Token.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuthSecretRefToken"
            )
          );
        };
      };

      config = {
        "token" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuthSecretRefAccessKeyID" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuthSecretRefSecretAccessKey" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderVolcengineAuthSecretRefToken" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhook" = {

      options = {
        "auth" = mkOption {
          description = "Auth specifies a authorization protocol. Only one protocol may be set.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookAuth")
          );
        };
        "body" = mkOption {
          description = "Body";
          type = (types.nullOr types.str);
        };
        "caBundle" = mkOption {
          description = "PEM encoded CA bundle used to validate webhook server certificate. Only used\nif the Server URL is using HTTPS protocol. This parameter is ignored for\nplain HTTP protocol connection. If not set the system root certificates\nare used to validate the TLS connection.";
          type = (types.nullOr types.str);
        };
        "caProvider" = mkOption {
          description = "The provider for the CA bundle to use to validate webhook server certificate.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookCaProvider")
          );
        };
        "headers" = mkOption {
          description = "Headers";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "method" = mkOption {
          description = "Webhook Method";
          type = (types.nullOr types.str);
        };
        "result" = mkOption {
          description = "Result formatting";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookResult")
          );
        };
        "secrets" = mkOption {
          description = "Secrets to fill in templates\nThese secrets will be passed to the templating function as key value pairs under the given name";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookSecrets"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "timeout" = mkOption {
          description = "Timeout";
          type = (types.nullOr types.str);
        };
        "url" = mkOption {
          description = "Webhook url to call";
          type = types.str;
        };
      };

      config = {
        "auth" = mkOverride 1002 null;
        "body" = mkOverride 1002 null;
        "caBundle" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
        "headers" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "result" = mkOverride 1002 null;
        "secrets" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookAuth" = {

      options = {
        "ntlm" = mkOption {
          description = "NTLMProtocol configures the store to use NTLM for auth";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookAuthNtlm")
          );
        };
      };

      config = {
        "ntlm" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookAuthNtlm" = {

      options = {
        "passwordSecret" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookAuthNtlmPasswordSecret"
          );
        };
        "usernameSecret" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookAuthNtlmUsernameSecret"
          );
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookAuthNtlmPasswordSecret" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookAuthNtlmUsernameSecret" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookCaProvider" = {

      options = {
        "key" = mkOption {
          description = "The key where the CA certificate can be found in the Secret or ConfigMap.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the object located at the provider type.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "The namespace the Provider type is in.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "The type of provider to use such as \"Secret\", or \"ConfigMap\".";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookResult" = {

      options = {
        "jsonPath" = mkOption {
          description = "Json path of return value";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "jsonPath" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookSecrets" = {

      options = {
        "name" = mkOption {
          description = "Name of this secret in templates";
          type = types.str;
        };
        "secretRef" = mkOption {
          description = "Secret ref to fill in credentials";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookSecretsSecretRef");
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderWebhookSecretsSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanager" = {

      options = {
        "apiEndpoint" = mkOption {
          description = "Yandex.Cloud API endpoint (e.g. 'api.cloud.yandex.net:443')";
          type = (types.nullOr types.str);
        };
        "auth" = mkOption {
          description = "Auth defines the information necessary to authenticate against Yandex.Cloud";
          type = (
            submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerAuth"
          );
        };
        "caProvider" = mkOption {
          description = "The provider for the CA bundle to use to validate Yandex.Cloud server certificate.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerCaProvider"
            )
          );
        };
        "fetching" = mkOption {
          description = "FetchingPolicy configures the provider to interpret the `data.secretKey.remoteRef.key` field in ExternalSecret as certificate ID or certificate name";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerFetching"
            )
          );
        };
      };

      config = {
        "apiEndpoint" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
        "fetching" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerAuth" = {

      options = {
        "authorizedKeySecretRef" = mkOption {
          description = "The authorized key used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerAuthAuthorizedKeySecretRef"
            )
          );
        };
      };

      config = {
        "authorizedKeySecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerAuthAuthorizedKeySecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerCaProvider" = {

      options = {
        "certSecretRef" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerCaProviderCertSecretRef"
            )
          );
        };
      };

      config = {
        "certSecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerCaProviderCertSecretRef" =
      {

        options = {
          "key" = mkOption {
            description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "The name of the Secret resource being referred to.";
            type = (types.nullOr types.str);
          };
          "namespace" = mkOption {
            description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "key" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerFetching" = {

      options = {
        "byID" = mkOption {
          description = "ByID configures the provider to interpret the `data.secretKey.remoteRef.key` field in ExternalSecret as secret ID.";
          type = (types.nullOr types.attrs);
        };
        "byName" = mkOption {
          description = "ByName configures the provider to interpret the `data.secretKey.remoteRef.key` field in ExternalSecret as secret name.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerFetchingByName"
            )
          );
        };
      };

      config = {
        "byID" = mkOverride 1002 null;
        "byName" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexcertificatemanagerFetchingByName" = {

      options = {
        "folderID" = mkOption {
          description = "The folder to fetch secrets from";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockbox" = {

      options = {
        "apiEndpoint" = mkOption {
          description = "Yandex.Cloud API endpoint (e.g. 'api.cloud.yandex.net:443')";
          type = (types.nullOr types.str);
        };
        "auth" = mkOption {
          description = "Auth defines the information necessary to authenticate against Yandex.Cloud";
          type = (submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxAuth");
        };
        "caProvider" = mkOption {
          description = "The provider for the CA bundle to use to validate Yandex.Cloud server certificate.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxCaProvider"
            )
          );
        };
        "fetching" = mkOption {
          description = "FetchingPolicy configures the provider to interpret the `data.secretKey.remoteRef.key` field in ExternalSecret as secret ID or secret name";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxFetching"
            )
          );
        };
      };

      config = {
        "apiEndpoint" = mkOverride 1002 null;
        "caProvider" = mkOverride 1002 null;
        "fetching" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxAuth" = {

      options = {
        "authorizedKeySecretRef" = mkOption {
          description = "The authorized key used for authentication";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxAuthAuthorizedKeySecretRef"
            )
          );
        };
      };

      config = {
        "authorizedKeySecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxAuthAuthorizedKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxCaProvider" = {

      options = {
        "certSecretRef" = mkOption {
          description = "SecretKeySelector is a reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxCaProviderCertSecretRef"
            )
          );
        };
      };

      config = {
        "certSecretRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxCaProviderCertSecretRef" = {

      options = {
        "key" = mkOption {
          description = "A key in the referenced Secret.\nSome instances of this field may be defaulted, in others it may be required.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the Secret resource being referred to.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "The namespace of the Secret resource being referred to.\nIgnored if referent is not cluster-scoped, otherwise defaults to the namespace of the referent.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxFetching" = {

      options = {
        "byID" = mkOption {
          description = "ByID configures the provider to interpret the `data.secretKey.remoteRef.key` field in ExternalSecret as secret ID.";
          type = (types.nullOr types.attrs);
        };
        "byName" = mkOption {
          description = "ByName configures the provider to interpret the `data.secretKey.remoteRef.key` field in ExternalSecret as secret name.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxFetchingByName"
            )
          );
        };
      };

      config = {
        "byID" = mkOverride 1002 null;
        "byName" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecProviderYandexlockboxFetchingByName" = {

      options = {
        "folderID" = mkOption {
          description = "The folder to fetch secrets from";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ClusterSecretStoreSpecRetrySettings" = {

      options = {
        "maxRetries" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "retryInterval" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "maxRetries" = mkOverride 1002 null;
        "retryInterval" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreStatus" = {

      options = {
        "capabilities" = mkOption {
          description = "SecretStoreCapabilities defines the possible operations a SecretStore can do.";
          type = (types.nullOr types.str);
        };
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "external-secrets.io.v1.ClusterSecretStoreStatusConditions")
            )
          );
        };
      };

      config = {
        "capabilities" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ClusterSecretStoreStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = types.str;
        };
        "type" = mkOption {
          description = "SecretStoreConditionType represents the condition of the SecretStore.";
          type = types.str;
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecret" = {

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
          description = "ExternalSecretSpec defines the desired state of ExternalSecret.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpec"));
        };
        "status" = mkOption {
          description = "ExternalSecretStatus defines the observed state of ExternalSecret.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretStatus"));
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
    "external-secrets.io.v1.ExternalSecretSpec" = {

      options = {
        "data" = mkOption {
          description = "Data defines the connection between the Kubernetes Secret keys and the Provider data";
          type = (types.nullOr (types.listOf (submoduleOf "external-secrets.io.v1.ExternalSecretSpecData")));
        };
        "dataFrom" = mkOption {
          description = "DataFrom is used to fetch all properties from a specific Provider data\nIf multiple entries are specified, the Secret keys are merged in the specified order";
          type = (
            types.nullOr (types.listOf (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFrom"))
          );
        };
        "refreshInterval" = mkOption {
          description = "RefreshInterval is the amount of time before the values are read again from the SecretStore provider,\nspecified as Golang Duration strings.\nValid time units are \"ns\", \"us\" (or \"µs\"), \"ms\", \"s\", \"m\", \"h\"\nExample values: \"1h\", \"2h30m\", \"10s\"\nMay be set to zero to fetch and create it once. Defaults to 1h.";
          type = (types.nullOr types.str);
        };
        "refreshPolicy" = mkOption {
          description = "RefreshPolicy determines how the ExternalSecret should be refreshed:\n- CreatedOnce: Creates the Secret only if it does not exist and does not update it thereafter\n- Periodic: Synchronizes the Secret from the external source at regular intervals specified by refreshInterval.\n  No periodic updates occur if refreshInterval is 0.\n- OnChange: Only synchronizes the Secret when the ExternalSecret's metadata or specification changes";
          type = (types.nullOr types.str);
        };
        "secretStoreRef" = mkOption {
          description = "SecretStoreRef defines which SecretStore to fetch the ExternalSecret data.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecSecretStoreRef"));
        };
        "target" = mkOption {
          description = "ExternalSecretTarget defines the Kubernetes Secret to be created,\nthere can be only one target per ExternalSecret.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecTarget"));
        };
      };

      config = {
        "data" = mkOverride 1002 null;
        "dataFrom" = mkOverride 1002 null;
        "refreshInterval" = mkOverride 1002 null;
        "refreshPolicy" = mkOverride 1002 null;
        "secretStoreRef" = mkOverride 1002 null;
        "target" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecData" = {

      options = {
        "remoteRef" = mkOption {
          description = "RemoteRef points to the remote secret and defines\nwhich secret (version/property/..) to fetch.";
          type = (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataRemoteRef");
        };
        "secretKey" = mkOption {
          description = "The key in the Kubernetes Secret to store the value.";
          type = types.str;
        };
        "sourceRef" = mkOption {
          description = "SourceRef allows you to override the source\nfrom which the value will be pulled.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataSourceRef"));
        };
      };

      config = {
        "sourceRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFrom" = {

      options = {
        "extract" = mkOption {
          description = "Used to extract multiple key/value pairs from one secret\nNote: Extract does not support sourceRef.Generator or sourceRef.GeneratorRef.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromExtract"));
        };
        "find" = mkOption {
          description = "Used to find secrets based on tags or regular expressions\nNote: Find does not support sourceRef.Generator or sourceRef.GeneratorRef.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromFind"));
        };
        "rewrite" = mkOption {
          description = "Used to rewrite secret Keys after getting them from the secret Provider\nMultiple Rewrite operations can be provided. They are applied in a layered order (first to last)";
          type = (
            types.nullOr (types.listOf (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromRewrite"))
          );
        };
        "sourceRef" = mkOption {
          description = "SourceRef points to a store or generator\nwhich contains secret values ready to use.\nUse this in combination with Extract or Find pull values out of\na specific SecretStore.\nWhen sourceRef points to a generator Extract or Find is not supported.\nThe generator returns a static map of values";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromSourceRef"));
        };
      };

      config = {
        "extract" = mkOverride 1002 null;
        "find" = mkOverride 1002 null;
        "rewrite" = mkOverride 1002 null;
        "sourceRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromExtract" = {

      options = {
        "conversionStrategy" = mkOption {
          description = "Used to define a conversion Strategy";
          type = (types.nullOr types.str);
        };
        "decodingStrategy" = mkOption {
          description = "Used to define a decoding Strategy";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Key is the key used in the Provider, mandatory";
          type = types.str;
        };
        "metadataPolicy" = mkOption {
          description = "Policy for fetching tags/labels from provider secrets, possible options are Fetch, None. Defaults to None";
          type = (types.nullOr types.str);
        };
        "property" = mkOption {
          description = "Used to select a specific property of the Provider value (if a map), if supported";
          type = (types.nullOr types.str);
        };
        "version" = mkOption {
          description = "Used to select a specific version of the Provider value, if supported";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conversionStrategy" = mkOverride 1002 null;
        "decodingStrategy" = mkOverride 1002 null;
        "metadataPolicy" = mkOverride 1002 null;
        "property" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromFind" = {

      options = {
        "conversionStrategy" = mkOption {
          description = "Used to define a conversion Strategy";
          type = (types.nullOr types.str);
        };
        "decodingStrategy" = mkOption {
          description = "Used to define a decoding Strategy";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Finds secrets based on the name.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromFindName"));
        };
        "path" = mkOption {
          description = "A root path to start the find operations.";
          type = (types.nullOr types.str);
        };
        "tags" = mkOption {
          description = "Find secrets based on tags.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "conversionStrategy" = mkOverride 1002 null;
        "decodingStrategy" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "tags" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromFindName" = {

      options = {
        "regexp" = mkOption {
          description = "Finds secrets base";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "regexp" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromRewrite" = {

      options = {
        "merge" = mkOption {
          description = "Used to merge key/values in one single Secret\nThe resulting key will contain all values from the specified secrets";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromRewriteMerge"));
        };
        "regexp" = mkOption {
          description = "Used to rewrite with regular expressions.\nThe resulting key will be the output of a regexp.ReplaceAll operation.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromRewriteRegexp")
          );
        };
        "transform" = mkOption {
          description = "Used to apply string transformation on the secrets.\nThe resulting key will be the output of the template applied by the operation.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromRewriteTransform")
          );
        };
      };

      config = {
        "merge" = mkOverride 1002 null;
        "regexp" = mkOverride 1002 null;
        "transform" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromRewriteMerge" = {

      options = {
        "conflictPolicy" = mkOption {
          description = "Used to define the policy to use in conflict resolution.";
          type = (types.nullOr types.str);
        };
        "into" = mkOption {
          description = "Used to define the target key of the merge operation.\nRequired if strategy is JSON. Ignored otherwise.";
          type = (types.nullOr types.str);
        };
        "priority" = mkOption {
          description = "Used to define key priority in conflict resolution.";
          type = (types.nullOr (types.listOf types.str));
        };
        "priorityPolicy" = mkOption {
          description = "Used to define the policy when a key in the priority list does not exist in the input.";
          type = (types.nullOr types.str);
        };
        "strategy" = mkOption {
          description = "Used to define the strategy to use in the merge operation.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conflictPolicy" = mkOverride 1002 null;
        "into" = mkOverride 1002 null;
        "priority" = mkOverride 1002 null;
        "priorityPolicy" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromRewriteRegexp" = {

      options = {
        "source" = mkOption {
          description = "Used to define the regular expression of a re.Compiler.";
          type = types.str;
        };
        "target" = mkOption {
          description = "Used to define the target pattern of a ReplaceAll operation.";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromRewriteTransform" = {

      options = {
        "template" = mkOption {
          description = "Used to define the template to apply on the secret name.\n`.value ` will specify the secret name in the template.";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromSourceRef" = {

      options = {
        "generatorRef" = mkOption {
          description = "GeneratorRef points to a generator custom resource.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromSourceRefGeneratorRef")
          );
        };
        "storeRef" = mkOption {
          description = "SecretStoreRef defines which SecretStore to fetch the ExternalSecret data.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataFromSourceRefStoreRef")
          );
        };
      };

      config = {
        "generatorRef" = mkOverride 1002 null;
        "storeRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromSourceRefGeneratorRef" = {

      options = {
        "apiVersion" = mkOption {
          description = "Specify the apiVersion of the generator resource";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Specify the Kind of the generator resource";
          type = types.str;
        };
        "name" = mkOption {
          description = "Specify the name of the generator resource";
          type = types.str;
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataFromSourceRefStoreRef" = {

      options = {
        "kind" = mkOption {
          description = "Kind of the SecretStore resource (SecretStore or ClusterSecretStore)\nDefaults to `SecretStore`";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the SecretStore resource";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "kind" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataRemoteRef" = {

      options = {
        "conversionStrategy" = mkOption {
          description = "Used to define a conversion Strategy";
          type = (types.nullOr types.str);
        };
        "decodingStrategy" = mkOption {
          description = "Used to define a decoding Strategy";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Key is the key used in the Provider, mandatory";
          type = types.str;
        };
        "metadataPolicy" = mkOption {
          description = "Policy for fetching tags/labels from provider secrets, possible options are Fetch, None. Defaults to None";
          type = (types.nullOr types.str);
        };
        "property" = mkOption {
          description = "Used to select a specific property of the Provider value (if a map), if supported";
          type = (types.nullOr types.str);
        };
        "version" = mkOption {
          description = "Used to select a specific version of the Provider value, if supported";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conversionStrategy" = mkOverride 1002 null;
        "decodingStrategy" = mkOverride 1002 null;
        "metadataPolicy" = mkOverride 1002 null;
        "property" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataSourceRef" = {

      options = {
        "generatorRef" = mkOption {
          description = "GeneratorRef points to a generator custom resource.\n\nDeprecated: The generatorRef is not implemented in .data[].\nthis will be removed with v1.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataSourceRefGeneratorRef")
          );
        };
        "storeRef" = mkOption {
          description = "SecretStoreRef defines which SecretStore to fetch the ExternalSecret data.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecDataSourceRefStoreRef")
          );
        };
      };

      config = {
        "generatorRef" = mkOverride 1002 null;
        "storeRef" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataSourceRefGeneratorRef" = {

      options = {
        "apiVersion" = mkOption {
          description = "Specify the apiVersion of the generator resource";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Specify the Kind of the generator resource";
          type = types.str;
        };
        "name" = mkOption {
          description = "Specify the name of the generator resource";
          type = types.str;
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecDataSourceRefStoreRef" = {

      options = {
        "kind" = mkOption {
          description = "Kind of the SecretStore resource (SecretStore or ClusterSecretStore)\nDefaults to `SecretStore`";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the SecretStore resource";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "kind" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecSecretStoreRef" = {

      options = {
        "kind" = mkOption {
          description = "Kind of the SecretStore resource (SecretStore or ClusterSecretStore)\nDefaults to `SecretStore`";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the SecretStore resource";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "kind" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecTarget" = {

      options = {
        "creationPolicy" = mkOption {
          description = "CreationPolicy defines rules on how to create the resulting Secret.\nDefaults to \"Owner\"";
          type = (types.nullOr types.str);
        };
        "deletionPolicy" = mkOption {
          description = "DeletionPolicy defines rules on how to delete the resulting Secret.\nDefaults to \"Retain\"";
          type = (types.nullOr types.str);
        };
        "immutable" = mkOption {
          description = "Immutable defines if the final secret will be immutable";
          type = (types.nullOr types.bool);
        };
        "manifest" = mkOption {
          description = "Manifest defines a custom Kubernetes resource to create instead of a Secret.\nWhen specified, ExternalSecret will create the resource type defined here\n(e.g., ConfigMap, Custom Resource) instead of a Secret.\nWarning: Using Generic target. Make sure access policies and encryption are properly configured.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecTargetManifest"));
        };
        "name" = mkOption {
          description = "The name of the Secret resource to be managed.\nDefaults to the .metadata.name of the ExternalSecret resource";
          type = (types.nullOr types.str);
        };
        "template" = mkOption {
          description = "Template defines a blueprint for the created Secret resource.";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecTargetTemplate"));
        };
      };

      config = {
        "creationPolicy" = mkOverride 1002 null;
        "deletionPolicy" = mkOverride 1002 null;
        "immutable" = mkOverride 1002 null;
        "manifest" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "template" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecTargetManifest" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion of the target resource (e.g., \"v1\" for ConfigMap, \"argoproj.io/v1alpha1\" for ArgoCD Application)";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind of the target resource (e.g., \"ConfigMap\", \"Application\")";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ExternalSecretSpecTargetTemplate" = {

      options = {
        "data" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "engineVersion" = mkOption {
          description = "EngineVersion specifies the template engine version\nthat should be used to compile/execute the\ntemplate specified in .data and .templateFrom[].";
          type = (types.nullOr types.str);
        };
        "mergePolicy" = mkOption {
          description = "TemplateMergePolicy defines how the rendered template should be merged with the existing Secret data.";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "ExternalSecretTemplateMetadata defines metadata fields for the Secret blueprint.";
          type = (
            types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretSpecTargetTemplateMetadata")
          );
        };
        "templateFrom" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFrom")
            )
          );
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "data" = mkOverride 1002 null;
        "engineVersion" = mkOverride 1002 null;
        "mergePolicy" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "templateFrom" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecTargetTemplateMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "finalizers" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "finalizers" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFrom" = {

      options = {
        "configMap" = mkOption {
          description = "TemplateRef specifies a reference to either a ConfigMap or a Secret resource.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFromConfigMap"
            )
          );
        };
        "literal" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "secret" = mkOption {
          description = "TemplateRef specifies a reference to either a ConfigMap or a Secret resource.";
          type = (
            types.nullOr (
              submoduleOf "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFromSecret"
            )
          );
        };
        "target" = mkOption {
          description = "Target specifies where to place the template result.\nFor Secret resources, common values are: \"Data\", \"Annotations\", \"Labels\".\nFor custom resources (when spec.target.manifest is set), this supports\nnested paths like \"spec.database.config\" or \"data\".";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "configMap" = mkOverride 1002 null;
        "literal" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "target" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFromConfigMap" = {

      options = {
        "items" = mkOption {
          description = "A list of keys in the ConfigMap/Secret to use as templates for Secret data";
          type = (
            types.listOf (
              submoduleOf "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFromConfigMapItems"
            )
          );
        };
        "name" = mkOption {
          description = "The name of the ConfigMap/Secret resource";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFromConfigMapItems" = {

      options = {
        "key" = mkOption {
          description = "A key in the ConfigMap/Secret";
          type = types.str;
        };
        "templateAs" = mkOption {
          description = "TemplateScope specifies how the template keys should be interpreted.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "templateAs" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFromSecret" = {

      options = {
        "items" = mkOption {
          description = "A list of keys in the ConfigMap/Secret to use as templates for Secret data";
          type = (
            types.listOf (
              submoduleOf "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFromSecretItems"
            )
          );
        };
        "name" = mkOption {
          description = "The name of the ConfigMap/Secret resource";
          type = types.str;
        };
      };

      config = { };

    };
    "external-secrets.io.v1.ExternalSecretSpecTargetTemplateTemplateFromSecretItems" = {

      options = {
        "key" = mkOption {
          description = "A key in the ConfigMap/Secret";
          type = types.str;
        };
        "templateAs" = mkOption {
          description = "TemplateScope specifies how the template keys should be interpreted.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "templateAs" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretStatus" = {

      options = {
        "binding" = mkOption {
          description = "Binding represents a servicebinding.io Provisioned Service reference to the secret";
          type = (types.nullOr (submoduleOf "external-secrets.io.v1.ExternalSecretStatusBinding"));
        };
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "external-secrets.io.v1.ExternalSecretStatusConditions"))
          );
        };
        "refreshTime" = mkOption {
          description = "refreshTime is the time and date the external secret was fetched and\nthe target secret updated";
          type = (types.nullOr types.str);
        };
        "syncedResourceVersion" = mkOption {
          description = "SyncedResourceVersion keeps track of the last synced version";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "binding" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "refreshTime" = mkOverride 1002 null;
        "syncedResourceVersion" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretStatusBinding" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "external-secrets.io.v1.ExternalSecretStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = types.str;
        };
        "type" = mkOption {
          description = "ExternalSecretConditionType defines a value type for ExternalSecret conditions.";
          type = types.str;
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "generators.external-secrets.io.v1alpha1.Password" = {

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
          description = "PasswordSpec controls the behavior of the password generator.";
          type = (types.nullOr (submoduleOf "generators.external-secrets.io.v1alpha1.PasswordSpec"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "generators.external-secrets.io.v1alpha1.PasswordSpec" = {

      options = {
        "allowRepeat" = mkOption {
          description = "set AllowRepeat to true to allow repeating characters.";
          type = types.bool;
        };
        "digits" = mkOption {
          description = "Digits specifies the number of digits in the generated\npassword. If omitted it defaults to 25% of the length of the password";
          type = (types.nullOr types.int);
        };
        "encoding" = mkOption {
          description = "Encoding specifies the encoding of the generated password.\nValid values are:\n- \"raw\" (default): no encoding\n- \"base64\": standard base64 encoding\n- \"base64url\": base64url encoding\n- \"base32\": base32 encoding\n- \"hex\": hexadecimal encoding";
          type = (types.nullOr types.str);
        };
        "length" = mkOption {
          description = "Length of the password to be generated.\nDefaults to 24";
          type = types.int;
        };
        "noUpper" = mkOption {
          description = "Set NoUpper to disable uppercase characters";
          type = types.bool;
        };
        "symbolCharacters" = mkOption {
          description = "SymbolCharacters specifies the special characters that should be used\nin the generated password.";
          type = (types.nullOr types.str);
        };
        "symbols" = mkOption {
          description = "Symbols specifies the number of symbol characters in the generated\npassword. If omitted it defaults to 25% of the length of the password";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "digits" = mkOverride 1002 null;
        "encoding" = mkOverride 1002 null;
        "symbolCharacters" = mkOverride 1002 null;
        "symbols" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "external-secrets.io"."v1"."ClusterSecretStore" = mkOption {
        description = "ClusterSecretStore represents a secure external location for storing secrets, which can be referenced as part of `storeRef` fields.";
        type = (
          types.attrsOf (
            submoduleForDefinition "external-secrets.io.v1.ClusterSecretStore" "clustersecretstores"
              "ClusterSecretStore"
              "external-secrets.io"
              "v1"
          )
        );
        default = { };
      };
      "external-secrets.io"."v1"."ExternalSecret" = mkOption {
        description = "ExternalSecret is the Schema for the external-secrets API.\nIt defines how to fetch data from external APIs and make it available as Kubernetes Secrets.";
        type = (
          types.attrsOf (
            submoduleForDefinition "external-secrets.io.v1.ExternalSecret" "externalsecrets" "ExternalSecret"
              "external-secrets.io"
              "v1"
          )
        );
        default = { };
      };
      "generators.external-secrets.io"."v1alpha1"."Password" = mkOption {
        description = "Password generates a random password based on the\nconfiguration parameters in spec.\nYou can specify the length, characterset and other attributes.";
        type = (
          types.attrsOf (
            submoduleForDefinition "generators.external-secrets.io.v1alpha1.Password" "passwords" "Password"
              "generators.external-secrets.io"
              "v1alpha1"
          )
        );
        default = { };
      };

    }
    // {
      "clusterSecretStores" = mkOption {
        description = "ClusterSecretStore represents a secure external location for storing secrets, which can be referenced as part of `storeRef` fields.";
        type = (
          types.attrsOf (
            submoduleForDefinition "external-secrets.io.v1.ClusterSecretStore" "clustersecretstores"
              "ClusterSecretStore"
              "external-secrets.io"
              "v1"
          )
        );
        default = { };
      };
      "externalSecrets" = mkOption {
        description = "ExternalSecret is the Schema for the external-secrets API.\nIt defines how to fetch data from external APIs and make it available as Kubernetes Secrets.";
        type = (
          types.attrsOf (
            submoduleForDefinition "external-secrets.io.v1.ExternalSecret" "externalsecrets" "ExternalSecret"
              "external-secrets.io"
              "v1"
          )
        );
        default = { };
      };
      "passwords" = mkOption {
        description = "Password generates a random password based on the\nconfiguration parameters in spec.\nYou can specify the length, characterset and other attributes.";
        type = (
          types.attrsOf (
            submoduleForDefinition "generators.external-secrets.io.v1alpha1.Password" "passwords" "Password"
              "generators.external-secrets.io"
              "v1alpha1"
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
        name = "clustersecretstores";
        group = "external-secrets.io";
        version = "v1";
        kind = "ClusterSecretStore";
        attrName = "clusterSecretStores";
      }
      {
        name = "externalsecrets";
        group = "external-secrets.io";
        version = "v1";
        kind = "ExternalSecret";
        attrName = "externalSecrets";
      }
      {
        name = "passwords";
        group = "generators.external-secrets.io";
        version = "v1alpha1";
        kind = "Password";
        attrName = "passwords";
      }
    ];

    resources = {
      "external-secrets.io"."v1"."ClusterSecretStore" =
        mkAliasDefinitions
          options.resources."clusterSecretStores";
      "external-secrets.io"."v1"."ExternalSecret" =
        mkAliasDefinitions
          options.resources."externalSecrets";
      "generators.external-secrets.io"."v1alpha1"."Password" =
        mkAliasDefinitions
          options.resources."passwords";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "external-secrets.io";
        version = "v1";
        kind = "ExternalSecret";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "generators.external-secrets.io";
        version = "v1alpha1";
        kind = "Password";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
