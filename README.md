# homelab

I use these playbooks to setup and maintain my homelab. The playbooks are very specific to my setup.

## Initial steps

1. Install OS on Dell R720
2. Configure SSH public key login
3. Download Ansible requirements:
```ansible-galaxy install -r requirements.yaml```

## Hypervisor setup

```ansible-playbook -i inventory.yaml playbooks/setup_hypervisor.yaml```

## VM setup

```ansible-playbook -i inventory.yaml playbooks/provision_vms.yaml```

```ansible-playbook -i inventory.yaml playbooks/setup_vms.yaml```
