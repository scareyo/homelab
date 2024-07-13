# homelab

My Harvester homelab infrastructure

## Metal Deployments

### deploy-nami

Nami (Dell R720) will be (re)booted and Harvester will be installed

#### Requirements

1. Connected to the management VLAN
2. Rootful Podman
3. Firewall

    - `67/udp (DHCP)`
    - `69/udp (TFTP)`
    - `80/tcp (HTTP)`

#### Deploy

```
just deploy-nami
```

## Virtual Machines

### NAS

### Kubernetes
