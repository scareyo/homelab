default:
  just --list

podman_machine := "podman-machine-homelab"

init:
  #!/usr/bin/env sh
  podman machine inspect {{ podman_machine }} 1> /dev/null
  if [[ $? -ne 0 ]]; then
    podman machine stop
    podman machine init {{ podman_machine }} --rootful 2> /dev/null
    podman machine start {{ podman_machine }}
  elif [[ "Stopped" == $(podman machine inspect {{ podman_machine }} --format "{{{{ .State }}") ]]; then
    podman machine stop
    podman machine start {{ podman_machine }}
  fi
  podman context use {{ podman_machine }}-root

play playbook:
  ansible-playbook -i ./ansible/inventory.yaml ./ansible/{{ playbook }}.yaml --ask-become-pass

destroy-all:
  podman system prune --all --volumes --force

destroy-meshcentral:
  podman stop meshcentral
  podman rm meshcentral
  podman volume rm meshcentral-data
