# Omni

This directory contains manifests for the Omni cluster definition.

## Sync Cluster

To create and sync the Omni infrastructure:

```sh
just sync
```

## Bootstrap

When creating a new cluster, wait for the cluster to reach the status `Running`. Then bootstrap Nixidy and External Secrets:

```
just bootstrap
```

Sync Argo CD system applications in order:

1. cilium
2. external-secrets
3. cert-manager
4. external-snapshotter
5. velero
6. external-dns
7. agentgateway
8. gateway
9. openebs
10. rook
11. cnpg
12. pocket-id
13. monitoring
14. argocd
