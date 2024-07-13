default:
  just --list

podman_start := if `podman machine info -f "{{ .Host.CurrentMachine }}"` == "" {
    "podman machine init --now --rootful"
  } else if `podman machine info -f "{{ .Host.MachineState }}"` != "Running" {
    "podman machine start"
  } else {
    "echo Machine already running"
  }

init:
  @{{ podman_start }}

clear:
  sudo podman stop --all
  sudo podman rm --all

deploy-nami:
  ansible-playbook -i ./ansible/inventory.yaml ./ansible/deploy-nami.yaml --ask-become-pass

deploy-seraphim:
  ansible-playbook -i ./ansible/inventory.yaml ./ansible/deploy-seraphim.yaml --ask-become-pass
