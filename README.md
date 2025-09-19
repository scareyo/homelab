# homelab

My k8s homelab infrastructure

## Overview

### Seraphim

Seraphim is the 4-node Minisforum MS-01 cluster running the Cozystack platform.

- `s-snake  - control plane`
- `s-hawk   - control plane`
- `s-bear   - control plane`
- `s-shark  - worker`

### Zeus

Zeus is a Hetzner Cloud VPS used to expose services running on the Cozystack platform to the internet.

## Setup

### Requirements

1. All nodes must be powered off
2. Ansible host is connected to the IPMI VLAN
3. Ansible host has the following ports allowed by firewall:

    - `67/udp   (DHCP)`
    - `69/udp   (TFTP)`
    - `4011/udp (DHCP)`
    - `8080/tcp (HTTP)`

4. `HCLOUD_TOKEN` environment variable is set

### Seraphim

1. Provision the Seraphim cluster:

```
just play provision-seraphim
```

2. Configure the Seraphim cluster:

```
just play configure-seraphim
```

### Zeus

1. Provision and configure the Hetzner Cloud VPS:

```
just play provision-zeus
```

## Destroy

### Seraphim

This command is destructive. It will wipe the Seraphim data disks, reset Talos Linux, and power down the node.

```
just play destroy-seraphim
```

### Zeus

TODO: Create a playbook to tear down Hetzner Cloud resources
