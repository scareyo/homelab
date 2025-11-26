# homelab

My k8s homelab infrastructure

## Overview

### Seraphim

Seraphim is the 4-node Minisforum MS-01 cluster running Talos Linux.

- `s-snake  - control plane`
- `s-hawk   - control plane`
- `s-bear   - control plane`
- `s-shark  - worker`

### Zeus

Zeus is a Hetzner Cloud VPS used to expose cluster applications to the internet.

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

1. Create the Seraphim cluster

```
just play create-seraphim
```
