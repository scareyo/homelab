# homelab

My Harvester homelab infrastructure

## Metal Deployments

### deploy-seraphim

Seraphim cluster (4-node Minisforum MS-01) will be (re)booted and Harvester will be installed via PXE boot

#### Requirements

1. Connected to the Service VLAN
2. Podman
3. Target machines should be able to access the following host ports:

    - `67/udp (DHCP)`
    - `69/udp (TFTP)`
    - `80/tcp (HTTP)`

#### Deploy

```
just deploy-seraphim
```
