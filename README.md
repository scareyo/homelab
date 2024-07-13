# homelab

My Harvester homelab infrastructure

## Getting Started

To start up Podman for the first time, run

```
just init
```

## Metal Deployments

### deploy-seraphim

Seraphim cluster (4-node Minisforum MS-01) will be booted and Harvester will be installed via PXE boot

- `s-snake`
- `s-bear`
- `s-hawk`
- `s-shark`

#### Requirements

1. All nodes must be powered off
2. Ansible host is connected to the Service VLAN
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

Ansible will spin up a PXE server, and each node will be booted to PXE. With a 1GbE connection, this process takes about 30 minutes.

```
just play deploy-seraphim
```
