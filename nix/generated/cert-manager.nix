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
    "cert-manager.io.v1.ClusterIssuer" = {

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
          description = "Desired state of the ClusterIssuer resource.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpec");
        };
        "status" = mkOption {
          description = "Status of the ClusterIssuer. This is set and managed automatically.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpec" = {

      options = {
        "acme" = mkOption {
          description = "ACME configures this issuer to communicate with a RFC8555 (ACME) server\nto obtain signed x509 certificates.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcme"));
        };
        "ca" = mkOption {
          description = "CA configures this issuer to sign certificates using a signing CA keypair\nstored in a Secret resource.\nThis is used to build internal PKIs that are managed by cert-manager.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecCa"));
        };
        "selfSigned" = mkOption {
          description = "SelfSigned configures this issuer to 'self sign' certificates using the\nprivate key used to create the CertificateRequest object.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecSelfSigned"));
        };
        "vault" = mkOption {
          description = "Vault configures this issuer to sign certificates using a HashiCorp Vault\nPKI backend.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVault"));
        };
        "venafi" = mkOption {
          description = "Venafi configures this issuer to sign certificates using a Venafi TPP\nor Venafi Cloud policy zone.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVenafi"));
        };
      };

      config = {
        "acme" = mkOverride 1002 null;
        "ca" = mkOverride 1002 null;
        "selfSigned" = mkOverride 1002 null;
        "vault" = mkOverride 1002 null;
        "venafi" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcme" = {

      options = {
        "caBundle" = mkOption {
          description = "Base64-encoded bundle of PEM CAs which can be used to validate the certificate\nchain presented by the ACME server.\nMutually exclusive with SkipTLSVerify; prefer using CABundle to prevent various\nkinds of security vulnerabilities.\nIf CABundle and SkipTLSVerify are unset, the system certificate bundle inside\nthe container is used to validate the TLS connection.";
          type = (types.nullOr types.str);
        };
        "disableAccountKeyGeneration" = mkOption {
          description = "Enables or disables generating a new ACME account key.\nIf true, the Issuer resource will *not* request a new account but will expect\nthe account key to be supplied via an existing secret.\nIf false, the cert-manager system will generate a new ACME account key\nfor the Issuer.\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "email" = mkOption {
          description = "Email is the email address to be associated with the ACME account.\nThis field is optional, but it is strongly recommended to be set.\nIt will be used to contact you in case of issues with your account or\ncertificates, including expiry notification emails.\nThis field may be updated after the account is initially registered.";
          type = (types.nullOr types.str);
        };
        "enableDurationFeature" = mkOption {
          description = "Enables requesting a Not After date on certificates that matches the\nduration of the certificate. This is not supported by all ACME servers\nlike Let's Encrypt. If set to true when the ACME server does not support\nit, it will create an error on the Order.\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "externalAccountBinding" = mkOption {
          description = "ExternalAccountBinding is a reference to a CA external account of the ACME\nserver.\nIf set, upon registration cert-manager will attempt to associate the given\nexternal account credentials with the registered ACME account.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeExternalAccountBinding")
          );
        };
        "preferredChain" = mkOption {
          description = "PreferredChain is the chain to use if the ACME server outputs multiple.\nPreferredChain is no guarantee that this one gets delivered by the ACME\nendpoint.\nFor example, for Let's Encrypt's DST cross-sign you would use:\n\"DST Root CA X3\" or \"ISRG Root X1\" for the newer Let's Encrypt root CA.\nThis value picks the first certificate bundle in the combined set of\nACME default and alternative chains that has a root-most certificate with\nthis value as its issuer's commonname.";
          type = (types.nullOr types.str);
        };
        "privateKeySecretRef" = mkOption {
          description = "PrivateKey is the name of a Kubernetes Secret resource that will be used to\nstore the automatically generated ACME account private key.\nOptionally, a `key` may be specified to select a specific entry within\nthe named Secret resource.\nIf `key` is not specified, a default of `tls.key` will be used.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmePrivateKeySecretRef");
        };
        "profile" = mkOption {
          description = "Profile allows requesting a certificate profile from the ACME server.\nSupported profiles are listed by the server's ACME directory URL.";
          type = (types.nullOr types.str);
        };
        "server" = mkOption {
          description = "Server is the URL used to access the ACME server's 'directory' endpoint.\nFor example, for Let's Encrypt's staging endpoint, you would use:\n\"https://acme-staging-v02.api.letsencrypt.org/directory\".\nOnly ACME v2 endpoints (i.e. RFC 8555) are supported.";
          type = types.str;
        };
        "skipTLSVerify" = mkOption {
          description = "INSECURE: Enables or disables validation of the ACME server TLS certificate.\nIf true, requests to the ACME server will not have the TLS certificate chain\nvalidated.\nMutually exclusive with CABundle; prefer using CABundle to prevent various\nkinds of security vulnerabilities.\nOnly enable this option in development environments.\nIf CABundle and SkipTLSVerify are unset, the system certificate bundle inside\nthe container is used to validate the TLS connection.\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "solvers" = mkOption {
          description = "Solvers is a list of challenge solvers that will be used to solve\nACME challenges for the matching domains.\nSolver configurations must be provided in order to obtain certificates\nfrom an ACME server.\nFor more information, see: https://cert-manager.io/docs/configuration/acme/";
          type = (
            types.nullOr (types.listOf (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolvers"))
          );
        };
      };

      config = {
        "caBundle" = mkOverride 1002 null;
        "disableAccountKeyGeneration" = mkOverride 1002 null;
        "email" = mkOverride 1002 null;
        "enableDurationFeature" = mkOverride 1002 null;
        "externalAccountBinding" = mkOverride 1002 null;
        "preferredChain" = mkOverride 1002 null;
        "profile" = mkOverride 1002 null;
        "skipTLSVerify" = mkOverride 1002 null;
        "solvers" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeExternalAccountBinding" = {

      options = {
        "keyAlgorithm" = mkOption {
          description = "Deprecated: keyAlgorithm field exists for historical compatibility\nreasons and should not be used. The algorithm is now hardcoded to HS256\nin golang/x/crypto/acme.";
          type = (types.nullOr types.str);
        };
        "keyID" = mkOption {
          description = "keyID is the ID of the CA key that the External Account is bound to.";
          type = types.str;
        };
        "keySecretRef" = mkOption {
          description = "keySecretRef is a Secret Key Selector referencing a data item in a Kubernetes\nSecret which holds the symmetric MAC key of the External Account Binding.\nThe `key` is the index string that is paired with the key data in the\nSecret and should not be confused with the key data itself, or indeed with\nthe External Account Binding keyID above.\nThe secret key stored in the Secret **must** be un-padded, base64 URL\nencoded data.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeExternalAccountBindingKeySecretRef");
        };
      };

      config = {
        "keyAlgorithm" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeExternalAccountBindingKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmePrivateKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolvers" = {

      options = {
        "dns01" = mkOption {
          description = "Configures cert-manager to attempt to complete authorizations by\nperforming the DNS01 challenge flow.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01"));
        };
        "http01" = mkOption {
          description = "Configures cert-manager to attempt to complete authorizations by\nperforming the HTTP01 challenge flow.\nIt is not possible to obtain certificates for wildcard domain names\n(e.g., `*.example.com`) using the HTTP01 challenge mechanism.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01"));
        };
        "selector" = mkOption {
          description = "Selector selects a set of DNSNames on the Certificate resource that\nshould be solved using this challenge solver.\nIf not specified, the solver will be treated as the 'default' solver\nwith the lowest priority, i.e. if any other solver has a more specific\nmatch, it will be used instead.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversSelector"));
        };
      };

      config = {
        "dns01" = mkOverride 1002 null;
        "http01" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01" = {

      options = {
        "acmeDNS" = mkOption {
          description = "Use the 'ACME DNS' (https://github.com/joohoi/acme-dns) API to manage\nDNS01 challenge records.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AcmeDNS"));
        };
        "akamai" = mkOption {
          description = "Use the Akamai DNS zone management API to manage DNS01 challenge records.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Akamai"));
        };
        "azureDNS" = mkOption {
          description = "Use the Microsoft Azure DNS API to manage DNS01 challenge records.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AzureDNS"));
        };
        "cloudDNS" = mkOption {
          description = "Use the Google Cloud DNS API to manage DNS01 challenge records.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01CloudDNS"));
        };
        "cloudflare" = mkOption {
          description = "Use the Cloudflare API to manage DNS01 challenge records.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Cloudflare")
          );
        };
        "cnameStrategy" = mkOption {
          description = "CNAMEStrategy configures how the DNS01 provider should handle CNAME\nrecords when found in DNS zones.";
          type = (types.nullOr types.str);
        };
        "digitalocean" = mkOption {
          description = "Use the DigitalOcean DNS API to manage DNS01 challenge records.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Digitalocean")
          );
        };
        "rfc2136" = mkOption {
          description = "Use RFC2136 (\"Dynamic Updates in the Domain Name System\") (https://datatracker.ietf.org/doc/rfc2136/)\nto manage DNS01 challenge records.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Rfc2136"));
        };
        "route53" = mkOption {
          description = "Use the AWS Route53 API to manage DNS01 challenge records.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53"));
        };
        "webhook" = mkOption {
          description = "Configure an external webhook based DNS01 challenge solver to manage\nDNS01 challenge records.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Webhook"));
        };
      };

      config = {
        "acmeDNS" = mkOverride 1002 null;
        "akamai" = mkOverride 1002 null;
        "azureDNS" = mkOverride 1002 null;
        "cloudDNS" = mkOverride 1002 null;
        "cloudflare" = mkOverride 1002 null;
        "cnameStrategy" = mkOverride 1002 null;
        "digitalocean" = mkOverride 1002 null;
        "rfc2136" = mkOverride 1002 null;
        "route53" = mkOverride 1002 null;
        "webhook" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AcmeDNS" = {

      options = {
        "accountSecretRef" = mkOption {
          description = "A reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AcmeDNSAccountSecretRef");
        };
        "host" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AcmeDNSAccountSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Akamai" = {

      options = {
        "accessTokenSecretRef" = mkOption {
          description = "A reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AkamaiAccessTokenSecretRef"
          );
        };
        "clientSecretSecretRef" = mkOption {
          description = "A reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AkamaiClientSecretSecretRef"
          );
        };
        "clientTokenSecretRef" = mkOption {
          description = "A reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AkamaiClientTokenSecretRef"
          );
        };
        "serviceConsumerDomain" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AkamaiAccessTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AkamaiClientSecretSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AkamaiClientTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AzureDNS" = {

      options = {
        "clientID" = mkOption {
          description = "Auth: Azure Service Principal:\nThe ClientID of the Azure Service Principal used to authenticate with Azure DNS.\nIf set, ClientSecret and TenantID must also be set.";
          type = (types.nullOr types.str);
        };
        "clientSecretSecretRef" = mkOption {
          description = "Auth: Azure Service Principal:\nA reference to a Secret containing the password associated with the Service Principal.\nIf set, ClientID and TenantID must also be set.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AzureDNSClientSecretSecretRef"
            )
          );
        };
        "environment" = mkOption {
          description = "name of the Azure environment (default AzurePublicCloud)";
          type = (types.nullOr types.str);
        };
        "hostedZoneName" = mkOption {
          description = "name of the DNS zone that should be used";
          type = (types.nullOr types.str);
        };
        "managedIdentity" = mkOption {
          description = "Auth: Azure Workload Identity or Azure Managed Service Identity:\nSettings to enable Azure Workload Identity or Azure Managed Service Identity\nIf set, ClientID, ClientSecret and TenantID must not be set.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AzureDNSManagedIdentity"
            )
          );
        };
        "resourceGroupName" = mkOption {
          description = "resource group the DNS zone is located in";
          type = types.str;
        };
        "subscriptionID" = mkOption {
          description = "ID of the Azure subscription";
          type = types.str;
        };
        "tenantID" = mkOption {
          description = "Auth: Azure Service Principal:\nThe TenantID of the Azure Service Principal used to authenticate with Azure DNS.\nIf set, ClientID and ClientSecret must also be set.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "clientID" = mkOverride 1002 null;
        "clientSecretSecretRef" = mkOverride 1002 null;
        "environment" = mkOverride 1002 null;
        "hostedZoneName" = mkOverride 1002 null;
        "managedIdentity" = mkOverride 1002 null;
        "tenantID" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AzureDNSClientSecretSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01AzureDNSManagedIdentity" = {

      options = {
        "clientID" = mkOption {
          description = "client ID of the managed identity, cannot be used at the same time as resourceID";
          type = (types.nullOr types.str);
        };
        "resourceID" = mkOption {
          description = "resource ID of the managed identity, cannot be used at the same time as clientID\nCannot be used for Azure Managed Service Identity";
          type = (types.nullOr types.str);
        };
        "tenantID" = mkOption {
          description = "tenant ID of the managed identity, cannot be used at the same time as resourceID";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "clientID" = mkOverride 1002 null;
        "resourceID" = mkOverride 1002 null;
        "tenantID" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01CloudDNS" = {

      options = {
        "hostedZoneName" = mkOption {
          description = "HostedZoneName is an optional field that tells cert-manager in which\nCloud DNS zone the challenge record has to be created.\nIf left empty cert-manager will automatically choose a zone.";
          type = (types.nullOr types.str);
        };
        "project" = mkOption {
          description = "";
          type = types.str;
        };
        "serviceAccountSecretRef" = mkOption {
          description = "A reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01CloudDNSServiceAccountSecretRef"
            )
          );
        };
      };

      config = {
        "hostedZoneName" = mkOverride 1002 null;
        "serviceAccountSecretRef" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01CloudDNSServiceAccountSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Cloudflare" = {

      options = {
        "apiKeySecretRef" = mkOption {
          description = "API key to use to authenticate with Cloudflare.\nNote: using an API token to authenticate is now the recommended method\nas it allows greater control of permissions.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01CloudflareApiKeySecretRef"
            )
          );
        };
        "apiTokenSecretRef" = mkOption {
          description = "API token used to authenticate with Cloudflare.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01CloudflareApiTokenSecretRef"
            )
          );
        };
        "email" = mkOption {
          description = "Email of the account, only required when using API key based authentication.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "apiKeySecretRef" = mkOverride 1002 null;
        "apiTokenSecretRef" = mkOverride 1002 null;
        "email" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01CloudflareApiKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01CloudflareApiTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Digitalocean" = {

      options = {
        "tokenSecretRef" = mkOption {
          description = "A reference to a specific 'key' within a Secret resource.\nIn some instances, `key` is a required field.";
          type = (
            submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01DigitaloceanTokenSecretRef"
          );
        };
      };

      config = { };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01DigitaloceanTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Rfc2136" = {

      options = {
        "nameserver" = mkOption {
          description = "The IP address or hostname of an authoritative DNS server supporting\nRFC2136 in the form host:port. If the host is an IPv6 address it must be\nenclosed in square brackets (e.g [2001:db8::1]) ; port is optional.\nThis field is required.";
          type = types.str;
        };
        "protocol" = mkOption {
          description = "Protocol to use for dynamic DNS update queries. Valid values are (case-sensitive) ``TCP`` and ``UDP``; ``UDP`` (default).";
          type = (types.nullOr types.str);
        };
        "tsigAlgorithm" = mkOption {
          description = "The TSIG Algorithm configured in the DNS supporting RFC2136. Used only\nwhen ``tsigSecretSecretRef`` and ``tsigKeyName`` are defined.\nSupported values are (case-insensitive): ``HMACMD5`` (default),\n``HMACSHA1``, ``HMACSHA256`` or ``HMACSHA512``.";
          type = (types.nullOr types.str);
        };
        "tsigKeyName" = mkOption {
          description = "The TSIG Key name configured in the DNS.\nIf ``tsigSecretSecretRef`` is defined, this field is required.";
          type = (types.nullOr types.str);
        };
        "tsigSecretSecretRef" = mkOption {
          description = "The name of the secret containing the TSIG value.\nIf ``tsigKeyName`` is defined, this field is required.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Rfc2136TsigSecretSecretRef"
            )
          );
        };
      };

      config = {
        "protocol" = mkOverride 1002 null;
        "tsigAlgorithm" = mkOverride 1002 null;
        "tsigKeyName" = mkOverride 1002 null;
        "tsigSecretSecretRef" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Rfc2136TsigSecretSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53" = {

      options = {
        "accessKeyID" = mkOption {
          description = "The AccessKeyID is used for authentication.\nCannot be set when SecretAccessKeyID is set.\nIf neither the Access Key nor Key ID are set, we fall-back to using env\nvars, shared credentials file or AWS Instance metadata,\nsee: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials";
          type = (types.nullOr types.str);
        };
        "accessKeyIDSecretRef" = mkOption {
          description = "The SecretAccessKey is used for authentication. If set, pull the AWS\naccess key ID from a key within a Kubernetes Secret.\nCannot be set when AccessKeyID is set.\nIf neither the Access Key nor Key ID are set, we fall-back to using env\nvars, shared credentials file or AWS Instance metadata,\nsee: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53AccessKeyIDSecretRef"
            )
          );
        };
        "auth" = mkOption {
          description = "Auth configures how cert-manager authenticates.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53Auth")
          );
        };
        "hostedZoneID" = mkOption {
          description = "If set, the provider will manage only this zone in Route53 and will not do a lookup using the route53:ListHostedZonesByName api call.";
          type = (types.nullOr types.str);
        };
        "region" = mkOption {
          description = "Override the AWS region.\n\nRoute53 is a global service and does not have regional endpoints but the\nregion specified here (or via environment variables) is used as a hint to\nhelp compute the correct AWS credential scope and partition when it\nconnects to Route53. See:\n- [Amazon Route 53 endpoints and quotas](https://docs.aws.amazon.com/general/latest/gr/r53.html)\n- [Global services](https://docs.aws.amazon.com/whitepapers/latest/aws-fault-isolation-boundaries/global-services.html)\n\nIf you omit this region field, cert-manager will use the region from\nAWS_REGION and AWS_DEFAULT_REGION environment variables, if they are set\nin the cert-manager controller Pod.\n\nThe `region` field is not needed if you use [IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).\nInstead an AWS_REGION environment variable is added to the cert-manager controller Pod by:\n[Amazon EKS Pod Identity Webhook](https://github.com/aws/amazon-eks-pod-identity-webhook).\nIn this case this `region` field value is ignored.\n\nThe `region` field is not needed if you use [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html).\nInstead an AWS_REGION environment variable is added to the cert-manager controller Pod by:\n[Amazon EKS Pod Identity Agent](https://github.com/aws/eks-pod-identity-agent),\nIn this case this `region` field value is ignored.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a Role ARN which the Route53 provider will assume using either the explicit credentials AccessKeyID/SecretAccessKey\nor the inferred credentials from environment variables, shared credentials file or AWS Instance metadata";
          type = (types.nullOr types.str);
        };
        "secretAccessKeySecretRef" = mkOption {
          description = "The SecretAccessKey is used for authentication.\nIf neither the Access Key nor Key ID are set, we fall-back to using env\nvars, shared credentials file or AWS Instance metadata,\nsee: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53SecretAccessKeySecretRef"
            )
          );
        };
      };

      config = {
        "accessKeyID" = mkOverride 1002 null;
        "accessKeyIDSecretRef" = mkOverride 1002 null;
        "auth" = mkOverride 1002 null;
        "hostedZoneID" = mkOverride 1002 null;
        "region" = mkOverride 1002 null;
        "role" = mkOverride 1002 null;
        "secretAccessKeySecretRef" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53AccessKeyIDSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53Auth" = {

      options = {
        "kubernetes" = mkOption {
          description = "Kubernetes authenticates with Route53 using AssumeRoleWithWebIdentity\nby passing a bound ServiceAccount token.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53AuthKubernetes");
        };
      };

      config = { };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53AuthKubernetes" = {

      options = {
        "serviceAccountRef" = mkOption {
          description = "A reference to a service account that will be used to request a bound\ntoken (also known as \"projected token\"). To use this field, you must\nconfigure an RBAC rule to let cert-manager request a token.";
          type = (
            submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53AuthKubernetesServiceAccountRef"
          );
        };
      };

      config = { };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53AuthKubernetesServiceAccountRef" = {

      options = {
        "audiences" = mkOption {
          description = "TokenAudiences is an optional list of audiences to include in the\ntoken passed to AWS. The default token consisting of the issuer's namespace\nand name is always included.\nIf unset the audience defaults to `sts.amazonaws.com`.";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "Name of the ServiceAccount used to request a token.";
          type = types.str;
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Route53SecretAccessKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversDns01Webhook" = {

      options = {
        "config" = mkOption {
          description = "Additional configuration that should be passed to the webhook apiserver\nwhen challenges are processed.\nThis can contain arbitrary JSON data.\nSecret values should not be specified in this stanza.\nIf secret values are needed (e.g., credentials for a DNS service), you\nshould use a SecretKeySelector to reference a Secret resource.\nFor details on the schema of this field, consult the webhook provider\nimplementation's documentation.";
          type = (types.nullOr types.attrs);
        };
        "groupName" = mkOption {
          description = "The API group name that should be used when POSTing ChallengePayload\nresources to the webhook apiserver.\nThis should be the same as the GroupName specified in the webhook\nprovider implementation.";
          type = types.str;
        };
        "solverName" = mkOption {
          description = "The name of the solver to use, as defined in the webhook provider\nimplementation.\nThis will typically be the name of the provider, e.g., 'cloudflare'.";
          type = types.str;
        };
      };

      config = {
        "config" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01" = {

      options = {
        "gatewayHTTPRoute" = mkOption {
          description = "The Gateway API is a sig-network community API that models service networking\nin Kubernetes (https://gateway-api.sigs.k8s.io/). The Gateway solver will\ncreate HTTPRoutes with the specified labels in the same namespace as the challenge.\nThis solver is experimental, and fields / behaviour may change in the future.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoute")
          );
        };
        "ingress" = mkOption {
          description = "The ingress based HTTP01 challenge solver will solve challenges by\ncreating or modifying Ingress resources in order to route requests for\n'/.well-known/acme-challenge/XYZ' to 'challenge solver' pods that are\nprovisioned by cert-manager for each Challenge to be completed.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01Ingress"));
        };
      };

      config = {
        "gatewayHTTPRoute" = mkOverride 1002 null;
        "ingress" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoute" = {

      options = {
        "labels" = mkOption {
          description = "Custom labels that will be applied to HTTPRoutes created by cert-manager\nwhile solving HTTP-01 challenges.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "parentRefs" = mkOption {
          description = "When solving an HTTP-01 challenge, cert-manager creates an HTTPRoute.\ncert-manager needs to know which parentRefs should be used when creating\nthe HTTPRoute. Usually, the parentRef references a Gateway. See:\nhttps://gateway-api.sigs.k8s.io/api-types/httproute/#attaching-to-gateways";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRouteParentRefs"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "podTemplate" = mkOption {
          description = "Optional pod template used to configure the ACME challenge solver pods\nused for HTTP01 challenges.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplate"
            )
          );
        };
        "serviceType" = mkOption {
          description = "Optional service type for Kubernetes solver service. Supported values\nare NodePort or ClusterIP. If unset, defaults to NodePort.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "labels" = mkOverride 1002 null;
        "parentRefs" = mkOverride 1002 null;
        "podTemplate" = mkOverride 1002 null;
        "serviceType" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRouteParentRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\n<gateway:experimental:description>\nParentRefs from a Route to a Service in the same namespace are \"producer\"\nroutes, which apply default routing rules to inbound connections from\nany namespace to the Service.\n\nParentRefs from a Route to a Service in a different namespace are\n\"consumer\" routes, and these routing rules are only applied to outbound\nconnections originating from the same namespace as the Route, for which\nthe intended destination of the connections are a Service targeted as a\nParentRef of the Route.\n</gateway:experimental:description>\n\nSupport: Core";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\n<gateway:experimental:description>\nWhen the parent resource is a Service, this targets a specific port in the\nService spec. When both Port (experimental) and SectionName are specified,\nthe name and port of the selected port must match both specified values.\n</gateway:experimental:description>\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = (types.nullOr types.int);
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplate" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta overrides for the pod used to solve HTTP01 challenges.\nOnly the 'labels' and 'annotations' fields may be set.\nIf labels or annotations overlap with in-built values, the values here\nwill override the in-built values.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateMetadata"
            )
          );
        };
        "spec" = mkOption {
          description = "PodSpec defines overrides for the HTTP01 challenge solver pod.\nCheck ACMEChallengeSolverHTTP01IngressPodSpec to find out currently supported fields.\nAll other fields will be ignored.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpec"
            )
          );
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations that should be added to the created ACME HTTP01 solver pods.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "Labels that should be added to the created ACME HTTP01 solver pods.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpec" = {

      options = {
        "affinity" = mkOption {
          description = "If specified, the pod's scheduling constraints";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinity"
            )
          );
        };
        "imagePullSecrets" = mkOption {
          description = "If specified, the pod's imagePullSecrets";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecImagePullSecrets"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector is a selector which must be true for the pod to fit on a node.\nSelector which must match a node's labels for the pod to be scheduled on that node.\nMore info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "priorityClassName" = mkOption {
          description = "If specified, the pod's priorityClassName.";
          type = (types.nullOr types.str);
        };
        "resources" = mkOption {
          description = "If specified, the pod's resource requirements.\nThese values override the global resource configuration flags.\nNote that when only specifying resource limits, ensure they are greater than or equal\nto the corresponding global resource requests configured via controller flags\n(--acme-http01-solver-resource-request-cpu, --acme-http01-solver-resource-request-memory).\nKubernetes will reject pod creation if limits are lower than requests, causing challenge failures.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecResources"
            )
          );
        };
        "securityContext" = mkOption {
          description = "If specified, the pod's security context";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecSecurityContext"
            )
          );
        };
        "serviceAccountName" = mkOption {
          description = "If specified, the pod's service account";
          type = (types.nullOr types.str);
        };
        "tolerations" = mkOption {
          description = "If specified, the pod's tolerations.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecTolerations"
              )
            )
          );
        };
      };

      config = {
        "affinity" = mkOverride 1002 null;
        "imagePullSecrets" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "serviceAccountName" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinity"
            )
          );
        };
      };

      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinity" =
      {

        options = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
                )
              )
            );
          };
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            );
          };
        };

        config = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinity" =
      {

        options = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
                )
              )
            );
          };
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
                )
              )
            );
          };
        };

        config = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinity" =
      {

        options = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
                )
              )
            );
          };
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
                )
              )
            );
          };
        };

        config = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecImagePullSecrets" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecResources" = {

      options = {
        "limits" = mkOption {
          description = "Limits describes the maximum amount of compute resources allowed.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "requests" = mkOption {
          description = "Requests describes the minimum amount of compute resources required.\nIf Requests is omitted for a container, it defaults to Limits if that is explicitly specified,\notherwise to the global values configured via controller flags. Requests cannot exceed Limits.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
      };

      config = {
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecSecurityContext" =
      {

        options = {
          "fsGroup" = mkOption {
            description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
            type = (types.nullOr types.int);
          };
          "fsGroupChangePolicy" = mkOption {
            description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
            type = (types.nullOr types.str);
          };
          "runAsGroup" = mkOption {
            description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
            type = (types.nullOr types.int);
          };
          "runAsNonRoot" = mkOption {
            description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
            type = (types.nullOr types.bool);
          };
          "runAsUser" = mkOption {
            description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
            type = (types.nullOr types.int);
          };
          "seLinuxOptions" = mkOption {
            description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecSecurityContextSeLinuxOptions"
              )
            );
          };
          "seccompProfile" = mkOption {
            description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecSecurityContextSeccompProfile"
              )
            );
          };
          "supplementalGroups" = mkOption {
            description = "A list of groups applied to the first process run in each container, in addition\nto the container's primary GID, the fsGroup (if specified), and group memberships\ndefined in the container image for the uid of the container process. If unspecified,\nno additional groups are added to any container. Note that group memberships\ndefined in the container image for the uid of the container process are still effective,\neven if they are not included in this list.\nNote that this field cannot be set when spec.os.name is windows.";
            type = (types.nullOr (types.listOf types.int));
          };
          "sysctls" = mkOption {
            description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecSecurityContextSysctls"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
        };

        config = {
          "fsGroup" = mkOverride 1002 null;
          "fsGroupChangePolicy" = mkOverride 1002 null;
          "runAsGroup" = mkOverride 1002 null;
          "runAsNonRoot" = mkOverride 1002 null;
          "runAsUser" = mkOverride 1002 null;
          "seLinuxOptions" = mkOverride 1002 null;
          "seccompProfile" = mkOverride 1002 null;
          "supplementalGroups" = mkOverride 1002 null;
          "sysctls" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecSecurityContextSeLinuxOptions" =
      {

        options = {
          "level" = mkOption {
            description = "Level is SELinux level label that applies to the container.";
            type = (types.nullOr types.str);
          };
          "role" = mkOption {
            description = "Role is a SELinux role label that applies to the container.";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "Type is a SELinux type label that applies to the container.";
            type = (types.nullOr types.str);
          };
          "user" = mkOption {
            description = "User is a SELinux user label that applies to the container.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "level" = mkOverride 1002 null;
          "role" = mkOverride 1002 null;
          "type" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecSecurityContextSeccompProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecSecurityContextSysctls" =
      {

        options = {
          "name" = mkOption {
            description = "Name of a property to set";
            type = types.str;
          };
          "value" = mkOption {
            description = "Value of a property to set";
            type = types.str;
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01GatewayHTTPRoutePodTemplateSpecTolerations" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01Ingress" = {

      options = {
        "class" = mkOption {
          description = "This field configures the annotation `kubernetes.io/ingress.class` when\ncreating Ingress resources to solve ACME challenges that use this\nchallenge solver. Only one of `class`, `name` or `ingressClassName` may\nbe specified.";
          type = (types.nullOr types.str);
        };
        "ingressClassName" = mkOption {
          description = "This field configures the field `ingressClassName` on the created Ingress\nresources used to solve ACME challenges that use this challenge solver.\nThis is the recommended way of configuring the ingress class. Only one of\n`class`, `name` or `ingressClassName` may be specified.";
          type = (types.nullOr types.str);
        };
        "ingressTemplate" = mkOption {
          description = "Optional ingress template used to configure the ACME challenge solver\ningress used for HTTP01 challenges.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressIngressTemplate"
            )
          );
        };
        "name" = mkOption {
          description = "The name of the ingress resource that should have ACME challenge solving\nroutes inserted into it in order to solve HTTP01 challenges.\nThis is typically used in conjunction with ingress controllers like\ningress-gce, which maintains a 1:1 mapping between external IPs and\ningress resources. Only one of `class`, `name` or `ingressClassName` may\nbe specified.";
          type = (types.nullOr types.str);
        };
        "podTemplate" = mkOption {
          description = "Optional pod template used to configure the ACME challenge solver pods\nused for HTTP01 challenges.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplate")
          );
        };
        "serviceType" = mkOption {
          description = "Optional service type for Kubernetes solver service. Supported values\nare NodePort or ClusterIP. If unset, defaults to NodePort.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "class" = mkOverride 1002 null;
        "ingressClassName" = mkOverride 1002 null;
        "ingressTemplate" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "podTemplate" = mkOverride 1002 null;
        "serviceType" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressIngressTemplate" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta overrides for the ingress used to solve HTTP01 challenges.\nOnly the 'labels' and 'annotations' fields may be set.\nIf labels or annotations overlap with in-built values, the values here\nwill override the in-built values.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressIngressTemplateMetadata"
            )
          );
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressIngressTemplateMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations that should be added to the created ACME HTTP01 solver ingress.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "Labels that should be added to the created ACME HTTP01 solver ingress.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplate" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta overrides for the pod used to solve HTTP01 challenges.\nOnly the 'labels' and 'annotations' fields may be set.\nIf labels or annotations overlap with in-built values, the values here\nwill override the in-built values.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateMetadata"
            )
          );
        };
        "spec" = mkOption {
          description = "PodSpec defines overrides for the HTTP01 challenge solver pod.\nCheck ACMEChallengeSolverHTTP01IngressPodSpec to find out currently supported fields.\nAll other fields will be ignored.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpec"
            )
          );
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations that should be added to the created ACME HTTP01 solver pods.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "Labels that should be added to the created ACME HTTP01 solver pods.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpec" = {

      options = {
        "affinity" = mkOption {
          description = "If specified, the pod's scheduling constraints";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinity"
            )
          );
        };
        "imagePullSecrets" = mkOption {
          description = "If specified, the pod's imagePullSecrets";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecImagePullSecrets"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector is a selector which must be true for the pod to fit on a node.\nSelector which must match a node's labels for the pod to be scheduled on that node.\nMore info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "priorityClassName" = mkOption {
          description = "If specified, the pod's priorityClassName.";
          type = (types.nullOr types.str);
        };
        "resources" = mkOption {
          description = "If specified, the pod's resource requirements.\nThese values override the global resource configuration flags.\nNote that when only specifying resource limits, ensure they are greater than or equal\nto the corresponding global resource requests configured via controller flags\n(--acme-http01-solver-resource-request-cpu, --acme-http01-solver-resource-request-memory).\nKubernetes will reject pod creation if limits are lower than requests, causing challenge failures.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecResources"
            )
          );
        };
        "securityContext" = mkOption {
          description = "If specified, the pod's security context";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecSecurityContext"
            )
          );
        };
        "serviceAccountName" = mkOption {
          description = "If specified, the pod's service account";
          type = (types.nullOr types.str);
        };
        "tolerations" = mkOption {
          description = "If specified, the pod's tolerations.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecTolerations"
              )
            )
          );
        };
      };

      config = {
        "affinity" = mkOverride 1002 null;
        "imagePullSecrets" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "serviceAccountName" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinity"
            )
          );
        };
      };

      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinity" =
      {

        options = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
                )
              )
            );
          };
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            );
          };
        };

        config = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinity" =
      {

        options = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
                )
              )
            );
          };
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
            description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
                )
              )
            );
          };
        };

        config = {
          "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
          "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecImagePullSecrets" = {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecResources" = {

      options = {
        "limits" = mkOption {
          description = "Limits describes the maximum amount of compute resources allowed.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "requests" = mkOption {
          description = "Requests describes the minimum amount of compute resources required.\nIf Requests is omitted for a container, it defaults to Limits if that is explicitly specified,\notherwise to the global values configured via controller flags. Requests cannot exceed Limits.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
      };

      config = {
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecSecurityContext" = {

      options = {
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in addition\nto the container's primary GID, the fsGroup (if specified), and group memberships\ndefined in the container image for the uid of the container process. If unspecified,\nno additional groups are added to any container. Note that group memberships\ndefined in the container image for the uid of the container process are still effective,\neven if they are not included in this list.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "fsGroup" = mkOverride 1002 null;
        "fsGroupChangePolicy" = mkOverride 1002 null;
        "runAsGroup" = mkOverride 1002 null;
        "runAsNonRoot" = mkOverride 1002 null;
        "runAsUser" = mkOverride 1002 null;
        "seLinuxOptions" = mkOverride 1002 null;
        "seccompProfile" = mkOverride 1002 null;
        "supplementalGroups" = mkOverride 1002 null;
        "sysctls" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecSecurityContextSeLinuxOptions" =
      {

        options = {
          "level" = mkOption {
            description = "Level is SELinux level label that applies to the container.";
            type = (types.nullOr types.str);
          };
          "role" = mkOption {
            description = "Role is a SELinux role label that applies to the container.";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "Type is a SELinux type label that applies to the container.";
            type = (types.nullOr types.str);
          };
          "user" = mkOption {
            description = "User is a SELinux user label that applies to the container.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "level" = mkOverride 1002 null;
          "role" = mkOverride 1002 null;
          "type" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecSecurityContextSeccompProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecSecurityContextSysctls" =
      {

        options = {
          "name" = mkOption {
            description = "Name of a property to set";
            type = types.str;
          };
          "value" = mkOption {
            description = "Value of a property to set";
            type = types.str;
          };
        };

        config = { };

      };
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversHttp01IngressPodTemplateSpecTolerations" = {

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
    "cert-manager.io.v1.ClusterIssuerSpecAcmeSolversSelector" = {

      options = {
        "dnsNames" = mkOption {
          description = "List of DNSNames that this solver will be used to solve.\nIf specified and a match is found, a dnsNames selector will take\nprecedence over a dnsZones selector.\nIf multiple solvers match with the same dnsNames value, the solver\nwith the most matching labels in matchLabels will be selected.\nIf neither has more matches, the solver defined earlier in the list\nwill be selected.";
          type = (types.nullOr (types.listOf types.str));
        };
        "dnsZones" = mkOption {
          description = "List of DNSZones that this solver will be used to solve.\nThe most specific DNS zone match specified here will take precedence\nover other DNS zone matches, so a solver specifying sys.example.com\nwill be selected over one specifying example.com for the domain\nwww.sys.example.com.\nIf multiple solvers match with the same dnsZones value, the solver\nwith the most matching labels in matchLabels will be selected.\nIf neither has more matches, the solver defined earlier in the list\nwill be selected.";
          type = (types.nullOr (types.listOf types.str));
        };
        "matchLabels" = mkOption {
          description = "A label selector that is used to refine the set of certificate's that\nthis challenge solver will apply to.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "dnsNames" = mkOverride 1002 null;
        "dnsZones" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecCa" = {

      options = {
        "crlDistributionPoints" = mkOption {
          description = "The CRL distribution points is an X.509 v3 certificate extension which identifies\nthe location of the CRL from which the revocation of this certificate can be checked.\nIf not set, certificates will be issued without distribution points set.";
          type = (types.nullOr (types.listOf types.str));
        };
        "issuingCertificateURLs" = mkOption {
          description = "IssuingCertificateURLs is a list of URLs which this issuer should embed into certificates\nit creates. See https://www.rfc-editor.org/rfc/rfc5280#section-4.2.2.1 for more details.\nAs an example, such a URL might be \"http://ca.domain.com/ca.crt\".";
          type = (types.nullOr (types.listOf types.str));
        };
        "ocspServers" = mkOption {
          description = "The OCSP server list is an X.509 v3 extension that defines a list of\nURLs of OCSP responders. The OCSP responders can be queried for the\nrevocation status of an issued certificate. If not set, the\ncertificate will be issued with no OCSP servers set. For example, an\nOCSP server URL could be \"http://ocsp.int-x3.letsencrypt.org\".";
          type = (types.nullOr (types.listOf types.str));
        };
        "secretName" = mkOption {
          description = "SecretName is the name of the secret used to sign Certificates issued\nby this Issuer.";
          type = types.str;
        };
      };

      config = {
        "crlDistributionPoints" = mkOverride 1002 null;
        "issuingCertificateURLs" = mkOverride 1002 null;
        "ocspServers" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecSelfSigned" = {

      options = {
        "crlDistributionPoints" = mkOption {
          description = "The CRL distribution points is an X.509 v3 certificate extension which identifies\nthe location of the CRL from which the revocation of this certificate can be checked.\nIf not set certificate will be issued without CDP. Values are strings.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "crlDistributionPoints" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVault" = {

      options = {
        "auth" = mkOption {
          description = "Auth configures how cert-manager authenticates with the Vault server.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultAuth");
        };
        "caBundle" = mkOption {
          description = "Base64-encoded bundle of PEM CAs which will be used to validate the certificate\nchain presented by Vault. Only used if using HTTPS to connect to Vault and\nignored for HTTP connections.\nMutually exclusive with CABundleSecretRef.\nIf neither CABundle nor CABundleSecretRef are defined, the certificate bundle in\nthe cert-manager controller container is used to validate the TLS connection.";
          type = (types.nullOr types.str);
        };
        "caBundleSecretRef" = mkOption {
          description = "Reference to a Secret containing a bundle of PEM-encoded CAs to use when\nverifying the certificate chain presented by Vault when using HTTPS.\nMutually exclusive with CABundle.\nIf neither CABundle nor CABundleSecretRef are defined, the certificate bundle in\nthe cert-manager controller container is used to validate the TLS connection.\nIf no key for the Secret is specified, cert-manager will default to 'ca.crt'.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultCaBundleSecretRef"));
        };
        "clientCertSecretRef" = mkOption {
          description = "Reference to a Secret containing a PEM-encoded Client Certificate to use when the\nVault server requires mTLS.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultClientCertSecretRef"));
        };
        "clientKeySecretRef" = mkOption {
          description = "Reference to a Secret containing a PEM-encoded Client Private Key to use when the\nVault server requires mTLS.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultClientKeySecretRef"));
        };
        "namespace" = mkOption {
          description = "Name of the vault namespace. Namespaces is a set of features within Vault Enterprise that allows Vault environments to support Secure Multi-tenancy. e.g: \"ns1\"\nMore about namespaces can be found here https://www.vaultproject.io/docs/enterprise/namespaces";
          type = (types.nullOr types.str);
        };
        "path" = mkOption {
          description = "Path is the mount path of the Vault PKI backend's `sign` endpoint, e.g:\n\"my_pki_mount/sign/my-role-name\".";
          type = types.str;
        };
        "server" = mkOption {
          description = "Server is the connection address for the Vault server, e.g: \"https://vault.example.com:8200\".";
          type = types.str;
        };
        "serverName" = mkOption {
          description = "ServerName is used to verify the hostname on the returned certificates\nby the Vault server.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "caBundle" = mkOverride 1002 null;
        "caBundleSecretRef" = mkOverride 1002 null;
        "clientCertSecretRef" = mkOverride 1002 null;
        "clientKeySecretRef" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "serverName" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultAuth" = {

      options = {
        "appRole" = mkOption {
          description = "AppRole authenticates with Vault using the App Role auth mechanism,\nwith the role and secret stored in a Kubernetes Secret resource.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultAuthAppRole"));
        };
        "clientCertificate" = mkOption {
          description = "ClientCertificate authenticates with Vault by presenting a client\ncertificate during the request's TLS handshake.\nWorks only when using HTTPS protocol.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultAuthClientCertificate")
          );
        };
        "kubernetes" = mkOption {
          description = "Kubernetes authenticates with Vault by passing the ServiceAccount\ntoken stored in the named Secret resource to the Vault server.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultAuthKubernetes"));
        };
        "tokenSecretRef" = mkOption {
          description = "TokenSecretRef authenticates with Vault by presenting a token.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultAuthTokenSecretRef"));
        };
      };

      config = {
        "appRole" = mkOverride 1002 null;
        "clientCertificate" = mkOverride 1002 null;
        "kubernetes" = mkOverride 1002 null;
        "tokenSecretRef" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultAuthAppRole" = {

      options = {
        "path" = mkOption {
          description = "Path where the App Role authentication backend is mounted in Vault, e.g:\n\"approle\"";
          type = types.str;
        };
        "roleId" = mkOption {
          description = "RoleID configured in the App Role authentication backend when setting\nup the authentication backend in Vault.";
          type = types.str;
        };
        "secretRef" = mkOption {
          description = "Reference to a key in a Secret that contains the App Role secret used\nto authenticate with Vault.\nThe `key` field must be specified and denotes which entry within the Secret\nresource is used as the app role secret.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultAuthAppRoleSecretRef");
        };
      };

      config = { };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultAuthAppRoleSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultAuthClientCertificate" = {

      options = {
        "mountPath" = mkOption {
          description = "The Vault mountPath here is the mount path to use when authenticating with\nVault. For example, setting a value to `/v1/auth/foo`, will use the path\n`/v1/auth/foo/login` to authenticate with Vault. If unspecified, the\ndefault value \"/v1/auth/cert\" will be used.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the certificate role to authenticate against.\nIf not set, matching any certificate role, if available.";
          type = (types.nullOr types.str);
        };
        "secretName" = mkOption {
          description = "Reference to Kubernetes Secret of type \"kubernetes.io/tls\" (hence containing\ntls.crt and tls.key) used to authenticate to Vault using TLS client\nauthentication.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "mountPath" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultAuthKubernetes" = {

      options = {
        "mountPath" = mkOption {
          description = "The Vault mountPath here is the mount path to use when authenticating with\nVault. For example, setting a value to `/v1/auth/foo`, will use the path\n`/v1/auth/foo/login` to authenticate with Vault. If unspecified, the\ndefault value \"/v1/auth/kubernetes\" will be used.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "A required field containing the Vault Role to assume. A Role binds a\nKubernetes ServiceAccount with a set of Vault policies.";
          type = types.str;
        };
        "secretRef" = mkOption {
          description = "The required Secret field containing a Kubernetes ServiceAccount JWT used\nfor authenticating with Vault. Use of 'ambient credentials' is not\nsupported.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultAuthKubernetesSecretRef")
          );
        };
        "serviceAccountRef" = mkOption {
          description = "A reference to a service account that will be used to request a bound\ntoken (also known as \"projected token\"). Compared to using \"secretRef\",\nusing this field means that you don't rely on statically bound tokens. To\nuse this field, you must configure an RBAC rule to let cert-manager\nrequest a token.";
          type = (
            types.nullOr (
              submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVaultAuthKubernetesServiceAccountRef"
            )
          );
        };
      };

      config = {
        "mountPath" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "serviceAccountRef" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultAuthKubernetesSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultAuthKubernetesServiceAccountRef" = {

      options = {
        "audiences" = mkOption {
          description = "TokenAudiences is an optional list of extra audiences to include in the token passed to Vault. The default token\nconsisting of the issuer's namespace and name is always included.";
          type = (types.nullOr (types.listOf types.str));
        };
        "name" = mkOption {
          description = "Name of the ServiceAccount used to request a token.";
          type = types.str;
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultAuthTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultCaBundleSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultClientCertSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVaultClientKeySecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVenafi" = {

      options = {
        "cloud" = mkOption {
          description = "Cloud specifies the Venafi cloud configuration settings.\nOnly one of TPP or Cloud may be specified.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVenafiCloud"));
        };
        "tpp" = mkOption {
          description = "TPP specifies Trust Protection Platform configuration settings.\nOnly one of TPP or Cloud may be specified.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVenafiTpp"));
        };
        "zone" = mkOption {
          description = "Zone is the Venafi Policy Zone to use for this issuer.\nAll requests made to the Venafi platform will be restricted by the named\nzone policy.\nThis field is required.";
          type = types.str;
        };
      };

      config = {
        "cloud" = mkOverride 1002 null;
        "tpp" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVenafiCloud" = {

      options = {
        "apiTokenSecretRef" = mkOption {
          description = "APITokenSecretRef is a secret key selector for the Venafi Cloud API token.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVenafiCloudApiTokenSecretRef");
        };
        "url" = mkOption {
          description = "URL is the base URL for Venafi Cloud.\nDefaults to \"https://api.venafi.cloud/\".";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "url" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVenafiCloudApiTokenSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVenafiTpp" = {

      options = {
        "caBundle" = mkOption {
          description = "Base64-encoded bundle of PEM CAs which will be used to validate the certificate\nchain presented by the TPP server. Only used if using HTTPS; ignored for HTTP.\nIf undefined, the certificate bundle in the cert-manager controller container\nis used to validate the chain.";
          type = (types.nullOr types.str);
        };
        "caBundleSecretRef" = mkOption {
          description = "Reference to a Secret containing a base64-encoded bundle of PEM CAs\nwhich will be used to validate the certificate chain presented by the TPP server.\nOnly used if using HTTPS; ignored for HTTP. Mutually exclusive with CABundle.\nIf neither CABundle nor CABundleSecretRef is defined, the certificate bundle in\nthe cert-manager controller container is used to validate the TLS connection.";
          type = (
            types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVenafiTppCaBundleSecretRef")
          );
        };
        "credentialsRef" = mkOption {
          description = "CredentialsRef is a reference to a Secret containing the Venafi TPP API credentials.\nThe secret must contain the key 'access-token' for the Access Token Authentication,\nor two keys, 'username' and 'password' for the API Keys Authentication.";
          type = (submoduleOf "cert-manager.io.v1.ClusterIssuerSpecVenafiTppCredentialsRef");
        };
        "url" = mkOption {
          description = "URL is the base URL for the vedsdk endpoint of the Venafi TPP instance,\nfor example: \"https://tpp.example.com/vedsdk\".";
          type = types.str;
        };
      };

      config = {
        "caBundle" = mkOverride 1002 null;
        "caBundleSecretRef" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVenafiTppCaBundleSecretRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the entry in the Secret resource's `data` field to be used.\nSome instances of this field may be defaulted, in others it may be\nrequired.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = {
        "key" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerSpecVenafiTppCredentialsRef" = {

      options = {
        "name" = mkOption {
          description = "Name of the resource being referred to.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
      };

      config = { };

    };
    "cert-manager.io.v1.ClusterIssuerStatus" = {

      options = {
        "acme" = mkOption {
          description = "ACME specific status options.\nThis field should only be set if the Issuer is configured to use an ACME\nserver to issue certificates.";
          type = (types.nullOr (submoduleOf "cert-manager.io.v1.ClusterIssuerStatusAcme"));
        };
        "conditions" = mkOption {
          description = "List of status conditions to indicate the status of a CertificateRequest.\nKnown condition types are `Ready`.";
          type = (
            types.nullOr (types.listOf (submoduleOf "cert-manager.io.v1.ClusterIssuerStatusConditions"))
          );
        };
      };

      config = {
        "acme" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerStatusAcme" = {

      options = {
        "lastPrivateKeyHash" = mkOption {
          description = "LastPrivateKeyHash is a hash of the private key associated with the latest\nregistered ACME account, in order to track changes made to registered account\nassociated with the Issuer";
          type = (types.nullOr types.str);
        };
        "lastRegisteredEmail" = mkOption {
          description = "LastRegisteredEmail is the email associated with the latest registered\nACME account, in order to track changes made to registered account\nassociated with the  Issuer";
          type = (types.nullOr types.str);
        };
        "uri" = mkOption {
          description = "URI is the unique account identifier, which can also be used to retrieve\naccount details from the CA";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastPrivateKeyHash" = mkOverride 1002 null;
        "lastRegisteredEmail" = mkOverride 1002 null;
        "uri" = mkOverride 1002 null;
      };

    };
    "cert-manager.io.v1.ClusterIssuerStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "LastTransitionTime is the timestamp corresponding to the last status\nchange of this condition.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Message is a human readable description of the details of the last\ntransition, complementing reason.";
          type = (types.nullOr types.str);
        };
        "observedGeneration" = mkOption {
          description = "If set, this represents the .metadata.generation that the condition was\nset based upon.\nFor instance, if .metadata.generation is currently 12, but the\n.status.condition[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the Issuer.";
          type = (types.nullOr types.int);
        };
        "reason" = mkOption {
          description = "Reason is a brief machine readable explanation for the condition's last\ntransition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of (`True`, `False`, `Unknown`).";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of the condition, known values are (`Ready`).";
          type = types.str;
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "cert-manager.io"."v1"."ClusterIssuer" = mkOption {
        description = "A ClusterIssuer represents a certificate issuing authority which can be\nreferenced as part of `issuerRef` fields.\nIt is similar to an Issuer, however it is cluster-scoped and therefore can\nbe referenced by resources that exist in *any* namespace, not just the same\nnamespace as the referent.";
        type = (
          types.attrsOf (
            submoduleForDefinition "cert-manager.io.v1.ClusterIssuer" "clusterissuers" "ClusterIssuer"
              "cert-manager.io"
              "v1"
          )
        );
        default = { };
      };

    }
    // {
      "clusterIssuers" = mkOption {
        description = "A ClusterIssuer represents a certificate issuing authority which can be\nreferenced as part of `issuerRef` fields.\nIt is similar to an Issuer, however it is cluster-scoped and therefore can\nbe referenced by resources that exist in *any* namespace, not just the same\nnamespace as the referent.";
        type = (
          types.attrsOf (
            submoduleForDefinition "cert-manager.io.v1.ClusterIssuer" "clusterissuers" "ClusterIssuer"
              "cert-manager.io"
              "v1"
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
        name = "clusterissuers";
        group = "cert-manager.io";
        version = "v1";
        kind = "ClusterIssuer";
        attrName = "clusterIssuers";
      }
    ];

    resources = {
      "cert-manager.io"."v1"."ClusterIssuer" = mkAliasDefinitions options.resources."clusterIssuers";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [ ];
  };
}
