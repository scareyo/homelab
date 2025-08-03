# App of Apps

This chart templates an ApplicationSet to create Argo CD applications. Each project defined in values.yaml is an ApplicationSet that creates an Application for each `app.yaml`

## values.yaml

```yaml
# 

# A list of projects
projects:

    # Name of the project
  - name: project-name

    # Optional. A list of application names in the desired sync order. If
    # defined, ProgressiveSync is enabled for the ApplicationSet.
    #
    # ProgressiveSync must be enabled in Argo CD config.
    steps:
      - cilium
      - external-secrets
      - hcloud
      - cert-manager
      - gateway
      - argocd
```

## app.yaml

Each application should define an `app.yaml` file. The directory structure is as follows:

```
k8s/
  project-name/
    app1/
      app.yaml
      ... (k8s manifests)
    app2/
      app.yaml
    ...
```

```yaml
# (required) string - Name of the application
name: app1

# (required) string - Namespace of the application
namespace: app1

# bool - Enable autosync. Does not apply if ApplicationSet uses ProgressiveSync. Default false.
autosync: false

# list - A list of Argo CD sources
sources:

    # string - Type of source (helm, dir)
  - type: helm

    # string - Helm chart name
    chart: external-secrets

    # string - Helm chart repo URL
    repoURL: https://charts.external-secrets.io

    # string - Helm chart version
    targetRevision: 0.18.2

  - type: dir

    # string - Path to the directory containing manifests relative to the app
    # directory. Default is the app directory.
    path: manifests
```
