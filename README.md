# homelab

My k8s homelab infrastructure

## Getting Started

To start up Podman for the first time, run

```
just init
```

## Metal Deployments

### deploy-seraphim

Seraphim cluster (4-node Minisforum MS-01) will be booted and Talos will be installed via PXE boot. After installation, it will be bootstrapped and services will be deployed with Argo CD

- `s-snake  - control plane`
- `s-hawk   - control plane`
- `s-bear   - control plane`
- `s-shark  - worker`

#### Requirements

1. All nodes must be powered off
2. Ansible host is connected to the cluster VLAN
3. Target machines should be able to access the following host ports:

    - `67/udp   (DHCP)`
    - `69/udp   (TFTP)`
    - `4011/udp (DHCP)`
    - `8080/tcp (HTTP)`

#### Start MeshCentral (optional)

MeshCentral is used to access the remote desktop for each node. We can use this to observe the installation process.

```
just play run-meshcentral
```

#### Deploy

1. Ansible spins up a PXE server
2. Each node boots to PXE
3. Talos is installed and bootstrapped
4. Cilium is deployed to the cluster
5. Argo CD is deployed to the cluster, along with its managed applications

```
just play deploy-seraphim
```

#### Destroy

This command is destructive. It will reset the Talos cluster and power down the machines.

```
just destroy-talos
```
